//
//  SettingsViewModel.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation
import SwiftData

@MainActor
@Observable
class SettingsViewModel {
    private let modelContext: ModelContext
    
    var nabucasaURL = ""
    var haToken = ""
    var deviceName = ""
    var notificationsEnabled = true
    var defaultWateringIntervalDays = 7
    var notificationTime = Date()
    
    var isTesting = false
    var testResult: TestResult?
    var showingTokenInfo = false
    
    enum TestResult {
        case success
        case failure(String)
    }
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSettings()
    }
    
    // MARK: - Load Settings
    
    func loadSettings() {
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let settings = try modelContext.fetch(descriptor)
            
            if let existing = settings.first {
                nabucasaURL = existing.nabucasaURL
                deviceName = existing.deviceName
                notificationsEnabled = existing.notificationsEnabled
                defaultWateringIntervalDays = existing.defaultWateringIntervalDays
                notificationTime = existing.notificationTime
            } else {
                // Create default settings
                let newSettings = AppSettings()
                modelContext.insert(newSettings)
                try? modelContext.save()
            }
            
            // Load token from keychain
            haToken = (try? KeychainService.getHAToken()) ?? ""
            
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
    
    // MARK: - Save Settings
    
    func saveSettings() {
        let descriptor = FetchDescriptor<AppSettings>()
        
        do {
            let settings = try modelContext.fetch(descriptor)
            let settingsObject: AppSettings
            
            if let existing = settings.first {
                settingsObject = existing
            } else {
                settingsObject = AppSettings()
                modelContext.insert(settingsObject)
            }
            
            settingsObject.nabucasaURL = nabucasaURL.trimmingCharacters(in: .whitespacesAndNewlines)
            settingsObject.deviceName = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
            settingsObject.notificationsEnabled = notificationsEnabled
            settingsObject.defaultWateringIntervalDays = defaultWateringIntervalDays
            settingsObject.notificationTime = notificationTime
            
            try modelContext.save()
            
            // Save token to keychain
            if !haToken.isEmpty {
                try? KeychainService.saveHAToken(haToken)
            }
            
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    // MARK: - Test Connection
    
    /// Validates the credentials **as stored**, not as typed.
    ///
    /// This used to build an HAService straight from the in-memory fields,
    /// which made it possible for the check to pass while every real sync
    /// failed: the token only reached the Keychain via `saveSettings()` on
    /// `.onDisappear`, and `HAService.configured(from:)` — the path watering,
    /// refresh and the cleanup scan all use — reads it from there. A green
    /// "Connected" against a token that was never persisted is worse than no
    /// check at all, because it points the user away from the actual fault.
    ///
    /// Persisting first also means a token can't be lost by testing it and
    /// then leaving the app without navigating out of Settings.
    func testConnection() async {
        guard !nabucasaURL.isEmpty, !haToken.isEmpty else {
            testResult = .failure(String(localized: "settings.test.missing.credentials"))
            return
        }

        isTesting = true
        testResult = nil
        defer { isTesting = false }

        saveSettings()

        guard let haService = HAService.configured(from: modelContext) else {
            testResult = .failure(String(localized: "settings.test.not.stored"))
            return
        }

        do {
            _ = try await haService.testConnection()
            testResult = .success
        } catch {
            testResult = .failure(error.localizedDescription)
        }
    }
    
    // MARK: - Request Notification Permission
    
    func requestNotificationPermission() async {
        do {
            let granted = try await NotificationService.shared.requestAuthorization()
            notificationsEnabled = granted
            saveSettings()
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
}
