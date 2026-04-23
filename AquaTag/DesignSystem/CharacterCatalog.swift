//
//  CharacterCatalog.swift
//  AquaTag
//
//  Maps plant characters — Monty, Fernie, Suzy, Cleo, Ollie, Pip — to their
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
    case cleo      // yellow flag — cactus
    case suzy      // red flag — succulent
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

    /// Species / archetype the character represents. Localised.
    var archetype: String {
        switch self {
        case .monty:   return String(localized: "character.monty.archetype")
        case .fernie:  return String(localized: "character.fernie.archetype")
        case .cleo:    return String(localized: "character.cleo.archetype")
        case .suzy:    return String(localized: "character.suzy.archetype")
        case .ollie:   return String(localized: "character.ollie.archetype")
        case .pip:     return String(localized: "character.pip.archetype")
        }
    }

    /// Character hero color (pulled from the sticker artwork).
    var color: Color {
        switch self {
        case .monty:   return Color("AT/Char/Monty")     // #2DB489 green
        case .fernie:  return Color("AT/Char/Fernie")    // #1E6AA8 blue
        case .cleo:    return Color("AT/Char/Cleo")      // #F0DC5A yellow
        case .suzy:    return Color("AT/Char/Suzy")      // #C8201E red
        case .ollie:   return Color("AT/Char/Ollie")     // #E8388A pink
        case .pip:     return Color("AT/Char/Pip")       // #F5F2EA white
        }
    }

    /// Image name in Assets.xcassets (SVG vector, supports dark mode).
    var imageName: String {
        "AT/Character/\(rawValue)"
    }

    /// Flag-stake color name (matches the six physical T-flag stakes shipped in the kit).
    /// Canonical hex values live on the Color asset sets in `AT/Char/*`.
    var flagColorName: String {
        switch self {
        case .monty:   return "green"   // #2DB489
        case .fernie:  return "blue"    // #1E6AA8
        case .cleo:    return "yellow"  // #F0DC5A
        case .suzy:    return "red"     // #C8201E
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

    /// Copy shown on the character picker card. Localised.
    var tagline: String {
        switch self {
        case .monty:   return String(localized: "character.monty.tagline")
        case .fernie:  return String(localized: "character.fernie.tagline")
        case .cleo:    return String(localized: "character.cleo.tagline")
        case .suzy:    return String(localized: "character.suzy.tagline")
        case .ollie:   return String(localized: "character.ollie.tagline")
        case .pip:     return String(localized: "character.pip.tagline")
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
