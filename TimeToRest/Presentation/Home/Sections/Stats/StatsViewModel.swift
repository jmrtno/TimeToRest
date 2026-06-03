import Foundation

// MARK: - StatsViewModel
/// ViewModel for the statistics screen.
/// Loads and exposes rest statistics for display.
@MainActor
@Observable
final class StatsViewModel {

    // MARK: - Published state
    var stats: RestStatsEntity = .empty

    // MARK: - Dependencies
    private let calculateStatsUseCase: CalculateStatsUseCase

    init(calculateStatsUseCase: CalculateStatsUseCase) {
        self.calculateStatsUseCase = calculateStatsUseCase
    }

    // MARK: - Actions

    func onAppear() {
        loadStats()
    }

    func loadStats() {
        stats = calculateStatsUseCase.execute()
        
#if DEBUG
        stats = .debugConsistentMock()
#endif
    }

    var formattedAverageStartTime: String {
        guard let averageMinutes = stats.averageStartTimeMinutesLast15 else {
            return "--:--"
        }

        let hour = averageMinutes / 60
        let minute = averageMinutes % 60
        return String(format: "%02d:%02d", hour, minute)
    }

    var breakRateDailySeries: [Bool] {
        stats.breakStatusLast15Days.map(\.didBreak)
    }

    var totalTrackedDays: Int {
        stats.breakStatusLast15Days.count
    }

    var breakFreeDaysCount: Int {
        stats.breakStatusLast15Days.filter { !$0.didBreak }.count
    }

    var breakDaysCount: Int {
        stats.breakStatusLast15Days.filter(\.didBreak).count
    }

    var breakRatePercentage: Int {
        let totalDays = stats.breakStatusLast15Days.count
        guard totalDays > 0 else { return 0 }
        return Int((Double(breakDaysCount) / Double(totalDays) * 100.0).rounded())
    }
}
