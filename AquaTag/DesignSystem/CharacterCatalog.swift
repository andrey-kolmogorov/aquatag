//
//  CharacterCatalog.swift
//  AquaTag
//
//  Maps plant characters — Monty, Fernie, Cleo, Suzy, Ollie — to their
//  hero color and nationality flag, per the brand bible.
//
//  This adds a `characterID: String` field to `Plant` (see HANDOFF.md →
//  "Model migration"). Existing plants without a characterID fall back
//  to the default "monty" character.
//

import SwiftUI

// MARK: - Identity

/// Case-iterable enum of the 5 hero characters.
/// Stored as `rawValue` string on `Plant.characterID` for forward compatibility.
enum Character: String, CaseIterable, Identifiable, Codable {
    case monty
    case fernie
    case cleo
    case suzy
    case ollie

    var id: String { rawValue }

    /// Display name for UI.
    var displayName: String {
        switch self {
        case .monty:   return "Monty"
        case .fernie:  return "Fernie"
        case .cleo:    return "Cleo"
        case .suzy:    return "Suzy"
        case .ollie:   return "Ollie"
        }
    }

    /// Species / archetype the character represents.
    var archetype: String {
        switch self {
        case .monty:   return String(localized: "character.monty.archetype")
        case .fernie:  return String(localized: "character.fernie.archetype")
        case .cleo:    return String(localized: "character.cleo.archetype")
        case .suzy:    return String(localized: "character.suzy.archetype")
        case .ollie:   return String(localized: "character.ollie.archetype")
        }
    }

    /// Character hero color (pulled from the sticker artwork).
    var color: Color {
        switch self {
        case .monty:   return AquaTag.Colors.moss
        case .fernie:  return Color("AT/Char/Fernie")    // #4FA96A
        case .cleo:    return Color("AT/Char/Cleo")      // #D97757
        case .suzy:    return Color("AT/Char/Suzy")      // #C9A54D
        case .ollie:   return Color("AT/Char/Ollie")     // #6B8E3F
        }
    }

    /// Image name in Assets.xcassets (PDF vector, supports dark mode).
    var imageName: String {
        "AT/Character/\(rawValue)"
    }

    /// Nationality flag per the stickers & flags pairing.
    /// See `stickers.html` in the design project for the locked set.
    var flag: String {
        switch self {
        case .monty:   return "🇲🇽"  // Mexico — Monstera native
        case .fernie:  return "🇳🇿"  // New Zealand — tree fern
        case .cleo:    return "🇺🇸"  // US southwest — saguaro
        case .suzy:    return "🇿🇦"  // South Africa — succulent
        case .ollie:   return "🇬🇷"  // Greece — olive
        }
    }

    /// Default watering cadence (days) per species — used as suggestion
    /// when creating a new plant with this character.
    var suggestedIntervalDays: Int {
        switch self {
        case .monty:   return 7
        case .fernie:  return 4
        case .cleo:    return 21
        case .suzy:    return 14
        case .ollie:   return 10
        }
    }

    /// Copy shown on the character picker card.
    var tagline: String {
        switch self {
        case .monty:   return String(localized: "character.monty.tagline")
        case .fernie:  return String(localized: "character.fernie.tagline")
        case .cleo:    return String(localized: "character.cleo.tagline")
        case .suzy:    return String(localized: "character.suzy.tagline")
        case .ollie:   return String(localized: "character.ollie.tagline")
        }
    }
}

// MARK: - Plant convenience

extension Plant {
    /// Resolve the character enum from the stored `characterID`.
    /// Falls back to `.monty` for legacy records without one.
    var character: Character {
        get { Character(rawValue: characterID ?? "") ?? .monty }
        set { characterID = newValue.rawValue }
    }
}
