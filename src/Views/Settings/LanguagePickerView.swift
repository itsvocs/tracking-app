//
//  LanguagePickerView.swift
//  tracking-app
//
//  Created by iOS-Labor on 26.01.26.
//

import SwiftUI


//Pop up Fenster für die Spracheinstellungen
struct LanguagePickerView: View {

    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {

            Text("Sprache auswählen")
                .font(.title2)
                .fontWeight(.bold)
            // anzeigen von den 3 Möglichkeiten
            ForEach(AppLanguage.allCases) { language in
                Button {
                    appViewModel.language = language
                } label: {
                    HStack {
                        Text(language.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)

                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                appViewModel.language == language
                                ? Color.blue
                                : Color.gray.opacity(0.5),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button("Bestätigen") {
                dismiss()
            }
            .font(.headline)
        }
        .onChange(of: appViewModel.language){
            _, newValue in print(newValue.rawValue)
            
        }
        .padding()
    }
}

