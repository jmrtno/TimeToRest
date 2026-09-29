import Foundation
import DeviceActivity
import ManagedSettings

/// Principal class of the Device Activity Monitor extension.
/// Monitoring remains active during rest, but the break/unlock action is handled by Shield Action extension.
final class RestSessionDeviceActivityMonitor: DeviceActivityMonitor {

    nonisolated override init() {
        super.init()
    }

    nonisolated override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        guard activity == RestSessionDeviceActivityIdentifiers.monitorName,
              event == RestSessionDeviceActivityIdentifiers.blockedSocialUsageEvent else {
            return
        }
    }

    nonisolated override func intervalDidEnd(for activity: DeviceActivityName) {
        guard activity == RestSessionDeviceActivityIdentifiers.monitorName else { return }
        // Only post notification, no automatic completion or shield removal
    }
}
