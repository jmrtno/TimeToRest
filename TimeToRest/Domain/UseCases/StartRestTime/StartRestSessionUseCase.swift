import Foundation

// MARK: - StartRestSessionUseCase
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
/// let useCase = CreateRestTimeUseCase(repository: repository)
/// let result = useCase.execute(parameters)
/// ```
struct StartRestSessionUseCase {

    private let sessionRepository: RestSessionRepositoryContract
    private let fetchRestTimeUseCase: FetchRestTimeUseCase

    init(
        sessionRepository: RestSessionRepositoryContract,
        fetchRestTimeUseCase: FetchRestTimeUseCase
    ) {
        self.sessionRepository = sessionRepository
        self.fetchRestTimeUseCase = fetchRestTimeUseCase
    }

    /// Starts a new rest session for today.
    /// - Returns: The created session, or nil if an active (non-broken) one already exists.
    func execute(now: Date = Date()) async -> RestSessionEntity? {
        // If there's already an active session for today, return nil.
        // If the existing session was broken, allow creating a fresh one.
        if let existing = sessionRepository.fetch(for: now) {
            let hasActiveSession = !existing.didBreakRest && !existing.isCompleted
            if hasActiveSession {
                return nil
            }
        }

        guard let config = fetchRestTimeUseCase.execute() else {
            return nil
        }

        let session = RestSessionEntity(
            day: now,
            startedAt: now,
            didBreakRest: false,
            avoidedMinutes: 0,
            startTime: config.startTime,
            endTime: config.endTime,
            createdAt: now
        )

        await sessionRepository.save(session)
        return session
    }
}
