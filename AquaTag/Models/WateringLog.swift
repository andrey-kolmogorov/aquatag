//
//  WateringLog.swift
//  AquaTag
//

import Foundation
import SwiftData

@Model
class WateringLog {
    var id: UUID
    var plantID: String
    var timestamp: Date
    var wateredBy: String?

    init(
        id: UUID = UUID(),
        plantID: String,
        timestamp: Date = Date(),
        wateredBy: String? = nil
    ) {
        self.id = id
        self.plantID = plantID
        self.timestamp = timestamp
        self.wateredBy = wateredBy
    }
}
