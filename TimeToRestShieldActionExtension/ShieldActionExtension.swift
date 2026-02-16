import CoreFoundation
import ManagedSettings
import UserNotifications

final class ShieldActionExtension: ShieldActionDelegate {
    private static let managedSettingsStoreName = "RestSessionStore"
    private static let shieldUnlockRequestedDarwinNotification = "com.timetorest.rest.shield-unlock-requested"

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
        @unknown default:
            completionHandler(.defer)
        }
    }

    private func unlockAppsAndBreakRest() {
        let settingsStore = ManagedSettingsStore(named: .init(Self.managedSettingsStoreName))
        settingsStore.shield.applications = nil
        settingsStore.shield.applicationCategories = nil
        settingsStore.shield.webDomains = nil

        postRestBrokenNotification()

        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(Self.shieldUnlockRequestedDarwinNotification as CFString),
            nil,
            nil,
            true
        )
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
}
