import Foundation

// MARK: - TimeToRestEntity
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
/// let item = TimeToRestEntity(id: UUID(), name: "Example")
/// ```
struct TimeToRestEntity: Identifiable, Codable, Equatable {

    // MARK: - Identity
    let id: UUID

    // MARK: - Core configuration
    let startTime: DateComponents
    let endTime: DateComponents

    // MARK: - State (lightweight)
    let createdAt: Date

    // MARK: - Init principal
    init(
        id: UUID = UUID(),
        startTime: DateComponents,
        endTime: DateComponents,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.createdAt = createdAt
    }

    // MARK: - Identifier
    var restIdentifier: String {
        "resttime_\(id.uuidString)"
    }

    // MARK: - Init vacío (primer render / preview)
    static let firstConfig = TimeToRestEntity(
        id: UUID(),
        startTime: DateComponents(hour: 23, minute: 30),
        endTime: DateComponents(hour: 7, minute: 0),
        createdAt: Date()
    )
}
