//
//  WateringStatusBadge.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import SwiftUI

struct WateringStatusBadge: View {
    let plant: Plant
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundStyle(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.15))
        .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch plant.wateringStatus {
        case .ok:
            return .green
        case .dueSoon:
            return .orange
        case .overdue:
            return .red
        case .unknown:
            return .gray
        }
    }
    
    private var statusText: String {
        guard let daysUntil = plant.daysUntilNextWatering else {
            return "Not watered yet"
        }
        
        if daysUntil < 0 {
            let overdueDays = abs(daysUntil)
            return "\(overdueDays)d overdue"
        } else if daysUntil == 0 {
            return "Water today"
        } else if daysUntil == 1 {
            return "Water tomorrow"
        } else {
            return "In \(daysUntil)d"
        }
    }
}
