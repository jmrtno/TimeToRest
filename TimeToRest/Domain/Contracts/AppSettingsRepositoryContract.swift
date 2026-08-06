import Foundation

// MARK: - AppSettingsRepositoryContract
/// A repository contract that defines the interface for data access operations.
///
/// This protocol abstracts the data layer from the domain layer, allowing:
/// - Independence from specific data storage implementations
/// - Easy unit testing through mock implementations
/// - Flexibility to swap data sources (local, remote, cache) without affecting business logic
///
/// ## Implementation Guidelines
/// - Define methods for CRUD operations as needed
/// - Use domain entities as parameters and return types
/// - Keep the interface minimal and focused on domain needs
/// - Avoid exposing implementation details (e.g., database-specific types)
///
/// ## Example Implementation
/// ```swift
/// final class LocalAppSettingsRepository: AppSettingsRepositoryContract {
///     func fetch() -> AppSettingsEntity { ... }
/// }
/// ```
protocol AppSettingsRepositoryContract {
    func fetch() -> AppSettingsEntity
    func save(_ settings: AppSettingsEntity) async
}
