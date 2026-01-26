//
//  Models.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//


import Foundation
import SwiftData
import SwiftUI
/// Model für Benutzer-Stammdaten
@Model
final class User {
    @Attribute(.unique) var id: UUID
    var email: String
    var name: String
    var age: Int?
    var weight: Double?  // in kg
    var height: Double?  // in cm
    var gender: String?
    var createdAt: Date
    var updatedAt: Date
    
    // Beziehung zu Gefühls-Einträgen
    @Relationship(deleteRule: .cascade)
    var moodEntries: [MoodEntry]
    
    // Beziehung zu Health-Daten Einträgen
    @Relationship(deleteRule: .cascade)
    var healthEntries: [HealthDataEntry]
    
    init(email: String, name: String) {
        self.id = UUID()
        self.email = email
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.moodEntries = []
        self.healthEntries = []
    }
    
    /// Aktualisiert das updatedAt Datum
    func updateTimestamp() {
        self.updatedAt = Date()
    }
}

/// Enum für Gefühlszustände
enum MoodType: String, Codable, CaseIterable {
    case veryHappy = "Sehr glücklich"
    case happy = "Glücklich"
    case neutral = "Neutral"
    case sad = "Traurig"
    case verySad = "Sehr traurig"
    case anxious = "Ängstlich"
    case stressed = "Gestresst"
    case calm = "Ruhig"
    case energetic = "Energiegeladen"
    case tired = "Müde"
    
    /// Symbol für die UI-Darstellung
    var symbol: String {
        switch self {
        case .veryHappy: return "😄"
        case .happy: return "🙂"
        case .neutral: return "😐"
        case .sad: return "😔"
        case .verySad: return "😢"
        case .anxious: return "😰"
        case .stressed: return "😫"
        case .calm: return "😌"
        case .energetic: return "⚡"
        case .tired: return "😴"
        }
    }
    
    /// Numerischer Wert für Graphen (1-10 Skala)
    var numericValue: Double {
        switch self {
        case .veryHappy, .energetic: return 9.0
        case .happy, .calm: return 7.0
        case .neutral: return 5.0
        case .tired: return 4.0
        case .sad, .anxious: return 3.0
        case .verySad, .stressed: return 1.0
        }
    }
}

/// Model für Gefühls-Einträge (Tagebuch)
@Model
final class MoodEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var moodType: MoodType
    var notes: String?
    var intensity: Int  // 1-10 Skala
    
    // Optional: Kontext-Informationen
    var triggers: [String]?  // Was hat das Gefühl ausgelöst
    var activities: [String]?  // Was wurde gemacht
    
    init(moodType: MoodType, notes: String? = nil, intensity: Int = 5) {
        self.id = UUID()
        self.date = Date()
        self.moodType = moodType
        self.notes = notes
        self.intensity = min(max(intensity, 1), 10)  // Zwischen 1 und 10
    }
}

/// Model für Health-Daten Einträge
@Model
final class HealthDataEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    
    // Health Metrics
    var steps: Int?
    var calories: Double?  // kcal
    var sleepHours: Double?  // Stunden
    var waterIntake: Double?  // Liter
    
    // Flags für manuelle vs. automatische Daten
    var stepsManuallyEdited: Bool
    var caloriesManuallyEdited: Bool
    var sleepManuallyEdited: Bool
    var waterManuallyEdited: Bool
    
    init(date: Date = Date()) {
        self.id = UUID()
        self.date = date
        self.stepsManuallyEdited = false
        self.caloriesManuallyEdited = false
        self.sleepManuallyEdited = false
        self.waterManuallyEdited = false
    }
    
    /// Aktualisiert Schritte (markiert als manuell editiert wenn überschrieben)
    func updateSteps(_ steps: Int, manual: Bool = false) {
        self.steps = steps
        if manual {
            self.stepsManuallyEdited = true
        }
    }
    
    /// Aktualisiert Kalorien
    func updateCalories(_ calories: Double, manual: Bool = false) {
        self.calories = calories
        if manual {
            self.caloriesManuallyEdited = true
        }
    }
    
    /// Aktualisiert Schlaf
    func updateSleep(_ hours: Double, manual: Bool = false) {
        self.sleepHours = hours
        if manual {
            self.sleepManuallyEdited = true
        }
    }
    
    /// Aktualisiert Wasseraufnahme
    func updateWater(_ liters: Double, manual: Bool = false) {
        self.waterIntake = liters
        if manual {
            self.waterManuallyEdited = true
        }
    }
}

/// Model für App-Einstellungen
@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    
    // Benachrichtigungs-Einstellungen
    var notificationsEnabled: Bool
    var dailyReminderTime: Date?  // Uhrzeit für tägliche Erinnerung
    
    // UI-Einstellungen
    var preferredLanguage: String  // "de", "en", "fr"
    
    // Health-Sync Einstellungen
    var autoSyncHealthData: Bool
    var lastHealthSync: Date?
    
    init() {
        self.id = UUID()
        self.notificationsEnabled = true
        self.preferredLanguage = "de"
        self.autoSyncHealthData = true
        
        // Standard: 20:00 Uhr
        let calendar = Calendar.current
        let components = DateComponents(hour: 20, minute: 0)
        self.dailyReminderTime = calendar.date(from: components)
    }
}

/// Model für den Chat (KI)
@Model
class Chatbot{
    @Attribute(.unique) var id: UUID
    
    //Parameter für die Unterhaltung
    var text: String
    var timestamp: Date
    
    init(text:String){
        self.id = UUID()
        self.text = text
        self.timestamp = Date()
    }
}

//enum Theme
enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Hell"
        case .dark: return "Dunkel"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
