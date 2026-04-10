//
//  PlantListView.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import SwiftUI
import SwiftData

struct PlantListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Plant.name) private var plants: [Plant]
    @State private var viewModel: PlantListViewModel?
    @State private var showingAddPlant = false
    @State private var selectedPlant: Plant?
    @Binding var pendingPlantID: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if plants.isEmpty {
                    emptyStateView
                } else {
                    plantListView
                }
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            Task {
                                await viewModel?.scanNFCTag()
                            }
                        }) {
                            HStack {
                                Image(systemName: "wave.3.right")
                                    .font(.title2)
                                Text("Scan Tag")
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .clipShape(Capsule())
                            .shadow(radius: 4)
                        }
                        .padding(.trailing, 24)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("🌿 Plants")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddPlant = true }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        Task {
                            await viewModel?.refreshFromHA()
                        }
                    }) {
                        if viewModel?.isRefreshing == true {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(viewModel?.isRefreshing == true)
                }
            }
            .sheet(isPresented: $showingAddPlant) {
                AddPlantView()
            }
            .sheet(item: $selectedPlant) { plant in
                PlantDetailView(plant: plant)
            }
            .sheet(isPresented: Binding(
                get: { viewModel?.showingNewPlantSheet ?? false },
                set: { if !$0 { viewModel?.showingNewPlantSheet = false } }
            )) {
                if let plantID = viewModel?.scannedPlantID {
                    AddPlantView(suggestedID: plantID)
                }
            }
            .alert("Success", isPresented: Binding(
                get: { viewModel?.showingSuccess ?? false },
                set: { if !$0 { viewModel?.showingSuccess = false } }
            )) {
                Button("OK") { }
            } message: {
                Text(viewModel?.successMessage ?? "")
            }
            .alert("Error", isPresented: Binding(
                get: { viewModel?.showingError ?? false },
                set: { if !$0 { viewModel?.showingError = false } }
            )) {
                Button("OK") { }
            } message: {
                Text(viewModel?.errorMessage ?? "")
            }
            .alert("Already Watered", isPresented: Binding(
                get: { viewModel?.showingWaterConfirmation ?? false },
                set: { if !$0 {
                    viewModel?.showingWaterConfirmation = false
                    viewModel?.plantPendingConfirmation = nil
                }}
            )) {
                Button("Water Anyway") {
                    Task { await viewModel?.confirmWatering() }
                }
                Button("Skip", role: .cancel) { }
            } message: {
                if let plant = viewModel?.plantPendingConfirmation {
                    Text("\(plant.emoji) \(plant.name) is watered enough! You will be notified the day it needs watering. Would you still water it?")
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = PlantListViewModel(modelContext: modelContext)
                }

                // Retry any pending events
                Task {
                    await viewModel?.retryPendingEvents()
                }

                // Handle pending URL from cold launch
                if let plantID = pendingPlantID {
                    pendingPlantID = nil
                    Task {
                        await viewModel?.handleBackgroundTag(plantID: plantID)
                    }
                }
            }
            .onChange(of: pendingPlantID) { _, newValue in
                guard let plantID = newValue else { return }
                pendingPlantID = nil
                Task {
                    await viewModel?.handleBackgroundTag(plantID: plantID)
                }
            }
        }
    }
    
    private var plantListView: some View {
        List {
            ForEach(plants) { plant in
                Button(action: {
                    selectedPlant = plant
                }) {
                    PlantRowView(plant: plant) {
                        Task {
                            await viewModel?.waterPlantIfNeeded(plant)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .refreshable {
            await viewModel?.refreshFromHA()
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "leaf")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Plants Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add your first plant or scan an NFC tag to get started")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Button(action: { showingAddPlant = true }) {
                Label("Add Plant", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    @Previewable @State var pendingPlantID: String? = nil
    PlantListView(pendingPlantID: $pendingPlantID)
        .modelContainer(for: [Plant.self, AppSettings.self])
}
