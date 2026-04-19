//
//  PlantRowView.swift
//  AquaTag  — redesigned
//
//  Replaces the existing PlantRowView. Same API:
//    PlantRowView(plant: plant, onWaterNow: { ... })
//
//  Changes:
//  • Swaps the emoji for CharacterView
//  • Uses Fraunces for plant name, mono for "last watered" timestamp
//  • Primary background tile (Paper) with subtle border
//  • Water button uses brand Moss with water drop glyph
//

import SwiftUI

struct PlantRowView: View {
    let plant: Plant
    let onWaterNow: () -> Void

    var body: some View {
        HStack(spacing: AquaTag.Spacing.md) {
            CharacterView(character: plant.character, size: .medium)

            VStack(alignment: .leading, spacing: 4) {
                Text(plant.name)
                    .font(AquaTag.Typography.displayS)
                    .foregroundStyle(AquaTag.Colors.ink)
                    .lineLimit(1)

                if let lastWatered = plant.lastWateredDate {
                    Text("Last watered \(DateFormatters.relative.localizedString(for: lastWatered, relativeTo: Date()))")
                        .font(AquaTag.Typography.caption)
                        .foregroundStyle(AquaTag.Colors.inkSoft)
                        .lineLimit(1)
                } else {
                    Text("Never watered")
                        .font(AquaTag.Typography.caption)
                        .foregroundStyle(AquaTag.Colors.inkMute)
                }

                WateringStatusBadge(plant: plant)
                    .padding(.top, 2)
            }

            Spacer(minLength: AquaTag.Spacing.xs)

            // Water-now button
            Button(action: onWaterNow) {
                Image(systemName: "drop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AquaTag.Colors.cream)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle().fill(AquaTag.Colors.moss)
                    )
                    .atShadow(AquaTag.Shadow.card)
            }
            .buttonStyle(.plain)
        }
        .padding(AquaTag.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: AquaTag.Radius.lg, style: .continuous)
                .fill(AquaTag.Colors.paper)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AquaTag.Radius.lg, style: .continuous)
                .strokeBorder(AquaTag.Colors.divider, lineWidth: 0.5)
        )
    }
}
