import Foundation

// MARK: - NightModeViewModel+Timers
extension NightModeViewModel {

    // MARK: - Periodic window check (every minute)

    func startWindowCheckTimer() {
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

    func startButtonStyleTimer() {
        stopButtonStyleTimer()
        buttonStyleTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshButtonStyleState()
            }
        }
    }

    func stopButtonStyleTimer() {
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

    // MARK: - Button style & grace period state

    func refreshButtonStyleState(now: Date = Date()) {
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
        let remaining = gracePeriodDuration - elapsed
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
}
