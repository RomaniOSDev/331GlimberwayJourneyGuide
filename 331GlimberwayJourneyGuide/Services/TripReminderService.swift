import Foundation
import UserNotifications

enum TripReminderService {
    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func syncReminder(for destination: Destination) {
        let center = UNUserNotificationCenter.current()
        let id = notificationId(for: destination.id)
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard destination.reminderEnabled,
              let plannedDate = destination.plannedDate,
              !destination.isVisited else { return }

        guard let fireDate = Calendar.current.date(
            byAdding: .day,
            value: -max(destination.reminderDaysBefore, 1),
            to: Calendar.current.startOfDay(for: plannedDate)
        ) else { return }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        components.hour = 10
        components.minute = 0

        let triggerDate = Calendar.current.date(from: components) ?? fireDate
        guard triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Trip coming up"
        content.body = "\(destination.displayTitle) is in \(destination.reminderDaysBefore) day(s). Check your packing and departure list."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request, withCompletionHandler: nil)
    }

    static func removeReminder(for destinationId: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [notificationId(for: destinationId)])
    }

    static func rescheduleAll(for destinations: [Destination]) {
        for destination in destinations {
            syncReminder(for: destination)
        }
    }

    private static func notificationId(for destinationId: UUID) -> String {
        "glimberway.tripReminder.\(destinationId.uuidString)"
    }
}
