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
    let isCompleted: Bool
    let avoidedMinutes: Int

    // MARK: - Init
    init(
        id: UUID = UUID(),
        day: Date,
        startedAt: Date,
        delayInMinutes: Int,
        didBreakRest: Bool,
        breakedAt: Date? = nil,
        isCompleted: Bool = false,
        avoidedMinutes: Int
    ) {
        self.id = id
        self.day = day
        self.startedAt = startedAt
        self.delayInMinutes = delayInMinutes
        self.didBreakRest = didBreakRest
        self.breakedAt = breakedAt
        self.isCompleted = isCompleted
        self.avoidedMinutes = avoidedMinutes
    }

    // MARK: - Codable (backward compatibility for isCompleted)
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        day = try container.decode(Date.self, forKey: .day)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        delayInMinutes = try container.decode(Int.self, forKey: .delayInMinutes)
        didBreakRest = try container.decode(Bool.self, forKey: .didBreakRest)
        breakedAt = try container.decodeIfPresent(Date.self, forKey: .breakedAt)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        avoidedMinutes = try container.decode(Int.self, forKey: .avoidedMinutes)
    }
}
