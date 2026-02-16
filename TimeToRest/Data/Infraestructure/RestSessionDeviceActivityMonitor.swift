import Foundation
import DeviceActivity

/// Add this file to a Device Activity Monitor extension target in Xcode.
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
        // Keep monitoring active while the app remains shielded.
        // Rest break is now explicitly controlled by Shield Action ("Unlock").
    }
}
