import Foundation
import UserNotifications

/// Wrapper of UserNotifications that abstracts the complexity of notification handling
/// Responsibilities:
/// - Manage notification permissions
/// - Schedule local notifications for reminders
/// - Handle notification presentation in foreground
@MainActor
final class NotificationManager: NSObject {
    /// System notification center for all functionality
    private nonisolated let notificationCenter: UNUserNotificationCenter
    
    /// Current notification authorization status
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    // MARK: - Constants
    private static let preReminderMinutes = 10
    
    /// Configures UNUserNotificationCenter with delegate to handle events
    /// Updates authorization status on startup for consistent data
    override init() {
        self.notificationCenter = UNUserNotificationCenter.current()
        super.init()
        notificationCenter.delegate = self
        refreshAuthorizationStatus()
        // Clean up any legacy finish notifications that were scheduled daily
        removeLegacyFinishNotifications()
    }
    
    /// Requests notification permission with complete options
    /// - alert: shows notification banner
    /// - sound: plays sound when arriving
    /// - badge: shows number on app icon
    func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            Task { @MainActor [weak self] in
                self?.refreshAuthorizationStatus()
                completion(granted)
            }
        }
    }
    
    func refreshAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            Task { @MainActor [weak self] in
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Rest Time Notifications

    /// Schedules the nightly rest reminder at the configured start time.
    /// Fires daily at the configured hour.
    func scheduleRestReminder(for restTime: TimeToRestEntity) {
        cancelAllRestNotifications()

        guard let hour = restTime.startTime.hour,
              let minute = restTime.startTime.minute else { return }

        // Main notification at start time
        let content = UNMutableNotificationContent()
        content.title = "🌙 Time to Rest"
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
        notificationCenter.add(request) { _ in }

        // Pre-reminder 10 minutes before
        let preContent = UNMutableNotificationContent()
        preContent.title = "⏰ Almost Time"
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
        notificationCenter.add(preRequest) { _ in }
    }

    /// Removes old daily finish notifications created before per-session scheduling
    private func removeLegacyFinishNotifications() {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            let finishIds = requests
                .map { $0.identifier }
                .filter { $0.hasPrefix("rest_finish_") }
            guard !finishIds.isEmpty else { return }
            self?.notificationCenter.removePendingNotificationRequests(withIdentifiers: finishIds)
        }
    }

    /// Schedules a completion notification for the current session only
    /// This should be called when a session starts
    func scheduleSessionCompletionNotification(for restTime: TimeToRestEntity) {
        // First cancel any existing completion notifications
        cancelSessionCompletionNotification()
        
        guard let finishHour = restTime.endTime.hour,
              let finishMinute = restTime.endTime.minute else { return }
        
        let finishContent = UNMutableNotificationContent()
        finishContent.title = "Rest complete, welcome back!"
        finishContent.body = "You have completed the rest successfully, congratulations!"
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
        notificationCenter.add(finishRequest) { _ in }
    }

    /// Cancels the session completion notification
    /// This should be called when the user breaks the rest
    func cancelSessionCompletionNotification() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["rest_finish_current_session"])
    }

    /// Cancels all rest-related notifications.
    func cancelAllRestNotifications() {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix("rest_") }
                .map { $0.identifier }
            self?.notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        }
        notificationCenter.removeAllDeliveredNotifications()
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
