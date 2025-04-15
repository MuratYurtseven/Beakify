//
//  OnboardingView3.swift
//  Wordsy
//
//  Created by Murat on 12.04.2025.
//
import SwiftUI

struct OnboardingView3: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    @State private var reviewFrequency = 0
    let reviewOptions = ["Multiple times daily", "Once daily", "Every other day", "Weekly"]
    
    @State private var contentPreferences: [String: Bool] = [
        "Movies": false,
        "TV Shows": false,
        "Books": false,
        "News": false,
        "Music": false,
        "Podcasts": false,
        "Casual Conversations": false,
        "Social Media": false
    ]
    
    // Icon mapping for content types
    let contentIcons: [String: String] = [
        "Movies": "film",
        "TV Shows": "tv",
        "Books": "book",
        "News": "newspaper",
        "Music": "music.note",
        "Podcasts": "headphones",
        "Casual Conversations": "bubble.left.and.bubble.right",
        "Social Media": "network"
    ]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGray6).edgesIgnoringSafeArea(.all)
            
            ScrollView(.vertical){
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 10) {
                        Text("Your Learning Style")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.top, 20)
                        
                        Text("Tell us how you prefer to learn")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)
                    
                    // Review frequency section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("How often would you like to review vocabulary?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            ForEach(0..<reviewOptions.count, id: \.self) { index in
                                ReviewFrequencyButton(
                                    text: reviewOptions[index],
                                    isSelected: reviewFrequency == index,
                                    action: {
                                        reviewFrequency = index
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
                    
                    // Content preferences section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("What kind of content do you enjoy?")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(contentPreferences.keys.sorted(), id: \.self) { content in
                                ContentPreferenceButton(
                                    text: content,
                                    iconName: contentIcons[content] ?? "star",
                                    isSelected: contentPreferences[content] ?? false,
                                    action: {
                                        contentPreferences[content]?.toggle()
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
                        viewModel.reviewFrequency = reviewOptions[reviewFrequency]
                        viewModel.contentPreferences = contentPreferences.filter { $0.value }.keys.map { $0 }
                        
                        // Move to next screen
                        viewModel.currentPage = 3
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

// Fixed ReviewFrequencyButton component
struct ReviewFrequencyButton: View {
    let text: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
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

// Fixed ContentPreferenceButton component
struct ContentPreferenceButton: View {
    let text: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(height: 90)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
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
