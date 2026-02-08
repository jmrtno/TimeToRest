import Foundation

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
    let totalAvoidedMinutes: Int

    static let empty = RestStatsEntity(
        currentStreak: 0,
        bestStreak: 0,
        breaksThisWeek: 0,
        totalAvoidedMinutes: 0
    )
}
