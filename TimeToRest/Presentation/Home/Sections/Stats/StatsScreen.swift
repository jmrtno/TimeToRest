import Foundation
import SwiftUI

// MARK: - StatsScreen
/// The main screen of the app.
/// Transforms inline into night mode when the rest window is active.
/// No separate night mode screen — the home screen itself changes.
struct StatsScreen: View {

    var statsViewModel: StatsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @State private var isContentVisible = false
    @State private var isChartVisible = false
    @State private var displayedCurrentStreak = 0
    @State private var displayedBestStreak = 0
    @State private var displayedBreaksThisWeek = 0
    @State private var displayedBreakRatePercentage = 0

    init(statsViewModel: StatsViewModel) {
        self.statsViewModel = statsViewModel
    }
    
    // MARK: - Stats Content
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                stage(statsHeaderSection, delay: 0.0)
                statsGrid
                stage(restBreaks, delay: 0.24)
                stage(breakRateChart, delay: 0.36)
                stage(averageStartTime, delay: 0.48)
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .onAppear {
            statsViewModel.onAppear()
        }
        .task {
            await runEntranceAnimations()
        }
        .onChange(of: statsViewModel.stats) { _, newStats in
            syncDisplayedStats(with: newStats)
        }
    }
    
    // MARK: - Stats Header
    
    private var statsHeaderSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(.orange)
            
            Text("Your Progress")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            Text("Every night counts")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            stage(currentStreakCard, delay: 0.10)
            stage(bestStreakCard, delay: 0.18)
        }
    }
    
    private var currentStreakCard: some View {
        StatsGlassCardSectionView(icon: "trophy",
                                  title: "Current Streak",
                                  value: "\(displayedCurrentStreak)",
                                  iconColor: .orange,
                                  animateNumbers: true)
    }
    
    private var bestStreakCard: some View {
        StatsGlassCardSectionView(icon: "shield",
                                  title: "Best Streak",
                                  value: "\(displayedBestStreak)",
                                  iconColor: .indigo,
                                  animateNumbers: true)
    }
    
    // MARK: - Stats Rest Breaks
    
    private var restBreaks: some View {
        BigGlassCard(icon: "nosign",
                       title: "Rest breaks",
                       subtitle: "This week",
                       value: "\(displayedBreaksThisWeek)",
                       color: .red,
                       animateNumbers: true,
                       content: nil)
    }
    
    // MARK: - Stats Break Rate Chart

    private var breakRateChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            BigGlassCard(icon: "waveform.path.ecg",
                           title: "Break Rate 15d",
                           subtitle: "Daily break / no break",
                           value: "\(displayedBreakRatePercentage)%",
                           color: .red,
                           animateNumbers: true,
                           content: {
                
                VStack {
                    BreakRateDailyChart(values: statsViewModel.breakRateDailySeries, isVisible: isChartVisible)
                        .frame(height: 120)
                    
                    HStack {
                        Text("Oldest")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                        Spacer()
                        Text("Break-free: \(statsViewModel.breakFreeDaysCount)/\(statsViewModel.totalTrackedDays)")
                            .font(.caption2)
                            .foregroundStyle(.green.opacity(0.85))
                        Text("Breaks: \(statsViewModel.breakDaysCount)/\(statsViewModel.totalTrackedDays)")
                            .font(.caption2)
                            .foregroundStyle(.red.opacity(0.85))
                        Spacer()
                        Text("Today")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.45))
                    }
                }
            })
        }
    }
    
    // MARK: - Stats Average Start Time
    
    private var averageStartTime: some View {
        BigGlassCard(icon: "clock.badge",
                       title: "Average start time",
                       subtitle: "Last 15 days",
                       value: statsViewModel.formattedAverageStartTime,
                       color: .green,
                       content: nil)
    }
}

// MARK: - Animations

private extension StatsScreen {

    func runEntranceAnimations() async {
        withAnimation(.smooth(duration: 0.55, extraBounce: 0.04)) {
            isContentVisible = true
        }
        try? await Task.sleep(for: .seconds(0.5))
        syncDisplayedStats(with: statsViewModel.stats)
        try? await Task.sleep(for: .seconds(0.6))
        isChartVisible = true
    }

    /// Keeps the animated counters aligned with the source of truth, so a reload
    /// cannot leave them showing stale values.
    func syncDisplayedStats(with stats: RestStatsEntity) {
        withAnimation(.default) {
            displayedCurrentStreak = stats.currentStreak
            displayedBestStreak = stats.bestStreak
            displayedBreaksThisWeek = stats.breaksThisWeek
            displayedBreakRatePercentage = statsViewModel.breakRatePercentage
        }
    }

    @ViewBuilder
    func stage<Content: View>(_ view: Content, delay: TimeInterval) -> some View {
        if reduceMotion {
            view
                .opacity(isContentVisible ? 1 : 0)
                .animation(.smooth(duration: 0.4).delay(delay), value: isContentVisible)
        } else {
            view
                .offset(y: isContentVisible ? 0 : 16)
                .opacity(isContentVisible ? 1 : 0)
                .blur(radius: isContentVisible ? 0 : 4)
                .animation(.smooth(duration: 0.65, extraBounce: 0.04).delay(delay), value: isContentVisible)
        }
    }
}

#if DEBUG
#Preview {
    struct MockSessionRepo: RestSessionRepositoryContract {
        func fetchAll() -> [RestSessionEntity] { [] }
        func fetch(for day: Date) -> RestSessionEntity? { nil }
        func save(_ session: RestSessionEntity) async {}
        func update(_ session: RestSessionEntity) async {}
        func delete(_ session: RestSessionEntity) async {}
    }
    return ZStack {
        Color.black.ignoresSafeArea()
        StatsScreen(statsViewModel: StatsViewModel(calculateStatsUseCase: CalculateStatsUseCase(repository: MockSessionRepo())))
    }
}
#endif
