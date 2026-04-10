//
//  AppSettings.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation
import SwiftData

@Model
class AppSettings {
    var nabucasaURL: String
    var deviceName: String
    var notificationsEnabled: Bool
    var defaultWateringIntervalDays: Int
    var notificationTime: Date  // Time of day for notifications
    
    init(
        nabucasaURL: String = "",
        deviceName: String = "",
        notificationsEnabled: Bool = true,
        defaultWateringIntervalDays: Int = 7,
        notificationTime: Date = Calendar.current.date(
            from: DateComponents(hour: 8, minute: 0)
        ) ?? Date()
    ) {
        self.nabucasaURL = nabucasaURL
        self.deviceName = deviceName
        self.notificationsEnabled = notificationsEnabled
        self.defaultWateringIntervalDays = defaultWateringIntervalDays
        self.notificationTime = notificationTime
    }
    
    var isConfigured: Bool {
        !nabucasaURL.isEmpty && !deviceName.isEmpty
    }
}
