import Foundation

struct CalculateStatsUseCase {

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

            // Rachas
            if session.didBreakRest {
                tempStreak = 0
            } else {
                tempStreak += 1
                currentStreak = tempStreak
                bestStreak = max(bestStreak, tempStreak)
            }

            // Breaks esta semana
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
