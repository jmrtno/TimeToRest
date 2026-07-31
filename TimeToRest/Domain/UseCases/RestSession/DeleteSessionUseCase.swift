import Foundation

// MARK: - DeleteSessionUseCase
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
/// let useCase = DeleteSessionUseCase(repository: repository)
/// await useCase.execute(session: session)
/// ```
struct DeleteSessionUseCase {
    private let repository: RestSessionRepositoryContract

    init(repository: RestSessionRepositoryContract) {
        self.repository = repository
    }

    /// Deletes a session from persistence as if it never existed.
    ///
    /// Used by the grace period reconfiguration flow: unlike marking a session
    /// as broken, deleting it removes it entirely from stats calculations.
    ///
    /// - Parameter session: The session to delete.
    func execute(session: RestSessionEntity) async {
        await repository.delete(session)
    }
}
