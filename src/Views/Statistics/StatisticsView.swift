//
//  StatisticsView.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//

import SwiftUI
import SwiftData
import Charts

/// Statistik View - Visualisierung von Gesundheits- und Stimmungsdaten
struct StatisticsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    @StateObject private var healthViewModel = HealthViewModel()
    @StateObject private var moodViewModel = MoodViewModel()
    
    @State private var selectedTimeRange: TimeRange = .week
    
    enum TimeRange: String, CaseIterable {
        case week = "Woche"
        case month = "Monat"
        case year = "Jahr"
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Time Range Picker
                    TimeRangePicker(selectedRange: $selectedTimeRange)
                    
                    // Mood Chart
                    MoodChartCard(viewModel: moodViewModel)
                    
                    // Steps Chart
                    StepsChartCard(viewModel: healthViewModel)
                    
                    // Health Metrics Summary
                    HealthMetricsSummaryCard(viewModel: healthViewModel)
                    
                    // Insights
                    InsightsCard(moodViewModel: moodViewModel)
                }
                .padding()
            }
            .navigationTitle("Statistiken")
            .onAppear {
                setupViewModels()
                loadData()
            }
        }
    }
    
    private func setupViewModels() {
        healthViewModel.modelContext = modelContext
        healthViewModel.currentUser = appViewModel.currentUser
        
        moodViewModel.modelContext = modelContext
        moodViewModel.currentUser = appViewModel.currentUser
    }
    
    private func loadData() {
        moodViewModel.loadRecentMoodEntries(limit: 30)
        Task {
            await healthViewModel.loadWeeklyStepsData()
        }
    }
}

// MARK: - Time Range Picker

struct TimeRangePicker: View {
    @Binding var selectedRange: StatisticsView.TimeRange
    
    var body: some View {
        Picker("Zeitraum", selection: $selectedRange) {
            ForEach(StatisticsView.TimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Mood Chart Card

struct MoodChartCard: View {
    @ObservedObject var viewModel: MoodViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stimmungsverlauf")
                .font(.headline)
            
            let moodData = viewModel.getMoodDataForChart(days: 7)
            
            if !moodData.isEmpty {
                Chart {
                    ForEach(Array(moodData.enumerated()), id: \.offset) { index, data in
                        LineMark(
                            x: .value("Datum", data.date),
                            y: .value("Stimmung", data.value)
                        )
                        .foregroundStyle(.pink.gradient)
                        .symbol(Circle())
                        
                        AreaMark(
                            x: .value("Datum", data.date),
                            y: .value("Stimmung", data.value)
                        )
                        .foregroundStyle(.pink.opacity(0.1))
                    }
                }
                .frame(height: 200)
                .chartYScale(domain: 0...10)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                    .font(.caption)
                            }
                        }
                    }
                }
            } else {
                Text("Noch keine Daten verfügbar")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

// MARK: - Steps Chart Card

struct StepsChartCard: View {
    @ObservedObject var viewModel: HealthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schritte")
                .font(.headline)
            
            if !viewModel.weeklyStepsData.isEmpty {
                Chart {
                    ForEach(Array(viewModel.weeklyStepsData.enumerated()), id: \.offset) { index, data in
                        BarMark(
                            x: .value("Datum", data.date),
                            y: .value("Schritte", data.steps)
                        )
                        .foregroundStyle(.green.gradient)
                        .cornerRadius(4)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                    .font(.caption)
                            }
                        }
                    }
                }
            } else {
                Text("Noch keine Daten verfügbar")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

// MARK: - Health Metrics Summary

struct HealthMetricsSummaryCard: View {
    @ObservedObject var viewModel: HealthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wochendurchschnitt")
                .font(.headline)
            
            let averages = viewModel.calculateWeeklyAverages()
            
            VStack(spacing: 12) {
                MetricRow(
                    icon: "figure.walk",
                    label: "Schritte",
                    value: String(format: "%.0f", averages.steps),
                    color: .green
                )
                
                MetricRow(
                    icon: "flame.fill",
                    label: "Kalorien",
                    value: String(format: "%.0f kcal", averages.calories),
                    color: .orange
                )
                
                MetricRow(
                    icon: "bed.double.fill",
                    label: "Schlaf",
                    value: String(format: "%.1f Std", averages.sleep),
                    color: .blue
                )
                
                MetricRow(
                    icon: "drop.fill",
                    label: "Wasser",
                    value: String(format: "%.1f L", averages.water),
                    color: .cyan
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

struct MetricRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 30)
            
            Text(label)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Insights Card

struct InsightsCard: View {
    @ObservedObject var moodViewModel: MoodViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                
                Text("Erkenntnisse")
                    .font(.headline)
            }
            
            let insights = moodViewModel.generateInsights()
            
            if !insights.isEmpty {
                ForEach(insights, id: \.self) { insight in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text(insight)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            } else {
                Text("Erfasse mehr Stimmungen, um Erkenntnisse zu erhalten")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

#Preview {
    StatisticsView()
        .environmentObject(AppViewModel())
        .modelContainer(for: [User.self, MoodEntry.self, HealthDataEntry.self])
}
