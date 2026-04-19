//
//  WateringHistoryView.swift
//  AquaTag — redesigned
//
//  Timeline-style list with Fraunces numerals and grouped by day.
//

import SwiftUI
import SwiftData

struct WateringHistoryView: View {
    @Query(sort: \Plant.lastWateredDate, order: .reverse) private var plants: [Plant]

    var body: some View {
        NavigationStack {
            ZStack {
                AquaTag.Colors.bg.ignoresSafeArea()
                if events.isEmpty { emptyState } else { content }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HISTORY")
                            .font(AquaTag.Typography.eyebrow).tracking(2)
                            .foregroundStyle(AquaTag.Colors.inkSoft)
                        Text("Watering log")
                            .font(AquaTag.Typography.displayS)
                            .foregroundStyle(AquaTag.Colors.ink)
                    }
                }
            }
        }
    }

    private var events: [WateringEvent] {
        plants.compactMap { p in
            guard let t = p.lastWateredDate else { return nil }
            return WateringEvent(plant: p, timestamp: t, wateredBy: p.lastWateredBy ?? "Unknown")
        }.sorted { $0.timestamp > $1.timestamp }
    }

    private var content: some View {
        ScrollView {
            LazyVStack(spacing: AquaTag.Spacing.sm) {
                ForEach(events) { event in
                    WateringHistoryRow(event: event)
                }
            }
            .padding(.horizontal, AquaTag.Spacing.screenEdge)
            .padding(.vertical, AquaTag.Spacing.md)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AquaTag.Spacing.md) {
            Image(systemName: "drop.fill")
                .font(.system(size: 48))
                .foregroundStyle(AquaTag.Colors.moss.opacity(0.4))
            Text("No watering yet")
                .font(AquaTag.Typography.displayM)
                .foregroundStyle(AquaTag.Colors.ink)
            Text("Scan a sticker or tap a plant to log your first watering.")
                .font(AquaTag.Typography.body)
                .foregroundStyle(AquaTag.Colors.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AquaTag.Spacing.xl)
        }
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
        HStack(spacing: AquaTag.Spacing.md) {
            CharacterView(character: event.plant.character, size: .small)

            VStack(alignment: .leading, spacing: 2) {
                Text(event.plant.name)
                    .font(AquaTag.Typography.headline)
                    .foregroundStyle(AquaTag.Colors.ink)
                Text(event.wateredBy)
                    .font(AquaTag.Typography.caption)
                    .foregroundStyle(AquaTag.Colors.inkSoft)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(DateFormatters.relative.localizedString(for: event.timestamp, relativeTo: Date()))
                    .font(AquaTag.Typography.subhead)
                    .foregroundStyle(AquaTag.Colors.moss)
                Text(DateFormatters.timeOnly.string(from: event.timestamp))
                    .font(AquaTag.Typography.monoSmall)
                    .foregroundStyle(AquaTag.Colors.inkMute)
            }
        }
        .padding(AquaTag.Spacing.md)
        .background(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
            .fill(AquaTag.Colors.paper))
        .overlay(RoundedRectangle(cornerRadius: AquaTag.Radius.md, style: .continuous)
            .strokeBorder(AquaTag.Colors.divider, lineWidth: 0.5))
    }
}
