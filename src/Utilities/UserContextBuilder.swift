//
//  UserContextBuilder.swift
//  tracking-app
//
//  Created by Jo on 13.02.26.
//

import Foundation
import SwiftData

struct UserContextBuilder {

    static func buildContext(modelContext: ModelContext, user: User, daysBack: Int = 14) throws -> String {
        let cal = Calendar.current
        let end = Date()
        let start = cal.date(byAdding: .day, value: -daysBack, to: end)!

        // Mood Entries
        let moodDesc = FetchDescriptor<MoodEntry>(
            predicate: #Predicate { e in
                e.date >= start && e.date <= end
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let moods = try modelContext.fetch(moodDesc)

        // Health Entries
        let healthDesc = FetchDescriptor<HealthDataEntry>(
            predicate: #Predicate { e in
                e.date >= start && e.date <= end
            },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        let health = try modelContext.fetch(healthDesc)

        // Simple Aggregates (robust, nicht perfekt – aber gut genug für v1)
        let moodAvg = moods.isEmpty ? nil : (moods.map { $0.moodType.numericValue }.reduce(0,+) / Double(moods.count))
        let sleepAvg = avg(health.compactMap { $0.sleepHours })
        let stepsAvg = avg(health.compactMap { Double($0.steps ?? 0) }.filter { $0 > 0 })
        let kcalAvg  = avg(health.compactMap { $0.calories })
        let waterAvg = avg(health.compactMap { $0.waterIntake })

        let lastMood = moods.last
        let lastMoodText: String = {
            guard let lastMood else { return "Keine Stimmungseinträge." }
            return "\(lastMood.moodType.rawValue) (Intensität \(lastMood.intensity)/10)"
        }()

        return """
        Nutzerprofil:
        - Name: \(user.name)
        - Alter: \(user.age.map(String.init) ?? "unbekannt")
        - Gewicht: \(user.weight.map { "\($0) kg" } ?? "unbekannt")
        - Größe: \(user.height.map { "\($0) cm" } ?? "unbekannt")

        Letzter Mood-Check: \(lastMoodText)

        Trends der letzten \(daysBack) Tage:
        - Stimmung Ø (1..10): \(moodAvg.map { String(format: "%.1f", $0) } ?? "n/a")
        - Schritte Ø: \(stepsAvg.map { String(format: "%.0f", $0) } ?? "n/a")
        - Aktive Kalorien Ø: \(kcalAvg.map { String(format: "%.0f", $0) } ?? "n/a")
        - Schlaf Ø (h): \(sleepAvg.map { String(format: "%.1f", $0) } ?? "n/a")
        - Wasser Ø (L): \(waterAvg.map { String(format: "%.1f", $0) } ?? "n/a")

        Wichtige Regel:
        - Gib keine medizinischen Diagnosen, wenn du merkst dass es zu schlecht ist Nummer von Hilfe.
        - Wenn Stimmung länger schlecht: sanfte, konkrete Vorschläge (Spaziergang, Yoga, Freunde, Routine, Schlafhygiene).
        -  
        """
    }

    private static func avg(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0,+) / Double(values.count)
    }
}
