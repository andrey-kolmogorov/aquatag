//
//  WateringStatusBadge.swift
//  AquaTag  — redesigned
//
//  Replaces the existing WateringStatusBadge. Same API (`plant: Plant`),
//  new visual: mono eyebrow label, dot + text, rounded pill.
//

import SwiftUI

struct WateringStatusBadge: View {
    let plant: Plant

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(AquaTag.Colors.status(plant.wateringStatus))
                .frame(width: 6, height: 6)

            Text(statusText)
                .textCase(.uppercase)
                .font(AquaTag.Typography.micro)
                .tracking(0.8)
                .foregroundStyle(AquaTag.Colors.status(plant.wateringStatus))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(AquaTag.Colors.status(plant.wateringStatus).opacity(0.10))
        )
        .overlay(
            Capsule()
                .strokeBorder(
                    AquaTag.Colors.status(plant.wateringStatus).opacity(0.25),
                    lineWidth: 0.5
                )
        )
    }

    private var statusText: String {
        guard let daysUntil = plant.daysUntilNextWatering else {
            return String(localized: "status.new")
        }
        if daysUntil < 0 {
            return L10n.Status.overdue(days: abs(daysUntil))
        } else if daysUntil == 0 {
            return String(localized: "status.today")
        } else if daysUntil == 1 {
            return String(localized: "status.tomorrow")
        } else {
            return L10n.Status.inDays(daysUntil)
        }
    }
}
