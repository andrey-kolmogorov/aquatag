//
//  AddPlantView.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import SwiftUI
import SwiftData

struct AddPlantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [AppSettings]
    
    var suggestedID: String?
    
    @State private var name = ""
    @State private var emoji = "🌿"
    @State private var wateringIntervalDays = 7
    @State private var notes = ""
    @State private var showingEmojiPicker = false
    
    private let emojiOptions = [
        "🌿", "🪴", "🌱", "🌵", "🌴", "🌳", "🌲", "🎋",
        "🍀", "☘️", "🌾", "🌺", "🌸", "🌼", "🌻", "🌷",
        "🥀", "🏵️", "💐", "🌹", "🪷", "🪻"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Plant Info") {
                    HStack {
                        Text("Emoji")
                        Spacer()
                        Button(action: { showingEmojiPicker.toggle() }) {
                            Text(emoji)
                                .font(.system(size: 40))
                        }
                    }
                    
                    if showingEmojiPicker {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                            ForEach(emojiOptions, id: \.self) { option in
                                Button(action: {
                                    emoji = option
                                    showingEmojiPicker = false
                                }) {
                                    Text(option)
                                        .font(.system(size: 32))
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    TextField("Name", text: $name)
                    
                    Stepper("Water every \(wateringIntervalDays) days", value: $wateringIntervalDays, in: 1...30)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 100)
                }
                
                Section("Home Assistant") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.caption)
                            Text("Create this helper in Home Assistant")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        Text("Entity ID:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(generatedEntityID)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.blue)
                            .textSelection(.enabled)
                        
                        Text("Settings → Devices & Services → Helpers → Create Helper → Date and/or time")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .navigationTitle("Add Plant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePlant()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let defaultInterval = settings.first?.defaultWateringIntervalDays {
                    wateringIntervalDays = defaultInterval
                }
                
                // If we have a suggested ID from NFC scan, pre-fill name
                if let suggestedID = suggestedID {
                    name = suggestedID.replacingOccurrences(of: "_", with: " ").capitalized
                }
            }
        }
    }
    
    private var generatedEntityID: String {
        let plantID = suggestedID ?? PlantIDGenerator.generateID(from: name)
        return "input_datetime.plant_\(plantID)_last_watered"
    }
    
    private func savePlant() {
        let plantID = suggestedID ?? PlantIDGenerator.generateID(from: name)
        
        let plant = Plant(
            id: plantID,
            name: name,
            emoji: emoji,
            wateringIntervalDays: wateringIntervalDays,
            notes: notes
        )
        
        modelContext.insert(plant)
        
        do {
            try modelContext.save()
            
            // Auto-create HA helper in the background
            Task {
                await createHelperInBackground(for: plant)
            }
            
            dismiss()
        } catch {
            print("Failed to save plant: \(error)")
        }
    }
    
    private func createHelperInBackground(for plant: Plant) async {
        guard let settings = settings.first,
              settings.isConfigured,
              let token = try? KeychainService.getHAToken() else {
            return
        }
        
        let haService = HAService(baseURL: settings.nabucasaURL, token: token)
        
        do {
            try await haService.ensureHelperExists(plantID: plant.id, plantName: plant.name)
            print("✅ Helper auto-created for \(plant.name)")
        } catch {
            print("⚠️ Could not auto-create helper: \(error)")
            // Fail silently - user can still use the app
        }
    }
}

#Preview {
    AddPlantView()
        .modelContainer(for: [Plant.self, AppSettings.self])
}
