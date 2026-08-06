import Foundation

// MARK: - SettingsViewModel
/// ViewModel that manages the editable state of the app settings.
/// Reads and persists the grace period and the notifications toggle.
@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - View state

    var gracePeriodMinutes: Int = 10
    var isNotificationsEnabled: Bool = true
    private(set) var saveConfirmationVisible = false

    // MARK: - Dependencies

    private let fetchAppSettingsUseCase: FetchAppSettingsUseCase
    private let saveAppSettingsUseCase: SaveAppSettingsUseCase
    private let notificationManager: NotificationManager
    private let fetchRestTimeUseCase: FetchRestTimeUseCase

    // MARK: - Initialization

    init(
        fetchAppSettingsUseCase: FetchAppSettingsUseCase,
        saveAppSettingsUseCase: SaveAppSettingsUseCase,
        notificationManager: NotificationManager,
        fetchRestTimeUseCase: FetchRestTimeUseCase
    ) {
        self.fetchAppSettingsUseCase = fetchAppSettingsUseCase
        self.saveAppSettingsUseCase = saveAppSettingsUseCase
        self.notificationManager = notificationManager
        self.fetchRestTimeUseCase = fetchRestTimeUseCase
    }

    // MARK: - Lifecycle

    func onAppear() {
        load()
    }

    // MARK: - Public methods

    /// Loads the stored settings into the view state.
    func load() {
        let settings = fetchAppSettingsUseCase.execute()
        gracePeriodMinutes = settings.gracePeriodMinutes
        isNotificationsEnabled = settings.isNotificationsEnabled
    }

    /// Persists the current view state and reschedules or cancels
    /// rest time notifications accordingly.
    func save() async {
        let settings = AppSettingsEntity(
            gracePeriodMinutes: gracePeriodMinutes,
            isNotificationsEnabled: isNotificationsEnabled
        )
        await saveAppSettingsUseCase.execute(settings)

        if isNotificationsEnabled,
           let restTime = fetchRestTimeUseCase.execute() {
            notificationManager.scheduleRestReminder(for: restTime)
        } else {
            notificationManager.cancelAllRestNotifications()
        }

        saveConfirmationVisible = true
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        saveConfirmationVisible = false
    }
}

// MARK: - Preview

#if DEBUG
extension SettingsViewModel {

    static var preview: SettingsViewModel {
        struct MockAppSettingsRepo: AppSettingsRepositoryContract {
            func fetch() -> AppSettingsEntity { .defaultSettings }
            func save(_ settings: AppSettingsEntity) async {}
        }
        struct MockTimeRepo: TimeToRestRepositoryContract {
            func hasConfiguration() -> Bool { true }
            func fetch() -> TimeToRestEntity { .firstConfig }
            func save(_ restTime: TimeToRestEntity) async {}
            func update(_ restTime: TimeToRestEntity) async {}
        }
        return SettingsViewModel(
            fetchAppSettingsUseCase: FetchAppSettingsUseCase(repository: MockAppSettingsRepo()),
            saveAppSettingsUseCase: SaveAppSettingsUseCase(repository: MockAppSettingsRepo()),
            notificationManager: NotificationManager(),
            fetchRestTimeUseCase: FetchRestTimeUseCase(repository: MockTimeRepo())
        )
    }
}
#endif
