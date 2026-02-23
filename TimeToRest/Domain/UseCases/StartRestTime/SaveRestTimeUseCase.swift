import Foundation

// MARK: - SaveRestTimeUseCase
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
/// let useCase = UpdateRestTimeUseCase(repository: repository)
/// let result = useCase.execute(parameters)
/// ```
struct SaveRestTimeUseCase {
    private let repository: TimeToRestRepositoryContract
    
    init(repository: TimeToRestRepositoryContract) {
        self.repository = repository
    }
    
    /// Executes the use case operation.
    ///
    /// - Parameter input: The input required for this operation (modify as needed)
    /// - Returns: The result of the operation (modify return type as needed)
    func execute(restTime: TimeToRestEntity, isNew: Bool) async {
        if isNew {
            await repository.save(restTime)
        } else {
            await repository.update(restTime)
        }
    }
}
