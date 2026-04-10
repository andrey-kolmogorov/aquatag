//
//  ContentView.swift
//  AquaTag
//
//  Created by Andrei Kolmogorov on 05.04.26.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Binding var pendingPlantID: String?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            PlantListView(pendingPlantID: $pendingPlantID)
                .tabItem {
                    Label("Plants", systemImage: "leaf.fill")
                }
                .tag(0)

            WateringHistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(1)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .onChange(of: pendingPlantID) { _, newValue in
            if newValue != nil {
                selectedTab = 0
            }
        }
    }
}

#Preview {
    @Previewable @State var pendingPlantID: String? = nil
    ContentView(pendingPlantID: $pendingPlantID)
        .modelContainer(for: [Plant.self, AppSettings.self, PendingWateringEvent.self])
}
