//
//  StatisticsView.swift
//  tracking-app
//
//  Created by Jo on 10.01.26.
//

import SwiftUI
import SwiftData

/// Einstellungen View
struct SettingsView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    @Query private var settings: [AppSettings]
    
    @State private var showingProfileEdit = false
    @State private var showingLogoutConfirmation = false
    @State private var notificationsEnabled = true
    @State private var selectedReminderTime = Date()
    
    var appSettings: AppSettings? {
        settings.first
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Profile Section
                ProfileSection(
                    user: appViewModel.currentUser,
                    showingEdit: $showingProfileEdit
                )
                
                // Notifications Section
                NotificationsSection(
                    enabled: $notificationsEnabled,
                    reminderTime: $selectedReminderTime
                )
                
                // Data & Privacy Section
                DataPrivacySection()
                
                // About Section
                AboutSection()
                
                // Logout Section
                LogoutSection(showingConfirmation: $showingLogoutConfirmation)
            }
            .navigationTitle("Einstellungen")
            .onAppear {
                loadSettings()
            }
            .sheet(isPresented: $showingProfileEdit) {
                ProfileEditView()
            }
            .alert("Abmelden", isPresented: $showingLogoutConfirmation) {
                Button("Abbrechen", role: .cancel) { }
                Button("Abmelden", role: .destructive) {
                    appViewModel.signOut()
                }
            } message: {
                Text("Möchtest du dich wirklich abmelden?")
            }
            .onChange(of: notificationsEnabled) { _, newValue in
                updateNotificationSettings(enabled: newValue)
            }
            .onChange(of: selectedReminderTime) { _, newTime in
                updateReminderTime(newTime)
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func loadSettings() {
        if let settings = appSettings {
            notificationsEnabled = settings.notificationsEnabled
            selectedReminderTime = settings.dailyReminderTime ?? Date()
        }
    }
    
    private func updateNotificationSettings(enabled: Bool) {
        guard let settings = appSettings else { return }
        
        settings.notificationsEnabled = enabled
        
        do {
            try modelContext.save()
            
            if enabled {
                scheduleNotifications()
            } else {
                NotificationManager.shared.removeDailyReminder()
            }
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }
    
    private func updateReminderTime(_ time: Date) {
        guard let settings = appSettings else { return }
        
        settings.dailyReminderTime = time
        
        do {
            try modelContext.save()
            scheduleNotifications()
        } catch {
            print("Fehler beim Speichern: \(error)")
        }
    }
    
    private func scheduleNotifications() {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedReminderTime)
        
        if let hour = components.hour, let minute = components.minute {
            NotificationManager.shared.scheduleDailyReminder(hour: hour, minute: minute)
        }
    }
}

// MARK: - Profile Section

struct ProfileSection: View {
    let user: User?
    @Binding var showingEdit: Bool
    
    var body: some View {
        Section {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user?.name ?? "Unbekannt")
                        .font(.headline)
                    
                    Text(user?.email ?? "")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingEdit = true }) {
                    Text("Bearbeiten")
                        .font(.subheadline)
                }
            }
            
            if let user = user {
                if let age = user.age {
                    LabeledContent("Alter", value: "\(age) Jahre")
                }
                
                if let weight = user.weight {
                    LabeledContent("Gewicht", value: String(format: "%.1f kg", weight))
                }
                
                if let height = user.height {
                    LabeledContent("Größe", value: String(format: "%.0f cm", height))
                }
            }
        } header: {
            Text("Profil")
        }
    }
}

// MARK: - Notifications Section

struct NotificationsSection: View {
    @Binding var enabled: Bool
    @Binding var reminderTime: Date
    
    var body: some View {
        Section {
            Toggle("Benachrichtigungen", isOn: $enabled)
            
            if enabled {
                DatePicker(
                    "Erinnerungszeit",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
            }
        } header: {
            Text("Benachrichtigungen")
        } footer: {
            Text("Erhalte tägliche Erinnerungen, um deine Stimmung zu erfassen.")
        }
    }
}

// MARK: - Data & Privacy Section

struct DataPrivacySection: View {
    var body: some View {
        Section {
            NavigationLink {
                DataPrivacyDetailView()
            } label: {
                Label("Datenschutz", systemImage: "lock.shield")
            }
            
            Button(action: {
                // TODO: Implementiere Health Sync
            }) {
                Label("Health-Daten synchronisieren", systemImage: "arrow.clockwise")
            }
        } header: {
            Text("Daten & Datenschutz")
        }
    }
}

// MARK: - About Section

struct AboutSection: View {
    var body: some View {
        Section {
            LabeledContent("Version", value: "1.0.0")
            
            Link(destination: URL(string: "https://example.com")!) {
                Label("Hilfe & Support", systemImage: "questionmark.circle")
            }
        } header: {
            Text("Über")
        }
    }
}

// MARK: - Logout Section

struct LogoutSection: View {
    @Binding var showingConfirmation: Bool
    
    var body: some View {
        Section {
            Button(role: .destructive, action: {
                showingConfirmation = true
            }) {
                HStack {
                    Spacer()
                    Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Profile Edit View

struct ProfileEditView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    @State private var age: String = ""
    @State private var weight: String = ""
    @State private var height: String = ""
    @State private var gender: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Persönliche Daten") {
                    TextField("Alter", text: $age)
                        .keyboardType(.numberPad)
                    
                    TextField("Gewicht (kg)", text: $weight)
                        .keyboardType(.decimalPad)
                    
                    TextField("Größe (cm)", text: $height)
                        .keyboardType(.decimalPad)
                    
                    Picker("Geschlecht", selection: $gender) {
                        Text("Nicht angegeben").tag("")
                        Text("Männlich").tag("männlich")
                        Text("Weiblich").tag("weiblich")
                        Text("Divers").tag("divers")
                    }
                }
            }
            .navigationTitle("Profil bearbeiten")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        saveProfile()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentData()
            }
        }
    }
    
    private func loadCurrentData() {
        if let user = appViewModel.currentUser {
            age = user.age.map { String($0) } ?? ""
            weight = user.weight.map { String(format: "%.1f", $0) } ?? ""
            height = user.height.map { String(format: "%.0f", $0) } ?? ""
            gender = user.gender ?? ""
        }
    }
    
    private func saveProfile() {
        let ageValue = Int(age)
        let weightValue = Double(weight)
        let heightValue = Double(height)
        
        appViewModel.updateUserProfile(
            age: ageValue,
            weight: weightValue,
            height: heightValue,
            gender: gender.isEmpty ? nil : gender
        )
    }
}

// MARK: - Data Privacy Detail View

struct DataPrivacyDetailView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Datenschutz")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Deine Privatsphäre ist uns wichtig")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 12) {
                    PrivacyPoint(
                        icon: "lock.fill",
                        title: "Lokale Speicherung",
                        description: "Alle deine Daten werden sicher auf deinem Gerät gespeichert."
                    )
                    
                    PrivacyPoint(
                        icon: "hand.raised.fill",
                        title: "Keine Weitergabe",
                        description: "Deine Daten werden nicht an Dritte weitergegeben."
                    )
                    
                    PrivacyPoint(
                        icon: "checkmark.shield.fill",
                        title: "DSGVO-konform",
                        description: "Wir halten uns an alle Datenschutzrichtlinien."
                    )
                    
                    PrivacyPoint(
                        icon: "trash.fill",
                        title: "Deine Kontrolle",
                        description: "Du kannst deine Daten jederzeit löschen."
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Datenschutz")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPoint: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppViewModel())
        .modelContainer(for: [User.self, AppSettings.self])
}
