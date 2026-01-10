//
//  MoodViewModel.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

/// ViewModel für Gefühls-Tracking (Stimmungstagebuch)
@MainActor
class MoodViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var todayMoodEntry: MoodEntry?
    @Published var recentMoodEntries: [MoodEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // For mood input
    @Published var selectedMood: MoodType = .neutral
    @Published var moodIntensity: Int = 5
    @Published var moodNotes: String = ""
    
    // SwiftData Context
    var modelContext: ModelContext?
    var currentUser: User?
    
    // MARK: - Load Data
    
    /// Lädt den heutigen Gefühls-Eintrag
    func loadTodayMoodEntry() {
        guard let context = modelContext else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let descriptor = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { entry in
                entry.date >= today && entry.date < tomorrow
            }
        )
        
        do {
            let entries = try context.fetch(descriptor)
            todayMoodEntry = entries.first
            
            // Wenn ein Eintrag existiert, lade die Werte
            if let entry = entries.first {
                selectedMood = entry.moodType
                moodIntensity = entry.intensity
                moodNotes = entry.notes ?? ""
            }
        } catch {
            errorMessage = "Fehler beim Laden: \(error.localizedDescription)"
        }
    }
    
    /// Lädt die letzten Gefühls-Einträge
    func loadRecentMoodEntries(limit: Int = 30) {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<MoodEntry>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let allEntries = try context.fetch(descriptor)
            recentMoodEntries = Array(allEntries.prefix(limit))
        } catch {
            errorMessage = "Fehler beim Laden: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Save Mood Entry
    
    /// Speichert einen neuen Gefühls-Eintrag oder aktualisiert den heutigen
    func saveMoodEntry() {
        guard let context = modelContext,
              let user = currentUser else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            if let existingEntry = todayMoodEntry {
                // Update existierenden Eintrag
                existingEntry.moodType = selectedMood
                existingEntry.intensity = moodIntensity
                existingEntry.notes = moodNotes.isEmpty ? nil : moodNotes
            } else {
                // Erstelle neuen Eintrag
                let newEntry = MoodEntry(
                    moodType: selectedMood,
                    notes: moodNotes.isEmpty ? nil : moodNotes,
                    intensity: moodIntensity
                )
                context.insert(newEntry)
                user.moodEntries.append(newEntry)
                todayMoodEntry = newEntry
            }
            
            try context.save()
            
            // Lade aktuelle Einträge neu
            loadRecentMoodEntries()
            
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Löscht einen Gefühls-Eintrag
    func deleteMoodEntry(_ entry: MoodEntry) {
        guard let context = modelContext else { return }
        
        context.delete(entry)
        
        do {
            try context.save()
            loadRecentMoodEntries()
            
            // Wenn der gelöschte Eintrag der heutige war, setze zurück
            if entry.id == todayMoodEntry?.id {
                todayMoodEntry = nil
                resetInput()
            }
        } catch {
            errorMessage = "Fehler beim Löschen: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Input Management
    
    /// Setzt die Eingabefelder zurück
    func resetInput() {
        selectedMood = .neutral
        moodIntensity = 5
        moodNotes = ""
    }
    
    // MARK: - Statistics
    
    /// Berechnet die häufigste Stimmung in den letzten 7 Tagen
    func getMostFrequentMoodLastWeek() -> MoodType? {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let recentEntries = recentMoodEntries.filter { $0.date >= weekAgo }
        
        guard !recentEntries.isEmpty else { return nil }
        
        let moodCounts = Dictionary(grouping: recentEntries, by: { $0.moodType })
            .mapValues { $0.count }
        
        return moodCounts.max(by: { $0.value < $1.value })?.key
    }
    
    /// Berechnet den durchschnittlichen Stimmungswert (1-10) für einen Zeitraum
    func getAverageMoodValue(days: Int = 7) -> Double {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let entries = recentMoodEntries.filter { $0.date >= startDate }
        
        guard !entries.isEmpty else { return 5.0 }
        
        let total = entries.reduce(0.0) { $0 + $1.moodType.numericValue }
        return total / Double(entries.count)
    }
    
    /// Gibt Stimmungsdaten für Graphen zurück
    func getMoodDataForChart(days: Int = 7) -> [(date: Date, value: Double)] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let entries = recentMoodEntries.filter { $0.date >= startDate }
        
        return entries.map { entry in
            (date: entry.date, value: entry.moodType.numericValue)
        }.sorted { $0.date < $1.date }
    }
    
    /// Gibt Mood-Verteilung zurück (für Pie Chart o.ä.)
    func getMoodDistribution(days: Int = 30) -> [MoodType: Int] {
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let entries = recentMoodEntries.filter { $0.date >= startDate }
        
        var distribution: [MoodType: Int] = [:]
        
        for entry in entries {
            distribution[entry.moodType, default: 0] += 1
        }
        
        return distribution
    }
    
    // MARK: - Insights
    
    /// Generiert einfache Insights basierend auf Stimmungsdaten
    func generateInsights() -> [String] {
        var insights: [String] = []
        
        // Durchschnittliche Stimmung
        let avgMood = getAverageMoodValue()
        if avgMood >= 7.0 {
            insights.append("Deine Stimmung war in der letzten Woche überwiegend positiv!")
        } else if avgMood <= 4.0 {
            insights.append("Du hattest eine herausfordernde Woche. Denke daran, dir Zeit für dich selbst zu nehmen.")
        }
        
        // Häufigste Stimmung
        if let mostFrequent = getMostFrequentMoodLastWeek() {
            insights.append("Am häufigsten fühltest du dich: \(mostFrequent.rawValue)")
        }
        
        // Konsistenz
        let entries = recentMoodEntries.prefix(7)
        if entries.count >= 5 {
            insights.append("Gut gemacht! Du hast regelmäßig deine Stimmung erfasst.")
        }
        
        return insights
    }
}
