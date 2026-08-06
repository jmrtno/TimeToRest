import Foundation

// MARK: - AppSettingsEntity
/// A domain entity representing a core business object.
///
/// This entity encapsulates the essential properties and behaviors of the domain model.
/// It is designed to be independent of any framework or infrastructure concerns,
/// following Clean Architecture principles.
///
/// ## Design Rules
/// - No `Codable` (only in Data layer DTOs)
/// - No UI dependencies (SwiftUI, UIKit)
/// - No infrastructure dependencies
/// - Pure business model with Foundation only when needed
///
/// ## Usage
/// - Define the properties that represent the entity's state
/// - Add computed properties for derived values
/// - Implement `Equatable` for comparison operations
/// - Implement `Sendable` when used across concurrency boundaries
///
/// ## Example
/// ```swift
/// let settings = AppSettingsEntity(gracePeriodMinutes: 10, isNotificationsEnabled: true)
/// ```
struct AppSettingsEntity: Identifiable, Equatable, Sendable {
    let id: UUID
    let gracePeriodMinutes: Int
    let isNotificationsEnabled: Bool
    
    init(
        id: UUID = UUID(),
        gracePeriodMinutes: Int,
        isNotificationsEnabled: Bool
    ) {
        self.id = id
        self.gracePeriodMinutes = gracePeriodMinutes
        self.isNotificationsEnabled = isNotificationsEnabled
    }

    // MARK: - Default settings
    static let defaultSettings = AppSettingsEntity(
        id: UUID(),
        gracePeriodMinutes: 10,
        isNotificationsEnabled: true
    )
}
