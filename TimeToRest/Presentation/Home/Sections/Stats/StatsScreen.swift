import Foundation
import SwiftUI

// MARK: - StatsScreen
/// The main screen of the app.
/// Transforms inline into night mode when the rest window is active.
/// No separate night mode screen — the home screen itself changes.
struct StatsScreen: View {

    @StateObject private var statsViewModel: StatsViewModel

    init(calculateStatsUseCase: CalculateStatsUseCase) {
        self._statsViewModel = StateObject(wrappedValue: StatsViewModel(
            calculateStatsUseCase: calculateStatsUseCase
        ))
    }
    
    // MARK: - Stats Content
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statsHeaderSection
                statsGrid
                restBreaks
                breakRateChart
                averageStartTime
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
        }
        .onAppear {
            statsViewModel.onAppear()
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
            StatsGlassCardSectionView(icon: "trophy",
                                      title: "Current Streak",
                                      value: "\(statsViewModel.stats.currentStreak)",
                                      iconColor: .orange)
            
            StatsGlassCardSectionView(icon: "shield",
                                      title: "Best Streak",
                                      value: "\(statsViewModel.stats.bestStreak)",
                                      iconColor: .indigo)
        }
    }
    
    // MARK: - Stats Rest Breaks
    
    private var restBreaks: some View {
        BigGlassCard(icon: "nosign",
                       title: "Rest breaks",
                       subtitle: "This week",
                       value: "\(statsViewModel.stats.breaksThisWeek)",
                       color: .red,
                       content: nil)
    }
    
    // MARK: - Stats Break Rate Chart

    private var breakRateChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            BigGlassCard(icon: "waveform.path.ecg",
                           title: "Break Rate 15d",
                           subtitle: "Daily break / no break",
                           value: "\(statsViewModel.breakRatePercentage)%",
                           color: .red,
                           content: {
                
                return VStack {
                    BreakRateDailyChart(values: statsViewModel.breakRateDailySeries)
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

#Preview {
    struct MockSessionRepo: RestSessionRepositoryContract {
        func fetchAll() -> [RestSessionEntity] { [] }
        func fetch(for day: Date) -> RestSessionEntity? { nil }
        func save(_ session: RestSessionEntity) async {}
        func update(_ session: RestSessionEntity) async {}
    }
    return ZStack {
        Color.black.ignoresSafeArea()
        StatsScreen(calculateStatsUseCase: CalculateStatsUseCase(repository: MockSessionRepo()))
    }
}
