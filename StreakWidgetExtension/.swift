//
//  StreakWidget.swift
//  tracking-app
//
//  Created by Jo on 15.02.26.
//

import WidgetKit
import SwiftUI

struct StreakEntry: TimelineEntry {
    let date: Date
    let streak: Int
    let last7: [Bool]
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, streak: 3, last7: [true,true,false,true,true,false,true])
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let data = StreakSharedStore.load()
        completion(StreakEntry(date: .now, streak: data.streak, last7: data.last7))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let data = StreakSharedStore.load()
        let entry = StreakEntry(date: .now, streak: data.streak, last7: data.last7)

        // Widgets werden vom System “wann es will” aktualisiert.
        // Wir geben zusätzlich eine sinnvolle Policy (z.B. in 30 Min).
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now.addingTimeInterval(1800)

        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct StreakWidgetView: View {
    let entry: StreakEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                Text("\(entry.streak) Tage")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                Spacer()
            }

            Text(entry.streak == 0 ? "Starte heute 🔥" : "Weiter so!")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(0..<7, id: \.self) { i in
                    Circle()
                        .fill(entry.last7[safe: i] == true ? AnyShapeStyle(.green) : AnyShapeStyle(.gray.opacity(0.25)))
                        .frame(width: 10, height: 10)
                }
                Spacer()
            }
        }
        .padding()
        .containerBackground(.background, for: .widget)
    }
}

@main
struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "StreakWidget", provider: Provider()) { entry in
            StreakWidgetView(entry: entry)
        }
        .configurationDisplayName("Streak")
        .description("Zeigt deinen 7-Tage-Streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// safe indexing helper
fileprivate extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
