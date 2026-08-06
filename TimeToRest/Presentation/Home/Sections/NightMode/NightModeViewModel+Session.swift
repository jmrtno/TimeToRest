import Foundation

// MARK: - NightModeViewModel+Session
extension NightModeViewModel {

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
            if appSettings.isNotificationsEnabled {
                notificationManager.scheduleSessionCompletionNotification(for: config)
            }
        } else {
            restoreSessionIfNeeded()
            if session != nil {
                if appSettings.isNotificationsEnabled {
                notificationManager.scheduleSessionCompletionNotification(for: config)
            }
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
    func restoreSessionIfNeeded() {
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
    func checkIfBrokenTonight() {
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

    // MARK: - Session helpers

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
