import Foundation

// MARK: - CalculateStatsUseCase
/// A use case that encapsulates a single business operation.
///
/// Use cases represent the application's business rules and orchestrate the flow
/// of data between entities and repositories. They are the entry points to the
/// domain layer from the presentation layer.
///
/// ## Design Principles
/// - Single Responsibility: Each use case handles one specific business operation
/// - Dependency Injection: Repositories and services are injected via initializer
/// - Framework Independence: No UI or infrastructure dependencies
/// - Testability: Easy to unit test with mock dependencies
///
/// ## Usage
/// ```swift
/// let useCase = GetDataUseCase(repository: repository)
/// let result = useCase.execute(parameters)
/// ```
final class CalculateStatsUseCase {

    private let repository: RestSessionRepositoryContract

    init(repository: RestSessionRepositoryContract) {
        self.repository = repository
    }

    func execute() -> RestStatsEntity {
        let sessions = repository.fetchAll()

        var currentStreak = 0
        var bestStreak = 0
        var breaksThisWeek = 0
        var totalAvoidedMinutes = 0

        var tempStreak = 0
        let calendar = Calendar.current
        let now = Date()

        let currentWeek = calendar.dateComponents(
            [.weekOfYear, .yearForWeekOfYear],
            from: now
        )

        for session in sessions.sorted(by: { $0.day < $1.day }) {

            // Streaks: only count sessions with a definitive outcome
            if session.didBreakRest {
                tempStreak = 0
            } else if session.isCompleted {
                tempStreak += 1
                currentStreak = tempStreak
                bestStreak = max(bestStreak, tempStreak)
            }
            // Sessions that are neither broken nor completed are still in progress — skip

            // Breaks esta semana (today's broken session does count here)
            let sessionWeek = calendar.dateComponents(
                [.weekOfYear, .yearForWeekOfYear],
                from: session.day
            )

            if session.didBreakRest,
               sessionWeek.weekOfYear == currentWeek.weekOfYear,
               sessionWeek.yearForWeekOfYear == currentWeek.yearForWeekOfYear {
                breaksThisWeek += 1
            }

            // Minutos evitados
            totalAvoidedMinutes += session.avoidedMinutes
        }

        let averageStartTimeMinutesLast30 = calculateAverageStartTimeMinutes(for: sessions)

        return RestStatsEntity(
                currentStreak: currentStreak,
                bestStreak: bestStreak,
                breaksThisWeek: breaksThisWeek,
                totalAvoidedMinutes: totalAvoidedMinutes,
                averageStartTimeMinutesLast30: averageStartTimeMinutesLast30
        )
    }

    /// Calculates a moving average start time using only the latest 30 sessions.
    /// If there are fewer than 30 sessions, it averages all available ones.
    private func calculateAverageStartTimeMinutes(for sessions: [RestSessionEntity]) -> Int? {
        let recentSessions = sessions
            .sorted(by: { $0.startedAt < $1.startedAt })
            .suffix(30)

        guard !recentSessions.isEmpty else { return nil }

        let calendar = Calendar.current
        let minutesInDay = 24.0 * 60.0

        // Circular mean avoids wrong averages around midnight (e.g. 23:50 and 00:10).
        let sums = recentSessions.reduce((sin: 0.0, cos: 0.0)) { partial, session in
            let components = calendar.dateComponents([.hour, .minute], from: session.startedAt)
            let hour = components.hour ?? 0
            let minute = components.minute ?? 0
            let totalMinutes = Double(hour * 60 + minute)
            let angle = (2.0 * Double.pi * totalMinutes) / minutesInDay

            return (
                sin: partial.sin + Foundation.sin(angle),
                cos: partial.cos + Foundation.cos(angle)
            )
        }

        var meanAngle = Foundation.atan2(sums.sin, sums.cos)
        if meanAngle < 0 {
            meanAngle += 2.0 * Double.pi
        }

        let meanMinutes = Int((meanAngle * minutesInDay / (2.0 * Double.pi)).rounded()) % 1440
        return meanMinutes
    }
}
