//
//  PlantRowView.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import SwiftUI

struct PlantRowView: View {
    let plant: Plant
    let onWaterNow: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Emoji
            Text(plant.emoji)
                .font(.system(size: 40))
            
            // Plant info
            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(.headline)
                
                if let lastWatered = plant.lastWateredDate {
                    Text("Last watered \(DateFormatters.relative.localizedString(for: lastWatered, relativeTo: Date()))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Never watered")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                WateringStatusBadge(plant: plant)
            }
            
            Spacer()
            
            // Quick water button
            Button(action: onWaterNow) {
                Image(systemName: "drop.fill")
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.blue)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 8)
    }
}
