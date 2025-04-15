//
//  OnboardingView4.swift
//  Wordsy
//
//  Created by Murat on 12.04.2025.
//

import SwiftUI
import CoreData

struct OnboardingView4: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    @State private var name = ""
    @State private var selectedGender = 0
    let genderOptions = ["Male", "Female", "Other"]
    
    @State private var selectedCountry = 0
    let countries = ["USA", "UK", "Canada", "Australia", "Turkey", "Germany", "France", "Spain", "Italy", "Japan","Korean","UAE","Saudi Arabia", "China", "Brazil", "Mexico", "Russia", "India", "Other"]
    
    // Flag emoji mapping for countries
    let countryFlags: [String: String] = [
        "USA": "🇺🇸",
        "UK": "🇬🇧",
        "Canada": "🇨🇦",
        "Australia": "🇦🇺",
        "Turkey": "🇹🇷",
        "Germany": "🇩🇪",
        "France": "🇫🇷",
        "Spain": "🇪🇸",
        "Italy": "🇮🇹",
        "Japan": "🇯🇵",
        "Korean":"🇰🇷",
        "UAE":"🇦🇪",
        "Saudi Arabia":"🇸🇦",
        "China": "🇨🇳",
        "Brazil": "🇧🇷",
        "Mexico": "🇲🇽",
        "Russia": "🇷🇺",
        "India": "🇮🇳",
        "Other": "🌍"
    ]
    
    @State private var selectedTranslationLanguage = 0
    
    // Updated to include language codes like in LanguageSettingsView
    let languageOptions: [LanguageOption] = [
        LanguageOption(name: "English", code: "en-US", flag: "🇺🇸"),
        LanguageOption(name: "Spanish", code: "es", flag: "🇪🇸"),
        LanguageOption(name: "French", code: "fr", flag: "🇫🇷"),
        LanguageOption(name: "German", code: "de", flag: "🇩🇪"),
        LanguageOption(name: "Italian", code: "it", flag: "🇮🇹"),
        LanguageOption(name: "Japanese", code: "ja", flag: "🇯🇵"),
        LanguageOption(name: "Chinese", code: "zh", flag: "🇨🇳"),
        LanguageOption(name: "Turkish", code: "tr", flag: "🇹🇷"),
        LanguageOption(name: "Russian", code: "ru", flag: "🇷🇺"),
        LanguageOption(name: "Portuguese", code: "pt-BR", flag: "🇧🇷"),
        LanguageOption(name: "Arabic", code: "ar-AE", flag: "🇦🇪"),
        LanguageOption(name: "Korean", code: "ko", flag: "🇰🇷")
    ]
    
    var translationLanguages: [String] {
        return languageOptions.map { $0.name }
    }
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Tell Us About Yourself")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 20)
                        
                        Text("This helps us personalize your experience")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // Personal info card
                    VStack(spacing: 20) {
                        // Name field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Your Name")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            TextField("Enter your name", text: $name)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                        
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Gender")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            HStack {
                                ForEach(0..<genderOptions.count, id: \.self) { index in
                                    GenderButton(
                                        text: genderOptions[index],
                                        isSelected: selectedGender == index,
                                        action: {
                                            selectedGender = index
                                        }
                                    )
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    // Country and language card
                    VStack(spacing: 20) {
                        // Country selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Country")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(0..<countries.count, id: \.self) { index in
                                        CountryButton(
                                            country: countries[index],
                                            flag: countryFlags[countries[index]] ?? "🌍",
                                            isSelected: selectedCountry == index,
                                            action: {
                                                selectedCountry = index
                                            }
                                        )
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        
                        // Translation language
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preferred Translation Language")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(0..<translationLanguages.count, id: \.self) { index in
                                        LanguageButton(
                                            language: translationLanguages[index],
                                            isSelected: selectedTranslationLanguage == index,
                                            action: {
                                                selectedTranslationLanguage = index
                                            }
                                        )
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 30)
                    
                    // Continue button
                    Button(action: {
                        viewModel.name = name
                        viewModel.age = 0
                        viewModel.gender = genderOptions[selectedGender]
                        viewModel.country = countries[selectedCountry]
                        viewModel.translationLanguage = translationLanguages[selectedTranslationLanguage]
                        // Save to UserPreferences
                        let viewContext = PersistenceController.shared.container.viewContext
                        let userPreferences = UserPreferences.getCurrentPreferences(in: viewContext)
                        userPreferences.nameValue = name
                        
                        // Get the language code for the selected translation language
                        let selectedLanguageOption = languageOptions[selectedTranslationLanguage]
                        userPreferences.translateLanguage = selectedLanguageOption.code
                        
                        // Save the context
                        do {
                            try viewContext.save()
                            print("Updated user preferences successfully")
                        } catch {
                            print("Failed to update user preferences: \(error)")
                        }
                        
                        // Navigate to next page
                        viewModel.currentPage = 4
                    }) {
                        Text("Continue")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.oliveGreenColor, Color.DarkOliveGreenColor]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .shadow(color: Color.russetColor, radius: 0.75, x: 0.2, y: 0.2)
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
    }
}

// Same components as before
struct GenderButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ?
                              LinearGradient(
                                  gradient: Gradient(colors: [Color.oliveGreenColor, Color.DarkOliveGreenColor]),
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing
                              ) : LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                )
        }
    }
}

struct CountryButton: View {
    let country: String
    let flag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(flag)
                    .font(.system(size: 30))
                
                Text(country)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
            }
            .frame(width: 80, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ?
                          LinearGradient(
                              gradient: Gradient(colors: [Color.oliveGreenColor, Color.DarkOliveGreenColor]),
                              startPoint: .topLeading,
                              endPoint: .bottomTrailing
                          ) : LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)]),
                            startPoint: .leading,
                            endPoint: .trailing
                          ))
            )
        }
    }
}

struct LanguageButton: View {
    let language: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(language)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ?
                              LinearGradient(
                                  gradient: Gradient(colors: [Color.oliveGreenColor, Color.DarkOliveGreenColor]),
                                  startPoint: .topLeading,
                                  endPoint: .bottomTrailing
                              ) : LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                )
        }
    }
}
