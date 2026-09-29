import Foundation
import DeviceActivity

/// Shared identifiers used by the app and the DeviceActivity monitor extension.
enum RestSessionDeviceActivityIdentifiers {
    nonisolated static let managedSettingsStoreName = "RestSessionStore"

    nonisolated static let blockedSocialUsageDarwinNotification = "com.timetorest.rest.blocked-social-usage"
    nonisolated static let shieldUnlockRequestedDarwinNotification = "com.timetorest.rest.shield-unlock-requested"

    nonisolated static let appGroupIdentifier = "group.com.javidev.TimeToRest"

    nonisolated static let sessionStorageKey = "RestSessions"

    private nonisolated static let monitorRawValue = "rest.session.monitor"
    private nonisolated static let blockedSocialUsageEventRawValue = "rest.blocked.social.usage"

    /// `DeviceActivityName` is not `Sendable`, so it is built on demand rather than
    /// stored in a static property, which would be shared mutable state.
    nonisolated static var monitorName: DeviceActivityName {
        DeviceActivityName(monitorRawValue)
    }

    /// `DeviceActivityEvent.Name` is not `Sendable`, so it is built on demand rather
    /// than stored in a static property, which would be shared mutable state.
    nonisolated static var blockedSocialUsageEvent: DeviceActivityEvent.Name {
        DeviceActivityEvent.Name(blockedSocialUsageEventRawValue)
    }
}
