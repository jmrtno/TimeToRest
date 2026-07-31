import Foundation
import FamilyControls

// MARK: - SetupViewModel
/// ViewModel for the rest configuration modal.
/// Handles both mandatory (first use) and editable (subsequent) modes.
@MainActor
@Observable
final class SetupViewModel {

    // MARK: - Published state
    var startTime: Date
    var endTime: Date
    var blockedSelection: FamilyActivitySelection
    var isFamilyActivityPickerPresented: Bool = false
    var sleepTip: String = ""
    var isTipLoading: Bool = true

    // MARK: - Mode
    let mode: RestConfigurationMode

    // MARK: - Dependencies
    private let saveRestTimeUseCase: SaveRestTimeUseCase
    private let fetchRestTimeUseCase: FetchRestTimeUseCase
    private let getSleepTipUseCase: GetSleepTipUseCase
    private let notificationManager: NotificationManager
    private let restSessionManager: RestSessionManager

    // MARK: - Callbacks
    var onSave: (() -> Void)?

    init(
        mode: RestConfigurationMode,
        saveRestTimeUseCase: SaveRestTimeUseCase,
        fetchRestTimeUseCase: FetchRestTimeUseCase,
        getSleepTipUseCase: GetSleepTipUseCase,
        notificationManager: NotificationManager,
        restSessionManager: RestSessionManager
    ) {
        self.mode = mode
        self.saveRestTimeUseCase = saveRestTimeUseCase
        self.fetchRestTimeUseCase = fetchRestTimeUseCase
        self.getSleepTipUseCase = getSleepTipUseCase
        self.notificationManager = notificationManager
        self.restSessionManager = restSessionManager
        self.blockedSelection = restSessionManager.currentBlockedSelection

        // Default times
        let calendar = Calendar.current
        let now = Date()
        self.startTime = calendar.date(bySettingHour: 23, minute: 30, second: 0, of: now) ?? now
        self.endTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: now) ?? now

        // If editing, load existing config
        if mode == .editable {
            loadExistingConfig()
        }
    }

    // MARK: - Actions

    func loadSleepTip() async {
        isTipLoading = true
        sleepTip = await getSleepTipUseCase.execute()
        isTipLoading = false
    }

    func save() async {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        let entity = TimeToRestEntity(
            startTime: startComponents,
            endTime: endComponents
        )

        await saveRestTimeUseCase.execute(restTime: entity, isNew: mode == .mandatory)

        // Schedule notifications
        let manager = notificationManager
        let savedEntity = entity
        
        manager.scheduleRestReminder(for: savedEntity)

        restSessionManager.updateBlockedSelection(blockedSelection)
        restSessionManager.prepareAuthorization()
        onSave?()
    }

    var canCancel: Bool {
        mode == .editable
    }
    
    var blockedSocialAppsDescription: String {
        var components: [String] = []
        if !blockedSelection.applicationTokens.isEmpty {
            components.append("\(blockedSelection.applicationTokens.count) apps")
        }
        if !blockedSelection.categoryTokens.isEmpty {
            components.append("\(blockedSelection.categoryTokens.count) categories")
        }
        if !blockedSelection.webDomainTokens.isEmpty {
            components.append("\(blockedSelection.webDomainTokens.count) web domains")
        }
        if components.isEmpty {
            return "No blocked apps selected"
        }
        return components.joined(separator: " + ")
    }

    // MARK: - Private

    private func loadExistingConfig() {
        guard let config = fetchRestTimeUseCase.execute() else { return }
        let calendar = Calendar.current
        let now = Date()

        if let h = config.startTime.hour, let m = config.startTime.minute {
            startTime = calendar.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now
        }
        if let h = config.endTime.hour, let m = config.endTime.minute {
            endTime = calendar.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now
        }
    }
}

// MARK: - Preview

#if DEBUG
extension SetupViewModel {

    static var preview: SetupViewModel {
        struct MockTimeRepo: TimeToRestRepositoryContract {
            func hasConfiguration() -> Bool { false }
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
        return SetupViewModel(
            mode: .editable,
            saveRestTimeUseCase: SaveRestTimeUseCase(repository: MockTimeRepo()),
            fetchRestTimeUseCase: FetchRestTimeUseCase(repository: MockTimeRepo()),
            getSleepTipUseCase: GetSleepTipUseCase(),
            notificationManager: NotificationManager(),
            restSessionManager: RestSessionManager(
                breakRestUseCase: BreakRestUseCase(repository: MockSessionRepo()),
                fetchCurrentSessionUseCase: FetchCurrentSessionUseCase(repository: MockSessionRepo())
            )
        )
    }
}
#endif
