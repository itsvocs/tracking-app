//
//  MainTabView.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//

import SwiftUI

/// Haupt-Tab Navigation der App
struct MainTabView: View {
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard / Home
            HomeView()
                .tabItem {
                    Label("Übersicht", systemImage: "house.fill")
                }
                .tag(0)
            
            // Mood Tracking
            MoodTrackingView()
                .tabItem {
                    Label("Gefühle", systemImage: "heart.fill")
                }
                .tag(1)
            
            // Statistics / Charts
            StatisticsView()
                .tabItem {
                    Label("Statistiken", systemImage: "chart.bar.fill")
                }
                .tag(2)
            
            // Settings
            SettingsView()
                .tabItem {
                    Label("Einstellungen", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppViewModel())
}
