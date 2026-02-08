import Foundation
import Combine

// MARK: - HomeViewModel
/// ViewModel for the main home screen.
/// The home screen transforms into night mode when the rest window is active.
/// A periodic timer checks the window so the UI updates automatically.
@MainActor
final class HomeViewModel: ObservableObject {

    // MARK: - Published state
    @Published var config: TimeToRestEntity = .firstConfig
    @Published var stats: RestStatsEntity = .empty
    @Published var isWithinNightWindow: Bool = false
    @Published var hasConfiguration: Bool = false

    // MARK: - Night mode state (inline, not a separate screen)
    @Published var session: RestSessionEntity?
    @Published var lateMessage: String?
    @Published var didBreakTonight: Bool = false

    /// Controls whether the night mode UI is shown.
    /// False if the user already broke the rest tonight.
    var showNightMode: Bool {
        isWithinNightWindow && !didBreakTonight
    }

    // MARK: - Dependencies
    private let fetchRestTimeUseCase: FetchRestTimeUseCase
    private let calculateStatsUseCase: CalculateStatsUseCase
    private let startRestSessionUseCase: StartRestSessionUseCase
    private let completeRestSessionUseCase: CompleteRestSessionUseCase
    private let fetchCurrentSessionUseCase: FetchCurrentSessionUseCase

    private var windowCheckTimer: Timer?

    init(
        fetchRestTimeUseCase: FetchRestTimeUseCase,
        calculateStatsUseCase: CalculateStatsUseCase,
        startRestSessionUseCase: StartRestSessionUseCase,
        completeRestSessionUseCase: CompleteRestSessionUseCase,
        fetchCurrentSessionUseCase: FetchCurrentSessionUseCase
    ) {
        self.fetchRestTimeUseCase = fetchRestTimeUseCase
        self.calculateStatsUseCase = calculateStatsUseCase
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

    /// Reloads all data from repositories. Call when returning from pushed screens.
    func reload() {
        guard loadConfig() else { return }
        loadStats()
        checkIfBrokenTonight()
        restoreSessionIfNeeded()
        checkNightWindow()
    }

    /// Called after the user saves a new configuration.
    /// Resets the break flag so night mode can re-activate with the new config.
    func reloadAfterConfigChange() {
        didBreakTonight = false
        session = nil
        lateMessage = nil
        guard loadConfig() else { return }
        loadStats()
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

    func loadStats() {
        stats = calculateStatsUseCase.execute()
    }

    // MARK: - Night window

    func checkNightWindow() {
        let wasInWindow = isWithinNightWindow
        isWithinNightWindow = Self.isCurrentlyInNightWindow(config: config)

        /// Entering the night window → start a rest session
        if isWithinNightWindow && !wasInWindow {
            startRestSession()
        }

        /// Leaving the night window → mark session completed, clear state, reset break flag
        if !isWithinNightWindow && wasInWindow {
            completeCurrentSession()
            session = nil
            lateMessage = nil
            didBreakTonight = false
            loadStats()
        }

        /// If already in window on appear and no session yet (and not broken), start one
        if isWithinNightWindow && !didBreakTonight && session == nil {
            startRestSession()
        }

        /// If we're outside the window, check for any unfinished session and mark it completed
        if !isWithinNightWindow {
            completeCurrentSession()
        }
    }

    /// Starts a rest session if within the night window.
    func startRestSession() {
        if let newSession = startRestSessionUseCase.execute() {
            session = newSession
            if newSession.delayInMinutes > 0 {
                lateMessage = "Started a bit late today, but here you are 🌙"
            } else {
                lateMessage = nil
            }
        }
    }

    /// Marks the current session as completed (user didn't break rest).
    /// Checks both today and yesterday to handle overnight windows.
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
            if persisted.delayInMinutes > 0 {
                lateMessage = "Started a bit late today, but here you are 🌙"
            }
        }
    }

    /// Checks persisted session to see if rest was already broken tonight.
    /// Checks both today and yesterday to handle overnight windows.
    private func checkIfBrokenTonight() {
        if fetchCurrentSessionUseCase.execute()?.didBreakRest == true {
            didBreakTonight = true
        }
    }

    var isStrictMode: Bool {
        config.isStrictModeEnabled
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

    // MARK: - Formatted helpers

    var formattedStartTime: String {
        let h = config.startTime.hour ?? 23
        let m = config.startTime.minute ?? 30
        return String(format: "%02d:%02d", h, m)
    }

    var formattedEndTime: String {
        let h = config.endTime.hour ?? 7
        let m = config.endTime.minute ?? 0
        return String(format: "%02d:%02d", h, m)
    }
}

