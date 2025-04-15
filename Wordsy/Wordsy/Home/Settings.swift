//
//  Settings.swift
//  Wordsy
//
//  Created by Murat on 11.04.2025.
//
import SwiftUI
struct Settings: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingLanguageSettings = false
    
    var body: some View {
        NavigationView {
            VStack{
                List {
                    NavigationLink(destination: LanguageSettingsView()) {
                        Label("Language and Profile Settings", systemImage: "globe")
                    }
                }
            }
            .background(Color(UIColor.systemGray6))
            .navigationTitle("Settings")
        }
    }
}
