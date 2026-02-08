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
    let isEnabled: Bool
    let startTime: DateComponents
    let endTime: DateComponents

    // MARK: - Behaviour
    let isStrictModeEnabled: Bool
    let allowedApps: [AllowedApp]

    // MARK: - State (lightweight)
    let createdAt: Date
    let lastRestStartDate: Date?

    // MARK: - Init principal
    init(
        id: UUID = UUID(),
        isEnabled: Bool = true,
        startTime: DateComponents,
        endTime: DateComponents,
        isStrictModeEnabled: Bool = false,
        allowedApps: [AllowedApp] = [.phone, .emergency],
        createdAt: Date = Date(),
        lastRestStartDate: Date? = nil
    ) {
        self.id = id
        self.isEnabled = isEnabled
        self.startTime = startTime
        self.endTime = endTime
        self.isStrictModeEnabled = isStrictModeEnabled
        self.allowedApps = allowedApps
        self.createdAt = createdAt
        self.lastRestStartDate = lastRestStartDate
    }

    // MARK: - Identifier
    var restIdentifier: String {
        "resttime_\(id.uuidString)"
    }

    // MARK: - Init vacío (primer render / preview)
    static let firstConfig = TimeToRestEntity(
        id: UUID(),
        isEnabled: false,
        startTime: DateComponents(hour: 23, minute: 30),
        endTime: DateComponents(hour: 7, minute: 0),
        isStrictModeEnabled: false,
        allowedApps: [.phone, .emergency],
        createdAt: Date(),
        lastRestStartDate: nil
    )
}

enum AllowedApp: String, Codable, CaseIterable {
    case phone
    case emergency
    case spotify
}
