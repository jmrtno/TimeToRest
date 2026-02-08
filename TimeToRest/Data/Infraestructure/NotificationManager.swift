import Foundation
import UserNotifications

/// Protocolo de delegado para eventos de notificaciones
/// Permite que GeofenceService sepa cuando se recibe una notificación en primer plano
protocol NotificationManagerDelegate: AnyObject {
    func didReceiveNotificationInForeground(identifier: String) // Notificación recibida con app activa
}

/// Wrapper de UserNotifications que abstrae la complejidad del manejo de notificaciones
/// Responsabilidades:
/// - Gestionar permisos de notificaciones
/// - Programar notificaciones locales para reminders
/// - Manejar presentación de notificaciones en primer plano
/// Flujo: GeofenceService → NotificationManager → UNUserNotificationCenter → Sistema
final class NotificationManager: NSObject {
    /// Centro de notificaciones del sistema para toda la funcionalidad
    private let notificationCenter: UNUserNotificationCenter
    
    weak var delegate: NotificationManagerDelegate?
    
    /// Estado actual de autorización de notificaciones
    /// Se mantiene en caché para acceso rápido y consultas de estado
    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    
    var isAuthorized: Bool {
        authorizationStatus == .authorized
    }
    
    var isDenied: Bool {
        authorizationStatus == .denied
    }
    
    var isNotDetermined: Bool {
        authorizationStatus == .notDetermined
    }
    
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
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
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
    
    /// Programa una notificación inmediata para un reminder de salida
    /// Se usa cuando el usuario sale de una región geofence
    /// El identificador único permite cancelarla después si es necesario
    func scheduleExitNotification(for restTime: TimeToRestEntity) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Rest"
        content.body = "It's time to put down the phone and relax."
        content.sound = .default
        content.categoryIdentifier = "REST_TIME"
        
        let request = UNNotificationRequest(
            identifier: restTime.restIdentifier,
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { _ in }
    }
    
    /// Cancela una notificación específica (pendiente y entregada)
    /// Se usa cuando se deshabilita un reminder o se elimina una región
    func cancelNotification(for restTime: TimeToRestEntity) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [restTime.restIdentifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [restTime.restIdentifier])
    }
    
    func cancelNotification(identifier: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
        notificationCenter.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
    
    // MARK: - Debug Methods
    
    /// Programa notificación con retraso para pruebas de debugging
    /// Útil para simular eventos de geofence sin moverse físicamente
    func scheduleDelayedNotification(for restTime: TimeToRestEntity, delay: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "Did I Forget?"
        content.body = "It's time to put down the phone and relax."
        content.sound = .default
        content.categoryIdentifier = "REST_TIME"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "debug_\(restTime.restIdentifier)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { _ in }
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    /// Maneja notificaciones en primer plano (app activa)
    /// Fuerza presentación para mejor experiencia de usuario
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        delegate?.didReceiveNotificationInForeground(identifier: notification.request.identifier)
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Maneja interacción del usuario con notificación (tap, etc.)
    /// Extensible para navegación o acciones específicas
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
