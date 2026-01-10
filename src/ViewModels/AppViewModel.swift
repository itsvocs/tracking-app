//
//  AppViewModel.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//


import Foundation
import SwiftUI
import SwiftData
import Combine

/// Haupt-ViewModel für App-weiten State
/// Verwaltet Authentifizierung und zentrale App-Logik
@MainActor
class AppViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Services
    private let healthKitManager = HealthKitManager.shared
    private let notificationManager = NotificationManager.shared
    
    // SwiftData Context
    var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication
    
    /// Prüft ob ein Nutzer bereits eingeloggt ist
    private func checkAuthenticationStatus() {
        // TODO: Hier würde die Google Sign-In Session geprüft werden
        // Für jetzt simulieren wir dies über UserDefaults
        
        if let userEmail = UserDefaults.standard.string(forKey: "currentUserEmail") {
            loadUser(email: userEmail)
        }
    }
    
    /// Lädt den aktuellen Nutzer aus der Datenbank
    private func loadUser(email: String) {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.email == email
            }
        )
        
        do {
            let users = try context.fetch(descriptor)
            if let user = users.first {
                currentUser = user
                isAuthenticated = true
            }
        } catch {
            print("Fehler beim Laden des Nutzers: \(error)")
        }
    }
    
    /// Führt Google Sign-In durch
    /// - Parameters:
    ///   - email: E-Mail des Nutzers
    ///   - name: Name des Nutzers
    func signInWithGoogle(email: String, name: String) async {
        isLoading = true
        errorMessage = nil
        
        // Simuliere Sign-In Prozess
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        guard let context = modelContext else {
            errorMessage = "Datenbank nicht verfügbar"
            isLoading = false
            return
        }
        
        // Prüfe ob Nutzer bereits existiert
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.email == email
            }
        )
        
        do {
            let existingUsers = try context.fetch(descriptor)
            
            if let user = existingUsers.first {
                // Nutzer existiert bereits
                currentUser = user
            } else {
                // Neuen Nutzer erstellen
                let newUser = User(email: email, name: name)
                context.insert(newUser)
                try context.save()
                currentUser = newUser
                
                // Initiale Einstellungen erstellen
                let settings = AppSettings()
                context.insert(settings)
                try context.save()
            }
            
            // Speichere Session
            UserDefaults.standard.set(email, forKey: "currentUserEmail")
            isAuthenticated = true
            
            // Fordere Berechtigungen an
            await requestPermissions()
            
        } catch {
            errorMessage = "Fehler beim Anmelden: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Meldet den Nutzer ab
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "currentUserEmail")
        currentUser = nil
        isAuthenticated = false
    }
    
    // MARK: - Permissions
    
    /// Fordert alle benötigten Berechtigungen an
    private func requestPermissions() async {
        // HealthKit Berechtigung
        if healthKitManager.isHealthDataAvailable {
            do {
                try await healthKitManager.requestAuthorization()
            } catch {
                print("HealthKit Berechtigung fehlgeschlagen: \(error)")
            }
        }
        
        // Benachrichtigungs-Berechtigung
        do {
            _ = try await notificationManager.requestAuthorization()
        } catch {
            print("Notification Berechtigung fehlgeschlagen: \(error)")
        }
    }
    
    // MARK: - User Profile
    
    /// Aktualisiert das Nutzerprofil
    func updateUserProfile(age: Int?, weight: Double?, height: Double?, gender: String?) {
        guard let user = currentUser else { return }
        
        user.age = age
        user.weight = weight
        user.height = height
        user.gender = gender
        user.updateTimestamp()
        
        do {
            try modelContext?.save()
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }
}
