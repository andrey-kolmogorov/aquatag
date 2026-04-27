//
//  CalendarView.swift
//  AquaTag
//
//  Replaces the previous "Six weeks of care" heatmap. Shows a familiar
//  month grid where each day surfaces:
//    • past actuals — solid moss dots, one per WateringLog on that day
//    • future scheduled — hollow moss rings, one per plant predicted to be
//      watered that day based on `lastWateredDate + N*wateringIntervalDays`
//
//  Tapping a day populates the inline detail panel underneath the grid.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var plants: [Plant]
    @Query(sort: \WateringLog.timestamp, order: .reverse) private var logs: [WateringLog]

    @State private var visibleMonth: Date = Self.startOfMonth(for: Date())
    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())

    private var calendar: Calendar { Calendar.current }
    private var today: Date { calendar.startOfDay(for: Date()) }

    var body: some View {
        NavigationStack {
            ZStack {
                AquaTag.Colors.bg.ignoresSafeArea()
                if plants.isEmpty && logs.isEmpty {
                    emptyState
                } else {
                    content
                }
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

                monthHeader
                    .padding(.horizontal, AquaTag.Spacing.screenEdge)
                    .padding(.top, AquaTag.Spacing.md)

                weekdayHeader
                    .padding(.horizontal, AquaTag.Spacing.screenEdge)
                    .padding(.top, AquaTag.Spacing.sm)

                grid
                    .padding(.horizontal, AquaTag.Spacing.screenEdge)
                    .padding(.top, 6)

                Divider()
                    .background(AquaTag.Colors.divider)
                    .padding(.horizontal, AquaTag.Spacing.screenEdge)
                    .padding(.top, AquaTag.Spacing.lg)

                dayDetail
                    .padding(.horizontal, AquaTag.Spacing.screenEdge)
                    .padding(.top, AquaTag.Spacing.md)
                    .padding(.bottom, AquaTag.Spacing.xl)
            }
        }
    }

    // MARK: Header (eyebrow + display title)

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.Calendar.eyebrow)
                .font(AquaTag.Typography.eyebrow).tracking(1.5)
                .foregroundStyle(AquaTag.Colors.inkSoft)
            Text(L10n.Calendar.title)
                .font(AquaTag.Typography.displayL)
                .foregroundStyle(AquaTag.Colors.ink)
        }
    }

    // MARK: Month nav

    private var monthHeader: some View {
        HStack(spacing: AquaTag.Spacing.sm) {
            Text(DateFormatters.monthYear.string(from: visibleMonth))
                .font(AquaTag.Typography.displayM)
                .foregroundStyle(AquaTag.Colors.ink)

            Spacer()

            navButton(systemImage: "chevron.left") { stepMonth(by: -1) }

            Button {
                let now = Date()
                visibleMonth = Self.startOfMonth(for: now)
                selectedDate = calendar.startOfDay(for: now)
            } label: {
                Text(L10n.Calendar.today)
                    .font(AquaTag.Typography.subhead)
                    .foregroundStyle(AquaTag.Colors.moss)
                    .padding(.horizontal, 12)
                    .frame(height: 32)
                    .background(Capsule().strokeBorder(AquaTag.Colors.moss, lineWidth: 1))
            }
            .buttonStyle(.plain)

            navButton(systemImage: "chevron.right") { stepMonth(by: 1) }
        }
    }

    private func navButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AquaTag.Colors.ink)
                .frame(width: 32, height: 32)
                .background(Circle().fill(AquaTag.Colors.paper))
                .overlay(Circle().strokeBorder(AquaTag.Colors.divider, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func stepMonth(by months: Int) {
        if let next = calendar.date(byAdding: .month, value: months, to: visibleMonth) {
            visibleMonth = Self.startOfMonth(for: next)
        }
    }

    // MARK: Weekday header

    private var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(AquaTag.Typography.monoSmall)
                    .foregroundStyle(AquaTag.Colors.inkSoft)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// Short weekday symbols, rotated so the first column matches the user's
    /// locale's first weekday (Mon for de-DE, Sun for en-US). Uses the
    /// abbreviated form ("Mon", "Mo.") rather than single-letter so de-DE
    /// can distinguish Donnerstag vs Dienstag.
    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        let raw = formatter.shortStandaloneWeekdaySymbols
            ?? ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
        let firstWeekday = calendar.firstWeekday
        let shift = firstWeekday - 1
        return Array(raw[shift...]) + Array(raw[..<shift])
    }

    // MARK: Grid

    private var grid: some View {
        let cells = monthCells
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(cells, id: \.self) { date in
                DayCell(
                    date: date,
                    isInVisibleMonth: calendar.isDate(date, equalTo: visibleMonth, toGranularity: .month),
                    isToday: calendar.isDate(date, inSameDayAs: today),
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    actualCount: actualEvents(for: date).count,
                    scheduledCount: scheduledPlants(for: date).count
                ) {
                    selectedDate = calendar.startOfDay(for: date)
                }
            }
        }
    }

    /// 42 dates for the visible-month grid, including leading days from the
    /// previous month and trailing days from the next month so weekday columns
    /// align with the locale's first weekday.
    private var monthCells: [Date] {
        guard let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: visibleMonth)) else { return [] }
        let firstWeekdayOfMonth = calendar.component(.weekday, from: firstOfMonth)
        let firstWeekday = calendar.firstWeekday
        let leadingOffset = (firstWeekdayOfMonth - firstWeekday + 7) % 7
        guard let gridStart = calendar.date(byAdding: .day, value: -leadingOffset, to: firstOfMonth) else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: gridStart) }
    }

    // MARK: Day detail

    private var dayDetail: some View {
        let date = selectedDate
        let actuals = actualEvents(for: date)
        let scheduled = scheduledPlants(for: date)

        return VStack(alignment: .leading, spacing: AquaTag.Spacing.md) {
            Text(DateFormatters.weekdayDate.string(from: date).uppercased())
                .font(AquaTag.Typography.eyebrow).tracking(1.5)
                .foregroundStyle(AquaTag.Colors.inkSoft)

            if actuals.isEmpty && scheduled.isEmpty {
                Text(L10n.Calendar.noEvents)
                    .font(AquaTag.Typography.caption)
                    .foregroundStyle(AquaTag.Colors.inkMute)
                    .padding(.vertical, AquaTag.Spacing.sm)
            } else {
                if !actuals.isEmpty {
                    sectionLabel(L10n.Calendar.actualLabel)
                    VStack(spacing: 0) {
                        ForEach(actuals) { event in
                            DayDetailRow(event: event)
                        }
                    }
                }
                if !scheduled.isEmpty {
                    sectionLabel(L10n.Calendar.scheduledLabel)
                    VStack(spacing: 0) {
                        ForEach(scheduled, id: \.id) { plant in
                            ScheduledRow(plant: plant)
                        }
                    }
                }
            }
        }
    }

    private func sectionLabel(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(AquaTag.Typography.eyebrow).tracking(1.2)
            .foregroundStyle(AquaTag.Colors.inkMute)
            .padding(.top, AquaTag.Spacing.xs)
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: AquaTag.Spacing.md) {
            Image(systemName: "calendar")
                .font(.system(size: 48))
                .foregroundStyle(AquaTag.Colors.moss.opacity(0.4))
            Text(L10n.Calendar.emptyTitle)
                .font(AquaTag.Typography.displayM)
                .foregroundStyle(AquaTag.Colors.ink)
            Text(L10n.Calendar.emptyBody)
                .font(AquaTag.Typography.body)
                .foregroundStyle(AquaTag.Colors.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AquaTag.Spacing.xl)
        }
    }

    // MARK: Data

    private func actualEvents(for date: Date) -> [WateringEvent] {
        let plantsByID = Dictionary(uniqueKeysWithValues: plants.map { ($0.id, $0) })
        let unknown = String(localized: "calendar.watered.by.unknown")
        let day = calendar.startOfDay(for: date)
        return logs
            .filter { calendar.isDate($0.timestamp, inSameDayAs: day) }
            .compactMap { log -> WateringEvent? in
                guard let plant = plantsByID[log.plantID] else { return nil }
                return WateringEvent(plant: plant, timestamp: log.timestamp, wateredBy: log.wateredBy ?? unknown)
            }
    }

    /// Plants whose schedule lands on `date`.
    ///
    /// For **today**, defers to `Plant.daysUntilNextWatering` so it agrees
    /// with the WateringStatusBadge on the Plants tab — anything due now or
    /// overdue is surfaced (`daysUntil <= 0`).
    ///
    /// For **future days**, walks each plant's schedule forward in
    /// interval-day steps from `lastWateredDate` until it lands on or passes
    /// the target day; matches mean the plant is predicted to be watered
    /// that day.
    ///
    /// Past days return `[]` — the calendar surfaces history via
    /// `actualEvents(for:)` instead.
    private func scheduledPlants(for date: Date) -> [Plant] {
        let day = calendar.startOfDay(for: date)
        if day < today { return [] }

        return plants.compactMap { plant -> Plant? in
            // Today: align with the Plants tab's badge logic.
            if calendar.isDate(day, inSameDayAs: today) {
                guard let daysUntil = plant.daysUntilNextWatering, daysUntil <= 0 else { return nil }
                return plant
            }

            // Future: step forward through scheduled occurrences until we
            // either match `day` or pass it.
            guard let last = plant.lastWateredDate else { return nil }
            let interval = max(1, plant.wateringIntervalDays)
            var occurrence = calendar.startOfDay(for: last)
            while true {
                guard let next = calendar.date(byAdding: .day, value: interval, to: occurrence) else { return nil }
                occurrence = calendar.startOfDay(for: next)
                if occurrence == day { return plant }
                if occurrence > day { return nil }
            }
        }
    }

    // MARK: Static helpers

    private static func startOfMonth(for date: Date) -> Date {
        let cal = Calendar.current
        return cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
    }
}

// MARK: - DayCell

private struct DayCell: View {
    let date: Date
    let isInVisibleMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let actualCount: Int
    let scheduledCount: Int
    let action: () -> Void

    private var dayNumber: String {
        let day = Calendar.current.component(.day, from: date)
        return "\(day)"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayNumber)
                    .font(AquaTag.Typography.subhead)
                    .foregroundStyle(numberColor)
                    .frame(width: 28, height: 28)
                    .background(numberBackground)
                    .overlay(numberBorder)

                indicators.frame(height: 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? AquaTag.Colors.paper : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var numberColor: Color {
        if !isInVisibleMonth { return AquaTag.Colors.inkMute }
        return AquaTag.Colors.ink
    }

    @ViewBuilder
    private var numberBackground: some View {
        if isToday {
            Circle().fill(AquaTag.Colors.terracotta.opacity(0.15))
        } else {
            Circle().fill(Color.clear)
        }
    }

    @ViewBuilder
    private var numberBorder: some View {
        if isToday {
            Circle().strokeBorder(AquaTag.Colors.terracotta, lineWidth: 1.5)
        }
    }

    @ViewBuilder
    private var indicators: some View {
        let total = actualCount + scheduledCount
        if total == 0 {
            Color.clear
        } else {
            HStack(spacing: 3) {
                let actualsToShow = min(actualCount, 3)
                ForEach(0..<actualsToShow, id: \.self) { _ in
                    Circle()
                        .fill(AquaTag.Colors.moss)
                        .frame(width: 5, height: 5)
                }
                let scheduledShown = min(scheduledCount, max(0, 3 - actualsToShow))
                ForEach(0..<scheduledShown, id: \.self) { _ in
                    Circle()
                        .strokeBorder(AquaTag.Colors.moss, lineWidth: 1)
                        .frame(width: 5, height: 5)
                }
                if total > 3 {
                    Text("+\(total - 3)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(AquaTag.Colors.inkSoft)
                }
            }
        }
    }
}

// MARK: - Day detail rows

struct WateringEvent: Identifiable {
    let id = UUID()
    let plant: Plant
    let timestamp: Date
    let wateredBy: String
}

private struct DayDetailRow: View {
    let event: WateringEvent

    var body: some View {
        HStack(spacing: AquaTag.Spacing.md) {
            CharacterView(character: event.plant.character, size: .small)
            VStack(alignment: .leading, spacing: 2) {
                Text(event.plant.name)
                    .font(AquaTag.Typography.headline)
                    .foregroundStyle(AquaTag.Colors.ink)
                Text(L10n.Calendar.wateredBy(
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
                .foregroundStyle(AquaTag.Colors.moss)
        }
        .padding(.vertical, AquaTag.Spacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AquaTag.Colors.divider).frame(height: 0.5)
        }
    }
}

private struct ScheduledRow: View {
    let plant: Plant

    var body: some View {
        HStack(spacing: AquaTag.Spacing.md) {
            CharacterView(character: plant.character, size: .small)
            VStack(alignment: .leading, spacing: 2) {
                Text(plant.name)
                    .font(AquaTag.Typography.headline)
                    .foregroundStyle(AquaTag.Colors.ink)
                Text(taglineText)
                    .font(AquaTag.Typography.caption)
                    .foregroundStyle(AquaTag.Colors.inkSoft)
            }
            Spacer()
            Image(systemName: "drop")
                .font(.system(size: 14))
                .foregroundStyle(AquaTag.Colors.moss)
        }
        .padding(.vertical, AquaTag.Spacing.sm)
        .overlay(alignment: .bottom) {
            Rectangle().fill(AquaTag.Colors.divider).frame(height: 0.5)
        }
    }

    private var taglineText: String {
        guard let last = plant.lastWateredDate else {
            return ""
        }
        return L10n.Calendar.futureTagline(
            intervalDays: plant.wateringIntervalDays,
            lastWatered: DateFormatters.dayMonth.string(from: last)
        )
    }
}
