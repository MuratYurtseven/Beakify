//
//  LanguageSelectionChatView.swift
//  Wordsy
//
//  Created by Murat on 11.04.2025.
//
import SwiftUI

struct LanguageSelectionChatView: View {
    @State private var selectedLanguage: String = "English"
    @State private var translateLanguage: String = "Turkish"
    @State private var navigateToTopicSelection = false
    

    // Available languages
    private let languages = ["English", "Turkish", "Spanish", "French", "German", "Italian", "Japanese", "Chinese", "Russian", "Korean", "Arabic", "Portuguese"]
    
    // Topic categories for passing to next screen
    private let topicCategories = [
        "All": [String](),
        "Daily Life": ["Morning Routine", "Commuting to Work", "Weekend Activities", "Hobbies"],
        "Food": ["Favorite Foods", "Cooking", "Restaurants", "Recipes"],
        "Travel": ["Travel Plans", "Destinations", "Travel Tips", "Cultural Experiences"]
    ]
    
    // Topic descriptions for passing to next screen
    private let topicDescriptions = [
        "Morning Routine": "Discussing your morning habits",
        "Commuting to Work": "Talking about your commute to work",
        "Weekend Activities": "Talking about weekend plans",
        "Favorite Foods": "Sharing your favorite dishes",
        "Travel Plans": "Discussing upcoming trips",
        "Cooking": "Sharing cooking experiences and recipes",
        "Restaurants": "Discussing favorite restaurants",
        "Recipes": "Sharing and discussing recipes",
        "Destinations": "Discussing travel destinations",
        "Travel Tips": "Sharing travel advice and tips",
        "Cultural Experiences": "Discussing experiences with different cultures",
        "Hobbies": "Discussing personal interests and activities"
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 30) {
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Choose your practice language:")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                                .foregroundStyle(Color.primary)
                            languageSelectionGrid(
                                title: "Practice in",
                                selection: $selectedLanguage,
                                disabledLanguage: translateLanguage
                            )
                            
                            Text("Translate responses to:")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                                .padding(.top, 10)
                                .foregroundStyle(Color.primary)
                            
                            languageSelectionGrid(
                                title: "Translate to",
                                selection: $translateLanguage,
                                disabledLanguage: selectedLanguage
                            )
                        }
                        
                        Spacer()
                        
                        // Continue button
                        NavigationLink(destination:
                            TopicSelectionView(
                                selectedLanguage: selectedLanguage,
                                translateLanguage: translateLanguage,
                                topicCategories: topicCategories,
                                topicDescriptions: topicDescriptions
                            )
                        ) {
                            Text("Continue")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(LinearGradient(colors: [Color.darkLavenderPurple,Color.darkLavenderPurple.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                                )
                                .padding(.horizontal, 30)
                        }
                        .padding(.bottom, 40)
                    }
                    .padding()
                }
            }
            //.navigationBarHidden(true)
            .navigationTitle("Chat")
        }
    }
    
    @ViewBuilder
    private func languageSelectionGrid(title: String, selection: Binding<String>, disabledLanguage: String) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(languages, id: \.self) { language in
                LanguageCard(
                    language: language,
                    isSelected: selection.wrappedValue == language,
                    isDisabled: language == disabledLanguage,
                    action: {
                        if language != disabledLanguage {
                            selection.wrappedValue = language
                        }
                    }
                )
            }
        }
        .padding(.horizontal)
    }
}

struct LanguageCard: View {
    let language: String
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void
    
    var flagEmoji: String {
        switch language {
        case "English": return "🇺🇸"
        case "Turkish": return "🇹🇷"
        case "Spanish": return "🇪🇸"
        case "French": return "🇫🇷"
        case "German": return "🇩🇪"
        case "Italian": return "🇮🇹"
        case "Japanese": return "🇯🇵"
        case "Chinese": return "🇨🇳"
        case "Russian": return "🇷🇺"
        case "Korean": return "🇰🇷"
        case "Arabic": return "🇦🇪"
        case "Portuguese": return "🇵🇹"
        default: return "🌐"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(flagEmoji)
                    .font(.system(size: 12))
                
                Text(language)
                    .font(.system(size: 8))
                    .foregroundColor(cardTextColor)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
        .disabled(isDisabled)
    }
    
    private var cardBackgroundColor: Color {
        if isDisabled {
            return Color.gray.opacity(0.3)
        } else if isSelected {
            return Color.DarkLavenderPurpleColor
        } else {
            return Color.white
        }
    }
    
    private var cardTextColor: Color {
        if isDisabled {
            return Color.gray
        } else if isSelected {
            return Color.white
        } else {
            return Color.primary
        }
    }
}
