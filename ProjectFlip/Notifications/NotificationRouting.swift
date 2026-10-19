import Observation
import OSLog
import UIKit
import UserNotifications

@Observable @MainActor
final class NotificationInbox {
    static let shared = NotificationInbox()
    var pending: GameRoute?
    func receive(_ value: String) {
        do { pending = try GameRoute.decode(value) }
        catch {
            Logger(subsystem: "ProjectFlip", category: "Routing").error("Invalid notification route: \(String(describing: error), privacy: .public)")
            pending = .unavailable
        }
    }
}

@MainActor
final class ProjectFlipAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.setNotificationCategories(Set(LocalNotificationCategory.allCases.map {
            UNNotificationCategory(identifier: $0.rawValue, actions: [], intentIdentifiers: [])
        }))
        return true
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void) {
        Task { @MainActor in completionHandler([]) }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping @Sendable () -> Void) {
        let isDefaultAction = response.actionIdentifier == UNNotificationDefaultActionIdentifier
        let route = response.notification.request.content.userInfo["route"] as? String
        // UIKit performs state restoration from this completion. The async ObjC bridge can
        // invoke it on a cooperative worker; explicitly finish once on the main actor instead.
        Task { @MainActor in
            if isDefaultAction, let route { NotificationInbox.shared.receive(route) }
            completionHandler()
        }
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        Task { @MainActor in NotificationInbox.shared.pending = .settings }
    }
}
