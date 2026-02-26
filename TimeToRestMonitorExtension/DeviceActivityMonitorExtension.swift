import DeviceActivity
import ManagedSettings
import Foundation
import UserNotifications

/// Device Activity Monitor Extension for TimeToRest
/// 
/// This extension monitors device activity during rest sessions and handles:
/// - Activity threshold events (when user tries to access blocked apps)
/// - Session interval completion (when rest period ends)
/// - Automatic session completion and shield removal
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private static let storageKey = "RestSessions"
    private static let monitorName = DeviceActivityName("rest.session.monitor")
    private static let blockedSocialUsageEvent = DeviceActivityEvent.Name("rest.blocked.social.usage")
    private static let managedSettingsStoreName = "RestSessionStore"
    private static let appGroupIdentifier = "group.com.javidev.TimeToRest"

    override init() {
        super.init()
    }

    /// Called when a monitored event reaches its threshold
    /// This happens when the user tries to access blocked apps during rest
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        guard activity == Self.monitorName,
              event == Self.blockedSocialUsageEvent else {
            return
        }
        
        // Post notification about blocked app usage attempt
        postBlockedUsageNotification()
    }

    /// Called when the monitoring interval ends.
    /// We no longer trigger any automation from the extension.
    override func intervalDidEnd(for activity: DeviceActivityName) {
        guard activity == Self.monitorName else { return }
        // Intentionally left blank. The main app handles notifications.
    }

    // MARK: - Private Methods


    
    /// Posts a notification when user tries to access blocked apps
    private func postBlockedUsageNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Rest Mode Active"
        content.body = "You're trying to access a blocked app during your rest period."
        content.sound = .default
        content.categoryIdentifier = "REST_BLOCKED_ATTEMPT"

        let request = UNNotificationRequest(
            identifier: "blocked_attempt_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }
}

// MARK: - Lightweight DTO for decoding/encoding sessions inside the extension
// Mirrors RestSessionEntity's Codable layout without requiring the entity in this target.
private struct SessionDTO: Codable {
    let id: UUID
    let day: Date
    let startedAt: Date
    let didBreakRest: Bool
    let breakReason: String?
    let brokenAt: Date?
    var isCompleted: Bool
    let avoidedMinutes: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        day = try container.decode(Date.self, forKey: .day)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        didBreakRest = try container.decode(Bool.self, forKey: .didBreakRest)
        breakReason = try container.decodeIfPresent(String.self, forKey: .breakReason)
        brokenAt = try container.decodeIfPresent(Date.self, forKey: .brokenAt)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        avoidedMinutes = try container.decode(Int.self, forKey: .avoidedMinutes)
    }
}
