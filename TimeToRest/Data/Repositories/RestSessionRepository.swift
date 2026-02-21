import Foundation

// MARK: - RestSessionRepository
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
/// let repository = RestSessionRepository()
/// let useCase = SomeUseCase(repository: repository)
/// ```
final class RestSessionRepository: RestSessionRepositoryContract {

    // MARK: - Storage
    private let storageKey = "RestSessions"
    private let userDefaults: UserDefaults

    // MARK: - Init
    init(userDefaults: UserDefaults = UserDefaults(suiteName: RestSessionDeviceActivityIdentifiers.appGroupIdentifier) ?? .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Fetch

    func fetchAll() -> [RestSessionEntity] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        do {
            let dtoList = try JSONDecoder().decode([RestSessionDTO].self, from: data)
            return dtoList.map { $0.toEntity() }
        } catch {
            return []
        }
    }

    func fetch(for day: Date) -> RestSessionEntity? {
        let calendar = Calendar.current
        return fetchAll().last {
            calendar.isDate($0.day, inSameDayAs: day)
        }
    }

    // MARK: - Save / Update

    func save(_ session: RestSessionEntity) {
        var sessions = fetchAll()
        sessions.append(session)
        Task { @MainActor in
            persistAll(sessions)
        }
    }

    func update(_ session: RestSessionEntity) {
        var sessions = fetchAll()

        guard let index = sessions.firstIndex(where: { $0.id == session.id }) else {
            return
        }

        sessions[index] = session
        Task { @MainActor in
            persistAll(sessions)
        }
    }

    // MARK: - Private helpers

    @MainActor
    private func persistAll(_ sessions: [RestSessionEntity]) {
        do {
            let dtoList = sessions.map(RestSessionDTO.init(entity:))
            let data = try JSONEncoder().encode(dtoList)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            // Aquí podrías loggear si quieres
        }
    }
}
