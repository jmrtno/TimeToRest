import Foundation

// MARK: - RestSessionEntity
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
/// - Implement `Codable` if persistence is required
///
/// ## Example
/// ```swift
/// let item = RestSessionEntity(id: UUID(), name: "Example")
/// ```
struct RestSessionEntity: Identifiable, Codable, Equatable {

    // MARK: - Identity
    let id: UUID

    /// Día lógico del descanso (ej: 2026-02-07)
    let day: Date

    // MARK: - Timing
    /// Momento en el que el usuario abrió la app durante el horario nocturno
    let startedAt: Date

    /// Diferencia entre la hora configurada y startedAt (en minutos)
    let delayInMinutes: Int

    // MARK: - Result
    let didBreakRest: Bool
    let breakedAt: Date?
    let avoidedMinutes: Int

    // MARK: - Init
    init(
        id: UUID = UUID(),
        day: Date,
        startedAt: Date,
        delayInMinutes: Int,
        didBreakRest: Bool,
        breakedAt: Date? = nil,
        avoidedMinutes: Int
    ) {
        self.id = id
        self.day = day
        self.startedAt = startedAt
        self.delayInMinutes = delayInMinutes
        self.didBreakRest = didBreakRest
        self.breakedAt = breakedAt
        self.avoidedMinutes = avoidedMinutes
    }
}
