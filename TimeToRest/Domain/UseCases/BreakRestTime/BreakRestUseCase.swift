import Foundation

// MARK: - BreakRestUseCase
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
/// let useCase = GetDataUseCase(repository: repository)
/// let result = useCase.execute(parameters)
/// ```
struct BreakRestUseCase {
    private let repository: RestSessionRepositoryContract

    init(repository: RestSessionRepositoryContract) {
        self.repository = repository
    }

    /// Rompe la sesión actual
    func execute(session: RestSessionEntity, breakedAt: Date = Date()) -> RestSessionEntity {
        // Calcula minutos evitados hasta romper
        let avoidedMinutes = max(0, Int(breakedAt.timeIntervalSince(session.startedAt) / 60))

        // Crea una nueva sesión con didBreakRest = true
        let updatedSession = RestSessionEntity(
            id: session.id,
            day: session.day,
            startedAt: session.startedAt,
            didBreakRest: true,
            breakedAt: breakedAt,
            avoidedMinutes: avoidedMinutes
        )

        // Guarda la sesión actualizada
        repository.update(updatedSession)

        return updatedSession
    }
}
