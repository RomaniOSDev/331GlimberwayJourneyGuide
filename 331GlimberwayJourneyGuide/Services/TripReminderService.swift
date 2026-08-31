import Foundation
import UserNotifications

enum TripReminderService {
    static func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    static func rescheduleAll(for destinations: [Destination]) {
        for destination in destinations {
            syncAll(for: destination)
        }
    }

    static func syncAll(for destination: Destination) {
        removeAll(for: destination.id)
        guard !destination.isVisited else { return }

        guard destination.reminderEnabled else { return }
        requestAuthorizationIfNeeded()
        scheduleMorningLead(for: destination)

        guard let departure = destination.plannedDate else { return }
        for task in destination.timelineTasks where task.notify && !task.isDone {
            scheduleTimeline(task, departure: departure, destination: destination)
        }
    }

    static func removeAll(for destinationId: UUID) {
        let center = UNUserNotificationCenter.current()
        var ids = [morningId(for: destinationId)]
        ids.append(contentsOf: TimelinePhase.allCases.map { timelineId(destinationId: destinationId, phase: $0) })
        center.getPendingNotificationRequests { requests in
            let prefix = "leave.\(destinationId.uuidString)"
            let extras = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            center.removePendingNotificationRequests(withIdentifiers: Array(Set(ids + extras)))
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    static func removeReminder(for destinationId: UUID) {
        removeAll(for: destinationId)
    }

    static func syncReminder(for destination: Destination) {
        syncAll(for: destination)
    }

    private static func scheduleMorningLead(for destination: Destination) {
        guard let plannedDate = destination.plannedDate else { return }
        guard let fireDate = Calendar.current.date(
            byAdding: .day,
            value: -max(destination.reminderDaysBefore, 1),
            to: Calendar.current.startOfDay(for: plannedDate)
        ) else { return }

        var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
        components.hour = 10
        components.minute = 0
        guard let triggerDate = Calendar.current.date(from: components), triggerDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Leave desk"
        content.body = "\(destination.displayTitle) is in \(destination.reminderDaysBefore) day(s). Run the house loop and weigh the bag."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: morningId(for: destination.id),
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    private static func scheduleTimeline(_ task: TimelineTask, departure: Date, destination: Destination) {
        let fire = task.fireDate(from: departure)
        guard fire > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(task.phase.title) · \(destination.displayTitle)"
        content.body = task.title
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fire
        )
        let request = UNNotificationRequest(
            identifier: "leave.\(destination.id.uuidString).task.\(task.id.uuidString)",
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    private static func morningId(for destinationId: UUID) -> String {
        "leave.\(destinationId.uuidString).morning"
    }

    private static func timelineId(destinationId: UUID, phase: TimelinePhase) -> String {
        "leave.\(destinationId.uuidString).phase.\(phase.rawValue)"
    }
}
