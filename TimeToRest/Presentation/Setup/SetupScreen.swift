import SwiftUI
import FamilyControls

// MARK: - SetupScreen
/// Full-screen modal for configuring the rest schedule.
/// In mandatory mode: cannot be dismissed without saving.
/// In editable mode: can be cancelled.
struct SetupScreen: View {

    @StateObject var viewModel: SetupViewModel
    @EnvironmentObject private var router: Router

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    timePickersSection
                    notAllowedAppsSection
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
