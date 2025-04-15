//
//  OnboardingView2.swift
//  Wordsy
//
//  Created by Murat on 12.04.2025.
//


import SwiftUI

struct OnboardingView2: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    // Learning preferences
    @State private var selectedFrequency = 0
    let frequencyOptions = ["Daily", "Twice a week", "Weekly"]
    
    @State private var selectedLanguages: [String: Bool] = [
        "English": false,
        "Spanish": false,
        "French": false,
        "German": false,
        "Italian": false,
        "Japanese": false,
        "Chinese": false,
        "Russian": false,
        "Turkish": false,
        "Korean":false,
        "Arabic":false,
        "Portuguese": false
    ]
    
    // Flag emoji mapping for each language
    let languageFlags: [String: String] = [
        "English": "🇺🇸",
        "Spanish": "🇪🇸",
        "French": "🇫🇷",
        "German": "🇩🇪",
        "Italian": "🇮🇹",
        "Japanese": "🇯🇵",
        "Chinese": "🇨🇳",
        "Russian": "🇷🇺",
        "Turkish": "🇹🇷",
        "Korean": "🇰🇷",
        "Arabic": "🇦🇪",
        "Portuguese":"🇵🇹"
    ]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
            ScrollView(.vertical) {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Choose Your Languages")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 20)
                        
                        Text("Select the languages you want to learn")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // Learning frequency section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("How often would you like to learn?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        HStack {
                            ForEach(0..<frequencyOptions.count, id: \.self) { index in
                                FrequencyButton(
                                    text: frequencyOptions[index],
                                    isSelected: selectedFrequency == index,
                                    action: {
                                        selectedFrequency = index
                                    }
                                )
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    // Languages grid with flags
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Which languages would you like to learn?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 5)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(selectedLanguages.keys.sorted(), id: \.self) { language in
                                LanguageSelectionButton(
                                    language: language,
                                    flag: languageFlags[language] ?? "🏳️",
                                    isSelected: selectedLanguages[language] ?? false,
                                    action: {
                                        selectedLanguages[language]?.toggle()
                                    }
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 15)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Continue button
                    Button(action: {
                        // Save preferences to viewModel
                        viewModel.learningFrequency = frequencyOptions[selectedFrequency]
                        viewModel.selectedLanguages = selectedLanguages.filter { $0.value }.keys.map { $0 }
                        
                        // Move to next screen
                        viewModel.currentPage = 2
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

// Fixed FrequencyButton component
struct FrequencyButton: View {
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
                              )
                              : LinearGradient(
                                gradient: Gradient(colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)]),
                                startPoint: .leading,
                                endPoint: .trailing
                              ))
                )
        }
    }
}

// Fixed LanguageSelectionButton component
struct LanguageSelectionButton: View {
    let language: String
    let flag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(flag)
                    .font(.system(size: 24))
                    .padding(.trailing, 5)
                
                Text(language)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .bold))
                }
            }
            .padding(12)
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
