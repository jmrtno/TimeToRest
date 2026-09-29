import Foundation
import os
import UserNotifications

/// Wrapper of UserNotifications that abstracts the complexity of notification handling
/// Responsibilities:
/// - Manage notification permissions
/// - Schedule local notifications for reminders
/// - Handle notification presentation in foreground
@MainActor
final class NotificationManager: NSObject {
    /// System notification center for all functionality
    private let notificationCenter: UNUserNotificationCenter

    /// Current notification authorization status
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    // MARK: - Constants
    private static let preReminderMinutes = 10
    private nonisolated static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "TimeToRest",
        category: "NotificationManager"
    )

    /// Configures UNUserNotificationCenter with delegate to handle events
    /// Updates authorization status on startup for consistent data
    override init() {
        self.notificationCenter = UNUserNotificationCenter.current()
        super.init()
        notificationCenter.delegate = self
        Task {
            await refreshAuthorizationStatus()
            // Clean up any legacy finish notifications that were scheduled daily
            await removeLegacyFinishNotifications()
        }
    }

    /// Requests notification permission with complete options
    /// - alert: shows notification banner
    /// - sound: plays sound when arriving
    /// - badge: shows number on app icon
    /// - Returns: Whether the user granted the permission.
    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted: Bool
        do {
            granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            Self.logger.error("Notification authorization request failed: \(error.localizedDescription, privacy: .public)")
            granted = false
        }
        await refreshAuthorizationStatus()
        return granted
    }

    func refreshAuthorizationStatus() async {
        authorizationStatus = await notificationCenter.notificationSettings().authorizationStatus
    }

    // MARK: - Rest Time Notifications

    /// Schedules the nightly rest reminder at the configured start time.
    /// Fires daily at the configured hour.
    func scheduleRestReminder(for restTime: TimeToRestEntity) async {
        await cancelStartReminderNotifications()

        guard let hour = restTime.startTime.hour,
              let minute = restTime.startTime.minute else { return }

        // Main notification at start time
        let content = UNMutableNotificationContent()
        content.title = "Time to Rest"
        content.body = "Keep the app open to track your progress. See you in the morning!"
        content.sound = .default
        content.categoryIdentifier = "REST_TIME"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "rest_start_\(restTime.restIdentifier)",
            content: content,
            trigger: trigger
        )
        await add(request)

        // Pre-reminder 10 minutes before
        let preContent = UNMutableNotificationContent()
        preContent.title = "Almost Time"
        preContent.body = "Last chance to put down the phone. Remember to keep the app open to track your progress."
        preContent.sound = .default
        preContent.categoryIdentifier = "REST_PRE_REMINDER"

        var preComponents = DateComponents()
        var preMinute = minute - Self.preReminderMinutes
        var preHour = hour
        if preMinute < 0 {
            preMinute += 60
            preHour -= 1
            if preHour < 0 { preHour += 24 }
        }
        preComponents.hour = preHour
        preComponents.minute = preMinute

        let preTrigger = UNCalendarNotificationTrigger(dateMatching: preComponents, repeats: true)
        let preRequest = UNNotificationRequest(
            identifier: "rest_pre_\(restTime.restIdentifier)",
            content: preContent,
            trigger: preTrigger
        )
        await add(preRequest)
    }

    /// Removes old daily finish notifications created before per-session scheduling
    private func removeLegacyFinishNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let finishIds = requests
            .map(\.identifier)
            .filter { $0.hasPrefix("rest_finish_") }
        guard !finishIds.isEmpty else { return }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: finishIds)
    }

    /// Schedules a completion notification for the current session only
    /// This should be called when a session starts
    func scheduleSessionCompletionNotification(for restTime: TimeToRestEntity) async {
        // First cancel any existing completion notifications
        cancelSessionCompletionNotification()

        guard let finishHour = restTime.endTime.hour,
              let finishMinute = restTime.endTime.minute else { return }

        let finishContent = UNMutableNotificationContent()
        finishContent.title = "Rest complete!"
        finishContent.body = "Finish your rest to increase your streak!"
        finishContent.sound = .default
        finishContent.categoryIdentifier = "REST_FINISH"

        var finishComponents = DateComponents()
        finishComponents.hour = finishHour
        finishComponents.minute = finishMinute

        let finishTrigger = UNCalendarNotificationTrigger(dateMatching: finishComponents, repeats: false) // No repeat
        let finishRequest = UNNotificationRequest(
            identifier: "rest_finish_current_session",
            content: finishContent,
            trigger: finishTrigger
        )
        await add(finishRequest)
    }

    /// Cancels the session completion notification
    /// This should be called when the user breaks the rest
    func cancelSessionCompletionNotification() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["rest_finish_current_session"])
    }

    /// Cancels all rest-related notifications.
    func cancelAllRestNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let ids = requests
            .filter { $0.identifier.hasPrefix("rest_") }
            .map(\.identifier)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        notificationCenter.removeAllDeliveredNotifications()
    }

    /// Cancels only start and pre-reminder notifications, preserving any active session completion notification.
    private func cancelStartReminderNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        let ids = requests
            .filter { $0.identifier.hasPrefix("rest_start_") || $0.identifier.hasPrefix("rest_pre_") }
            .map(\.identifier)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        notificationCenter.removeAllDeliveredNotifications()
    }

    /// Adds a request, logging the failure instead of silently discarding it.
    private func add(_ request: UNNotificationRequest) async {
        do {
            try await notificationCenter.add(request)
        } catch {
            Self.logger.error(
                "Failed to schedule notification \(request.identifier, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Handles notifications in foreground (app active)
    /// Forces presentation for better user experience
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    /// Handles user interaction with notification (tap, etc.)
    /// Extensible for navigation or specific actions
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
