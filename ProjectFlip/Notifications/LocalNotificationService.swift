import Foundation
import Observation
import OSLog
import UserNotifications

enum NotificationAuthorization: String { case unknown, notDetermined, denied, allowed }

@Observable @MainActor
final class LocalNotificationService {
    static let shared = LocalNotificationService()
    private(set) var authorization: NotificationAuthorization = .unknown
    private(set) var scheduledCount = 0
    private(set) var lastErrorKey: String?
    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "ProjectFlip", category: "Notifications")
    private var desired: [LocalNotificationSpec] = []
    private var revision: UInt64 = 0
    private var worker: Task<Void, Never>?

    func requestSync(state: GameSnapshot, definitions: [ItemDefinition], locale: Locale) {
        do { desired = try NotificationPlanner().makePlan(state: state, definitions: definitions, locale: locale, now: .now) }
        catch { fail(error); return }
        revision &+= 1
        if worker == nil {
            worker = Task {
                var applied: UInt64
                repeat {
                    applied = revision
                    let plan = desired
                    do { try await apply(plan) }
                    catch { fail(error) }
                } while applied != revision
                worker = nil
            }
        }
    }

    func requestAuthorization() async {
        do {
            let granted: Bool = try await withCheckedThrowingContinuation { continuation in
                center.requestAuthorization(options: [.alert, .sound]) { granted, error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume(returning: granted) }
                }
            }
            authorization = granted ? .allowed : .denied
            lastErrorKey = nil
        } catch { fail(error) }
    }

    private func status() async -> NotificationAuthorization {
        await withCheckedContinuation { continuation in
            center.getNotificationSettings { settings in
                let value: NotificationAuthorization
                switch settings.authorizationStatus {
                case .notDetermined: value = .notDetermined
                case .denied: value = .denied
                case .authorized, .provisional, .ephemeral: value = .allowed
                @unknown default: value = .unknown
                }
                continuation.resume(returning: value)
            }
        }
    }

    private func pendingIDs() async -> [String] {
        await withCheckedContinuation { continuation in
            center.getPendingNotificationRequests { requests in continuation.resume(returning: requests.map(\.identifier)) }
        }
    }

    private func deliveredIDs() async -> [String] {
        await withCheckedContinuation { continuation in
            center.getDeliveredNotifications { notifications in continuation.resume(returning: notifications.map { $0.request.identifier }) }
        }
    }

    private func apply(_ requested: [LocalNotificationSpec]) async throws {
        authorization = await status()
        let plan = authorization == .allowed ? requested : []
        let desiredIDs = Set(plan.map(\.id))
        let pending = await pendingIDs()
        center.removePendingNotificationRequests(withIdentifiers: pending.filter { $0.hasPrefix("event-") && !desiredIDs.contains($0) })
        let delivered = await deliveredIDs()
        center.removeDeliveredNotifications(withIdentifiers: delivered.filter { $0.hasPrefix("event-") && !desiredIDs.contains($0) })
        for spec in plan {
            let content = UNMutableNotificationContent()
            content.title = spec.title
            content.body = spec.body
            content.sound = .default
            content.categoryIdentifier = spec.category.rawValue
            content.userInfo = ["route": try spec.route.encoded(), "gameEventID": spec.id]
            let request = UNNotificationRequest(identifier: spec.id, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, spec.fireAt.timeIntervalSinceNow), repeats: false))
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                center.add(request) { error in
                    if let error { continuation.resume(throwing: error) }
                    else { continuation.resume() }
                }
            }
        }
        scheduledCount = plan.count
        lastErrorKey = nil
    }

    private func fail(_ error: any Error) {
        lastErrorKey = "notifications.error"
        #if DEBUG
        logger.error("Notification operation failed: \(String(describing: error), privacy: .public)")
        #endif
    }
}
