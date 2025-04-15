//
//  LanguageAndTopicSetupView.swift
//  Wordsy
//
//  Created by Murat on 11.04.2025.
//
import SwiftUI
struct LanguageAndTopicSetupView: View {
    @Binding var showSheet: Bool
    @Binding var selectedLanguage: String
    @Binding var selectedTopic: String
    @Binding var topicDescription: String
    @Binding var translateLanguage: String
    
    let languages: [String]
    let topicCategories: [String: [String]]
    let topicDescriptions: [String: String]
    
    @State private var selectedCategory: String = "All"
    
    var onStartChat: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Language Settings")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Practice Language:")
                    .font(.headline)
                
                Picker("Practice Language", selection: $selectedLanguage) {
                    ForEach(languages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Text("Translation Language:")
                    .font(.headline)
                    .padding(.top, 10)
                
                Picker("Translation Language", selection: $translateLanguage) {
                    ForEach(languages, id: \.self) { language in
                        Text(language).tag(language)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding(.horizontal)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Topic Category:")
                    .font(.headline)
                
                Picker("Category", selection: $selectedCategory) {
                    ForEach(Array(topicCategories.keys.sorted()), id: \.self) { category in
                        Text(category).tag(category)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                
                Text("Choose a Topic:")
                    .font(.headline)
                    .padding(.top, 10)
                
                // Topics list from selected category
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button(action: {
                            selectedTopic = ""
                        }) {
                            Text("No Topic")
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(selectedTopic.isEmpty ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundColor(selectedTopic.isEmpty ? .white : .black)
                                .cornerRadius(12)
                        }
                        
                        ForEach(selectedCategory == "All" ? Array(topicDescriptions.keys.sorted()) : (topicCategories[selectedCategory] ?? []), id: \.self) { topic in
                            Button(action: {
                                selectedTopic = topic
                                topicDescription = topicDescriptions[topic] ?? ""
                            }) {
                                Text(topic)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(selectedTopic == topic ? Color.blue : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedTopic == topic ? .white : .black)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }
                
                if !selectedTopic.isEmpty {
                    Text(topicDescription)
                        .italic()
                        .padding(.top, 5)
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                showSheet = false
                onStartChat()
            }) {
                Text("Start Chat")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3).edgesIgnoringSafeArea(.all))
    }
}
