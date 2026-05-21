import SwiftUI
import FamilyControls
import FoundationModels

// MARK: - SetupScreen
/// Full-screen modal for configuring the rest schedule.
/// In mandatory mode: cannot be dismissed without saving.
/// In editable mode: can be cancelled.
struct SetupScreen: View {
    
    @StateObject var viewModel: SetupViewModel
    @EnvironmentObject private var router: Router
    @State private var suggestionText: String = ""
    @State private var isLoadingTip: Bool = true
    @State private var showSettingsAlert: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    timePickersSection
                    notAllowedAppsSection
                    coachText
                    footerText
                }
                .padding(.horizontal, 24)
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(viewModel.mode == .mandatory)
        .toolbar {
            if viewModel.canCancel {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        router.dismissRestConfiguration()
                    }
                    .foregroundStyle(.white.opacity(0.6))
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(viewModel.mode == .mandatory ? "Start Resting" : "Save") {
                    Task {
                        await viewModel.save()
                    }
                }
                .foregroundStyle(.white.opacity(0.6))
            }
        }
        .onAppear {
            viewModel.onSave = {
                router.dismissRestConfiguration()
            }
        }
        .familyActivityPicker(
            isPresented: $viewModel.isFamilyActivityPickerPresented,
            selection: $viewModel.blockedSelection
        )
    }
}

// MARK: - Views

private extension SetupScreen {

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if viewModel.mode == .mandatory {
                Text("Let's set a limit for tonight.")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 12)

                Text("It takes less than 30 seconds")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                Text("Configuration")
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .padding(.top, 12)
            }
        }
        .task {
            suggestionText = await getItem()
            isLoadingTip = false
        }
    }

    // MARK: - Time Pickers

    private var timePickersSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Night Schedule")
                .textCase(.uppercase)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.4))
            timeRow(label: "Start time", selection: $viewModel.startTime)
            timeRow(label: "End time", selection: $viewModel.endTime)
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }

    private func timeRow(label: String, selection: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(.body)
                .foregroundStyle(.white.opacity(0.8))

            Spacer()

            DatePicker(
                "",
                selection: selection,
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .tint(.orange)
            .colorScheme(.dark)
        }
    }
    
    // MARK: - Blocked Apps

    private var notAllowedAppsSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Blocks during your rest")
                    .textCase(.uppercase)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 16)

                Text("Selected apps will be blocked automatically while you rest.")
                    .font(.headline)
                    .foregroundStyle(.white)

                Button {
                    viewModel.isFamilyActivityPickerPresented = true
                } label: {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.orange.opacity(0.1))
                                .frame(width: 48, height: 48)
                            Image(systemName: "lock.app.dashed")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundStyle(.orange)
                        }
                        Text("Select apps")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)
                    }
                }
                
                Text("Apps blocked: \(viewModel.blockedSocialAppsDescription).")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
            
            Spacer()
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
    
    // MARK: - Coach

    private var coachText: some View {
        Group {
            if viewModel.mode == .editable {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AI Coach:")
                            .textCase(.uppercase)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white.opacity(0.4))
                            .padding(.bottom, 16)
                        
                        if isLoadingTip {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .tint(.orange)
                                Text("Loading tip...")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(suggestionText)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.75))
                                
                                if suggestionText.contains("Apple Intelligence is not enabled") {
                                    Button("Open Settings") {
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(url)
                                        }
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(16)
                .glassEffect(in: .rect(cornerRadius: 24))
            }
        }
    }

    // MARK: - Footer

    private var footerText: some View {
        Group {
            if viewModel.mode == .mandatory {
                Text("You can change this whenever you want.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .padding(.bottom, 40)
    }
}

// MARK: - Coach Suggestions Logic

private extension SetupScreen {
    
    @Generable
    struct SearchSuggestions {
        @Guide(description: "A single, concise tip to prepare for a restful sleep")
        var tip: String
    }

    func getItem() async -> String {
        // Check model availability first
        let availability = SystemLanguageModel.default.availability
        switch availability {
        case .available:
            break
        case .unavailable(let reason):
            let errorMessage = switch reason {
            case .appleIntelligenceNotEnabled:
                "Apple Intelligence is not enabled. Please enable it in Settings > Apple & Siri."
            case .deviceNotEligible:
                "Apple Intelligence is not available on this device."
            case .modelNotReady:
                "AI Coach is getting ready. Please try again in a moment."
            @unknown default:
                "AI Coach is temporarily unavailable."
            }
            return errorMessage
        }
        
        do {
            let instructions = """
                You're a Sleep Optimisation Coach. Provide exactly one concise, \
                actionable tip in one or two short sentences. Address the user in the \
                second person ("you") and use a warm, encouraging tone. Each time you \
                respond, try to cover a different aspect of sleep hygiene to maximize \
                variety. Avoid repeating the same topics consecutively.
                """
            let session = LanguageModelSession(instructions: instructions)
            let prompt = """
                Give one single practical tip that a person should follow before going \
                to bed to ensure a restful night's sleep. Choose from these diverse \
                categories: screen time and blue light, breathing exercises and \
                meditation, room temperature and ventilation, lighting and darkness, \
                mattress and pillow comfort, evening wind-down routines, caffeine and \
                alcohol timing, exercise timing, noise reduction, aromatherapy, \
                journaling before bed, reading habits, shower or bath timing, \
                stretching or yoga, mindful eating in the evening, phone placement, \
                sleep schedule consistency, napping guidelines, stress management \
                techniques, or any other evidence-based sleep habit. Keep it to a \
                couple of lines.
                """
            let response = try await session.respond(
                to: prompt,
                generating: SearchSuggestions.self
            )
            return response.content.tip
        } catch {
            return "Unable to load AI Coach tips. Make sure your iPhone and Siri are set to the same language in Settings."
        }
    }
}
