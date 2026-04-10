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
    @State private var pendingPlantID: String?

    var body: some Scene {
        WindowGroup {
            ContentView(pendingPlantID: $pendingPlantID)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
        .modelContainer(for: [Plant.self, AppSettings.self, PendingWateringEvent.self])
    }

    init() {
        NotificationService.shared.setupNotificationCategories()
    }

    private func handleIncomingURL(_ url: URL) {
        // Handle aquatag://water/{plantID}
        guard url.scheme == "aquatag",
              url.host == "water",
              let plantID = url.pathComponents.last,
              !plantID.isEmpty,
              plantID != "/" else {
            print("⚠️ Invalid URL: \(url)")
            return
        }

        print("🏷️ Background NFC tag opened app with plant ID: \(plantID)")
        pendingPlantID = plantID
    }
}
