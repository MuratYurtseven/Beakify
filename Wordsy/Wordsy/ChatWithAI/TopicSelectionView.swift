//
//  TopicSelectionView.swift
//  Wordsy
//
//  Created by Murat on 11.04.2025.
//
import SwiftUI

struct TopicSelectionView: View {
    let selectedLanguage: String
    let translateLanguage: String
    let topicCategories: [String: [String]]
    let topicDescriptions: [String: String]

    @State private var selectedCategory: String = "All"
    @State private var selectedTopic: String = ""
    @State private var topicDescription: String = ""
    @State private var navigateToChat = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select a Topic")
                .font(.largeTitle)
                .bold()
                .foregroundStyle(Color.darkLavenderPurple.gradient)
                .padding(.horizontal)


            // Category selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(topicCategories.keys).sorted(), id: \.self) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory == category,
                            action: { selectedCategory = category }
                        )
                    }
                }
                .padding(.horizontal)
            }

            // Topics list
            ScrollView {
                VStack(spacing: 12) {
                    // Option for no topic
                    TopicCard(
                        topic: "No specific topic",
                        description: "Free conversation without a specific topic",
                        isSelected: selectedTopic.isEmpty,
                        action: {
                            selectedTopic = ""
                            topicDescription = "Free conversation without a specific topic"
                        }
                    )
                    
                    let topicsToShow = selectedCategory == "All"
                        ? Array(topicDescriptions.keys).sorted()
                        : (topicCategories[selectedCategory] ?? []).sorted()

                    ForEach(topicsToShow, id: \.self) { topic in
                        TopicCard(
                            topic: topic,
                            description: topicDescriptions[topic] ?? "",
                            isSelected: selectedTopic == topic,
                            action: {
                                selectedTopic = topic
                                topicDescription = topicDescriptions[topic] ?? ""
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Start Chat Button
            NavigationLink(destination: ChatWithAIView(
                selectedLanguage: selectedLanguage,
                translateLanguage: translateLanguage,
                selectedTopic: selectedTopic,
                topicDescription: topicDescription
            ), isActive: $navigateToChat) {
                Button(action: {
                    navigateToChat = true
                }) {
                    Text("Start Chat")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [Color.DarkLavenderPurpleColor,Color.DarkLavenderPurpleColor.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        )
                }
                .padding([.horizontal, .bottom], 20)
            }
        }
        .navigationTitle("Choose a Topic")
        .navigationBarTitleDisplayMode(.inline)
    }
}
