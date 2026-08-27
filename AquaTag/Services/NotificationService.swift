//
//  NotificationService.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Request Authorization
    
    func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        return try await center.requestAuthorization(options: [.alert, .sound, .badge])
    }
    
    // MARK: - Check Authorization Status
    
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    /// Returns whether we may display notifications, prompting once if the
    /// user has not been asked yet.
    ///
    /// Requesting here rather than at launch keeps the prompt in context: it
    /// appears the first time a plant is watered, which is the first moment a
    /// reminder means anything.
    func ensureAuthorized() async -> Bool {
        switch await checkAuthorizationStatus() {
        case .notDetermined:
            return (try? await requestAuthorization()) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    // MARK: - Schedule Watering Reminder
    
    func scheduleWateringReminder(
        for plant: Plant,
        preferredTime: Date
    ) async throws {
        guard let nextWateringDate = plant.nextWateringDate else {
            return
        }

        // Ask for permission the first time there is actually something to
        // show. Previously this was only requested when the user toggled
        // "Watering reminders" from off to on — but that toggle defaults to
        // on, so anyone who never touched it was never prompted, and iOS
        // silently accepted every scheduled reminder without displaying one.
        guard await ensureAuthorized() else {
            return
        }
        
        // Cancel any existing notification for this plant
        await cancelWateringReminder(for: plant)
        
        // Get hour and minute from preferred time
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: preferredTime)
        
        // Create date components for the notification
        var dateComponents = calendar.dateComponents(
            [.year, .month, .day],
            from: nextWateringDate
        )
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute

        // An overdue plant's next-watering date is already behind us, and a
        // non-repeating calendar trigger pinned to a past moment is accepted
        // by iOS but never delivered. Roll forward to the next occurrence of
        // the preferred time so overdue plants are still reminded — otherwise
        // the plants that most need watering are exactly the ones that go
        // silent. Only reachable from the reschedule paths; watering always
        // produces a future date.
        if let intended = calendar.date(from: dateComponents), intended <= Date() {
            guard let nextOccurrence = calendar.nextDate(
                after: Date(),
                matching: DateComponents(
                    hour: timeComponents.hour,
                    minute: timeComponents.minute
                ),
                matchingPolicy: .nextTime
            ) else {
                return
            }
            dateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: nextOccurrence
            )
        }
        
        let content = UNMutableNotificationContent()
        content.title = String(format: String(localized: "notification.title"), plant.emoji, plant.name)

        if let daysSince = plant.daysSinceLastWatered {
            // Plural rules live in Localizable.stringsdict, which only resolves
            // through localizedStringWithFormat + NSLocalizedString — the same
            // pairing L10n.Status.overdue uses.
            content.body = String.localizedStringWithFormat(
                NSLocalizedString("notification.body.days.ago", comment: "Watering reminder body, days since last watered"),
                daysSince
            )
        } else {
            content.body = String(localized: "notification.body.default")
        }
        
        content.sound = .default
        content.categoryIdentifier = "WATERING_REMINDER"
        content.userInfo = ["plantID": plant.id]
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: dateComponents,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "watering_\(plant.id)",
            content: content,
            trigger: trigger
        )
        
        try await UNUserNotificationCenter.current().add(request)
    }
    
    /// Re-schedules every plant's reminder.
    ///
    /// Needed because a pending `UNCalendarNotificationTrigger` is a fixed
    /// point in time: changing a plant's interval or the preferred reminder
    /// time does not move an already-scheduled notification. Without this, the
    /// only thing that ever refreshed a reminder was watering the plant again.
    func rescheduleAll(plants: [Plant], preferredTime: Date) async {
        for plant in plants {
            try? await scheduleWateringReminder(for: plant, preferredTime: preferredTime)
        }
    }

    // MARK: - Cancel Watering Reminder
    
    func cancelWateringReminder(for plant: Plant) async {
        let identifier = "watering_\(plant.id)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [identifier]
        )
    }
    
    // MARK: - Cancel All Reminders
    
    func cancelAllReminders() async {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    // MARK: - Setup Notification Categories
    
    func setupNotificationCategories() {
        let markWateredAction = UNNotificationAction(
            identifier: "MARK_WATERED",
            title: "Mark as Watered",
            options: [.foreground]
        )
        
        let wateringCategory = UNNotificationCategory(
            identifier: "WATERING_REMINDER",
            actions: [markWateredAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([wateringCategory])
    }
}
