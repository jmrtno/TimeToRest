import SwiftUI

// MARK: - StatsScreen
/// Statistics screen showing visual, simple stats without tables.
struct StatsScreen: View {

    @StateObject var viewModel: StatsViewModel

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    headerSection
                    statsGrid
                    motivationSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
            }
        }
        .preferredColorScheme(.dark)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onAppear()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("📊")
                .font(.system(size: 48))

            Text("Your Progress")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("Every night counts")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.top, 20)
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(
                    icon: "🔥",
                    title: "Current Streak",
                    value: "\(viewModel.stats.currentStreak)"
                )

                StatCard(
                    icon: "🏆",
                    title: "Best Streak",
                    value: "\(viewModel.stats.bestStreak)"
                )
            }

            HStack(spacing: 12) {
                StatCard(
                    icon: "📉",
                    title: "Breaks This Week",
                    value: "\(viewModel.stats.breaksThisWeek)"
                )

                StatCard(
                    icon: "⏱️",
                    title: "Minutes Avoided",
                    value: "\(viewModel.stats.totalAvoidedMinutes)"
                )
            }
        }
    }

    // MARK: - Motivation

    private var motivationSection: some View {
        VStack(spacing: 12) {
            if viewModel.stats.currentStreak > 0 {
                motivationCard(
                    message: streakMessage,
                    color: .orange
                )
            }

            if viewModel.stats.breaksThisWeek == 0 {
                motivationCard(
                    message: "Perfect week so far! Keep it up 💪",
                    color: .green
                )
            }
        }
        .padding(.bottom, 40)
    }

    private func motivationCard(message: String, color: Color) -> some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
            )
    }

    private var streakMessage: String {
        let streak = viewModel.stats.currentStreak
        switch streak {
        case 1: return "1 night down. The journey begins 🌱"
        case 2...4: return "\(streak) nights! Building momentum 🔥"
        case 5...9: return "\(streak) nights! You're on fire 🔥🔥"
        case 10...29: return "\(streak) nights! Incredible discipline 💪"
        default: return "\(streak) nights! You're unstoppable 🚀"
        }
    }
}
