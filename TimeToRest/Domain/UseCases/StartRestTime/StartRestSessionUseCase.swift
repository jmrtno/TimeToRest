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
    ///
    /// This method checks if there's already an active session for the current day.
    /// If an active session exists (not broken and not completed), it returns nil.
    /// If the existing session was broken or completed, a new session can be created.
    ///
    /// The session is created with the user's configured start and end times
    /// from the fetched rest time configuration.
    ///
    /// - Parameter now: The date to use for session creation (defaults to current date).
    /// - Returns: The created session, or nil if an active session already exists or no configuration is found.
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
