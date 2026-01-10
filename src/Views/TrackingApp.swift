//
//  TrackingApp.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//


import SwiftUI
import SwiftData

/// Haupt-App Entry Point
@main
struct TrackingApp: App {
    
    // MARK: - App State
    
    @StateObject private var appViewModel = AppViewModel()
    
    // MARK: - SwiftData Container
    
    let modelContainer: ModelContainer
    
    init() {
        // Konfiguriere SwiftData Model Container
        do {
            modelContainer = try ModelContainer(
                for: User.self,
                    MoodEntry.self,
                    HealthDataEntry.self,
                    AppSettings.self
            )
        } catch {
            fatalError("Konnte ModelContainer nicht initialisieren: \(error)")
        }
    }
    
    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .modelContainer(modelContainer)
                .onAppear {
                    // Übergebe ModelContext an AppViewModel
                    appViewModel.modelContext = modelContainer.mainContext
                }
                .preferredColorScheme(nil) // Ermöglicht Dark Mode
        }
    }
}

/// Root View der App - zeigt Login oder Dashboard basierend auf Auth-Status
struct ContentView: View {
    
    @EnvironmentObject var appViewModel: AppViewModel
    
    var body: some View {
        Group {
            if appViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .animation(.easeInOut, value: appViewModel.isAuthenticated)
    }
}
