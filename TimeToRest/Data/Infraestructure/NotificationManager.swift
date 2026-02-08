import Foundation
import UserNotifications

/// Wrapper de UserNotifications que abstrae la complejidad del manejo de notificaciones
/// Responsabilidades:
/// - Gestionar permisos de notificaciones
/// - Programar notificaciones locales para reminders
/// - Manejar presentación de notificaciones en primer plano
final class NotificationManager: NSObject {
    /// Centro de notificaciones del sistema para toda la funcionalidad
    private nonisolated let notificationCenter: UNUserNotificationCenter
    
    /// Estado actual de autorización de notificaciones
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    /// Configura UNUserNotificationCenter con el delegado para manejar eventos
    /// Actualiza el estado de autorización al iniciar para tener datos consistentes
    override init() {
        self.notificationCenter = UNUserNotificationCenter.current()
        super.init()
        notificationCenter.delegate = self
        refreshAuthorizationStatus()
    }
    
    /// Solicita permiso de notificaciones con opciones completas
    /// - alert: muestra el banner de notificación
    /// - sound: reproduce sonido al llegar
    /// - badge: muestra número en ícono de app
    func requestAuthorization(completion: @escaping @Sendable (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.refreshAuthorizationStatus()
                completion(granted)
            }
        }
    }
    
    func refreshAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    // MARK: - Rest Time Notifications

    /// Schedules the nightly rest reminder at the configured start time.
    /// Fires daily at the configured hour.
    func scheduleRestReminder(for restTime: TimeToRestEntity) {
        cancelAllRestNotifications()

        guard let hour = restTime.startTime.hour,
              let minute = restTime.startTime.minute else { return }

        // Main notification at start time
        let content = UNMutableNotificationContent()
        content.title = "🌙 Time to Rest"
        content.body = "Remember the commitment you made."
        content.sound = .default
        content.categoryIdentifier = "REST_TIME"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "rest_start_\(restTime.restIdentifier)",
            content: content,
            trigger: trigger
        )
        notificationCenter.add(request) { _ in }

        // Pre-reminder 10 minutes before
        let preContent = UNMutableNotificationContent()
        preContent.title = "⏰ Almost Time"
        preContent.body = "Last chance to put down the phone."
        preContent.sound = .default
        preContent.categoryIdentifier = "REST_PRE_REMINDER"

        var preComponents = DateComponents()
        var preMinute = minute - 10
        var preHour = hour
        if preMinute < 0 {
            preMinute += 60
            preHour -= 1
            if preHour < 0 { preHour += 24 }
        }
        preComponents.hour = preHour
        preComponents.minute = preMinute

        let preTrigger = UNCalendarNotificationTrigger(dateMatching: preComponents, repeats: true)
        let preRequest = UNNotificationRequest(
            identifier: "rest_pre_\(restTime.restIdentifier)",
            content: preContent,
            trigger: preTrigger
        )
        notificationCenter.add(preRequest) { _ in }
    }

    /// Schedules strict mode notifications with more direct messaging.
    func scheduleStrictReminder(for restTime: TimeToRestEntity) {
        cancelAllRestNotifications()

        guard let hour = restTime.startTime.hour,
              let minute = restTime.startTime.minute else { return }

        let content = UNMutableNotificationContent()
        content.title = "🌙 Time to Rest"
        content.body = "This is exactly what you wanted to avoid."
        content.sound = .default
        content.categoryIdentifier = "REST_TIME"

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "rest_start_\(restTime.restIdentifier)",
            content: content,
            trigger: trigger
        )
        notificationCenter.add(request) { _ in }
    }

    /// Cancels all rest-related notifications.
    func cancelAllRestNotifications() {
        notificationCenter.getPendingNotificationRequests { [weak self] requests in
            let ids = requests
                .filter { $0.identifier.hasPrefix("rest_") }
                .map { $0.identifier }
            self?.notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
        }
        notificationCenter.removeAllDeliveredNotifications()
    }

}

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Maneja notificaciones en primer plano (app activa)
    /// Fuerza presentación para mejor experiencia de usuario
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Maneja interacción del usuario con notificación (tap, etc.)
    /// Extensible para navegación o acciones específicas
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
