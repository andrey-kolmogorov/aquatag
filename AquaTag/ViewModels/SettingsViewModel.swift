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
    
    func testConnection() async {
        guard !nabucasaURL.isEmpty, !haToken.isEmpty else {
            testResult = .failure("Please enter both URL and token")
            return
        }
        
        isTesting = true
        testResult = nil
        
        let haService = HAService(baseURL: nabucasaURL, token: haToken)
        
        do {
            _ = try await haService.testConnection()
            testResult = .success
        } catch {
            testResult = .failure(error.localizedDescription)
        }
        
        isTesting = false
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
