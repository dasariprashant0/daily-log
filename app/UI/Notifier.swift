// Notifier.swift - UserNotifications wrapper. Every call degrades silently: an ad-hoc-signed app may be denied or
// unable to register, and the in-window banner + menu bar icon remain the fallback signal.
import Foundation
import UserNotifications
import AppKit

final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    static let shared = Notifier()
    private weak var model: AppModel?
    private let id = "dailylog.reminder"       // one notification, replaced not stacked
    private var center: UNUserNotificationCenter? {
        Bundle.main.bundleIdentifier == nil || Bundle.main.bundlePath.hasSuffix(".app") == false ? nil : UNUserNotificationCenter.current()
    }

    func setup(model: AppModel) {
        self.model = model
        guard let c = center else { return }
        c.delegate = self
        let open = UNNotificationAction(identifier: "open", title: "Open", options: [.foreground])
        let snooze = UNNotificationAction(identifier: "snooze", title: "Snooze \(model.settings.snoozeMinutes) min", options: [])
        c.setNotificationCategories([UNNotificationCategory(identifier: "reminder", actions: [open, snooze], intentIdentifiers: [], options: [])])
    }

    func requestAuthorization(_ done: @escaping (Bool) -> Void = { _ in }) {
        guard let c = center else { done(false); return }
        c.requestAuthorization(options: [.alert]) { ok, _ in DispatchQueue.main.async { done(ok) } }
    }

    func refreshState(_ done: @escaping (NotifState) -> Void) {
        guard let c = center else { done(.unknown); return }
        c.getNotificationSettings { s in
            DispatchQueue.main.async {
                switch s.authorizationStatus {
                case .denied: done(.denied)
                case .authorized, .provisional: done(.allowed)
                default: done(.unknown)
                }
            }
        }
    }

    /// Content never includes log text, streak numbers or anything personal.
    func post(title: String, body: String, snoozeMinutes: Int) {
        guard let c = center else { return }
        let content = UNMutableNotificationContent()
        content.title = title; content.body = body; content.categoryIdentifier = "reminder"
        c.add(UNNotificationRequest(identifier: id, content: content, trigger: nil)) { _ in }
    }

    func cancelAll() {
        guard let c = center else { return }
        c.removePendingNotificationRequests(withIdentifiers: [id]); c.removeDeliveredNotifications(withIdentifiers: [id])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler done: @escaping (UNNotificationPresentationOptions) -> Void) { done([.banner]) }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler done: @escaping () -> Void) {
        let action = response.actionIdentifier
        DispatchQueue.main.async { [weak self] in
            if action == "snooze" { self?.model?.snooze() } else { self?.model?.showMainWindow(activate: true) }
            done()
        }
    }
}
