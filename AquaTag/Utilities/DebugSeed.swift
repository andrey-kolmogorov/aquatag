//
//  DebugSeed.swift
//  AquaTag
//
//  Debug-only sample data generator. Compiled into DEBUG builds so the
//  Settings screen can offer "Seed sample data" / "Wipe all data" actions
//  for App Store screenshot capture and visual QA. Not shipped in release.
//

#if DEBUG

import Foundation
import SwiftData

enum DebugSeed {
    /// Wipes plants, watering logs, pending events, and seeds 6 plants
    /// (one per character) plus ~6 weeks of realistic watering history.
    @MainActor
    static func seed(into modelContext: ModelContext) {
        wipe(in: modelContext)

        let now = Date()
        let calendar = Calendar.current
        let device = "iPhone"

        // Blueprint: (character, plant name, days since last watered).
        // The "lastDaysAgo" value is hand-picked to give a realistic mix of
        // badge states for screenshots: overdue, due today, tomorrow, and
        // not-yet-due plants all appear together.
        let blueprint: [(character: Character, name: String, lastDaysAgo: Int)] = [
            (.monty,  "Monstera",        9),  // interval 7  → overdue by 2
            (.fernie, "Boston Fern",     5),  // interval 4  → overdue by 1
            (.cleo,   "Cleo Cactus",    21),  // interval 21 → due today
            (.suzy,   "Echeveria",      13),  // interval 14 → tomorrow
            (.ollie,  "Sunny Sunflower", 6),  // interval 10 → in 4 days
            (.pip,    "Pip the Pilea",   2)   // interval 7  → in 5 days
        ]

        for (character, name, lastDaysAgo) in blueprint {
            let interval = character.suggestedIntervalDays
            let plant = Plant(
                id: PlantIDGenerator.generateID(from: name),
                name: name,
                emoji: "🌿",
                characterID: character.rawValue,
                wateringIntervalDays: interval
            )
            modelContext.insert(plant)

            // Generate one watering every `interval` days going back ~42
            // days, anchored on `lastDaysAgo` so the most recent log matches
            // the plant's status. Small jitter on older entries keeps the
            // heatmap from looking artificially uniform.
            let totalDays = 42
            var offset = lastDaysAgo
            var first = true
            while offset <= totalDays {
                let jitter = first ? 0 : Int.random(in: -1...1)
                let actualOffset = max(0, min(totalDays, offset + jitter))
                if let logDate = calendar.date(byAdding: .day, value: -actualOffset, to: now) {
                    let log = WateringLog(
                        plantID: plant.id,
                        timestamp: noisyTime(on: logDate, calendar: calendar),
                        wateredBy: device
                    )
                    modelContext.insert(log)
                }
                offset += interval
                first = false
            }

            plant.lastWateredDate = calendar.date(byAdding: .day, value: -lastDaysAgo, to: now)
            plant.lastWateredBy = device
        }

        try? modelContext.save()
    }

    /// Removes every Plant, WateringLog, and PendingWateringEvent.
    /// Settings (HA URL, notification prefs) are preserved.
    @MainActor
    static func wipe(in modelContext: ModelContext) {
        do {
            try modelContext.delete(model: WateringLog.self)
            try modelContext.delete(model: PendingWateringEvent.self)
            try modelContext.delete(model: Plant.self)
            try modelContext.save()
        } catch {
            print("⚠️ DebugSeed.wipe failed: \(error)")
        }
    }

    /// Returns the same calendar date with a random hour/minute so logged
    /// timestamps look like real waterings rather than midnight UTC.
    private static func noisyTime(on date: Date, calendar: Calendar) -> Date {
        var comps = calendar.dateComponents([.year, .month, .day], from: date)
        comps.hour = Int.random(in: 7...20)
        comps.minute = Int.random(in: 0...59)
        return calendar.date(from: comps) ?? date
    }
}

#endif
