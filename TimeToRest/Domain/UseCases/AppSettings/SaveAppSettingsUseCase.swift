import Foundation

// MARK: - SaveAppSettingsUseCase
/// A use case that encapsulates a single business operation.
///
/// Use cases represent the application's business rules and orchestrate the flow
/// of data between entities and repositories. They are the entry points to the
/// domain layer from the presentation layer.
///
/// ## Design Principles
/// - Single Responsibility: Each use case handles one specific business operation
/// - Dependency Injection: Repositories and services are injected via initializer
/// - Framework Independence: No UI or infrastructure dependencies
/// - Testability: Easy to unit test with mock dependencies
///
/// ## Usage
/// ```swift
/// let useCase = SaveAppSettingsUseCase(repository: repository)
/// await useCase.execute(settings)
/// ```
struct SaveAppSettingsUseCase {
    private let repository: AppSettingsRepositoryContract

    init(repository: AppSettingsRepositoryContract) {
        self.repository = repository
    }

    /// Persists the given app settings.
    func execute(_ settings: AppSettingsEntity) async {
        await repository.save(settings)
    }
}
