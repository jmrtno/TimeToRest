import Foundation

// MARK: - NightModeViewModel
/// ViewModel for the night mode section.
/// Handles night-window/session state used to switch UI mode.
@MainActor
@Observable
final class NightModeViewModel {

    enum BreakRequestOutcome {
        case completed
        case needsManualBreak
        case noSession
    }

    // MARK: - Published state
    var config: TimeToRestEntity = .firstConfig
    var isWithinNightWindow: Bool = false
    var hasConfiguration: Bool = false
    var session: RestSessionEntity?
    var didBreakTonight: Bool = false
    var showCompletedButtonStyle: Bool = false
    var minutesLate: Int? = nil
    var isAwaitingGracePeriodReconfiguration: Bool = false
    var gracePeriodSecondsRemaining: Int?

    /// Controls whether the night mode UI is shown.
    /// True if there's an active session or we're within the night window and didn't break rest.
    var showNightMode: Bool {
        (session != nil && !didBreakTonight) || (isWithinNightWindow && !didBreakTonight)
    }

    var formattedEndTime: String {
        Self.formatTime(hour: config.endTime.hour ?? 7, minute: config.endTime.minute ?? 0)
    }

    /// Total rest hours for the current session (or configured window if session is not available yet).
    var formattedSessionRestHours: String {
        let totalMinutes = session.map(sessionRestMinutes) ?? configuredWindowMinutes()
        let hours = max(0, totalMinutes) / 60
        let minutes = max(0, totalMinutes) % 60
        return String(format: "%02d:%02d", hours, minutes)
    }

    /// True while the current session is still within its 10 minute grace period,
    /// during which the user can reconfigure the schedule without the session
    /// counting as a broken rest.
    var isWithinGracePeriod: Bool {
        gracePeriodSecondsRemaining != nil
    }

    // MARK: - Dependencies
    let fetchRestTimeUseCase: FetchRestTimeUseCase
    let startRestSessionUseCase: StartRestSessionUseCase
    let completeRestSessionUseCase: CompleteRestSessionUseCase
    let fetchCurrentSessionUseCase: FetchCurrentSessionUseCase
    let deleteSessionUseCase: DeleteSessionUseCase
    let fetchAppSettingsUseCase: FetchAppSettingsUseCase
    let restSessionManager: RestSessionManager
    let notificationManager: NotificationManager

    var windowCheckTimer: Timer?
    var lastTimerCheckedMinute: Int?
    var buttonStyleTimer: Timer?

    var appSettings: AppSettingsEntity = .defaultSettings
    var gracePeriodDuration: TimeInterval = 10 * 60

    init(
        fetchRestTimeUseCase: FetchRestTimeUseCase,
        startRestSessionUseCase: StartRestSessionUseCase,
        completeRestSessionUseCase: CompleteRestSessionUseCase,
        fetchCurrentSessionUseCase: FetchCurrentSessionUseCase,
        fetchAppSettingsUseCase: FetchAppSettingsUseCase,
        deleteSessionUseCase: DeleteSessionUseCase,
        restSessionManager: RestSessionManager,
        notificationManager: NotificationManager
    ) {
        self.fetchRestTimeUseCase = fetchRestTimeUseCase
        self.startRestSessionUseCase = startRestSessionUseCase
        self.completeRestSessionUseCase = completeRestSessionUseCase
        self.fetchCurrentSessionUseCase = fetchCurrentSessionUseCase
        self.fetchAppSettingsUseCase = fetchAppSettingsUseCase
        self.deleteSessionUseCase = deleteSessionUseCase
        self.restSessionManager = restSessionManager
        self.notificationManager = notificationManager

        // Cancel any residual completion notifications on init
        notificationManager.cancelSessionCompletionNotification()

        // Listen for background task notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleBackgroundNightCheck),
            name: .nightCheckBackgroundTask,
            object: nil
        )
    }

    @objc private func handleBackgroundNightCheck() {
        Task {
            await checkNightWindow()
        }
    }

    // MARK: - Lifecycle

    func onAppear() {
        lastTimerCheckedMinute = nil
        reload()
        startWindowCheckTimer()
        startButtonStyleTimer()
    }

    func onDisappear() {
        stopWindowCheckTimer()
        stopButtonStyleTimer()
    }

    /// Reloads data relevant to night mode/session handling.
    func reload() {
        guard !isAwaitingGracePeriodReconfiguration else { return }
        lastTimerCheckedMinute = nil
        guard loadConfig() else { return }
        checkIfBrokenTonight()
        restoreSessionIfNeeded()
        Task {
            await checkNightWindow()
        }
    }

    /// Called after the user saves a new configuration.
    /// Resets the break flag so night mode can re-activate with the new config.
    ///
    /// When the change comes from a grace period reconfiguration, the previous session
    /// is discarded here so it never counts towards stats or streaks.
    func reloadAfterConfigChange() {
        // The flag stays raised until the discarded session is gone, so a concurrent
        // reload cannot restore the session that is about to be deleted.
        let sessionToDiscard = isAwaitingGracePeriodReconfiguration ? session : nil
        lastTimerCheckedMinute = nil
        didBreakTonight = false
        session = nil
        gracePeriodSecondsRemaining = nil
        showCompletedButtonStyle = false
        guard loadConfig() else {
            isAwaitingGracePeriodReconfiguration = false
            return
        }
        Task {
            if let sessionToDiscard {
                restSessionManager.stopMonitoringAndUnlockApps()
                await deleteSessionUseCase.execute(session: sessionToDiscard)
                notificationManager.cancelSessionCompletionNotification()
            }
            isAwaitingGracePeriodReconfiguration = false
            checkIfBrokenTonight()
            restoreSessionIfNeeded()
            await checkNightWindow()
        }
    }

    /// Called after the user saves a configuration without changing the night schedule.
    ///
    /// If there is an active (non-broken) session, the save only refreshed the blocked
    /// apps or notifications, so the session is resumed untouched. If there is no active
    /// session (e.g. the user previously broke rest), the config was already re-saved
    /// with a new `createdAt`, so `reloadAfterConfigChange` will treat any previous break
    /// as belonging to an older window and start a fresh session.
    func handleSaveWithoutChanges() {
        if session != nil && !didBreakTonight {
            resumeAfterConfigDismissal()
        } else {
            reloadAfterConfigChange()
        }
    }

    // MARK: - Data loading

    @discardableResult
    func loadConfig() -> Bool {
        guard let fetched = fetchRestTimeUseCase.execute() else {
            hasConfiguration = false
            return false
        }
        hasConfiguration = true
        config = fetched
        appSettings = fetchAppSettingsUseCase.execute()
        gracePeriodDuration = TimeInterval(appSettings.gracePeriodMinutes) * 60
        return true
    }

    // MARK: - Formatting helpers

    private static func formatTime(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }
}
