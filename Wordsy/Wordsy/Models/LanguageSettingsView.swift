//
//  LanguageSettingsView.swift
//  Wordsy
//
//  Created by Murat on 11.04.2025.
//
import SwiftUI

struct LanguageOption: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let code: String
    let flag: String
}

struct LanguageSettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    // State variables for form fields
    @State private var userName: String = ""
    @State private var selectedLanguage: LanguageOption?
    @State private var isLoading = true
    @State private var showLanguageSelectionSheet = false
    
    // Languages list
    private let languages = [
        LanguageOption(name: "English (United States)", code: "en-US", flag: "🇺🇸"),
        LanguageOption(name: "Chinese", code: "zh", flag: "🇨🇳"),
        LanguageOption(name: "Japanese", code: "ja", flag: "🇯🇵"),
        LanguageOption(name: "English (United Kingdom)", code: "en-GB", flag: "🇬🇧"),
        LanguageOption(name: "English (Canada)", code: "en-CA", flag: "🇨🇦"),
        LanguageOption(name: "German", code: "de", flag: "🇩🇪"),
        LanguageOption(name: "English (Australia)", code: "en-AU", flag: "🇦🇺"),
        LanguageOption(name: "French", code: "fr", flag: "🇫🇷"),
        LanguageOption(name: "Korean", code: "ko", flag: "🇰🇷"),
        LanguageOption(name: "Hindi", code: "hi", flag: "🇮🇳"),
        LanguageOption(name: "Portuguese (Brazil)", code: "pt-BR", flag: "🇧🇷"),
        LanguageOption(name: "Russian", code: "ru", flag: "🇷🇺"),
        LanguageOption(name: "Italian", code: "it", flag: "🇮🇹"),
        LanguageOption(name: "Spanish", code: "es", flag: "🇪🇸"),
        LanguageOption(name: "Spanish (Mexico)", code: "es-MX", flag: "🇲🇽"),
        LanguageOption(name: "Turkish", code: "tr", flag: "🇹🇷"),
        LanguageOption(name: "Arabic (UAE)", code: "ar-AE", flag: "🇦🇪"),
        LanguageOption(name: "Chinese (Taiwan)", code: "zh-TW", flag: "🇹🇼")
    ]
    
    var body: some View {
        Form {
            Section(header: Text("Profile Information")) {
                TextField("Enter your name", text: $userName)
                    .font(.headline)
                    .padding(.vertical, 8)
            }
            
            Section(header: Text("Language Preference")) {
                Button(action: {
                    showLanguageSelectionSheet = true
                }) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Translation Language")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                            
                            if let language = selectedLanguage {
                                Text("\(language.flag) \(language.name)")
                                    .foregroundColor(.gray)
                            } else {
                                Text("Select a language")
                                    .foregroundColor(.gray)
                                    .italic()
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
            }
            
            Section {
                Button(action: saveSettings) {
                    Text("Save Changes")
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(BorderlessButtonStyle())
                .listRowBackground(Color.blue.opacity(0.1))
            }
        }
        .navigationTitle("Language & Profile")
        .sheet(isPresented: $showLanguageSelectionSheet) {
            NavigationView {
                LanguageSelectionView(selectedLanguage: $selectedLanguage, languages: languages)
                    .navigationBarItems(trailing: Button("Done") {
                        showLanguageSelectionSheet = false
                    })
            }
        }
        .onAppear {
            loadPreferences()
        }
        .alert(isPresented: .constant(isLoading)) {
            Alert(
                title: Text("Loading"),
                message: Text("Please wait while we load your preferences..."),
                dismissButton: .none
            )
        }
    }
    
    // Load existing preferences if available
    private func loadPreferences() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let preferences = UserPreferences.getCurrentPreferences(in: viewContext)
            
            // Load name
            userName = preferences.nameValue
            
            // Load language preference
            if let langCode = preferences.translateLanguage {
                selectedLanguage = languages.first(where: { $0.code == langCode })
            }
            
            isLoading = false
        }
    }
    
    // Save preferences to CoreData
    private func saveSettings() {
        let preferences = UserPreferences.getCurrentPreferences(in: viewContext)
        
        // Update name
        preferences.name = userName
        
        // Update language
        preferences.translateLanguage = selectedLanguage?.code
        
        // Update creation date if it's a new record
        if preferences.createdAt == nil {
            preferences.createdAt = Date()
        }
        
        // Save to CoreData
        do {
            try viewContext.save()
            // Show success feedback
            withAnimation {
                // You could add a toast message here
            }
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("Error saving preferences: \(error)")
            // Show error alert (you might want to implement this)
        }
    }
}

struct LanguageSelectionView: View {
    @Binding var selectedLanguage: LanguageOption?
    let languages: [LanguageOption]
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    
    var filteredLanguages: [LanguageOption] {
        if searchText.isEmpty {
            return languages
        } else {
            return languages.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        List {
            if !searchText.isEmpty && filteredLanguages.isEmpty {
                Text("No languages found")
                    .foregroundColor(.gray)
                    .italic()
            } else {
                ForEach(filteredLanguages) { language in
                    HStack {
                        Text(language.flag)
                            .font(.title2)
                            .padding(.trailing, 4)
                        
                        Text(language.name)
                            .font(.body)
                        
                        Spacer()
                        
                        if selectedLanguage?.code == language.code {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        self.selectedLanguage = language
                        // Don't dismiss here, let the user dismiss with Done button
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search languages")
        .navigationTitle("Select Language")
    }
}
