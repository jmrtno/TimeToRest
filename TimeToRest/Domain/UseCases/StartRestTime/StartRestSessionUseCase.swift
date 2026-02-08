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
final class StartRestSessionUseCase {

    private let sessionRepository: RestSessionRepositoryContract
    private let configRepository: TimeToRestRepositoryContract

    init(
        sessionRepository: RestSessionRepositoryContract,
        configRepository: TimeToRestRepositoryContract
    ) {
        self.sessionRepository = sessionRepository
        self.configRepository = configRepository
    }

    /// Starts a new rest session for today.
    /// - Returns: The created session, or nil if an active (non-broken) one already exists.
    func execute(now: Date = Date()) -> RestSessionEntity? {
        let calendar = Calendar.current

        // If there's already an active session for today, return nil.
        // If the existing session was broken, allow creating a fresh one.
        if let existing = sessionRepository.fetch(for: now) {
            if !existing.didBreakRest {
                return nil
            }
        }

        let config = configRepository.fetch()

        // Calculate delay in minutes from configured start time
        let configuredStart = calendar.date(
            bySettingHour: config.startTime.hour ?? 23,
            minute: config.startTime.minute ?? 30,
            second: 0,
            of: now
        ) ?? now

        let delayMinutes: Int
        if now > configuredStart {
            delayMinutes = max(0, Int(now.timeIntervalSince(configuredStart) / 60))
        } else {
            delayMinutes = 0
        }

        let session = RestSessionEntity(
            day: now,
            startedAt: now,
            delayInMinutes: delayMinutes,
            didBreakRest: false,
            avoidedMinutes: 0
        )

        sessionRepository.save(session)
        return session
    }
}
