import Foundation
import CoreFoundation
import DeviceActivity
import ManagedSettings
import UserNotifications

/// Add this file to a Device Activity Monitor extension target in Xcode.
/// The extension posts a Darwin notification consumed by `RestSessionManager`.
final class RestSessionDeviceActivityMonitor: DeviceActivityMonitor {
    nonisolated override init() {
        super.init()
    }

    nonisolated override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        guard activity == RestSessionDeviceActivityIdentifiers.monitorName,
              event == RestSessionDeviceActivityIdentifiers.blockedSocialUsageEvent else {
            return
        }

        let settingsStore = ManagedSettingsStore(
            named: .init(RestSessionDeviceActivityIdentifiers.managedSettingsStoreName)
        )
        settingsStore.shield.applications = nil
        settingsStore.shield.applicationCategories = nil
        settingsStore.shield.webDomains = nil

        let content = UNMutableNotificationContent()
        content.title = "Rest finished"
        content.body = "Your rest streak ended because a blocked app was used."
        content.sound = .default
        content.categoryIdentifier = "REST_BROKEN_BLOCKED_APP"

        let request = UNNotificationRequest(
            identifier: "rest_broken_blocked_app_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        UNUserNotificationCenter.current().add(request) { _ in }

        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(RestSessionDeviceActivityIdentifiers.blockedSocialUsageDarwinNotification as CFString),
            nil,
            nil,
            true
        )
    }
}
