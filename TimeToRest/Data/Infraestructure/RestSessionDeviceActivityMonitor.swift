import Foundation
import DeviceActivity
import ManagedSettings

/// Add this file to a Device Activity Monitor extension target in Xcode.
/// Monitoring remains active during rest, but the break/unlock action is handled by Shield Action extension.
final class RestSessionDeviceActivityMonitor: DeviceActivityMonitor {

    private static let storageKey = "RestSessions"

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
