//
//  PlantDetailView.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import SwiftUI
import SwiftData

struct PlantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var plant: Plant
    @Query private var settings: [AppSettings]
    
    @State private var isEditing = false
    @State private var isWritingTag = false
    @State private var showingWriteSuccess = false
    @State private var showingWriteError = false
    @State private var writeErrorMessage = ""
    @State private var showingDeleteConfirmation = false
    
    private let nfcService = NFCService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 16) {
                            Text(plant.emoji)
                                .font(.system(size: 80))
                            
                            Text(plant.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            WateringStatusBadge(plant: plant)
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
                
                Section("Watering") {
                    if let lastWatered = plant.lastWateredDate {
                        LabeledContent("Last Watered") {
                            VStack(alignment: .trailing) {
                                Text(DateFormatters.dateTime.string(from: lastWatered))
                                if let wateredBy = plant.lastWateredBy {
                                    Text(wateredBy)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        if let nextWatering = plant.nextWateringDate {
                            LabeledContent("Next Watering") {
                                Text(DateFormatters.short.string(from: nextWatering))
                            }
                        }
                    } else {
                        Text("Not watered yet")
                            .foregroundStyle(.secondary)
                    }
                    
                    if isEditing {
                        Stepper("Water every \(plant.wateringIntervalDays) days",
                               value: $plant.wateringIntervalDays,
                               in: 1...30)
                    } else {
                        LabeledContent("Watering Interval") {
                            Text("\(plant.wateringIntervalDays) days")
                        }
                    }
                }
                
                if !plant.notes.isEmpty || isEditing {
                    Section("Notes") {
                        if isEditing {
                            TextEditor(text: $plant.notes)
                                .frame(minHeight: 100)
                        } else {
                            Text(plant.notes)
                        }
                    }
                }
                
                Section("NFC Tag") {
                    Button(action: { writeNFCTag() }) {
                        Label("Write to NFC Tag", systemImage: "wave.3.right.circle.fill")
                    }
                    .disabled(isWritingTag)
                    
                    if let tagID = plant.nfcTagID {
                        LabeledContent("Tag ID") {
                            Text(tagID)
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
                
                Section("Home Assistant") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Entity ID")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(plant.haEntityID)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
                
                Section {
                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Delete Plant", systemImage: "trash")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Plant" : "Plant Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isEditing ? "Cancel" : "Done") {
                        if isEditing {
                            // Discard changes
                            modelContext.rollback()
                            isEditing = false
                        } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
            }
            .alert("Tag Written", isPresented: $showingWriteSuccess) {
                Button("OK") { }
            } message: {
                Text("NFC tag has been written successfully!")
            }
            .alert("Write Failed", isPresented: $showingWriteError) {
                Button("OK") { }
            } message: {
                Text(writeErrorMessage)
            }
            .alert("Delete Plant?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deletePlant()
                }
            } message: {
                Text("This will permanently delete \(plant.name) and cannot be undone.")
            }
        }
    }
    
    private func writeNFCTag() {
        Task {
            isWritingTag = true
            
            do {
                let plantID = "aquatag:\(plant.id)"
                try await nfcService.writeTag(plantID: plantID)
                showingWriteSuccess = true
            } catch {
                writeErrorMessage = error.localizedDescription
                showingWriteError = true
            }
            
            isWritingTag = false
        }
    }
    
    private func saveChanges() {
        do {
            try modelContext.save()
            isEditing = false
        } catch {
            print("Failed to save changes: \(error)")
        }
    }
    
    private func deletePlant() {
        // Cancel any pending notifications
        Task {
            await NotificationService.shared.cancelWateringReminder(for: plant)
        }
        
        modelContext.delete(plant)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to delete plant: \(error)")
        }
    }
}
