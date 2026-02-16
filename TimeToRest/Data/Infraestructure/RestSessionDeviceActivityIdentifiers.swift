import Foundation
import DeviceActivity

/// Shared identifiers used by the app and the DeviceActivity monitor extension.
enum RestSessionDeviceActivityIdentifiers {
    nonisolated static let monitorName = DeviceActivityName("rest.session.monitor")
    nonisolated static let blockedSocialUsageEvent = DeviceActivityEvent.Name("rest.blocked.social.usage")
    nonisolated static let managedSettingsStoreName = "RestSessionStore"

    nonisolated static let blockedSocialUsageDarwinNotification = "com.timetorest.rest.blocked-social-usage"
    nonisolated static let shieldUnlockRequestedDarwinNotification = "com.timetorest.rest.shield-unlock-requested"
}
