//
//  HealthViewModel.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//

import Foundation
import SwiftUI
import SwiftData
import Combine

/// ViewModel für Health-Daten Management
@MainActor
class HealthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var todayHealthData: HealthDataEntry?
    @Published var isLoadingHealthData = false
    @Published var isSyncingWithHealthKit = false
    @Published var errorMessage: String?
    
    // Historical data for charts
    @Published var weeklyStepsData: [(date: Date, steps: Int)] = []
    @Published var weeklyCaloriesData: [(date: Date, calories: Double)] = []
    
    // Services
    private let healthKitManager = HealthKitManager.shared
    
    // SwiftData Context
    var modelContext: ModelContext?
    var currentUser: User?
    
    // MARK: - Fetch Today's Data
    
    /// Lädt die heutigen Gesundheitsdaten
    func loadTodayHealthData() {
        guard let context = modelContext,
              let user = currentUser else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Berechne tomorrow VORHER, nicht im Predicate
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) else { return }
        
        // Nutze die berechneten Werte direkt im Predicate
        let descriptor = FetchDescriptor<HealthDataEntry>(
            predicate: #Predicate<HealthDataEntry> { entry in
                entry.date >= today && entry.date < tomorrow
            }
        )
        
        do {
            let entries = try context.fetch(descriptor)
            
            if let entry = entries.first {
                todayHealthData = entry
            } else {
                let newEntry = HealthDataEntry(date: today)
                context.insert(newEntry)
                user.healthEntries.append(newEntry)
                try context.save()
                todayHealthData = newEntry
            }
        } catch {
            errorMessage = "Fehler beim Laden der Daten: \(error.localizedDescription)"
        }
    }
    
    
    // MARK: - Sync with HealthKit
    
    /// Synchronisiert mit Apple Health
    func syncWithHealthKit() async {
        guard healthKitManager.isHealthDataAvailable else {
            errorMessage = "HealthKit ist nicht verfügbar"
            return
        }
        
        isSyncingWithHealthKit = true
        errorMessage = nil
        
        do {
            let today = Calendar.current.startOfDay(for: Date())
            let healthData = try await healthKitManager.fetchAllHealthData(for: today)
            
            // Aktualisiere nur Daten die nicht manuell editiert wurden
            if let entry = todayHealthData {
                if !entry.stepsManuallyEdited {
                    entry.updateSteps(healthData.steps)
                }
                if !entry.caloriesManuallyEdited {
                    entry.updateCalories(healthData.calories)
                }
                if !entry.sleepManuallyEdited {
                    entry.updateSleep(healthData.sleep)
                }
                if !entry.waterManuallyEdited {
                    entry.updateWater(healthData.water)
                }
                
                try modelContext?.save()
                
                // Aktualisiere UI
                objectWillChange.send()
            }
        } catch {
            errorMessage = "Fehler beim Synchronisieren: \(error.localizedDescription)"
        }
        
        isSyncingWithHealthKit = false
    }
    
    // MARK: - Manual Data Entry
    
    /// Aktualisiert Schritte manuell
    func updateSteps(_ steps: Int) {
        guard let entry = todayHealthData else { return }
        
        entry.updateSteps(steps, manual: true)
        
        do {
            try modelContext?.save()
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }
    
    /// Aktualisiert Kalorien manuell
    func updateCalories(_ calories: Double) {
        guard let entry = todayHealthData else { return }
        
        entry.updateCalories(calories, manual: true)
        
        do {
            try modelContext?.save()
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }
    
    /// Aktualisiert Schlaf manuell
    func updateSleep(_ hours: Double) {
        guard let entry = todayHealthData else { return }
        
        entry.updateSleep(hours, manual: true)
        
        do {
            try modelContext?.save()
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }
    
    /// Aktualisiert Wasser manuell
    func updateWater(_ liters: Double) {
        guard let entry = todayHealthData else { return }
        
        entry.updateWater(liters, manual: true)
        
        do {
            try modelContext?.save()
        } catch {
            errorMessage = "Fehler beim Speichern: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Historical Data for Charts
    
    /// Lädt Schritt-Daten für die letzte Woche
    func loadWeeklyStepsData() async {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        do {
            weeklyStepsData = try await healthKitManager.fetchStepsForRange(startDate: startDate, endDate: endDate)
        } catch {
            errorMessage = "Fehler beim Laden der Schrittdaten: \(error.localizedDescription)"
        }
    }
    
    /// Lädt Gesundheitsdaten für einen Datumsbereich aus der lokalen Datenbank
    func loadHealthDataForRange(startDate: Date, endDate: Date) -> [HealthDataEntry] {
        guard let context = modelContext else { return [] }
        
        let descriptor = FetchDescriptor<HealthDataEntry>(
            predicate: #Predicate { entry in
                entry.date >= startDate && entry.date <= endDate
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        
        do {
            return try context.fetch(descriptor)
        } catch {
            errorMessage = "Fehler beim Laden der Daten: \(error.localizedDescription)"
            return []
        }
    }
    
    // MARK: - Statistics
    
    /// Berechnet Durchschnittswerte für die letzte Woche
    func calculateWeeklyAverages() -> (steps: Double, calories: Double, sleep: Double, water: Double) {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: endDate)!
        
        let entries = loadHealthDataForRange(startDate: startDate, endDate: endDate)
        
        guard !entries.isEmpty else {
            return (0, 0, 0, 0)
        }
        
        let totalSteps = entries.compactMap { $0.steps }.reduce(0, +)
        let totalCalories = entries.compactMap { $0.calories }.reduce(0, +)
        let totalSleep = entries.compactMap { $0.sleepHours }.reduce(0, +)
        let totalWater = entries.compactMap { $0.waterIntake }.reduce(0, +)
        
        let count = Double(entries.count)
        
        return (
            steps: Double(totalSteps) / count,
            calories: totalCalories / count,
            sleep: totalSleep / count,
            water: totalWater / count
        )
    }
}
