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
struct CalculateStatsUseCase {

    private let repository: RestSessionRepositoryContract

    init(repository: RestSessionRepositoryContract) {
        self.repository = repository
    }

    /// Calculates rest statistics from all stored sessions.
    ///
    /// This method computes:
    /// - Current streak: consecutive days with completed rest sessions
    /// - Best streak: the longest streak achieved
    /// - Breaks this week: number of sessions broken in the current week
    /// - Average start time: circular mean of start times from last 30 sessions
    /// - Break status: daily break status for the last 15 days
    ///
    /// - Returns: A `RestStatsEntity` containing all calculated statistics.
    func execute() -> RestStatsEntity {
        let sessions = repository.fetchAll()

        var currentStreak = 0
        var bestStreak = 0
        var breaksThisWeek = 0

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

        }

        currentStreak = tempStreak

        let averageStartTimeMinutesLast15 = calculateAverageStartTimeMinutes(for: sessions)
        let breakStatusLast15Days = calculateBreakStatusLast15Days(for: sessions, now: now)

        return RestStatsEntity(
                currentStreak: currentStreak,
                bestStreak: bestStreak,
                breaksThisWeek: breaksThisWeek,
                averageStartTimeMinutesLast15: averageStartTimeMinutesLast15,
                breakStatusLast15Days: breakStatusLast15Days
        )
    }

    /// Calculates a moving average start time using only sessions from the last 15 days.
    /// If there are fewer sessions, it averages all available ones.
    private func calculateAverageStartTimeMinutes(for sessions: [RestSessionEntity]) -> Int? {
        let calendar = Calendar.current
        let fifteenDaysAgo = calendar.date(byAdding: .day, value: -15, to: Date()) ?? Date()
        
        let recentSessions = sessions
            .sorted(by: { $0.startedAt < $1.startedAt })
            .filter { $0.startedAt >= fifteenDaysAgo }

        guard !recentSessions.isEmpty else { return nil }

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

    /// Returns up to 15 points for the most recent days that have a recorded session.
    /// Only days with a completed or broken session are included — days without
    /// any session are skipped so the chart reflects real usage history.
    private func calculateBreakStatusLast15Days(
        for sessions: [RestSessionEntity],
        now: Date
    ) -> [DailyBreakStatusPoint] {
        let calendar = Calendar.current

        let resolvedSessions = sessions.filter { $0.isCompleted || $0.didBreakRest }

        let sessionsByDay = Dictionary(grouping: resolvedSessions) { session in
            calendar.startOfDay(for: session.day)
        }

        let sortedDays = sessionsByDay.keys.sorted()
        let recentDays = sortedDays.suffix(15)

        return recentDays.map { day in
            let didBreak = sessionsByDay[day]?.contains(where: \.didBreakRest) ?? false
            return DailyBreakStatusPoint(day: day, didBreak: didBreak)
        }
    }
}
