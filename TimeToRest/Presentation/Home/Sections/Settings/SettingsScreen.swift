import SwiftUI

// MARK: - SettingsScreen
/// The settings screen for configuring the grace period and notifications.
struct SettingsScreen: View {
    @Bindable var settingsViewModel: SettingsViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Settings")
                    .font(.title.bold())
                    .foregroundStyle(.white)

                BigGlassCard(
                    icon: "clock",
                    title: "Grace period",
                    subtitle: "Minutes after the session starts in which you can reconfigure without breaking the rest.",
                    value: "\(settingsViewModel.gracePeriodMinutes) min",
                    color: .orange
                ) {
                    Stepper(
                        value: $settingsViewModel.gracePeriodMinutes,
                        in: 0...10
                    ) {
                        EmptyView()
                    }
                    .tint(.orange)
                }

                BigGlassCard(
                    icon: "bell",
                    title: "Rest time notifications",
                    subtitle: "Notify me when it's time to rest.",
                    value: settingsViewModel.isNotificationsEnabled ? "On" : "Off",
                    color: .orange
                ) {
                    Toggle(isOn: $settingsViewModel.isNotificationsEnabled) {
                        EmptyView()
                    }
                    .tint(.orange)
                }

                Button {
                    Task {
                        await settingsViewModel.save()
                    }
                } label: {
                    Text("Save")
                        .font(.headline)
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .overlay(alignment: .bottom) {
                    if settingsViewModel.saveConfirmationVisible {
                        Label("Saved!", systemImage: "checkmark")
                            .font(.headline)
                            .foregroundStyle(.green)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .offset(y: 40)
                    }
                }
            }
            .padding(.horizontal, 24)
            .animation(.easeInOut, value: settingsViewModel.saveConfirmationVisible)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            settingsViewModel.onAppear()
        }
    }
}

#Preview {
    SettingsScreen(settingsViewModel: .preview)
        .preferredColorScheme(.dark)
}
