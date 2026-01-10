//
//  HealthKitManager.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//

import Foundation
import HealthKit
import Combine 
/// Manager für HealthKit Integration
/// Verantwortlich für das Abrufen von Gesundheitsdaten aus Apple Health
class HealthKitManager: ObservableObject {
    
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    
    /// Prüft ob HealthKit auf dem Gerät verfügbar ist
    var isHealthDataAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }
    
    // MARK: - Authorization
    
    /// Datentypen die wir lesen möchten
    private var readTypes: Set<HKObjectType> {
        guard let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount),
              let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
              let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
              let dietaryWater = HKObjectType.quantityType(forIdentifier: .dietaryWater) else {
            return []
        }
        
        return [stepCount, activeEnergy, sleepAnalysis, dietaryWater]
    }
    
    /// Fordert Berechtigung zum Lesen von Gesundheitsdaten an
    func requestAuthorization() async throws {
        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }
    
    // MARK: - Fetch Health Data
    
    /// Holt Schritte für einen bestimmten Tag
    /// - Parameter date: Datum für das die Schritte abgerufen werden sollen
    /// - Returns: Anzahl der Schritte
    func fetchSteps(for date: Date) async throws -> Int {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        let (startDate, endDate) = date.dayInterval
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let steps = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: stepType,
                                         quantitySamplePredicate: predicate,
                                         options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: steps)
            }
            
            healthStore.execute(query)
        }
        
        return Int(steps)
    }
    
    /// Holt verbrannte Kalorien für einen bestimmten Tag
    /// - Parameter date: Datum für das die Kalorien abgerufen werden sollen
    /// - Returns: Verbrannte Kalorien in kcal
    func fetchCalories(for date: Date) async throws -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        let (startDate, endDate) = date.dayInterval
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let calories = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: energyType,
                                         quantitySamplePredicate: predicate,
                                         options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let calories = result?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
                continuation.resume(returning: calories)
            }
            
            healthStore.execute(query)
        }
        
        return calories
    }
    
    /// Holt Schlafdauer für einen bestimmten Tag
    /// - Parameter date: Datum für das die Schlafdauer abgerufen werden soll
    /// - Returns: Schlafdauer in Stunden
    func fetchSleep(for date: Date) async throws -> Double {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        let (startDate, endDate) = date.dayInterval
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let sleepHours = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKSampleQuery(sampleType: sleepType,
                                     predicate: predicate,
                                     limit: HKObjectQueryNoLimit,
                                     sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sleepSamples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: 0)
                    return
                }
                
                // Nur "asleep" Samples zählen
                let sleepSeconds = sleepSamples
                    .filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                
                let hours = sleepSeconds / 3600.0
                continuation.resume(returning: hours)
            }
            
            healthStore.execute(query)
        }
        
        return sleepHours
    }
    
    /// Holt Wasseraufnahme für einen bestimmten Tag
    /// - Parameter date: Datum für das die Wasseraufnahme abgerufen werden soll
    /// - Returns: Wasseraufnahme in Litern
    func fetchWater(for date: Date) async throws -> Double {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        let (startDate, endDate) = date.dayInterval
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let water = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Double, Error>) in
            let query = HKStatisticsQuery(quantityType: waterType,
                                         quantitySamplePredicate: predicate,
                                         options: .cumulativeSum) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let water = result?.sumQuantity()?.doubleValue(for: HKUnit.liter()) ?? 0
                continuation.resume(returning: water)
            }
            
            healthStore.execute(query)
        }
        
        return water
    }
    
    /// Holt alle Health-Daten für einen bestimmten Tag
    /// - Parameter date: Datum für das die Daten abgerufen werden sollen
    /// - Returns: Tuple mit allen Health-Daten
    func fetchAllHealthData(for date: Date) async throws -> (steps: Int, calories: Double, sleep: Double, water: Double) {
        async let steps = fetchSteps(for: date)
        async let calories = fetchCalories(for: date)
        async let sleep = fetchSleep(for: date)
        async let water = fetchWater(for: date)
        
        return try await (steps, calories, sleep, water)
    }
    
    /// Holt Schritte für einen Datumsbereich (für Graphen)
    /// - Parameters:
    ///   - startDate: Start-Datum
    ///   - endDate: End-Datum
    /// - Returns: Array von Tuples (Datum, Schritte)
    func fetchStepsForRange(startDate: Date, endDate: Date) async throws -> [(date: Date, steps: Int)] {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.dataTypeNotAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        var anchorComponents = Calendar.current.dateComponents([.day, .month, .year], from: startDate)
        anchorComponents.hour = 0
        guard let anchorDate = Calendar.current.date(from: anchorComponents) else {
            throw HealthKitError.invalidDate
        }
        
        let interval = DateComponents(day: 1)
        
        let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[(date: Date, steps: Int)], Error>) in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: anchorDate,
                intervalComponents: interval
            )
            
            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let statsCollection = results else {
                    continuation.resume(returning: [])
                    return
                }
                
                var data: [(date: Date, steps: Int)] = []
                statsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                    let steps = Int(statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0)
                    data.append((date: statistics.startDate, steps: steps))
                }
                
                continuation.resume(returning: data)
            }
            
            healthStore.execute(query)
        }
        
        return data
    }
}

// MARK: - Error Handling

enum HealthKitError: LocalizedError {
    case dataTypeNotAvailable
    case invalidDate
    case authorizationDenied
    
    var errorDescription: String? {
        switch self {
        case .dataTypeNotAvailable:
            return "Dieser Datentyp ist nicht verfügbar"
        case .invalidDate:
            return "Ungültiges Datum"
        case .authorizationDenied:
            return "Zugriff auf Gesundheitsdaten wurde verweigert"
        }
    }
}

// MARK: - Date Extension

extension Date {
    /// Gibt Start und Ende des Tages zurück
    var dayInterval: (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: self)
        let end = calendar.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }
}
