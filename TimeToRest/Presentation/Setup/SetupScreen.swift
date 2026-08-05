import SwiftUI
import FamilyControls

// MARK: - SetupScreen
/// Full-screen modal for configuring the rest schedule.
/// In mandatory mode: cannot be dismissed without saving.
/// In editable mode: can be cancelled.
struct SetupScreen: View {

    @Bindable var viewModel: SetupViewModel
    @Environment(Router.self) private var router
    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion
    @State private var isContentSolid = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    materialize(header, delay: 0.0)
                    materialize(SetupTimePickerSectionView(startTime: $viewModel.startTime, endTime: $viewModel.endTime), delay: 0.3)
                    materialize(SetupNotAllowedAppsSectionView(viewModel: viewModel), delay: 0.6)
                    materialize(SetupAICoachSectionView(viewModel: viewModel), delay: 0.9)
                    materialize(footerText, delay: 1.2)
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
            viewModel.onSave = { didChangeSchedule in
                router.dismissRestConfiguration(didChangeSchedule: didChangeSchedule)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(0.2))
            isContentSolid = true
        }
        .task {
            await viewModel.loadSleepTip()
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
    
    private var header: some View {
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

    // MARK: - Materialize

    /// Condenses a section into place: it gains presence first, then sharpens and
    /// recovers its colour, without ever changing position or size.
    @ViewBuilder
    private func materialize<Content: View>(_ view: Content, delay: TimeInterval) -> some View {
        if reduceMotion {
            view
                .opacity(isContentSolid ? 1 : 0)
                .animation(.calmMaterialize.delay(delay), value: isContentSolid)
        } else {
            view
                .compositingGroup()
                .opacity(isContentSolid ? 1 : 0)
                .animation(.calmMaterialize.delay(delay), value: isContentSolid)
                .compositingGroup()
                .blur(radius: isContentSolid ? 0 : 14)
                .saturation(isContentSolid ? 1 : 0.4)
                .animation(.calmCondense.delay(delay), value: isContentSolid)
                .scrollTransition(.animated(.calmScroll)) { content, phase in
                    content
                        .opacity(phase.isIdentity ? 1 : 0.5)
                        .blur(radius: phase.isIdentity ? 0 : 2)
                }
        }
    }
}

// MARK: - Animation Curves

private extension Animation {
    /// Smooth spring with no bounce as the section gains presence.
    static let calmMaterialize = Animation.smooth(duration: 1.1, extraBounce: 0)

    /// Same smooth spring, stretched so the focus and colour condense slowly.
    static let calmCondense = Animation.smooth(duration: 1.4, extraBounce: 0)

    /// Shorter curve for motion driven by the user's scrolling.
    static let calmScroll = Animation.easeInOut(duration: 0.45)
}

#if DEBUG
#Preview {
    NavigationStack {
        SetupScreen(viewModel: .preview)
    }
    .environment(Router())
}
#endif
