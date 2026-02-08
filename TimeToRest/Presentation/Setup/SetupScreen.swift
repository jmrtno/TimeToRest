import SwiftUI

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
                VStack(spacing: 32) {
                    headerSection
                    timePickersSection
                    // allowedAppsSection 
                    strictModeToggle
                    saveButton
                    footerText
                }
                .padding(.horizontal, 24)
                .padding(.top, 40)
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
        }
        .onAppear {
            viewModel.onSave = {
                router.dismissRestConfiguration()
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("🌙")
                .font(.system(size: 56))

            if viewModel.mode == .mandatory {
                Text("Let's set a limit for tonight.")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("It takes less than 30 seconds")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))
            } else {
                Text("Edit your schedule")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Time Pickers

    private var timePickersSection: some View {
        VStack(spacing: 20) {
            timeRow(label: "Start time", selection: $viewModel.startTime)
            timeRow(label: "End time", selection: $viewModel.endTime)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
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

    // MARK: - Allowed Apps

    private var allowedAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Allowed apps (informational)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))

            HStack(spacing: 8) {
                ForEach(AllowedApp.allCases, id: \.self) { app in
                    AllowedAppChip(
                        app: app,
                        isSelected: viewModel.selectedApps.contains(app),
                        onTap: {
                            toggleApp(app)
                        }
                    )
                }
            }
        }
    }

    // MARK: - Strict Mode

    private var strictModeToggle: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("😈")
                    Text("Strict mode")
                        .font(.headline)
                        .foregroundStyle(.white)
                }

                Text("Longer countdown, more direct messages")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Toggle("", isOn: $viewModel.isStrictMode)
                .tint(.orange)
                .labelsHidden()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            viewModel.save()
        } label: {
            HStack {
                Text(viewModel.mode == .mandatory ? "Start Resting" : "Save Changes")
                if viewModel.mode == .mandatory {
                    Text("🌙")
                }
            }
            .font(.headline)
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.orange)
            )
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

    // MARK: - Helpers

    private func toggleApp(_ app: AllowedApp) {
        if viewModel.selectedApps.contains(app) {
            viewModel.selectedApps.remove(app)
        } else {
            viewModel.selectedApps.insert(app)
        }
    }
}
