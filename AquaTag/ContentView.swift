//
//  ContentView.swift
//  AquaTag — redesigned
//
//  Customises the TabBar appearance to match brand colors.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Binding var pendingPlantID: String?
    @State private var selectedTab = 0

    init(pendingPlantID: Binding<String?>) {
        self._pendingPlantID = pendingPlantID

        // Brand the tab bar
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AquaTag.Colors.paper)
        appearance.shadowColor = UIColor(AquaTag.Colors.divider)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.selected.iconColor = UIColor(AquaTag.Colors.moss)
        itemAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AquaTag.Colors.moss)
        ]
        itemAppearance.normal.iconColor = UIColor(AquaTag.Colors.inkMute)
        itemAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(AquaTag.Colors.inkMute)
        ]
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            PlantListView(pendingPlantID: $pendingPlantID)
                .tabItem { Label(L10n.Tabs.plants, systemImage: "leaf.fill") }
                .tag(0)
            CalendarView()
                .tabItem { Label(L10n.Tabs.calendar, systemImage: "calendar") }
                .tag(1)
            SettingsView()
                .tabItem { Label(L10n.Tabs.settings, systemImage: "gear") }
                .tag(2)
        }
        .tint(AquaTag.Colors.moss)
        .onChange(of: pendingPlantID) { _, new in
            if new != nil { selectedTab = 0 }
        }
    }
}
