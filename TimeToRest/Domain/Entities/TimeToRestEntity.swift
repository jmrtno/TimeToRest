import Foundation

// MARK: - TimeToRestEntity
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
/// let item = TimeToRestEntity(id: UUID(), name: "Example")
/// ```
struct TimeToRestEntity: Identifiable, Equatable {

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

    // MARK: - Empty init (first render / preview)
    static let firstConfig = TimeToRestEntity(
        id: UUID(),
        startTime: DateComponents(hour: 23, minute: 30),
        endTime: DateComponents(hour: 7, minute: 0),
        createdAt: Date()
    )
}
