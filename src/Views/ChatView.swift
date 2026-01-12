//
//  ChatView.swift
//  tracking-app
//
//  Created by iOS-Labor on 12.01.26.
//

import SwiftUI
import SwiftData

struct ChatView: View{
    
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    
    //Wie der Chat aussieht
    var body: some View{
        NavigationStack {
            VStack{
                ScrollView{
                    Text("🤖 Hi! Bechreibe mir, wie du dich heute fühlst.").opacity(0.2)
                        .padding()
                }
                
                HStack{
                    TextField("Nachricht eingeben...", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Senden"){
                        inputText = ""
                    }
                    
                }
                .padding()
            }
            .navigationTitle("Chat")
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button("Schließen"){
                        
                        dismiss()
                    }
                }
            }
        }
    }
}
