//
//  WateringHistoryView.swift
//  AquaTag — redesigned to match the "Six weeks of care" marketing screen
//
//  Layout (top → bottom):
//    • Eyebrow "THE LAST SIX WEEKS"
//    • Fraunces display "History"
//    • Big stats row: total waterings (accent) + day streak
//    • 7 × 6 heatmap, one row per weekday, six week-columns, dot opacity = load
//    • "THIS WEEK" entries: character + name + relative when/who + drop glyph
//
//  Data model notes:
//    - WateringEvent is derived from Plant.lastWateredDate in the sample code.
//      In production the schedule should be a separate @Model (WateringLog)
//      so a plant can accumulate history. See HANDOFF.md → Model migration.
//    - `heatmapBuckets(from:)` aggregates events into a [weekday][week] Int grid.
//      The view renders 0 as a divider-colored tile and 1+ as accent with
//      opacity scaled by count.
//

import SwiftUI
import SwiftData

// MARK: - View

struct WateringHistoryView: View {
    @Query(sort: \Plant.lastWateredDate, order: .reverse) private var plants: [Plant]

    var body: some View {
        NavigationStack {
            ZStack {
                AquaTag.Colors.bg.ignoresSafeArea()
                if events.isEmpty { emptyState } else { content }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: Content

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, AquaTag.Spacing.screenEdge)
                    .padding(.top, AquaTag.Spacing.lg)

                statsRow
                    .padding(.horizontal, AquaTag.Spacing.screenEdge)
                    .padding(.top, AquaTag.Spacing.lg)

                heatmap
                    .padding(.horizontal, AquaTag.Spacing.screenEdge)
                    .padding(.top, AquaTag.Spacing.lg)

                thisWeek
                    .padding(.horizontal, AquaTag.Spacing.screenEdge)
                    .padding(.top, AquaTag.Spacing.xl)
                    .padding(.bottom, AquaTag.Spacing.xl)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.History.eyebrowSixWeeks)
                .font(AquaTag.Typography.eyebrow).tracking(1.5)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            Text(L10n.History.title)
                .font(AquaTag.Typography.displayL)
                .foregroundStyle(AquaTag.Colors.ink)
        }
    }

    // MARK: Stats row

    private var statsRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: AquaTag.Spacing.xl) {
            stat(value: totalWaterings,
                 label: L10n.History.waterings,
                 accent: true)
            stat(value: dayStreak,
                 label: L10n.History.dayStreak,
                 accent: false)
            Spacer(minLength: 0)
        }
    }

    private func stat(value: Int, label: LocalizedStringKey, accent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)")
                .font(AquaTag.Typography.displayXL)
                .foregroundStyle(accent ? AquaTag.Colors.terracotta : AquaTag.Colors.ink)
            Text(label)
                .font(AquaTag.Typography.micro).tracking(1.2)
                .foregroundStyle(AquaTag.Colors.inkSoft)
        }
    }

    // MARK: Heatmap

    /// 6 weeks × 7 weekdays grid. Rows are weekdays (Mon → Sun), columns are
    /// weeks (oldest → current). Each cell is the count of waterings that day
    /// across all plants.
    private var heatmap: some View {
        let grid = heatmapBuckets(from: events)
        return VStack(spacing: 6) {
            ForEach(Array(weekdayLabels.enumerated()), id: \.offset) { rowIdx, label in
                HStack(spacing: 8) {
                    Text(label)
                        .font(AquaTag.Typography.monoSmall)
                        .foregroundStyle(AquaTag.Colors.inkSoft)
                        .frame(width: 30, alignment: .leading)

                    ForEach(0..<6, id: \.self) { colIdx in
                        let count = grid[rowIdx][colIdx]
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(tileColor(count: count))
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
    }

    private func tileColor(count: Int) -> Color {
        guard count > 0 else { return AquaTag.Colors.divider }
        // Opacity scales 0.3 → 1.0 based on activity; single-watering days show
        // at ~45%, very active days approach full moss.
        let opacity = min(1.0, 0.3 + Double(count) * 0.15)
        return AquaTag.Colors.moss.opacity(opacity)
    }

    // MARK: This week

    private var thisWeek: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.History.thisWeek)
                .font(AquaTag.Typography.micro).tracking(1.5)
                .foregroundStyle(AquaTag.Colors.inkSoft)
                .padding(.bottom, 10)

            ForEach(recentEvents) { event in
                WateringHistoryRow(event: event)
            }

            if recentEvents.isEmpty {
                Text(L10n.History.noneThisWeek)
                    .font(AquaTag.Typography.caption)
                    .foregroundStyle(AquaTag.Colors.inkMute)
                    .padding(.vertical, AquaTag.Spacing.sm)
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: AquaTag.Spacing.md) {
            Image(systemName: "drop.fill")
                .font(.system(size: 48))
                .foregroundStyle(AquaTag.Colors.moss.opacity(0.4))
            Text(L10n.History.emptyTitle)
                .font(AquaTag.Typography.displayM)
                .foregroundStyle(AquaTag.Colors.ink)
            Text(L10n.History.emptyBody)
                .font(AquaTag.Typography.body)
                .foregroundStyle(AquaTag.Colors.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AquaTag.Spacing.xl)
        }
    }

    // MARK: Derived data

    private var events: [WateringEvent] {
        plants.compactMap { p in
            guard let t = p.lastWateredDate else { return nil }
            return WateringEvent(plant: p, timestamp: t, wateredBy: p.lastWateredBy ?? "Unknown")
        }.sorted { $0.timestamp > $1.timestamp }
    }

    private var totalWaterings: Int { events.count }

    /// Consecutive days (ending today) where at least one plant was watered.
    private var dayStreak: Int {
        let cal = Calendar.current
        let dayBuckets = Set(events.map { cal.startOfDay(for: $0.timestamp) })
        var streak = 0
        var cursor = cal.startOfDay(for: Date())
        while dayBuckets.contains(cursor) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    private var recentEvents: [WateringEvent] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return Array(events.filter { $0.timestamp > cutoff }.prefix(5))
    }

    private var weekdayLabels: [String] {
        // Short weekday symbols, respecting current locale. Force Mon-first.
        let f = DateFormatter()
        f.locale = Locale.autoupdatingCurrent
        let raw = f.shortWeekdaySymbols ?? ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        // Rotate so Monday is first (iOS returns Sun as index 0 in en-US).
        return Array(raw[1...]) + [raw[0]]
    }

    /// Builds a 7×6 int grid: [weekday (Mon=0)][week (oldest=0)] = count.
    private func heatmapBuckets(from events: [WateringEvent]) -> [[Int]] {
        var grid = Array(repeating: Array(repeating: 0, count: 6), count: 7)
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let oldest = cal.date(byAdding: .day, value: -41, to: today) else { return grid }

        for event in events {
            let day = cal.startOfDay(for: event.timestamp)
            guard day >= oldest, day <= today else { continue }
            let daysFromOldest = cal.dateComponents([.day], from: oldest, to: day).day ?? 0
            let week = daysFromOldest / 7      // 0 … 5
            // Convert calendar weekday (Sun=1 … Sat=7) to Mon=0 … Sun=6
            let iosWeekday = cal.component(.weekday, from: day)
            let weekday = (iosWeekday + 5) % 7
            if week >= 0 && week < 6 && weekday >= 0 && weekday < 7 {
                grid[weekday][week] += 1
            }
        }
        return grid
    }
}

// MARK: - Row

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
                Text(L10n.History.wateredBy(
                    when: RelativeDateTimeFormatter.localized
                        .localizedString(for: event.timestamp, relativeTo: Date()),
                    who: event.wateredBy
                ))
                    .font(AquaTag.Typography.caption)
                    .foregroundStyle(AquaTag.Colors.inkSoft)
            }

            Spacer()

            Image(systemName: "drop.fill")
                .font(.system(size: 14))
                .foregroundStyle(AquaTag.Colors.terracotta)
        }
        .padding(.vertical, AquaTag.Spacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(AquaTag.Colors.divider)
                .frame(height: 0.5)
        }
    }
}
