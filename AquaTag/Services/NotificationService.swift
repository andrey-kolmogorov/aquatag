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
    
    // MARK: - Schedule Watering Reminder
    
    func scheduleWateringReminder(
        for plant: Plant,
        preferredTime: Date
    ) async throws {
        guard let nextWateringDate = plant.nextWateringDate else {
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
        
        let content = UNMutableNotificationContent()
        content.title = "\(plant.emoji) Time to water \(plant.name)!"
        
        if let daysSince = plant.daysSinceLastWatered {
            content.body = "Last watered \(daysSince) days ago"
        } else {
            content.body = "It's time to give your plant some water"
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
