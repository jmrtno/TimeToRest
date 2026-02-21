import Foundation

// MARK: - TimeToRest
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
/// let repository = TimeToRest()
/// let useCase = SomeUseCase(repository: repository)
/// ```
final class TimeToRestRepository: TimeToRestRepositoryContract {
    private let storageKey = "TimeToRest"
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    func hasConfiguration() -> Bool {
        userDefaults.data(forKey: storageKey) != nil
    }
    
    func fetch() -> TimeToRestEntity {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return .firstConfig
        }
        
        do {
            let dto = try JSONDecoder().decode(TimeToRestDTO.self, from: data)
            return dto.toEntity()
        } catch {
            return .firstConfig
        }
    }
    
    func save(_ restTime: TimeToRestEntity) {
        Task { @MainActor in
            persist(restTime)
        }
    }
    
    func update(_ restTime: TimeToRestEntity) {
        Task { @MainActor in
            persist(restTime)
        }
    }
    
    // MARK: - Private Helpers
    
    @MainActor
    private func persist(_ restTime: TimeToRestEntity) {
        do {
            let dto = TimeToRestDTO(entity: restTime)
            let data = try JSONEncoder().encode(dto)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            // Handle encoding error appropriately
        }
    }
}
