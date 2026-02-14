import Foundation
import Combine

// MARK: - NightModeViewModel
/// ViewModel for the night mode section.
/// Handles night-window/session state used to switch UI mode.
@MainActor
final class NightModeViewModel: ObservableObject {

    // MARK: - Published state
    @Published var config: TimeToRestEntity = .firstConfig
    @Published var isWithinNightWindow: Bool = false
    @Published var hasConfiguration: Bool = false
    @Published var session: RestSessionEntity?
    @Published var didBreakTonight: Bool = false

    /// Controls whether the night mode UI is shown.
    /// False if the user already broke the rest tonight.
    var showNightMode: Bool {
        isWithinNightWindow && !didBreakTonight
    }

    var isStrictMode: Bool {
        config.isStrictModeEnabled
    }

    var isStrictModeEnabled: String {
        isStrictMode ? "On" : "Off"
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

    // MARK: - Dependencies
    private let fetchRestTimeUseCase: FetchRestTimeUseCase
    private let startRestSessionUseCase: StartRestSessionUseCase
    private let completeRestSessionUseCase: CompleteRestSessionUseCase
    private let fetchCurrentSessionUseCase: FetchCurrentSessionUseCase

    private var windowCheckTimer: Timer?

    init(
        fetchRestTimeUseCase: FetchRestTimeUseCase,
        startRestSessionUseCase: StartRestSessionUseCase,
        completeRestSessionUseCase: CompleteRestSessionUseCase,
        fetchCurrentSessionUseCase: FetchCurrentSessionUseCase
    ) {
        self.fetchRestTimeUseCase = fetchRestTimeUseCase
        self.startRestSessionUseCase = startRestSessionUseCase
        self.completeRestSessionUseCase = completeRestSessionUseCase
        self.fetchCurrentSessionUseCase = fetchCurrentSessionUseCase
    }

    // MARK: - Lifecycle

    func onAppear() {
        reload()
        startWindowCheckTimer()
    }

    func onDisappear() {
        stopWindowCheckTimer()
    }

    /// Reloads data relevant to night mode/session handling.
    func reload() {
        guard loadConfig() else { return }
        checkIfBrokenTonight()
        restoreSessionIfNeeded()
        checkNightWindow()
    }

    /// Called after the user saves a new configuration.
    /// Resets the break flag so night mode can re-activate with the new config.
    func reloadAfterConfigChange() {
        didBreakTonight = false
        session = nil
        guard loadConfig() else { return }
        checkNightWindow()
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

    func checkNightWindow() {
        let wasInWindow = isWithinNightWindow
        isWithinNightWindow = Self.isCurrentlyInNightWindow(config: config)

        if isWithinNightWindow && !wasInWindow {
            startRestSession()
        }

        if !isWithinNightWindow && wasInWindow {
            completeCurrentSession()
            session = nil
            didBreakTonight = false
        }

        if isWithinNightWindow && !didBreakTonight && session == nil {
            startRestSession()
        }

        if !isWithinNightWindow {
            completeCurrentSession()
        }
    }
    

    /// Starts a rest session if within the night window.
    func startRestSession() {
        if let newSession = startRestSessionUseCase.execute() {
            session = newSession
        }
    }

    /// Marks the current session as completed (user didn't break rest).
    private func completeCurrentSession() {
        completeRestSessionUseCase.execute()
    }

    /// Restores the in-memory session from persistence if we're in the night window
    /// and the session was lost (e.g. after returning from a pushed screen).
    private func restoreSessionIfNeeded() {
        guard session == nil, !didBreakTonight else { return }
        if let persisted = fetchCurrentSessionUseCase.execute(),
           !persisted.didBreakRest, !persisted.isCompleted {
            session = persisted
        }
    }

    /// Checks persisted session to see if rest was already broken tonight.
    private func checkIfBrokenTonight() {
        if fetchCurrentSessionUseCase.execute()?.didBreakRest == true {
            didBreakTonight = true
        }
    }

    // MARK: - Periodic window check (every 5 seconds)

    private func startWindowCheckTimer() {
        stopWindowCheckTimer()
        windowCheckTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkNightWindow()
            }
        }
    }

    func stopWindowCheckTimer() {
        windowCheckTimer?.invalidate()
        windowCheckTimer = nil
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

    private static func formatTime(hour: Int, minute: Int) -> String {
        String(format: "%02d:%02d", hour, minute)
    }
}
