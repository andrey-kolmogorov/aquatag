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
                    pendingPlantID = handleAquaTagURL(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let url = activity.webpageURL else { return }
                    pendingPlantID = handleAquaTagURL(url)
                }
        }
        .modelContainer(for: [Plant.self, AppSettings.self, PendingWateringEvent.self, WateringLog.self])
    }

    init() {
        NotificationService.shared.setupNotificationCategories()
    }

    /// Parses AquaTag deep links into a plant ID.
    ///
    /// Accepts both the custom scheme written onto NFC tags and the HTTPS
    /// universal link used for QR codes / App Store fallback:
    /// - `aquatag://water/{plantID}`
    /// - `https://aquatag.app/water/{plantID}`
    ///
    /// Returns `nil` for anything else so callers can ignore unrelated URLs.
    func handleAquaTagURL(_ url: URL) -> String? {
        let plantID: String?

        switch (url.scheme?.lowercased(), url.host?.lowercased()) {
        case ("aquatag", "water"):
            plantID = url.pathComponents.last
        case ("https", "aquatag.app"), ("http", "aquatag.app"):
            let parts = url.pathComponents.filter { $0 != "/" }
            plantID = parts.count == 2 && parts[0].lowercased() == "water" ? parts[1] : nil
        default:
            plantID = nil
        }

        let trimmed = plantID?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let trimmed, !trimmed.isEmpty else {
            print("⚠️ Unrecognised AquaTag URL: \(url)")
            return nil
        }

        print("🏷️ AquaTag URL resolved to plant ID: \(trimmed)")
        return trimmed
    }
}
