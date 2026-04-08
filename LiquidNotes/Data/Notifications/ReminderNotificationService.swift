import Foundation
import UserNotifications
import os

enum ReminderAction: String {
    case openNote = "OPEN_NOTE"
    case clearReminder = "CLEAR_REMINDER"
    case snooze = "SNOOZE"
}

@MainActor
final class ReminderNotificationService: NSObject {
    static let categoryIdentifier = "NOTE_REMINDER"
    private let logger = Logger(subsystem: "LiquidNotes", category: "ReminderNotificationService")

    func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
            return true
        }

        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            logger.error("Notification authorization failed: \(error.localizedDescription)")
            return false
        }
    }

    func registerCategories() {
        let actions: [UNNotificationAction] = [
            UNNotificationAction(identifier: ReminderAction.openNote.rawValue, title: "Open Note"),
            UNNotificationAction(identifier: ReminderAction.clearReminder.rawValue, title: "Clear Reminder"),
            UNNotificationAction(identifier: ReminderAction.snooze.rawValue, title: "Snooze 10m")
        ]

        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: actions,
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    func scheduleReminder(for note: Note) async {
        guard let reminderDate = note.reminderDate else {
            cancelReminder(for: note.id)
            return
        }

        guard await requestAuthorizationIfNeeded() else { return }

        let content = UNMutableNotificationContent()
        content.title = note.effectiveTitle
        content.body = note.effectivePreview
        content.sound = .default
        content.categoryIdentifier = Self.categoryIdentifier
        content.userInfo = ["noteID": note.id.uuidString]

        let seconds = max(1, reminderDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: identifier(for: note.id), content: content, trigger: trigger)

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            logger.error("Failed scheduling reminder for note \(note.id.uuidString): \(error.localizedDescription)")
        }
    }

    func cancelReminder(for noteID: UUID) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier(for: noteID)])
    }

    func identifier(for noteID: UUID) -> String {
        "note-reminder-\(noteID.uuidString)"
    }
}
