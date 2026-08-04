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
    private var isAwaitingGracePeriodReconfiguration: Bool = false
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
    private let fetchRestTimeUseCase: FetchRestTimeUseCase
    private let startRestSessionUseCase: StartRestSessionUseCase
    private let completeRestSessionUseCase: CompleteRestSessionUseCase
    private let fetchCurrentSessionUseCase: FetchCurrentSessionUseCase
    private let deleteSessionUseCase: DeleteSessionUseCase
    private let restSessionManager: RestSessionManager
    private let notificationManager: NotificationManager

    private var windowCheckTimer: Timer?
    private var lastTimerCheckedMinute: Int?
    private var buttonStyleTimer: Timer?

    private static let gracePeriodDuration: TimeInterval = 10 * 60

    init(
        fetchRestTimeUseCase: FetchRestTimeUseCase,
        startRestSessionUseCase: StartRestSessionUseCase,
        completeRestSessionUseCase: CompleteRestSessionUseCase,
        fetchCurrentSessionUseCase: FetchCurrentSessionUseCase,
        deleteSessionUseCase: DeleteSessionUseCase,
        restSessionManager: RestSessionManager,
        notificationManager: NotificationManager
    ) {
        self.fetchRestTimeUseCase = fetchRestTimeUseCase
        self.startRestSessionUseCase = startRestSessionUseCase
        self.completeRestSessionUseCase = completeRestSessionUseCase
        self.fetchCurrentSessionUseCase = fetchCurrentSessionUseCase
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

    // MARK: - Data loading

    @discardableResult
    func loadConfig() -> Bool {
        guard let fetched = fetchRestTimeUseCase.execute() else {
            hasConfiguration = false
            return false
        }
        hasConfiguration = true
        config = fetched
        return true
    }

    // MARK: - Night window

    func checkNightWindow() async {
        guard !isAwaitingGracePeriodReconfiguration else { return }
        checkIfBrokenTonight()
        isWithinNightWindow = Self.isCurrentlyInNightWindow(config: config)

        if didBreakTonight {
            restSessionManager.stopMonitoringAndUnlockApps()
            session = nil
            showCompletedButtonStyle = false
            return
        }

        // Check if current session was broken (user cancelled via break screen)
        if let currentSession = session,
           let updatedSession = fetchCurrentSessionUseCase.execute(),
           updatedSession.didBreakRest && updatedSession.id == currentSession.id {
            session = nil
            didBreakTonight = true
            showCompletedButtonStyle = false
            // Cancel completion notification since session was broken
            notificationManager.cancelSessionCompletionNotification()
            return
        }

        // Session will only be completed when user explicitly terminates it
        guard isWithinNightWindow else { return }

        if session == nil {
            await startRestSession()
        }

        restSessionManager.startMonitoringIfNeeded(configuration: config)
    }
    

    /// Starts a rest session if within the night window.
    func startRestSession() async {
        // Don't start a new session if there's already one active
        guard session == nil else { return }

        if let newSession = await startRestSessionUseCase.execute() {
            session = newSession
            showCompletedButtonStyle = false

            // Calculate if user started late
            minutesLate = calculateMinutesLate(session: newSession)

            // Schedule completion notification for this session
            notificationManager.scheduleSessionCompletionNotification(for: config)
        } else {
            restoreSessionIfNeeded()
            if session != nil {
                notificationManager.scheduleSessionCompletionNotification(for: config)
            }
        }
    }

    func handleBreakRequest(now: Date = Date()) async -> BreakRequestOutcome {
        guard let currentSession = session else {
            return .noSession
        }

        if let _ = await completeRestSessionUseCase.execute(session: currentSession, completedAt: now) {
            session = nil
            didBreakTonight = false
            showCompletedButtonStyle = false
            restSessionManager.stopMonitoringAndUnlockApps()
            notificationManager.cancelSessionCompletionNotification()
            return .completed
        }

        return .needsManualBreak
    }

    /// Marks the start of a reconfiguration of the rest schedule during the grace period.
    ///
    /// The ongoing session is kept untouched and its grace period keeps counting down,
    /// so cancelling the configuration leaves the session exactly as it was. Discarding
    /// the session only happens if the user saves a different night schedule.
    /// Auto-start of a new session is suspended meanwhile.
    func beginGracePeriodReconfiguration() {
        guard session != nil else { return }
        isAwaitingGracePeriodReconfiguration = true
    }

    /// Called when the configuration modal is dismissed without changing the schedule,
    /// either because it was cancelled or because only the blocked apps were edited.
    ///
    /// The ongoing session and its grace period are resumed untouched, and monitoring is
    /// refreshed so that a new blocked apps selection applies right away.
    func resumeAfterConfigDismissal() {
        isAwaitingGracePeriodReconfiguration = false
        refreshButtonStyleState()
        Task {
            await checkNightWindow()
        }
    }

    /// Restores the in-memory session from persistence if we're in the night window
    /// and the session was lost (e.g. after returning from a pushed screen).
    private func restoreSessionIfNeeded() {
        guard session == nil, !didBreakTonight else { return }
        if let persisted = fetchCurrentSessionUseCase.execute(),
           isSessionInCurrentRestWindow(persisted),
           !persisted.didBreakRest, !persisted.isCompleted {
            session = persisted
            // Recalculate minutes late for restored session
            minutesLate = calculateMinutesLate(session: persisted)
        }
    }

    /// Checks persisted session to see if rest was already broken tonight.
    private func checkIfBrokenTonight() {
        guard let persistedSession = fetchCurrentSessionUseCase.execute() else {
            didBreakTonight = false
            return
        }
        guard isSessionInCurrentRestWindow(persistedSession) else {
            didBreakTonight = false
            return
        }

        guard persistedSession.didBreakRest else {
            didBreakTonight = false
            return
        }

        let breakReferenceDate = persistedSession.brokenAt ?? persistedSession.startedAt
        didBreakTonight = breakReferenceDate >= config.createdAt
    }

    private func isSessionInCurrentRestWindow(_ session: RestSessionEntity, now: Date = Date()) -> Bool {
        guard let currentWindow = currentRestWindowInterval(now: now) else { return false }
        return session.startedAt >= currentWindow.start && session.startedAt < currentWindow.end
    }

    private func currentRestWindowInterval(now: Date) -> (start: Date, end: Date)? {
        let calendar = Calendar.current

        let startHour = config.startTime.hour ?? 23
        let startMinute = config.startTime.minute ?? 30
        let endHour = config.endTime.hour ?? 7
        let endMinute = config.endTime.minute ?? 0

        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotal = currentHour * 60 + currentMinute

        let startTotal = startHour * 60 + startMinute
        let endTotal = endHour * 60 + endMinute
        let crossesMidnight = startTotal > endTotal

        let startOfToday = calendar.startOfDay(for: now)
        let todayStart = calendar.date(
            byAdding: DateComponents(hour: startHour, minute: startMinute),
            to: startOfToday
        ) ?? now
        let todayEnd = calendar.date(
            byAdding: DateComponents(hour: endHour, minute: endMinute),
            to: startOfToday
        ) ?? now

        if crossesMidnight {
            if currentTotal >= startTotal {
                let tomorrowEnd = calendar.date(byAdding: .day, value: 1, to: todayEnd) ?? todayEnd
                return (start: todayStart, end: tomorrowEnd)
            }
            if currentTotal < endTotal {
                let yesterdayStart = calendar.date(byAdding: .day, value: -1, to: todayStart) ?? todayStart
                return (start: yesterdayStart, end: todayEnd)
            }
            return nil
        }

        guard currentTotal >= startTotal, currentTotal < endTotal else { return nil }
        return (start: todayStart, end: todayEnd)
    }

    // MARK: - Periodic window check (every minute)

    private func startWindowCheckTimer() {
        stopWindowCheckTimer()
        windowCheckTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkNightWindowFromTimer()
            }
        }
    }

    func stopWindowCheckTimer() {
        windowCheckTimer?.invalidate()
        windowCheckTimer = nil
    }

    private func startButtonStyleTimer() {
        stopButtonStyleTimer()
        buttonStyleTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshButtonStyleState()
            }
        }
    }

    private func stopButtonStyleTimer() {
        buttonStyleTimer?.invalidate()
        buttonStyleTimer = nil
    }

    private func checkNightWindowFromTimer(now: Date = Date()) {
        let minuteMark = Int(now.timeIntervalSince1970 / 60)
        guard minuteMark != lastTimerCheckedMinute else { return }
        lastTimerCheckedMinute = minuteMark
        Task {
            await checkNightWindow()
        }
    }

    // MARK: - Night Window Logic

    static func isCurrentlyInNightWindow(config: TimeToRestEntity, now: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotal = currentHour * 60 + currentMinute

        let startHour = config.startTime.hour ?? 23
        let startMinute = config.startTime.minute ?? 30
        let startTotal = startHour * 60 + startMinute

        let endHour = config.endTime.hour ?? 7
        let endMinute = config.endTime.minute ?? 0
        let endTotal = endHour * 60 + endMinute

        if startTotal > endTotal {
            return currentTotal >= startTotal || currentTotal < endTotal
        } else {
            return currentTotal >= startTotal && currentTotal < endTotal
        }
    }

    // MARK: - Helpers

    private func configuredWindowMinutes() -> Int {
        let startTotal = (config.startTime.hour ?? 23) * 60 + (config.startTime.minute ?? 30)
        let endTotal = (config.endTime.hour ?? 7) * 60 + (config.endTime.minute ?? 0)
        return endTotal >= startTotal ? (endTotal - startTotal) : (24 * 60 - startTotal + endTotal)
    }

    private func sessionRestMinutes(session: RestSessionEntity) -> Int {
        let calendar = Calendar.current
        let normalizedStart = calendar.date(
            from: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: session.startedAt)
        ) ?? session.startedAt

        var endComponents = calendar.dateComponents([.year, .month, .day], from: normalizedStart)
        endComponents.hour = config.endTime.hour ?? 7
        endComponents.minute = config.endTime.minute ?? 0
        endComponents.second = 0

        guard var endDate = calendar.date(from: endComponents) else {
            return configuredWindowMinutes()
        }

        if endDate <= normalizedStart {
            endDate = calendar.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        }

        return max(0, Int(endDate.timeIntervalSince(normalizedStart) / 60))
    }

    private func refreshButtonStyleState(now: Date = Date()) {
        guard let currentSession = session else {
            showCompletedButtonStyle = false
            gracePeriodSecondsRemaining = nil
            return
        }
        showCompletedButtonStyle = isCompletionTimeReached(for: currentSession, now: now)
        gracePeriodSecondsRemaining = remainingGracePeriodSeconds(for: currentSession, now: now)
    }

    /// Seconds left in the 10 minute grace period for reconfiguring the schedule
    /// without the session counting as a broken rest. Returns nil once expired
    /// or once the session has already broken/completed.
    private func remainingGracePeriodSeconds(for session: RestSessionEntity, now: Date) -> Int? {
        guard !session.didBreakRest, !session.isCompleted else { return nil }
        let elapsed = now.timeIntervalSince(session.startedAt)
        let remaining = Self.gracePeriodDuration - elapsed
        return remaining > 0 ? Int(remaining) : nil
    }

    private func isCompletionTimeReached(for session: RestSessionEntity, now: Date = Date()) -> Bool {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: session.day)
        components.hour = session.endTime.hour ?? 0
        components.minute = session.endTime.minute ?? 0
        components.second = session.endTime.second ?? 0

        guard var endDate = Calendar.current.date(from: components) else {
            return false
        }

        if endDate <= session.startedAt {
            endDate = Calendar.current.date(byAdding: .day, value: 1, to: endDate) ?? endDate
        }

        return now >= endDate
    }

    private static func formatTime(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }

    /// Calculates how many minutes late the user started the session compared to the configured start time.
    /// Compares session.startedAt with the configured start time for the corresponding day.
    private func calculateMinutesLate(session: RestSessionEntity) -> Int? {
        guard let window = currentRestWindowInterval(now: session.startedAt) else {
            return nil
        }

        let lateMinutes = Int(session.startedAt.timeIntervalSince(window.start) / 60)
        return lateMinutes > 0 ? lateMinutes : nil
    }
}
