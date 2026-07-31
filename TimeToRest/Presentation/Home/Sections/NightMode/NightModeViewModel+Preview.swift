import Foundation

// MARK: - NightModeViewModel+Preview
/// ViewModel prfeviews config.
#if DEBUG
extension NightModeViewModel {

    static var preview: NightModeViewModel {
        struct MockTimeRepo: TimeToRestRepositoryContract {
            func hasConfiguration() -> Bool { true }
            func fetch() -> TimeToRestEntity { .firstConfig }
            func save(_ restTime: TimeToRestEntity) async {}
            func update(_ restTime: TimeToRestEntity) async {}
        }
        struct MockSessionRepo: RestSessionRepositoryContract {
            func fetchAll() -> [RestSessionEntity] { [] }
            func fetch(for day: Date) -> RestSessionEntity? { nil }
            func save(_ session: RestSessionEntity) async {}
            func update(_ session: RestSessionEntity) async {}
            func delete(_ session: RestSessionEntity) async {}
        }
        let mockTimeRepo = MockTimeRepo()
        let mockSessionRepo = MockSessionRepo()
        return NightModeViewModel(
            fetchRestTimeUseCase: FetchRestTimeUseCase(repository: mockTimeRepo),
            startRestSessionUseCase: StartRestSessionUseCase(
                sessionRepository: mockSessionRepo,
                fetchRestTimeUseCase: FetchRestTimeUseCase(repository: mockTimeRepo)
            ),
            completeRestSessionUseCase: CompleteRestSessionUseCase(repository: mockSessionRepo),
            fetchCurrentSessionUseCase: FetchCurrentSessionUseCase(repository: mockSessionRepo),
            deleteSessionUseCase: DeleteSessionUseCase(repository: mockSessionRepo),
            restSessionManager: RestSessionManager(
                breakRestUseCase: BreakRestUseCase(repository: mockSessionRepo),
                fetchCurrentSessionUseCase: FetchCurrentSessionUseCase(repository: mockSessionRepo)
            ),
            notificationManager: NotificationManager()
        )
    }

    /// A preview view model that simulates a session started 5 minutes ago,
    /// so the grace period reconfigure button is visible.
    static var previewWithGracePeriod: NightModeViewModel {
        struct MockTimeRepo: TimeToRestRepositoryContract {
            func hasConfiguration() -> Bool { true }
            func fetch() -> TimeToRestEntity { .firstConfig }
            func save(_ restTime: TimeToRestEntity) async {}
            func update(_ restTime: TimeToRestEntity) async {}
        }
        struct MockSessionRepo: RestSessionRepositoryContract {
            func fetchAll() -> [RestSessionEntity] { [] }
            func fetch(for day: Date) -> RestSessionEntity? { nil }
            func save(_ session: RestSessionEntity) async {}
            func update(_ session: RestSessionEntity) async {}
            func delete(_ session: RestSessionEntity) async {}
        }
        let mockTimeRepo = MockTimeRepo()
        let mockSessionRepo = MockSessionRepo()
        let viewModel = NightModeViewModel(
            fetchRestTimeUseCase: FetchRestTimeUseCase(repository: mockTimeRepo),
            startRestSessionUseCase: StartRestSessionUseCase(
                sessionRepository: mockSessionRepo,
                fetchRestTimeUseCase: FetchRestTimeUseCase(repository: mockTimeRepo)
            ),
            completeRestSessionUseCase: CompleteRestSessionUseCase(repository: mockSessionRepo),
            fetchCurrentSessionUseCase: FetchCurrentSessionUseCase(repository: mockSessionRepo),
            deleteSessionUseCase: DeleteSessionUseCase(repository: mockSessionRepo),
            restSessionManager: RestSessionManager(
                breakRestUseCase: BreakRestUseCase(repository: mockSessionRepo),
                fetchCurrentSessionUseCase: FetchCurrentSessionUseCase(repository: mockSessionRepo)
            ),
            notificationManager: NotificationManager()
        )

        let calendar = Calendar.current
        let now = Date()
        let fiveMinutesAgo = calendar.date(byAdding: .minute, value: -5, to: now) ?? now
        viewModel.config = .firstConfig
        viewModel.hasConfiguration = true
        viewModel.isWithinNightWindow = true
        viewModel.session = RestSessionEntity(
            day: now,
            startedAt: fiveMinutesAgo,
            didBreakRest: false,
            avoidedMinutes: 0,
            startTime: viewModel.config.startTime,
            endTime: viewModel.config.endTime
        )
        viewModel.gracePeriodSecondsRemaining = Int(10 * 60 - now.timeIntervalSince(fiveMinutesAgo))
        return viewModel
    }
}
#endif
