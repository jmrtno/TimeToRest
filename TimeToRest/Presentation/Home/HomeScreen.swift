import SwiftUI

// MARK: - HomeScreen
/// The main screen of the app.
/// Transforms inline into night mode when the rest window is active.
/// No separate night mode screen — the home screen itself changes.
struct HomeScreen: View {

    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var router: Router

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.showNightMode {
                nightModeContent
            } else {
                dayContent
            }
        }
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.5), value: viewModel.showNightMode)
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onChange(of: router.navigationPath) { _, newPath in
            if newPath.isEmpty {
                viewModel.reload()
            }
        }
    }

    // MARK: - Day Content (normal mode)

    private var dayContent: some View {
        ScrollView {
            VStack(spacing: 32) {
                headerSection
                scheduleCard
                quickStatsSection
                actionsSection
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
        }
    }

    // MARK: - Night Mode Content (inline)

    private var nightModeContent: some View {
        VStack(spacing: 40) {
            Spacer()

            Text("😴")
                .font(.system(size: 80))

            VStack(spacing: 16) {
                Text("Time to rest.")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Come back tomorrow")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.5))

                if let lateMessage = viewModel.lateMessage {
                    Text(lateMessage)
                        .font(.subheadline)
                        .foregroundStyle(.orange.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
            }

            Spacer()
            
            Text("Keep the app open to track your streak")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.3))

            VStack(spacing: 16) {
                // Break the block
                Button {
                    router.push(.breakBlock)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(viewModel.isStrictMode ? .caption2 : .caption)
                        Text("Break the block")
                            .font(viewModel.isStrictMode ? .caption : .subheadline)
                    }
                    .foregroundStyle(.red.opacity(0.6))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, viewModel.isStrictMode ? 10 : 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.bottom, 50)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("🌙")
                .font(.system(size: 48))

            Text("Time To Rest")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Do you really need your phone right now?")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.top, 20)
    }

    // MARK: - Schedule Card

    private var scheduleCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your schedule")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("\(viewModel.formattedStartTime) → \(viewModel.formattedEndTime)")
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()

                Button {
                    router.presentRestConfiguration(mode: .editable)
                } label: {
                    Image(systemName: "gear")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            if viewModel.isStrictMode {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                    Text("Strict mode enabled")
                        .font(.caption)
                }
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Quick Stats

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This week")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.7))

            HStack(spacing: 12) {
                StatCard(
                    icon: "🔥",
                    title: "Streak",
                    value: "\(viewModel.stats.currentStreak)"
                )

                StatCard(
                    icon: "🏆",
                    title: "Best",
                    value: "\(viewModel.stats.bestStreak)"
                )

                StatCard(
                    icon: "⏱️",
                    title: "Avoided",
                    value: "\(viewModel.stats.totalAvoidedMinutes)m"
                )
            }
        }
    }

    // MARK: - Actions

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                router.push(.stats)
            } label: {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("View Statistics")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
            }
        }
        .padding(.bottom, 40)
    }
}
