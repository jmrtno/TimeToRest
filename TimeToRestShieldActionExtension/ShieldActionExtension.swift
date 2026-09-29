import CoreFoundation
import Foundation
import ManagedSettings
import UserNotifications

final class ShieldActionExtension: ShieldActionDelegate {
    /// Must match the raw value of `RestSessionEntity.BreakReason.blockedSocialAppUsage`
    /// in the main app, otherwise the reason is silently dropped when decoding.
    private static let blockedSocialAppUsageBreakReason = "blockedSocialAppUsage"

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handle(action: action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handle(action: action, completionHandler: completionHandler)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        handle(action: action, completionHandler: completionHandler)
    }

    private func handle(
        action: ShieldAction,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            unlockAppsAndBreakRest()
            completionHandler(.none)
        case .secondaryButtonPressed:
            completionHandler(.close)
        case .firstSecondarySubmenuItemPressed:
            completionHandler(.defer)
        case .secondSecondarySubmenuItemPressed:
            completionHandler(.defer)
        case .thirdSecondarySubmenuItemPressed:
            completionHandler(.defer)
        @unknown default:
            completionHandler(.defer)
        }
    }

    private func unlockAppsAndBreakRest() {
        let settingsStore = ManagedSettingsStore(
            named: .init(RestSessionDeviceActivityIdentifiers.managedSettingsStoreName)
        )
        settingsStore.shield.applications = nil
        settingsStore.shield.applicationCategories = nil
        settingsStore.shield.webDomains = nil

        postRestBrokenNotification()

        // Notify the main app that rest was broken
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(
                RestSessionDeviceActivityIdentifiers.shieldUnlockRequestedDarwinNotification as CFString
            ),
            nil,
            nil,
            true
        )
        
        // Update session data to mark as broken
        markSessionAsBroken()
    }

    private func postRestBrokenNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Rest finished"
        content.body = "Your rest streak ended because you unlocked a blocked app."
        content.sound = .default
        content.categoryIdentifier = "REST_BROKEN_BLOCKED_APP"

        let request = UNNotificationRequest(
            identifier: "rest_broken_unlock_\(UUID().uuidString)",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )

        UNUserNotificationCenter.current().add(request) { _ in }
    }
    
    /// Marks the current session as broken in UserDefaults
    private func markSessionAsBroken() {
        guard let userDefaults = UserDefaults(
            suiteName: RestSessionDeviceActivityIdentifiers.appGroupIdentifier
        ) else { return }

        let storageKey = RestSessionDeviceActivityIdentifiers.sessionStorageKey
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        
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
        
        session.didBreakRest = true
        session.breakReason = Self.blockedSocialAppUsageBreakReason
        session.brokenAt = Date()
        sessions[index] = session
        
        guard let updatedData = try? encoder.encode(sessions) else { return }
        userDefaults.set(updatedData, forKey: storageKey)
    }
}

// MARK: - Session DTO for Shield Extension
/// Mirrors every field of the app's `RestSessionDTO`. The extension rewrites the whole
/// stored array, so any field missing here would be dropped for all sessions.
private struct SessionDTO: Codable {
    let id: UUID
    let day: Date
    let startedAt: Date
    var didBreakRest: Bool
    var breakReason: String?
    var brokenAt: Date?
    var isCompleted: Bool
    let avoidedMinutes: Int
    let startTime: DateComponents
    let endTime: DateComponents
    let createdAt: Date

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
        startTime = try container.decodeIfPresent(DateComponents.self, forKey: .startTime)
        ?? DateComponents(hour: 23, minute: 30)
        endTime = try container.decodeIfPresent(DateComponents.self, forKey: .endTime)
        ?? DateComponents(hour: 7, minute: 0)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? day
    }
}
