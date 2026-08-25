//
//  AppSettings.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation
import SwiftData
import UIKit

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
    
    /// Whether Home Assistant sync can run.
    ///
    /// Deliberately does **not** require `deviceName`: that field only labels
    /// *who* watered, and gating sync on it meant a blank name silently
    /// disabled every HA call in the app. `resolvedDeviceName` covers the
    /// attribution side with a sensible fallback instead.
    var isHAConfigured: Bool {
        !nabucasaURL.isEmpty
    }

    /// Display name for watering attribution, falling back to the device's own
    /// name when the user hasn't set one.
    @MainActor
    var resolvedDeviceName: String {
        let trimmed = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? UIDevice.current.name : trimmed
    }

    /// Whether the user has finished the full setup, including attribution.
    /// Use for onboarding prompts — not as a gate on sync.
    var isFullyConfigured: Bool {
        isHAConfigured && !deviceName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
