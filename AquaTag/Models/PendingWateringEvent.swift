//
//  PendingWateringEvent.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import Foundation
import SwiftData

@Model
class PendingWateringEvent {
    var plantID: String
    var plantName: String
    var deviceName: String
    var timestamp: Date
    var createdAt: Date
    
    init(
        plantID: String,
        plantName: String,
        deviceName: String,
        timestamp: Date,
        createdAt: Date = Date()
    ) {
        self.plantID = plantID
        self.plantName = plantName
        self.deviceName = deviceName
        self.timestamp = timestamp
        self.createdAt = createdAt
    }
}
