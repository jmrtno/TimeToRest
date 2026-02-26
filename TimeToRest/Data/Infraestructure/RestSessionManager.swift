import Foundation
import Combine
import CoreFoundation
import FamilyControls
import DeviceActivity
import ManagedSettings

@MainActor
final class RestSessionManager: ObservableObject {

    enum BreakReason: Equatable {
        case manualCancellation
        case blockedSocialAppUsage
    }

    enum State: Equatable {
        case idle
        case active
        case broken(BreakReason)
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var blockedSelection: FamilyActivitySelection

    private let breakRestUseCase: BreakRestUseCase
    private let fetchCurrentSessionUseCase: FetchCurrentSessionUseCase

    private let deviceActivityCenter = DeviceActivityCenter()
    private let settingsStore = ManagedSettingsStore(
        named: .init(RestSessionDeviceActivityIdentifiers.managedSettingsStoreName)
    )
    private let userDefaults: UserDefaults
    private static let blockedSelectionStorageKey = "RestSessionManager.BlockedSelection"

    private var monitoredApplicationTokens: Set<ApplicationToken> = []
    private var isShieldObserverRegistered = false

    init(
        breakRestUseCase: BreakRestUseCase,
        fetchCurrentSessionUseCase: FetchCurrentSessionUseCase,
        userDefaults: UserDefaults = UserDefaults(suiteName: RestSessionDeviceActivityIdentifiers.appGroupIdentifier) ?? .standard
    ) {
        self.breakRestUseCase = breakRestUseCase
        self.fetchCurrentSessionUseCase = fetchCurrentSessionUseCase
        self.userDefaults = userDefaults
        self.blockedSelection = Self.loadBlockedSelection(
            userDefaults: userDefaults,
            key: Self.blockedSelectionStorageKey
        )
        registerShieldUnlockObserverIfNeeded()
    }

    deinit {
        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterRemoveObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            nil,
            nil
        )
    }

    func prepareAuthorization() {
        Task {
            _ = try? await requestAuthorizationIfNeeded()
        }
    }

    func startMonitoringIfNeeded(configuration: TimeToRestEntity, now: Date = Date()) {
        guard isWithinNightWindow(configuration: configuration, now: now) else {
            return
        }

        Task {
            guard try await requestAuthorizationIfNeeded() else { return }
            guard !isSelectionEmpty(blockedSelection) else { return }

            let tokens = blockedSelection.applicationTokens
            if state == .active, monitoredApplicationTokens == tokens { return }

            monitoredApplicationTokens = tokens
            applyShields(selection: blockedSelection)
            startDeviceActivityMonitoring(
                configuration: configuration,
                now: now,
                selection: blockedSelection
            )
            state = .active
        }
    }

    func endMonitoringAfterSuccessfulRest() {
        // Automatic monitoring termination removed
        // User must explicitly terminate rest session
        // This method is no longer used
    }

    func cancelRestManually() {
        breakCurrentSession(reason: .manualCancellation)
    }
    
    func updateBlockedSelection(_ selection: FamilyActivitySelection) {
        blockedSelection = selection
        persistBlockedSelection(selection)
    }

    func stopMonitoringAndUnlockApps() {
        deviceActivityCenter.stopMonitoring([RestSessionDeviceActivityIdentifiers.monitorName])
        settingsStore.shield.applications = nil
        settingsStore.shield.applicationCategories = nil
        settingsStore.shield.webDomains = nil
        monitoredApplicationTokens.removeAll()
    }

    var currentBlockedSelection: FamilyActivitySelection {
        blockedSelection
    }

    private func requestAuthorizationIfNeeded() async throws -> Bool {
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved:
            return true
        case .notDetermined:
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            return AuthorizationCenter.shared.authorizationStatus == .approved
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func isSelectionEmpty(_ selection: FamilyActivitySelection) -> Bool {
        selection.applicationTokens.isEmpty &&
        selection.categoryTokens.isEmpty &&
        selection.webDomainTokens.isEmpty
    }

    private func applyShields(selection: FamilyActivitySelection) {
        settingsStore.shield.applications = selection.applicationTokens
        settingsStore.shield.applicationCategories = .specific(selection.categoryTokens)
        settingsStore.shield.webDomains = selection.webDomainTokens
    }

    private func startDeviceActivityMonitoring(
        configuration: TimeToRestEntity,
        now: Date,
        selection: FamilyActivitySelection
    ) {
        let schedule = makeSchedule(configuration: configuration, now: now)
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            webDomains: selection.webDomainTokens,
            threshold: DateComponents(second: 1)
        )

        do {
            try deviceActivityCenter.startMonitoring(
                RestSessionDeviceActivityIdentifiers.monitorName,
                during: schedule,
                events: [RestSessionDeviceActivityIdentifiers.blockedSocialUsageEvent: event]
            )
        } catch {
            // Best effort: the shield is still active even if monitoring setup fails.
        }
    }

    private func makeSchedule(configuration: TimeToRestEntity, now: Date) -> DeviceActivitySchedule {
        let calendar = Calendar.current
        let startOfMonitoring = now

        let endHour = configuration.endTime.hour ?? 7
        let endMinute = configuration.endTime.minute ?? 0

        let startOfDay = calendar.startOfDay(for: now)
        let todayEnd = calendar.date(
            byAdding: DateComponents(hour: endHour, minute: endMinute),
            to: startOfDay
        ) ?? now

        let endDate: Date
        if todayEnd > now {
            endDate = todayEnd
        } else {
            endDate = calendar.date(byAdding: .day, value: 1, to: todayEnd) ?? todayEnd
        }

        let startComponents = calendar.dateComponents([.hour, .minute, .second], from: startOfMonitoring)
        let endComponents = calendar.dateComponents([.hour, .minute, .second], from: endDate)

        return DeviceActivitySchedule(
            intervalStart: startComponents,
            intervalEnd: endComponents,
            repeats: false,
            warningTime: nil
        )
    }
    
    private func isWithinNightWindow(configuration: TimeToRestEntity, now: Date) -> Bool {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        let currentTotal = currentHour * 60 + currentMinute

        let startHour = configuration.startTime.hour ?? 23
        let startMinute = configuration.startTime.minute ?? 30
        let startTotal = startHour * 60 + startMinute

        let endHour = configuration.endTime.hour ?? 7
        let endMinute = configuration.endTime.minute ?? 0
        let endTotal = endHour * 60 + endMinute

        if startTotal > endTotal {
            return currentTotal >= startTotal || currentTotal < endTotal
        } else {
            return currentTotal >= startTotal && currentTotal < endTotal
        }
    }

    private func registerShieldUnlockObserverIfNeeded() {
        guard !isShieldObserverRegistered else { return }
        isShieldObserverRegistered = true

        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            observer,
            { _, observer, _, _, _ in
                guard let observer else { return }
                let manager = Unmanaged<RestSessionManager>.fromOpaque(observer).takeUnretainedValue()
                Task { @MainActor in
                    manager.handleShieldUnlockRequested()
                }
            },
            RestSessionDeviceActivityIdentifiers.shieldUnlockRequestedDarwinNotification as CFString,
            nil,
            .deliverImmediately
        )
    }

    private func handleShieldUnlockRequested() {
        breakCurrentSession(reason: .blockedSocialAppUsage)
    }

    private func breakCurrentSession(reason: BreakReason) {
        guard let session = fetchCurrentSessionUseCase.execute(), !session.didBreakRest else {
            stopMonitoringAndUnlockApps()
            return
        }

        let persistedBreakReason: RestSessionEntity.BreakReason
        switch reason {
        case .manualCancellation:
            persistedBreakReason = .manualCancellation
        case .blockedSocialAppUsage:
            persistedBreakReason = .blockedSocialAppUsage
        }

        Task {
            _ = await breakRestUseCase.execute(
                session: session,
                breakReason: persistedBreakReason
            )
            await MainActor.run {
                stopMonitoringAndUnlockApps()
                state = .broken(reason)
            }
        }
    }
    
    private func persistBlockedSelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try PropertyListEncoder().encode(selection)
            userDefaults.set(data, forKey: Self.blockedSelectionStorageKey)
        } catch {
            userDefaults.removeObject(forKey: Self.blockedSelectionStorageKey)
        }
    }

    private static func loadBlockedSelection(
        userDefaults: UserDefaults,
        key: String
    ) -> FamilyActivitySelection {
        guard let data = userDefaults.data(forKey: key) else {
            return FamilyActivitySelection()
        }
        do {
            return try PropertyListDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            return FamilyActivitySelection()
        }
    }
}
