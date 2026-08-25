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
    var showingBlankTagSheet = false
    var isWritingTag = false
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - NFC Scanning
    
    func scanNFCTag() async {
        guard NFCService.isNFCAvailable() else {
            errorMessage = String(localized: "error.tag.no.nfc.body")
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
        } catch NFCService.NFCError.blankTag {
            // Brand-new sticker: invite the user to link it to a plant.
            showingBlankTagSheet = true
        } catch NFCService.NFCError.unreadableTag {
            errorMessage = String(localized: "error.tag.unreadable.body")
            showingError = true
        } catch {
            errorMessage = String(localized: "error.tag.generic.body")
            showingError = true
            print("NFC Error: \(error)")
        }

        isScanning = false
    }

    // MARK: - Sticker writing (blank-tag flow)

    func writeStickerForPlant(_ plant: Plant) async {
        isWritingTag = true
        defer { isWritingTag = false }

        do {
            try await nfcService.writeTag(plantID: plant.id)
            showingBlankTagSheet = false
            successMessage = String(format: String(localized: "blank.write.success"), plant.name)
            showingSuccess = true
        } catch NFCService.NFCError.scanCancelled {
            // User backed out of the second tap — keep the sheet open silently.
        } catch {
            errorMessage = String(localized: "error.tag.write.body")
            showingError = true
            print("NFC write error: \(error)")
        }
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
        guard let haService = HAService.configured(from: modelContext) else {
            successMessage = "💧 Watered \(plant.name)!"
            showingSuccess = true
            return
        }

        let resolver = HAHelperResolver(modelContext: modelContext, service: haService)

        do {
            // Resolves an existing link, adopts a matching helper, or creates
            // one — and records whichever id HA actually assigned.
            let entityID = try await resolver.ensureHelper(for: plant)

            try await haService.logWatering(
                entityID: entityID,
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
        guard let haService = HAService.configured(from: modelContext) else { return }

        isRefreshing = true
        defer { isRefreshing = false }

        let resolver = HAHelperResolver(modelContext: modelContext, service: haService)

        do {
            // One inventory fetch serves both jobs: linking plants that were
            // never attached (repairing installs that predate the id fix), and
            // reading every current value. The old code did an N-request loop
            // of single-entity lookups instead.
            let inventory = try await haService.fetchHelperInventory()
            try await resolver.adoptExistingHelpers(inventory: inventory)

            let valuesByObjectID = Dictionary(
                inventory.map { ($0.objectID, $0.lastWatered) },
                uniquingKeysWith: { first, _ in first }
            )

            let plants = (try? modelContext.fetch(FetchDescriptor<Plant>())) ?? []
            for plant in plants {
                guard let objectID = plant.haHelperObjectID,
                      let lastWatered = valuesByObjectID[objectID] ?? nil else { continue }
                plant.lastWateredDate = lastWatered
            }

            try? modelContext.save()
        } catch {
            print("Failed to refresh from HA: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Retry Pending Events
    
    func retryPendingEvents() async {
        let descriptor = FetchDescriptor<PendingWateringEvent>()
        guard let pendingEvents = try? modelContext.fetch(descriptor),
              !pendingEvents.isEmpty else {
            return
        }
        
        guard let haService = HAService.configured(from: modelContext) else { return }

        let resolver = HAHelperResolver(modelContext: modelContext, service: haService)
        let plants = (try? modelContext.fetch(FetchDescriptor<Plant>())) ?? []
        let plantsByID = Dictionary(plants.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })

        for event in pendingEvents {
            do {
                // Pending events store only the plant id, so the entity has to
                // be resolved through the plant. A plant deleted while offline
                // leaves its event unsendable — drop it rather than retrying
                // forever.
                guard let plant = plantsByID[event.plantID] else {
                    modelContext.delete(event)
                    continue
                }

                let entityID = try await resolver.ensureHelper(for: plant)

                try await haService.logWatering(
                    entityID: entityID,
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
        guard let haService = HAService.configured(from: modelContext) else { return }

        let resolver = HAHelperResolver(modelContext: modelContext, service: haService)

        do {
            let entityID = try await resolver.ensureHelper(for: plant)
            print("✅ Helper linked for \(plant.name): \(entityID)")
        } catch {
            print("⚠️ Failed to link helper for \(plant.name): \(error)")
            // Don't show error to user - this is a background operation
        }
    }
}
