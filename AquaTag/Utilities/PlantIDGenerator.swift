//
//  PlantIDGenerator.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation

struct PlantIDGenerator {
    /// Converts a plant name to a URL-safe slug
    /// Example: "Monstera Deliciosa" -> "monstera_deliciosa"
    static func generateID(from name: String) -> String {
        let lowercased = name.lowercased()
        let alphanumeric = lowercased.replacingOccurrences(
            of: "[^a-z0-9]+",
            with: "_",
            options: .regularExpression
        )
        let trimmed = alphanumeric.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        
        return trimmed.isEmpty ? "plant_\(UUID().uuidString.prefix(8))" : trimmed
    }
}
