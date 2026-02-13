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
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    timePickersSection
                    // allowedAppsSection 
                    strictModeToggle
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
                    viewModel.save()
                } 
                .foregroundStyle(.white.opacity(0.6))
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
                Text("Advanced")
                    .textCase(.uppercase)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.bottom, 16)
                HStack(spacing: 6) {
                    Image(systemName: "shield")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.indigo)
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

    // MARK: - Helpers

    private func toggleApp(_ app: AllowedApp) {
        if viewModel.selectedApps.contains(app) {
            viewModel.selectedApps.remove(app)
        } else {
            viewModel.selectedApps.insert(app)
        }
    }
}
