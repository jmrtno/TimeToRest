import Foundation

// MARK: - RestSessionEntity
/// A domain entity representing a core business object.
///
/// This entity encapsulates the essential properties and behaviors of the domain model.
/// It is designed to be independent of any framework or infrastructure concerns,
/// following Clean Architecture principles for Swift 6.
///
/// ## Usage
/// - Define the properties that represent the entity's state
/// - Add computed properties for derived values
/// - Implement `Equatable` for comparison operations
/// - Keep persistence concerns in the Data layer via DTOs
///
/// ## Example
/// ```swift
/// let item = RestSessionEntity(id: UUID(), name: "Example")
/// ```
struct RestSessionEntity: Identifiable, Equatable {
    enum BreakReason: String, Equatable {
        case manualCancellation
        case blockedSocialAppUsage
    }

    // MARK: - Identity
    let id: UUID

    /// Día lógico del descanso (ej: 2026-02-07)
    let day: Date

    // MARK: - Core configuration
    let startTime: DateComponents
    let endTime: DateComponents

    // MARK: - State (lightweight)
    let createdAt: Date

    // MARK: - Timing
    /// Momento en el que el usuario abrió la app durante el horario nocturno
    let startedAt: Date

    // MARK: - Result
    let didBreakRest: Bool
    let breakReason: BreakReason?
    let brokenAt: Date?
    let isCompleted: Bool
    let avoidedMinutes: Int

    // MARK: - Init
    init(
        id: UUID = UUID(),
        day: Date,
        startedAt: Date,
        didBreakRest: Bool,
        breakReason: BreakReason? = nil,
        brokenAt: Date? = nil,
        isCompleted: Bool = false,
        avoidedMinutes: Int,
        startTime: DateComponents,
        endTime: DateComponents,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.day = day
        self.startedAt = startedAt
        self.didBreakRest = didBreakRest
        self.breakReason = breakReason
        self.brokenAt = brokenAt
        self.isCompleted = isCompleted
        self.avoidedMinutes = avoidedMinutes
        self.startTime = startTime
        self.endTime = endTime
        self.createdAt = createdAt
    }
}
