import Foundation
import UserNotifications

struct ReminderPayload {
    let taskID: UUID
    let title: String
    let notes: String
    let reminderDate: Date?
    let isCompleted: Bool

    var identifier: String {
        "calrem.task.\(taskID.uuidString)"
    }
}

final class NotificationScheduler {
    static let shared = NotificationScheduler()

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func sync(_ payload: ReminderPayload) async {
        await cancel(taskID: payload.taskID)

        guard
            !payload.isCompleted,
            let reminderDate = payload.reminderDate,
            reminderDate > .now
        else {
            return
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else { return }

            let content = UNMutableNotificationContent()
            content.title = payload.title
            content.body = payload.notes.isEmpty ? "CalRem reminder" : payload.notes
            content.sound = .default

            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            )
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: payload.identifier,
                content: content,
                trigger: trigger
            )

            try await center.add(request)
        } catch {
            // Permission and scheduling failures are non-fatal for local-first MVP.
        }
    }

    func cancel(taskID: UUID) async {
        let identifier = "calrem.task.\(taskID.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
    }
}
