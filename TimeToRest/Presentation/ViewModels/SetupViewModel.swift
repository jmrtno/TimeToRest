import Foundation
import Combine

// MARK: - SetupViewModel
/// ViewModel for the rest configuration modal.
/// Handles both mandatory (first use) and editable (subsequent) modes.
@MainActor
final class SetupViewModel: ObservableObject {

    // MARK: - Published state
    @Published var startTime: Date
    @Published var endTime: Date
    @Published var selectedApps: Set<AllowedApp> = [.phone, .emergency]
    @Published var isStrictMode: Bool = false

    // MARK: - Mode
    let mode: RestConfigurationMode

    // MARK: - Dependencies
    private let createRestTimeUseCase: CreateRestTimeUseCase
    private let updateRestTimeUseCase: UpdateRestTimeUseCase
    private let fetchRestTimeUseCase: FetchRestTimeUseCase
    private let notificationManager: NotificationManager

    // MARK: - Callbacks
    var onSave: (() -> Void)?

    init(
        mode: RestConfigurationMode,
        createRestTimeUseCase: CreateRestTimeUseCase,
        updateRestTimeUseCase: UpdateRestTimeUseCase,
        fetchRestTimeUseCase: FetchRestTimeUseCase,
        notificationManager: NotificationManager
    ) {
        self.mode = mode
        self.createRestTimeUseCase = createRestTimeUseCase
        self.updateRestTimeUseCase = updateRestTimeUseCase
        self.fetchRestTimeUseCase = fetchRestTimeUseCase
        self.notificationManager = notificationManager

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

    func save() {
        let calendar = Calendar.current
        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

        let entity = TimeToRestEntity(
            startTime: startComponents,
            endTime: endComponents,
            isStrictModeEnabled: isStrictMode,
            allowedApps: Array(selectedApps)
        )

        switch mode {
        case .mandatory:
            createRestTimeUseCase.execute(restTime: entity)
        case .editable:
            updateRestTimeUseCase.execute(restTime: entity)
        }

        // Schedule notifications
        let manager = notificationManager
        let isStrict = entity.isStrictModeEnabled
        let savedEntity = entity
        manager.requestAuthorization { granted in
            guard granted else { return }
            if isStrict {
                manager.scheduleStrictReminder(for: savedEntity)
            } else {
                manager.scheduleRestReminder(for: savedEntity)
            }
        }

        onSave?()
    }

    var canCancel: Bool {
        mode == .editable
    }

    // MARK: - Private

    private func loadExistingConfig() {
        let config = fetchRestTimeUseCase.execute()
        let calendar = Calendar.current
        let now = Date()

        if let h = config.startTime.hour, let m = config.startTime.minute {
            startTime = calendar.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now
        }
        if let h = config.endTime.hour, let m = config.endTime.minute {
            endTime = calendar.date(bySettingHour: h, minute: m, second: 0, of: now) ?? now
        }
        selectedApps = Set(config.allowedApps)
        isStrictMode = config.isStrictModeEnabled
    }
}
