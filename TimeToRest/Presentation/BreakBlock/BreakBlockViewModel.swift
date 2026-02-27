import Foundation
import Combine

// MARK: - BreakBlockViewModel
/// ViewModel for the "break the block" flow.
/// Manages the countdown, psychological messages, and the final break action.
@MainActor
final class BreakBlockViewModel: ObservableObject {

    // MARK: - Published state
    @Published var countdownRemaining: Int
    @Published var motivationalMessage: String = ""
    @Published var congratulationMessage: String = ""
    @Published var canBreak: Bool = false
    @Published var stats: RestStatsEntity = .empty

    // MARK: - Dependencies
    private let calculateStatsUseCase: CalculateStatsUseCase
    private let restSessionManager: RestSessionManager
    private let notificationManager: NotificationManager

    let totalCountdown: Int
    private var timer: Timer?

    // MARK: - Psychological messages
    private let breakMessages = [
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
    
    private let congratulationMessages = [
        "Rest completed. Your discipline is showing.",
        "Another night in your favor. Keep it up.",
        "You paused, you breathed, you gained clarity.",
        "Calm mind, grateful body. Excellent work.",
        "You stayed true to your plan. Pride well deserved.",
        "Every unplugged minute adds to your energy.",
        "Impeccable consistency, impeccable rest.",
        "You protected your time and your calm. Bravo.",
        "Today's serenity feeds tomorrow's focus.",
        "You did it again: full rest and a fresh mind."
    ]

    init(
        calculateStatsUseCase: CalculateStatsUseCase,
        restSessionManager: RestSessionManager,
        notificationManager: NotificationManager
    ) {
        self.calculateStatsUseCase = calculateStatsUseCase
        self.restSessionManager = restSessionManager
        self.notificationManager = notificationManager
        let total = 10
        self.totalCountdown = total
        self.countdownRemaining = total
    }

    // MARK: - Actions

    func startCountdown() {
        loadStats()
        pickMotivationalRandomMessage()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    func breakRest() {
        guard canBreak else { return }
        restSessionManager.cancelRestManually()
        // Cancel the completion notification immediately since session was broken
        notificationManager.cancelSessionCompletionNotification()
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

    private func pickMotivationalRandomMessage() {
        let breakMessages = breakMessages
        motivationalMessage = breakMessages.randomElement() ?? ""
    }
    
    func pickCongratulationRandomMessage() {
        let congratulationMessages = congratulationMessages
        congratulationMessage = congratulationMessages.randomElement() ?? ""
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
