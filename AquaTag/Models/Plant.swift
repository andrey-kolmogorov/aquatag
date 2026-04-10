//
//  Plant.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation
import SwiftData

@Model
class Plant {
    var id: String              // unique slug e.g. "monstera"
    var name: String            // display name e.g. "Monstera Deliciosa"
    var emoji: String           // e.g. "🌿"
    var wateringIntervalDays: Int  // how often to water
    var lastWateredDate: Date?
    var lastWateredBy: String?  // device name
    var notes: String
    var createdAt: Date
    var nfcTagID: String?       // raw NFC hardware UID (optional backup identifier)
    
    init(
        id: String,
        name: String,
        emoji: String = "🌿",
        wateringIntervalDays: Int = 7,
        lastWateredDate: Date? = nil,
        lastWateredBy: String? = nil,
        notes: String = "",
        createdAt: Date = Date(),
        nfcTagID: String? = nil
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.wateringIntervalDays = wateringIntervalDays
        self.lastWateredDate = lastWateredDate
        self.lastWateredBy = lastWateredBy
        self.notes = notes
        self.createdAt = createdAt
        self.nfcTagID = nfcTagID
    }
    
    // Computed properties for UI
    var nextWateringDate: Date? {
        guard let lastWatered = lastWateredDate else { return nil }
        return Calendar.current.date(
            byAdding: .day,
            value: wateringIntervalDays,
            to: lastWatered
        )
    }
    
    var daysSinceLastWatered: Int? {
        guard let lastWatered = lastWateredDate else { return nil }
        return Calendar.current.dateComponents(
            [.day],
            from: lastWatered,
            to: Date()
        ).day
    }
    
    var daysUntilNextWatering: Int? {
        guard let nextWatering = nextWateringDate else { return nil }
        return Calendar.current.dateComponents(
            [.day],
            from: Date(),
            to: nextWatering
        ).day
    }
    
    var wateringStatus: WateringStatus {
        guard let daysUntil = daysUntilNextWatering else {
            return .unknown
        }
        
        if daysUntil < 0 {
            return .overdue
        } else if daysUntil <= 1 {
            return .dueSoon
        } else {
            return .ok
        }
    }
    
    var haEntityID: String {
        "input_datetime.plant_\(id)_last_watered"
    }
}

enum WateringStatus {
    case ok
    case dueSoon
    case overdue
    case unknown
    
    var color: String {
        switch self {
        case .ok: return "green"
        case .dueSoon: return "orange"
        case .overdue: return "red"
        case .unknown: return "gray"
        }
    }
    
    var label: String {
        switch self {
        case .ok: return "OK"
        case .dueSoon: return "Due Soon"
        case .overdue: return "Overdue!"
        case .unknown: return "Not Watered Yet"
        }
    }
}
