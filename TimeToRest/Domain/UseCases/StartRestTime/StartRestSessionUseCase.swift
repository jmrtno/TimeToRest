import Foundation

// MARK: - StartRestSessionUseCase
/// Creates a new rest session when the user opens the app during the night window.
///
/// Calculates the delay between the configured start time and the actual moment
/// the user opened the app, then persists the session.
struct StartRestSessionUseCase {

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
