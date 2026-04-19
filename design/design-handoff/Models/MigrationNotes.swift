//
//  MigrationNotes.swift
//  AquaTag — handoff docs (not compiled into app target; informational)
//
//  =======================================================================
//  PLANT MODEL MIGRATION
//  =======================================================================
//  The new designs add a `characterID` field to Plant, which stores the
//  rawValue of the `Character` enum (e.g. "monty", "fernie"). Existing
//  plants have NO characterID — they fall back to .monty via the
//  `Plant.character` computed property.
//
//  RECOMMENDED: add the new property as OPTIONAL with a default of nil.
//  SwiftData handles this as a lightweight migration automatically — no
//  schema version bump required for iOS 17+.
//
//  -----------------------------------------------------------------------
//  BEFORE (AquaTag/Models/Plant.swift):
//  -----------------------------------------------------------------------
//    var id: String
//    var name: String
//    var emoji: String
//    var wateringIntervalDays: Int
//    …
//
//  -----------------------------------------------------------------------
//  AFTER:
//  -----------------------------------------------------------------------
//    var id: String
//    var name: String
//    var emoji: String                   // kept for backward compat
//    var characterID: String?            // NEW — stores Character.rawValue
//    var wateringIntervalDays: Int
//    …
//
//  And add to `init(...)`:
//    characterID: String? = nil
//
//  -----------------------------------------------------------------------
//  OPTIONAL BACKFILL
//  -----------------------------------------------------------------------
//  To migrate existing plants from their emoji to a character, add a
//  one-shot migration at app start (AquaTagApp.swift, inside a Task):
//
//    @MainActor
//    func backfillCharacters(modelContext: ModelContext) {
//        let descriptor = FetchDescriptor<Plant>(
//            predicate: #Predicate { $0.characterID == nil }
//        )
//        guard let plants = try? modelContext.fetch(descriptor) else { return }
//        for plant in plants {
//            plant.characterID = Self.guessCharacter(emoji: plant.emoji).rawValue
//        }
//        try? modelContext.save()
//    }
//
//    static func guessCharacter(emoji: String) -> Character {
//        switch emoji {
//        case "🌿", "🪴", "🌱": return .monty
//        case "🎋", "☘️", "🍀": return .fernie
//        case "🌵":             return .cleo
//        case "🌺", "🌷", "🥀": return .suzy
//        case "🌳", "🌲", "🌴": return .ollie
//        default:               return .monty
//        }
//    }
//
//  =======================================================================
//  APPSETTINGS — NO CHANGES REQUIRED
//  =======================================================================
//  All existing fields are preserved. The new Settings screen uses the
//  same bindings via SettingsViewModel.
//
//  =======================================================================
//  PENDINGWATERINGEVENT — NO CHANGES REQUIRED
//  =======================================================================

import Foundation
