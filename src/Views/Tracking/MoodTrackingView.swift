//
//  MoodTrackingView.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//

import SwiftUI
import SwiftData

/// View für Gefühls-Tracking - Tagebuch-Funktion
struct MoodTrackingView: View {
    
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var appViewModel: AppViewModel
    
    @StateObject private var moodViewModel = MoodViewModel()
    @State private var showSuccessMessage = false
    
    //Einstellung für den Chat
    @State private var showChat = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    MoodTrackingHeader()
                    
                    // Mood Selection
                    MoodSelectionSection(viewModel: moodViewModel)
                    
                    // Intensity Slider
                    IntensitySection(intensity: $moodViewModel.moodIntensity)
                    
                    // Notes Section
                    NotesSection(notes: $moodViewModel.moodNotes)
                    
                    // Save Button
                    SaveButton(viewModel: moodViewModel, showSuccess: $showSuccessMessage)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Gefühle")
            
            //Icon für den Chat
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button {
                        showChat = true
                    } label :{
                        Image(systemName: "message.fill")
                    }
                    .accessibilityLabel("Chat öffnen")
                }
            }
            .navigationDestination(isPresented: $showChat){
                ChatView()
            }
            // Ende
            .onAppear {
                setupViewModel()
                moodViewModel.loadTodayMoodEntry()
                moodViewModel.loadRecentMoodEntries()
            }
            .alert("Gespeichert", isPresented: $showSuccessMessage) {
                Button("OK") { }
            } message: {
                Text("Dein Gefühls-Eintrag wurde gespeichert.")
            }
        }
    }
    
    private func setupViewModel() {
        moodViewModel.modelContext = modelContext
        moodViewModel.currentUser = appViewModel.currentUser
    }
}

// MARK: - Header

struct MoodTrackingHeader: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.pink.gradient)
            
            Text("Wie fühlst du dich heute?")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Nimm dir einen Moment, um deine Gefühle zu reflektieren")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }
}

// MARK: - Mood Selection

struct MoodSelectionSection: View {
    @ObservedObject var viewModel: MoodViewModel
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Wähle deine Stimmung")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(MoodType.allCases, id: \.self) { mood in
                    MoodButton(
                        mood: mood,
                        isSelected: viewModel.selectedMood == mood
                    ) {
                        withAnimation(.spring()) {
                            viewModel.selectedMood = mood
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

struct MoodButton: View {
    let mood: MoodType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(mood.symbol)
                    .font(.system(size: 40))
                
                Text(mood.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? Color.blue.opacity(0.2)
                    : Color(.systemGray6)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Intensity Section

struct IntensitySection: View {
    @Binding var intensity: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Intensität")
                    .font(.headline)
                
                Spacer()
                
                Text("\(intensity)/10")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("Schwach")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Slider(value: Binding(
                    get: { Double(intensity) },
                    set: { intensity = Int($0) }
                ), in: 1...10, step: 1)
                    .tint(.blue)
                
                Text("Stark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

// MARK: - Notes Section

struct NotesSection: View {
    @Binding var notes: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notizen (optional)")
                .font(.headline)
            
            ZStack(alignment: .topLeading) {
                if notes.isEmpty && !isFocused {
                    Text("Was hat dieses Gefühl ausgelöst? Was hast du heute gemacht?")
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $notes)
                    .focused($isFocused)
                    .frame(minHeight: 120)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 10)
    }
}

// MARK: - Save Button

struct SaveButton: View {
    @ObservedObject var viewModel: MoodViewModel
    @Binding var showSuccess: Bool
    
    var body: some View {
        Button(action: {
            viewModel.saveMoodEntry()
            showSuccess = true
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Speichern")
                }
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.gradient)
            .cornerRadius(12)
        }
        .disabled(viewModel.isLoading)
        .padding(.horizontal)
    }
}

#Preview {
    MoodTrackingView()
        .environmentObject(AppViewModel())
        .modelContainer(for: [User.self, MoodEntry.self])
}
