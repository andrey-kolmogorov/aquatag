//
//  WateringHistoryView.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import SwiftUI
import SwiftData

struct WateringHistoryView: View {
    @Query(sort: \Plant.lastWateredDate, order: .reverse) private var plants: [Plant]
    
    var body: some View {
        NavigationStack {
            if wateringEvents.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(wateringEvents) { event in
                        WateringHistoryRow(event: event)
                    }
                }
                .navigationTitle("💧 History")
            }
        }
    }
    
    private var wateringEvents: [WateringEvent] {
        plants.compactMap { plant in
            guard let lastWatered = plant.lastWateredDate else { return nil }
            return WateringEvent(
                plant: plant,
                timestamp: lastWatered,
                wateredBy: plant.lastWateredBy ?? "Unknown"
            )
        }
        .sorted { $0.timestamp > $1.timestamp }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "drop")
                .font(.system(size: 72))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Watering History")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Water your plants to see history here")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .navigationTitle("💧 History")
    }
}

struct WateringEvent: Identifiable {
    let id = UUID()
    let plant: Plant
    let timestamp: Date
    let wateredBy: String
}

struct WateringHistoryRow: View {
    let event: WateringEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Plant emoji
            Text(event.plant.emoji)
                .font(.system(size: 40))
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.plant.name)
                    .font(.headline)
                
                Text("Watered by \(event.wateredBy)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(DateFormatters.relative.localizedString(for: event.timestamp, relativeTo: Date()))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Timestamp
            Text(DateFormatters.timeOnly.string(from: event.timestamp))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WateringHistoryView()
        .modelContainer(for: Plant.self)
}
