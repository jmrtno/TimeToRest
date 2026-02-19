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
        completeCurrentSessionFromExtension()
        removeShields()
    }

    // MARK: - Complete session directly via UserDefaults (no dependency on RestSessionRepository)

    private nonisolated func completeCurrentSessionFromExtension() {
        guard let userDefaults = UserDefaults(suiteName: RestSessionDeviceActivityIdentifiers.appGroupIdentifier) else { return }

        guard let data = userDefaults.data(forKey: Self.storageKey) else { return }

        let decoder = JSONDecoder()
        let encoder = JSONEncoder()

        guard var sessions = try? decoder.decode([SessionDTO].self, from: data) else { return }

        let now = Date()
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now

        let candidateIndex = sessions.lastIndex { session in
            calendar.isDate(session.day, inSameDayAs: now) || calendar.isDate(session.day, inSameDayAs: yesterday)
        }

        guard let index = candidateIndex else { return }

        var session = sessions[index]
        guard !session.didBreakRest, !session.isCompleted else { return }

        session.isCompleted = true
        sessions[index] = session

        guard let updatedData = try? encoder.encode(sessions) else { return }
        userDefaults.set(updatedData, forKey: Self.storageKey)
    }

    private nonisolated func removeShields() {
        let store = ManagedSettingsStore(
            named: .init(RestSessionDeviceActivityIdentifiers.managedSettingsStoreName)
        )
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
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
    let breakedAt: Date?
    var isCompleted: Bool
    let avoidedMinutes: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        day = try container.decode(Date.self, forKey: .day)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        didBreakRest = try container.decode(Bool.self, forKey: .didBreakRest)
        breakReason = try container.decodeIfPresent(String.self, forKey: .breakReason)
        breakedAt = try container.decodeIfPresent(Date.self, forKey: .breakedAt)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        avoidedMinutes = try container.decode(Int.self, forKey: .avoidedMinutes)
    }
}
