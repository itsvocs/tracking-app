//
//  LoginView.swift
//  tracking-app
//
//  Created by Jo on 09.01.26.
//

import SwiftUI

/// Login View - Authentifizierung mit Google Sign-In
struct LoginView: View {
    
    @EnvironmentObject var appViewModel: AppViewModel
    
    // Für Demo-Zwecke
    @State private var demoEmail = ""
    @State private var demoName = ""
    @State private var showDemoLogin = false
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo und Titel
                VStack(spacing: 16) {
                    Image(systemName: "heart.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundStyle(.white)
                    
                    Text("Gefühl Tracker")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Verstehe deine Emotionen und Gesundheit")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Login Button
                VStack(spacing: 16) {
                    // TODO: Echter Google Sign-In Button
                    // Momentan Demo-Button
                    Button(action: {
                        showDemoLogin = true
                    }) {
                        HStack {
                            Text("Sich anmelden")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                    }
                    .padding(.horizontal, 40)
                    
                    // Datenschutz-Hinweis
                    Text("Deine Daten bleiben privat und sicher auf deinem Gerät")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 50)
            }
            
            // Loading Overlay
            if appViewModel.isLoading {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
            }
        }
        .sheet(isPresented: $showDemoLogin) {
            DemoLoginSheet(
                email: $demoEmail,
                name: $demoName,
                onLogin: {
                    Task {
                        await appViewModel.signInWithGoogle(
                            email: demoEmail,
                            name: demoName
                        )
                    }
                }
            )
        }
        .alert("Fehler", isPresented: .constant(appViewModel.errorMessage != nil)) {
            Button("OK") {
                appViewModel.errorMessage = nil
            }
        } message: {
            Text(appViewModel.errorMessage ?? "")
        }
    }
}

/// Demo Login Sheet - wird später durch echtes Google Sign-In ersetzt
struct DemoLoginSheet: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var email: String
    @Binding var name: String
    var onLogin: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Demo Login") {
                    TextField("E-Mail", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                    
                    TextField("Name", text: $name)
                        .textContentType(.name)
                }
                
                Section {
                    Text("Dies ist ein Demo-Login für Entwicklungs- und Testzwecke.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("In der finalen Version wird hier Google Sign-In integriert.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Anmelden")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anmelden") {
                        onLogin()
                        dismiss()
                    }
                    .disabled(email.isEmpty || name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppViewModel())
}
