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

        return RestStatsEntity(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            breaksThisWeek: breaksThisWeek,
            totalAvoidedMinutes: totalAvoidedMinutes
        )
    }
}
