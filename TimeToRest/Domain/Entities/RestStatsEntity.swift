import Foundation

struct DailyBreakStatusPoint: Equatable {
    let day: Date
    let didBreak: Bool
}

// MARK: - RestStatsEntity
/// A domain entity representing a core business object.
///
/// This entity encapsulates the essential properties and behaviors of the domain model.
/// It is designed to be independent of any framework or infrastructure concerns,
/// following Clean Architecture principles.
///
/// ## Usage
/// - Define the properties that represent the entity's state
/// - Add computed properties for derived values
/// - Implement `Equatable` for comparison operations
///
/// ## Example
/// ```swift
/// let item = RestStatsEntity(id: UUID(), name: "Example")
/// ```
struct RestStatsEntity: Equatable {

    let currentStreak: Int
    let bestStreak: Int
    let breaksThisWeek: Int
    let averageStartTimeMinutesLast30: Int?
    let breakStatusLast15Days: [DailyBreakStatusPoint]

    static let empty = RestStatsEntity(
        currentStreak: 0,
        bestStreak: 0,
        breaksThisWeek: 0,
        averageStartTimeMinutesLast30: nil,
        breakStatusLast15Days: []
    )
}

#if DEBUG
extension RestStatsEntity {
    static func debugConsistentMock(now: Date = Date()) -> RestStatsEntity {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: now)

        // Oldest -> newest (today). false = no break, true = break.
        let mockDaily: [Bool] = [
            false, true,  false, false, true,
            false, false, true,  false, true,
            false, false, true,  false, false, false
        ]

        let points: [DailyBreakStatusPoint] = mockDaily.enumerated().compactMap { index, didBreak in
            guard let day = calendar.date(byAdding: .day, value: -(14 - index), to: today) else {
                return nil
            }
            return DailyBreakStatusPoint(day: day, didBreak: didBreak)
        }

        var tempStreak = 0
        var currentStreak = 0
        var bestStreak = 0
        for point in points {
            if point.didBreak {
                tempStreak = 0
            } else {
                tempStreak += 1
                currentStreak = tempStreak
                bestStreak = max(bestStreak, tempStreak)
            }
        }

        let currentWeek = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: today)
        let breaksThisWeek = points.filter { point in
            guard point.didBreak else { return false }
            let week = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: point.day)
            return week.weekOfYear == currentWeek.weekOfYear &&
                week.yearForWeekOfYear == currentWeek.yearForWeekOfYear
        }.count

        return RestStatsEntity(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            breaksThisWeek: breaksThisWeek,
            averageStartTimeMinutesLast30: 23 * 60 + 42,
            breakStatusLast15Days: points
        )
    }
}
#endif
