//
//  HomeView.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//

import SwiftUI
import SwiftData

/// Dashboard / Home View - Hauptansicht der App
struct HomeView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    @StateObject private var healthViewModel = HealthViewModel()
    @StateObject private var moodViewModel = MoodViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Greeting
                    GreetingSection(userName: appViewModel.currentUser?.name ?? "")
                    
                    // Quick Actions
                    QuickActionsSection()
                    
                    // Today's Health Summary
                    HealthSummaryCard(viewModel: healthViewModel)
                    
                    // Today's Mood
                    TodayMoodCard(viewModel: moodViewModel)
                    
                    // Recent Activity
                    RecentActivitySection(moodViewModel: moodViewModel)
                }
                .padding()
            }
            .navigationTitle("Übersicht")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await healthViewModel.syncWithHealthKit()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .refreshable {
                await refreshData()
            }
            .onAppear {
                setupViewModels()
                loadData()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func setupViewModels() {
        healthViewModel.modelContext = modelContext
        healthViewModel.currentUser = appViewModel.currentUser
        
        moodViewModel.modelContext = modelContext
        moodViewModel.currentUser = appViewModel.currentUser
    }
    
    private func loadData() {
        healthViewModel.loadTodayHealthData()
        moodViewModel.loadTodayMoodEntry()
        moodViewModel.loadRecentMoodEntries()
    }
    
    private func refreshData() async {
        await healthViewModel.syncWithHealthKit()
        loadData()
    }
}

// MARK: - Greeting Section

struct GreetingSection: View {
    let userName: String
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 0..<12:
            return "Guten Morgen"
        case 12..<18:
            return "Guten Tag"
        default:
            return "Guten Abend"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(greeting)
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text(userName)
                .font(.system(size: 32, weight: .bold, design: .rounded))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Quick Actions

struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Schnellaktionen")
                .font(.headline)
            
            HStack(spacing: 12) {
                QuickActionButton(
                    icon: "heart.text.square.fill",
                    title: "Gefühl erfassen",
                    color: .pink
                )
                
                QuickActionButton(
                    icon: "figure.walk",
                    title: "Schritte ansehen",
                    color: .green
                )
            }
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(color.gradient)
                .cornerRadius(12)
            
            Text(title)
                .font(.caption)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Health Summary Card

struct HealthSummaryCard: View {
    @ObservedObject var viewModel: HealthViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Heute")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.isSyncingWithHealthKit {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let healthData = viewModel.todayHealthData {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    HealthMetricView(
                        icon: "figure.walk",
                        value: "\(healthData.steps ?? 0)",
                        label: "Schritte",
                        color: .green
                    )
                    
                    HealthMetricView(
                        icon: "flame.fill",
                        value: String(format: "%.0f", healthData.calories ?? 0),
                        label: "kcal",
                        color: .orange
                    )
                    
                    HealthMetricView(
                        icon: "bed.double.fill",
                        value: String(format: "%.1fh", healthData.sleepHours ?? 0),
                        label: "Schlaf",
                        color: .blue
                    )
                    
                    HealthMetricView(
                        icon: "drop.fill",
                        value: String(format: "%.1fL", healthData.waterIntake ?? 0),
                        label: "Wasser",
                        color: .cyan
                    )
                }
            } else {
                Text("Keine Daten verfügbar")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

struct HealthMetricView: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Today's Mood Card

struct TodayMoodCard: View {
    @ObservedObject var viewModel: MoodViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stimmung")
                .font(.headline)
            
            if let moodEntry = viewModel.todayMoodEntry {
                HStack {
                    Text(moodEntry.moodType.symbol)
                        .font(.system(size: 50))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(moodEntry.moodType.rawValue)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("Intensität: \(moodEntry.intensity)/10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            } else {
                HStack {
                    Image(systemName: "heart.circle")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text("Noch keine Stimmung erfasst")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

// MARK: - Recent Activity

struct RecentActivitySection: View {
    @ObservedObject var moodViewModel: MoodViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Letzte Einträge")
                .font(.headline)
            
            if moodViewModel.recentMoodEntries.isEmpty {
                Text("Noch keine Einträge vorhanden")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(moodViewModel.recentMoodEntries.prefix(5)) { entry in
                    RecentMoodEntryRow(entry: entry)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

struct RecentMoodEntryRow: View {
    let entry: MoodEntry
    
    var body: some View {
        HStack {
            Text(entry.moodType.symbol)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.moodType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppViewModel())
        .modelContainer(for: [User.self, MoodEntry.self, HealthDataEntry.self])
}
