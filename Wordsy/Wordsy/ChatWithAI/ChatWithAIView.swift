//
//  ChatWithAIView.swift
//  Wordsy
//
//  Created by Murat on 11.04.2025.
//
import SwiftUI

struct ChatWithAIView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserPreferences.createdAt, ascending: false)],
        animation: .default)
    private var preferences: FetchedResults<UserPreferences>
    // Parameters passed from previous screens
    let selectedLanguage: String
    let translateLanguage: String
    let selectedTopic: String
    let topicDescription: String
    
    // Chat state
    @State private var messages: [ChatMessage] = []
    @State private var newMessage: String = ""
    @State private var isLoading: Bool = false
    @State private var scrollToBottom = false
    
    // ScrollView reader for auto-scrolling
    @Namespace private var bottomID
    
    // Use the shared OpenAI service from AppConfig
    private let openAIService = AppConfig.openAIService
    
    
    // Navigation
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background
            Color.gray.opacity(0.05).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom navigation bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Circle().fill(Color.white))
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 3) {
                        Text("Wordsy Chat")
                            .font(.headline)
                            .foregroundStyle(Color.DarkLavenderPurpleColor.gradient)
                        HStack(spacing: 5) {
                            Text("🗣 \(selectedLanguage)")
                                .font(.caption2)
                            
                            if !selectedTopic.isEmpty {
                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                
                                Text("\(selectedTopic)")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(Color.lavenderPurpleColor)
                                    .lineLimit(1)
                                    
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        
                    }) {
                        Image(systemName: "info.circle")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Circle().fill(Color.white))
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
                    }
                }
                .padding()
                .background(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                
                // Messages list
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(messages) { message in
                                MessageBubble(
                                    message: message,
                                    translateLanguage: translateLanguage,
                                    onTranslate: { message in
                                        translateMessage(message)
                                    },
                                    refreshID: UUID(),
                                    speakLanguage:selectedLanguage
                                    
                                )
                            }
                            
                            if isLoading {
                                HStack {
                                    Spacer()
                                    
                                    TypingIndicator()
                                        .padding()
                                        .background(Color.gray.opacity(0.1))
                                        .cornerRadius(20)
                                    
                                    Spacer()
                                }
                            }
                            
                            // Invisible view for scrolling target
                            Color.clear
                                .frame(height: 1)
                                .id(bottomID)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 10)
                    }
                    .onChange(of: messages) { _ in
                        withAnimation {
                            scrollView.scrollTo(bottomID)
                        }
                    }
                    .onChange(of: isLoading) { _ in
                        withAnimation {
                            scrollView.scrollTo(bottomID)
                        }
                    }
                }
                
                // Message input area
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $newMessage)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                        )
                    
                    Button(action: sendMessage) {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                            .padding(12)
                            .background(
                                Circle()
                                    .fill(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading ? Color.gray : Color.DarkLavenderPurpleColor)
                            )
                    }
                    .disabled(newMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                }
                .padding()
                .background(Color.white)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startConversation()
        }
    }
    
    private func startConversation() {
        // Show loading indicator while getting initial message
        isLoading = true
        
        // Create appropriate prompt based on topic
        let prompt: String
        if !selectedTopic.isEmpty {
            prompt = "Create a welcoming greeting in \(selectedLanguage) language for a language learning app chat. Mention that we'll talk about \(selectedTopic): \(topicDescription). Ask how you can help today. Keep it under 20 words. Use ONLY \(selectedLanguage) language, no other language."
        } else {
            prompt = "Create a welcoming greeting in \(selectedLanguage) language for a language learning app chat. Mention that you're ready to help practice \(selectedLanguage). Ask what they want to talk about. Keep it under 20 words. Use ONLY \(selectedLanguage) language, no other language."
        }
        
        // Use the OpenAI service to generate the first message in the selected language
        let dummyMessages = [ChatMessage(content: prompt, isUser: true, translatedContent: nil)]
        openAIService.chatWithAI(messages: dummyMessages, selectedLanguage: selectedLanguage) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    // Add AI welcome message in the selected language
                    messages.append(ChatMessage(
                        content: response,
                        isUser: false,
                        translatedContent: nil
                    ))
                case .failure(let error):
                    print("Error getting AI greeting: \(error.localizedDescription)")
                    // Fallback to a simple greeting in case of error
                    let fallbackGreeting = "👋 \(selectedLanguage)!"
                    messages.append(ChatMessage(
                        content: fallbackGreeting,
                        isUser: false,
                        translatedContent: nil
                    ))
                }
            }
        }
    }
    
    private func sendMessage() {
        let messageText = newMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !messageText.isEmpty else { return }
        
        // Add user message
        messages.append(ChatMessage(
            content: messageText,
            isUser: true,
            translatedContent: nil
        ))
        
        // Clear input
        newMessage = ""
        isLoading = true
        
        // Use OpenAI service to get response
        openAIService.chatWithAI(messages: messages, selectedLanguage: selectedLanguage) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let response):
                    messages.append(ChatMessage(
                        content: response,
                        isUser: false,
                        translatedContent: nil
                    ))
                case .failure(let error):
                    print("Error getting AI response: \(error.localizedDescription)")
                    // Show error message
                    messages.append(ChatMessage(
                        content: "Sorry, I couldn't process your message. Please try again.",
                        isUser: false,
                        translatedContent: nil
                    ))
                }
            }
        }
    }
    
    func translateLanguageForChat() -> String {
        // First try to use the translateLanguage parameter passed to the view
        if !translateLanguage.isEmpty {
            return translateLanguage
        }
        
        // Fall back to user preferences if available
        if let preferredLanguage = preferences.first?.translateLanguageValue {
            return preferredLanguage
        }
        
        // Default to English if nothing else is available
        return "English"
    }

    private func translateMessage(_ message: ChatMessage) {
        // Find index of the message to update
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            print("Message not found in array")
            return
        }
        
        // Set translating state
        var updatingMessages = self.messages
        var updatingMessage = updatingMessages[index]
        updatingMessage.isTranslating = true
        updatingMessages[index] = updatingMessage
        
        // Update UI immediately
        self.messages = updatingMessages
        
        // Get translation language using our helper function
        let targetLanguage = translateLanguageForChat()
        
        // Prepare translation prompt
        let prompt = "Translate the following text from \(selectedLanguage) to \(targetLanguage): \"\(message.content)\""
        
        openAIService.generateTranslation(prompt: prompt, translateLanguage: targetLanguage) { result in
            DispatchQueue.main.async {
                // Get fresh index in case array changed
                guard let currentIndex = self.messages.firstIndex(where: { $0.id == message.id }) else {
                    print("Message not found for update")
                    return
                }
                
                // Create a new array to force a UI update
                var newMessages = self.messages
                var updatedMessage = newMessages[currentIndex]
                
                switch result {
                case .success(let translation):
                    updatedMessage.translatedContent = translation
                case .failure(let error):
                    print("Translation error: \(error.localizedDescription)")
                    updatedMessage.translatedContent = "Translation failed. Try again."
                }
                
                // Clear translating state
                updatedMessage.isTranslating = false
                newMessages[currentIndex] = updatedMessage
                
                // Reassign to trigger state update
                self.messages = newMessages
            }
        }
    }
}
struct TypingIndicator: View {
    @State private var firstCircleScale: CGFloat = 1.0
    @State private var secondCircleScale: CGFloat = 1.0
    @State private var thirdCircleScale: CGFloat = 1.0
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundColor(.gray)
                    .scaleEffect(index == 0 ? firstCircleScale : (index == 1 ? secondCircleScale : thirdCircleScale))
            }
        }
        .onAppear {
            let animation = Animation.easeInOut(duration: 0.4).repeatForever(autoreverses: true)
            withAnimation(animation.delay(0.0)) {
                firstCircleScale = 0.6
            }
            withAnimation(animation.delay(0.2)) {
                secondCircleScale = 0.6
            }
            withAnimation(animation.delay(0.4)) {
                thirdCircleScale = 0.6
            }
        }
    }
}
