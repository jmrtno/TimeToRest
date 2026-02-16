import Foundation
import Combine

// MARK: - BreakBlockViewModel
/// ViewModel for the "break the block" flow.
/// Manages the countdown, psychological messages, and the final break action.
@MainActor
final class BreakBlockViewModel: ObservableObject {

    // MARK: - Published state
    @Published var countdownRemaining: Int
    @Published var currentMessage: String = ""
    @Published var canBreak: Bool = false
    @Published var stats: RestStatsEntity = .empty

    // MARK: - Dependencies
    private let calculateStatsUseCase: CalculateStatsUseCase
    private let restSessionManager: RestSessionManager
    private let isStrictMode: Bool

    let totalCountdown: Int
    private var timer: Timer?

    // MARK: - Psychological messages
    private let normalMessages = [
        "Are you sure about this?",
        "You were doing so well...",
        "Tomorrow you'll wish you hadn't.",
        "Think about why you started.",
        "Just one more night. You can do it.",
        "The phone will still be there tomorrow.",
        "Sleep is more valuable than scrolling.",
        "Your future self is watching.",
        "This is the moment that matters.",
        "You're stronger than this urge."
    ]

    private let strictMessages = [
        "This is exactly what you wanted to avoid.",
        "You made a promise to yourself.",
        "Every time you give in, it gets harder.",
        "Is this really worth breaking your streak?",
        "You know you'll regret this.",
        "The screen can wait. You can't get this sleep back.",
        "Stop. Think. Is this who you want to be?",
        "Your discipline defines you.",
        "One moment of weakness. Don't let it win.",
        "Put the phone down. Now."
    ]

    init(
        calculateStatsUseCase: CalculateStatsUseCase,
        restSessionManager: RestSessionManager,
        isStrictMode: Bool
    ) {
        self.calculateStatsUseCase = calculateStatsUseCase
        self.restSessionManager = restSessionManager
        self.isStrictMode = isStrictMode
        let total = isStrictMode ? 20 : 10
        self.totalCountdown = total
        self.countdownRemaining = total
    }

    // MARK: - Actions

    func startCountdown() {
        loadStats()
        pickRandomMessage()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    func breakRest() {
        guard canBreak else { return }
        restSessionManager.cancelRestManually()
        stats = calculateStatsUseCase.execute()
        stopTimer()
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private

    private func tick() {
        guard countdownRemaining > 0 else { return }

        countdownRemaining -= 1

        if countdownRemaining == 0 {
            canBreak = true
            stopTimer()
        }
    }

    private func pickRandomMessage() {
        let messages = isStrictMode ? strictMessages : normalMessages
        currentMessage = messages.randomElement() ?? ""
    }

    private func loadStats() {
        stats = calculateStatsUseCase.execute()
    }

    var streakMessage: String? {
        if stats.currentStreak > 0 {
            return "You had \(stats.currentStreak) consecutive nights"
        }
        return nil
    }
}
