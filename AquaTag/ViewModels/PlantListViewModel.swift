//
//  PlantListViewModel.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
class PlantListViewModel {
    private let modelContext: ModelContext
    private let nfcService = NFCService()
    
    var isScanning = false
    var showingError = false
    var errorMessage = ""
    var showingSuccess = false
    var successMessage = ""
    var scannedPlant: Plant?
    var showingNewPlantSheet = false
    var scannedPlantID: String?
    var isRefreshing = false
    var showingWaterConfirmation = false
    var plantPendingConfirmation: Plant?
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - NFC Scanning
    
    func scanNFCTag() async {
        guard NFCService.isNFCAvailable() else {
            errorMessage = "NFC is not available on this device"
            showingError = true
            return
        }
        
        isScanning = true
        
        do {
            let plantID = try await nfcService.readTag()
            await handleScannedPlantID(plantID)
        } catch NFCService.NFCError.scanCancelled {
            // User cancelled - no error needed
            print("NFC scan cancelled by user")
        } catch {
            errorMessage = "NFC scan failed: \(error.localizedDescription)"
            showingError = true
            print("NFC Error: \(error)")
        }
        
        isScanning = false
    }
    
    // Called when app is opened via background NFC tag (aquatag://water/{plantID})
    func handleBackgroundTag(plantID: String) async {
        print("🏷️ Background tag: processing plant ID '\(plantID)'")
        await handleScannedPlantID("aquatag:\(plantID)")
    }

    private func handleScannedPlantID(_ plantID: String) async {
        print("🏷️ Raw scanned NFC data: '\(plantID)'")
        
        // Parse "aquatag:plantid" format
        let cleanedID = plantID.replacingOccurrences(of: "aquatag:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("🏷️ Cleaned plant ID: '\(cleanedID)'")
        
        // Validate plant ID
        guard !cleanedID.isEmpty else {
            errorMessage = "Invalid tag format. Expected: aquatag:{plant_id}\nReceived: \(plantID)"
            showingError = true
            return
        }
        
        // Look up plant in database
        let descriptor = FetchDescriptor<Plant>(
            predicate: #Predicate { $0.id == cleanedID }
        )
        
        do {
            let plants = try modelContext.fetch(descriptor)
            print("🔍 Found \(plants.count) plants matching ID '\(cleanedID)'")
            
            if let plant = plants.first {
                print("✅ Found plant: \(plant.name)")
                scannedPlant = plant
                await waterPlantIfNeeded(plant)
            } else {
                print("❌ No plant found with ID '\(cleanedID)'")
                // Unknown plant - show registration sheet
                scannedPlantID = cleanedID
                showingNewPlantSheet = true
            }
        } catch {
            errorMessage = "Failed to lookup plant: \(error.localizedDescription)"
            showingError = true
        }
    }
    
    // MARK: - Watering

    func waterPlantIfNeeded(_ plant: Plant) async {
        if plant.wateringStatus == .ok {
            // Plant doesn't need water yet — ask for confirmation
            plantPendingConfirmation = plant
            showingWaterConfirmation = true
        } else {
            await waterPlant(plant)
        }
    }

    func confirmWatering() async {
        guard let plant = plantPendingConfirmation else { return }
        plantPendingConfirmation = nil
        await waterPlant(plant)
    }

    func waterPlant(_ plant: Plant) async {
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        let settings = try? modelContext.fetch(settingsDescriptor).first

        let timestamp = Date()
        let deviceName = settings?.deviceName.isEmpty == false
            ? settings!.deviceName
            : UIDevice.current.name

        // Update local data immediately
        plant.lastWateredDate = timestamp
        plant.lastWateredBy = deviceName

        modelContext.insert(WateringLog(
            plantID: plant.id,
            timestamp: timestamp,
            wateredBy: deviceName
        ))

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            showingError = true
            return
        }

        // Schedule notification (local — no HA needed)
        if settings?.notificationsEnabled ?? true {
            do {
                try await NotificationService.shared.scheduleWateringReminder(
                    for: plant,
                    preferredTime: settings?.notificationTime ?? Date()
                )
            } catch {
                print("Failed to schedule notification: \(error)")
            }
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        // Sync to Home Assistant if configured
        let token = try? KeychainService.getHAToken()
        guard let settings, settings.isConfigured, let token, !token.isEmpty else {
            successMessage = "💧 Watered \(plant.name)!"
            showingSuccess = true
            return
        }

        let haService = HAService(baseURL: settings.nabucasaURL, token: token)

        do {
            try await haService.logWatering(
                plantID: plant.id,
                plantName: plant.name,
                deviceName: deviceName,
                timestamp: timestamp
            )

            successMessage = L10n.Water.success(plantName: plant.name)
            showingSuccess = true
        } catch {
            let pendingEvent = PendingWateringEvent(
                plantID: plant.id,
                plantName: plant.name,
                deviceName: deviceName,
                timestamp: timestamp
            )
            modelContext.insert(pendingEvent)
            try? modelContext.save()

            successMessage = L10n.Water.successOffline(plantName: plant.name)
            showingSuccess = true

            print("Failed to sync with HA: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Refresh from HA
    
    func refreshFromHA() async {
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        guard let settings = try? modelContext.fetch(settingsDescriptor).first,
              settings.isConfigured,
              let token = try? KeychainService.getHAToken() else {
            return
        }
        
        isRefreshing = true
        
        let haService = HAService(baseURL: settings.nabucasaURL, token: token)
        
        // Fetch all plants
        let plantsDescriptor = FetchDescriptor<Plant>()
        guard let plants = try? modelContext.fetch(plantsDescriptor) else {
            isRefreshing = false
            return
        }
        
        // Update each plant's last watered date from HA
        for plant in plants {
            do {
                if let lastWatered = try await haService.getLastWateredDate(plantID: plant.id) {
                    plant.lastWateredDate = lastWatered
                }
            } catch {
                print("Failed to fetch last watered date for \(plant.name): \(error)")
            }
        }
        
        try? modelContext.save()
        isRefreshing = false
    }
    
    // MARK: - Retry Pending Events
    
    func retryPendingEvents() async {
        let descriptor = FetchDescriptor<PendingWateringEvent>()
        guard let pendingEvents = try? modelContext.fetch(descriptor),
              !pendingEvents.isEmpty else {
            return
        }
        
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        guard let settings = try? modelContext.fetch(settingsDescriptor).first,
              settings.isConfigured,
              let token = try? KeychainService.getHAToken() else {
            return
        }
        
        let haService = HAService(baseURL: settings.nabucasaURL, token: token)
        
        for event in pendingEvents {
            do {
                try await haService.logWatering(
                    plantID: event.plantID,
                    plantName: event.plantName,
                    deviceName: event.deviceName,
                    timestamp: event.timestamp
                )
                
                // Success - remove from pending
                modelContext.delete(event)
            } catch {
                // Keep in pending queue
                print("Failed to sync pending event: \(error)")
            }
        }
        
        try? modelContext.save()
    }
    
    // MARK: - Auto-Create HA Helper
    
    func ensureHelperExists(for plant: Plant) async {
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        guard let settings = try? modelContext.fetch(settingsDescriptor).first,
              settings.isConfigured,
              let token = try? KeychainService.getHAToken() else {
            return
        }
        
        let haService = HAService(baseURL: settings.nabucasaURL, token: token)
        
        do {
            try await haService.ensureHelperExists(plantID: plant.id, plantName: plant.name)
            print("✅ Helper created/verified for \(plant.name)")
        } catch {
            print("⚠️ Failed to create helper for \(plant.name): \(error)")
            // Don't show error to user - this is a background operation
        }
    }
}
