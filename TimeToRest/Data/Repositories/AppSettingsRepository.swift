import Foundation

// MARK: - AppSettingsRepository
/// A concrete repository implementation for data persistence and retrieval.
///
/// This class implements the repository contract and handles the actual data operations.
/// It encapsulates the logic for accessing data sources and translates between
/// domain entities and storage-specific data models.
///
/// ## Responsibilities
/// - Implement all methods defined in the repository contract
/// - Handle data serialization/deserialization
/// - Manage data source connections and error handling
/// - Provide data caching if needed
///
/// ## Usage
/// Inject this repository into use cases through the dependency container:
/// ```swift
/// let repository = AppSettingsRepository()
/// let useCase = SomeUseCase(repository: repository)
/// ```
final class AppSettingsRepository: AppSettingsRepositoryContract {
    private let storageKey = "AppConfiguration"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = UserDefaults(suiteName: RestSessionDeviceActivityIdentifiers.appGroupIdentifier) ?? .standard) {
        self.userDefaults = userDefaults
    }

    func fetch() -> AppSettingsEntity {
        guard let data = userDefaults.data(forKey: storageKey),
              let dto = try? JSONDecoder().decode(AppSettingsDTO.self, from: data) else {
            return .defaultSettings
        }
        return dto.toEntity()
    }

    func save(_ settings: AppSettingsEntity) async {
        let dto = AppSettingsDTO(entity: settings)
        guard let data = try? JSONEncoder().encode(dto) else { return }
        userDefaults.set(data, forKey: storageKey)
    }
}
