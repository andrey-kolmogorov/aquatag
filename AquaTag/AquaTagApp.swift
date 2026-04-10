//
//  AquaTagApp.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import SwiftUI
import SwiftData

@main
struct AquaTagApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Plant.self, AppSettings.self, PendingWateringEvent.self])
    }
    
    init() {
        // Setup notification categories
        NotificationService.shared.setupNotificationCategories()
    }
}
