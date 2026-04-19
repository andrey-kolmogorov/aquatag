//
//  CharacterCatalog.swift
//  AquaTag
//
//  Maps plant characters — Monty, Fernie, Cleo, Suzy, Ollie, Pip — to their
//  hero color and flag, per the brand bible.
//  One character per flag color (green, blue, yellow, red, pink, white).
//
//  This adds a `characterID: String` field to `Plant` (see HANDOFF.md →
//  "Model migration"). Existing plants without a characterID fall back
//  to the default "monty" character.
//

import SwiftUI

// MARK: - Identity

/// Case-iterable enum of the 6 hero characters.
/// Stored as `rawValue` string on `Plant.characterID` for forward compatibility.
/// Case order matches kit-box layout (green → blue → yellow → red → pink → white).
enum Character: String, CaseIterable, Identifiable, Codable {
    case monty     // green flag
    case fernie    // blue flag
    case suzy      // yellow flag
    case cleo      // red flag
    case ollie     // pink flag
    case pip       // white flag

    var id: String { rawValue }

    /// Display name for UI.
    var displayName: String {
        switch self {
        case .monty:   return "Monty"
        case .fernie:  return "Fernie"
        case .cleo:    return "Cleo"
        case .suzy:    return "Suzy"
        case .ollie:   return "Ollie"
        case .pip:     return "Pip"
        }
    }

    /// Species / archetype the character represents.
    var archetype: String {
        switch self {
        case .monty:   return "Monstera"
        case .fernie:  return "Fern"
        case .cleo:    return "Cactus"
        case .suzy:    return "Succulent"
        case .ollie:   return "Olive / Citrus"
        case .pip:     return "Pilea peperomioides"
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
        case .pip:     return Color("AT/Char/Pip")       // #F5F2EA (flag white)
        }
    }

    /// Image name in Assets.xcassets (PDF vector, supports dark mode).
    var imageName: String {
        "AT/Character/\(rawValue)"
    }

    /// Nationality flag per the stickers & flags pairing.
    /// See `stickers.html` in the design project for the locked set.
    /// Flag-stake color name (matches the six physical T-flag stakes shipped in the kit).
    /// Canonical hex values live on the Color asset sets in `AT/Char/*`.
    var flagColorName: String {
        switch self {
        case .monty:   return "green"   // #2DB489
        case .fernie:  return "blue"    // #1E6AA8
        case .suzy:    return "yellow"  // #E9B82A
        case .cleo:    return "red"     // #C8201E
        case .ollie:   return "pink"    // #E8388A
        case .pip:     return "white"   // #F5F2EA
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
        case .pip:     return 7
        }
    }

    /// Copy shown on the character picker card.
    var tagline: String {
        switch self {
        case .monty:   return "Big leaves, bigger drinks."
        case .fernie:  return "Keep me misted, keep me happy."
        case .cleo:    return "Forgetful owners welcome."
        case .suzy:    return "A little water goes a long way."
        case .ollie:   return "Mediterranean and chill."
        case .pip:     return "Round coin leaves, easy-going soul."
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
