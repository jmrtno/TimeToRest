import Foundation
import Combine

// MARK: - BreakBlockViewModel
/// ViewModel for the "break the block" flow.
/// Manages the countdown, psychological messages, and the final break action.
@MainActor
final class BreakBlockViewModel: ObservableObject {

    // MARK: - Published state
    /// The remaining seconds in the countdown before the user can break the rest.
    @Published var countdownRemaining: Int
    /// The current motivational message displayed during the countdown.
    @Published var motivationalMessage: String = ""
    /// The congratulatory message displayed when the rest is completed.
    @Published var congratulationMessage: String = ""
    /// Whether the user is allowed to break the rest (countdown finished).
    @Published var canBreak: Bool = false
    /// The current rest statistics displayed in the UI.
    @Published var stats: RestStatsEntity = .empty

    // MARK: - Dependencies
    /// Use case for calculating rest statistics.
    private let calculateStatsUseCase: CalculateStatsUseCase
    /// Manager for handling rest session lifecycle.
    private let restSessionManager: RestSessionManager
    /// Manager for handling notifications.
    private let notificationManager: NotificationManager

    /// The total duration of the countdown in seconds.
    let totalCountdown: Int
    /// The timer that drives the countdown.
    private var timer: Timer?

    // MARK: - Psychological messages
    /// Messages shown during the countdown to discourage breaking the rest.
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
    
    /// Messages shown when the rest is successfully completed.
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

    /// Starts the countdown timer and loads initial data.
    ///
    /// This method:
    /// 1. Loads current rest statistics
    /// 2. Picks a random motivational message
    /// 3. Starts a timer that decrements the countdown every second
    func startCountdown() {
        loadStats()
        pickMotivationalRandomMessage()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
    }

    /// Executes the break rest action.
    ///
    /// This method:
    /// 1. Checks if breaking is allowed (countdown finished)
    /// 2. Cancels the rest session manually
    /// 3. Cancels any pending completion notifications
    /// 4. Reloads statistics
    /// 5. Stops the timer
    func breakRest() {
        guard canBreak else { return }
        restSessionManager.cancelRestManually()
        // Cancel the completion notification immediately since session was broken
        notificationManager.cancelSessionCompletionNotification()
        stats = calculateStatsUseCase.execute()
        stopTimer()
    }

    /// Stops the countdown timer and cleans up resources.
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private

    /// Decrements the countdown by one second.
    ///
    /// When the countdown reaches zero, enables breaking and stops the timer.
    private func tick() {
        guard countdownRemaining > 0 else { return }

        countdownRemaining -= 1

        if countdownRemaining == 0 {
            canBreak = true
            stopTimer()
        }
    }

    /// Selects a random motivational message from the break messages array.
    private func pickMotivationalRandomMessage() {
        let breakMessages = breakMessages
        motivationalMessage = breakMessages.randomElement() ?? ""
    }
    
    /// Selects a random congratulatory message from the congratulation messages array.
    func pickCongratulationRandomMessage() {
        let congratulationMessages = congratulationMessages
        congratulationMessage = congratulationMessages.randomElement() ?? ""
    }

    /// Loads the latest rest statistics.
    private func loadStats() {
        stats = calculateStatsUseCase.execute()
    }

    /// A message showing the current streak that will be lost if the user breaks.
    ///
    /// - Returns: A string describing the current streak, or nil if no streak.
    var streakMessage: String? {
        if stats.currentStreak > 0 {
            return "You had \(stats.currentStreak) consecutive nights"
        }
        return nil
    }
}
