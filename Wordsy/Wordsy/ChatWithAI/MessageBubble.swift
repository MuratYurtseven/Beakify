//
//  MessageBubble.swift
//  Wordsy
//
//  Created by Murat on 11.04.2025.
//
import SwiftUI
import AVFoundation

struct MessageBubble: View {
    let message: ChatMessage
    let translateLanguage: String
    let onTranslate: (ChatMessage) -> Void
    let refreshID: UUID
    let speakLanguage: String
    
    @State private var showTranslation: Bool = false
    @State private var isSpeaking: Bool = false
    @State private var animateButtons: Bool = false
    
    // Shared speech synthesizer
    private static let sharedSpeechSynthesizer = AVSpeechSynthesizer()
    private var speechSynthesizer: AVSpeechSynthesizer {
        return MessageBubble.sharedSpeechSynthesizer
    }
    
    var body: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            // Message bubble
            VStack(alignment: .leading, spacing: 4) {
                // Optional sender name (for AI messages)
                if !message.isUser {
                    HStack(spacing: 6) {
                        Image("duckImg")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20,height: 20)
                            .clipShape(Circle())
                        
                        Text("Beakify")
                            .font(.caption.bold())
                            .foregroundColor(.DarkLavenderPurpleColor)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                
                // Message content
                HStack{
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(message.isUser ? .white : .black)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(5)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                    Spacer()
                }
                // Action buttons row
                HStack(spacing: 20) {
                    // Sound button with AVFoundation
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if isSpeaking {
                                stopSpeaking()
                            } else {
                                speakText(message.content)
                            }
                        }
                    }) {
                        Image(systemName: isSpeaking ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(message.isUser ? .white.opacity(0.9) : .DarkLavenderPurpleColor)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(message.isUser ? .white.opacity(0.2) : .DarkLavenderPurpleColor.opacity(0.1))
                            )
                            .scaleEffect(isSpeaking ? 1.1 : 1.0)
                    }
                    
                    // Translate button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            if message.translatedContent == nil && !message.isTranslating {
                                onTranslate(message)
                            }
                            showTranslation.toggle()
                        }
                    }) {
                        Image(systemName: "character.bubble.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(message.isUser ? .white.opacity(0.9) : .DarkLavenderPurpleColor)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(message.isUser ? .white.opacity(0.2) : .DarkLavenderPurpleColor.opacity(0.1))
                            )
                            .scaleEffect(showTranslation ? 1.1 : 1.0)
                    }
                    
                    // Bookmark button
                    Button(action: {
                        // Bookmark functionality
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            // Bookmark logic would go here
                        }
                    }) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(message.isUser ? .white.opacity(0.9) : .DarkLavenderPurpleColor)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(message.isUser ? .white.opacity(0.2) : .DarkLavenderPurpleColor.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .offset(y: animateButtons ? 0 : 20)
                .opacity(animateButtons ? 1 : 0)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: message.isUser ? .trailing : .leading)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(message.isUser ? LinearGradient(colors: [Color.DarkLavenderPurpleColor.opacity(0.5),Color.DarkLavenderPurpleColor.opacity(0.45)], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [Color.gray.opacity(0.1),Color.gray.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
            .padding(message.isUser ? .trailing : .leading, 8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3).delay(0.1)) {
                    animateButtons = true
                }
            }
            
            // Translation view
            if showTranslation {
                VStack(alignment: .leading, spacing: 6) {
                    // Translation status/content
                    if message.isTranslating {
                        HStack(spacing: 8) {
                            Text("Translating to \(translateLanguage)...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.gray.opacity(0.08))
                        )
                    } else if let translatedContent = message.translatedContent {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(translateLanguage)
                                    .font(.caption.bold())
                                    .foregroundColor(Color.lavenderPurpleColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(Color.lavenderPurpleColor.opacity(0.1))
                                    )
                                
                                Spacer()
                                
                            }
                            
                            Text(translatedContent)
                                .font(.system(size: 16))
                                .foregroundColor(.black.opacity(0.8))
                                .lineSpacing(5)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.lavenderPurpleColor.opacity(0.07))
                                .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                        )
                    } else {
                        HStack(spacing: 10) {
                            ProgressView()
                                .scaleEffect(0.8)
                            
                            Text("Starting translation...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.gray.opacity(0.08))
                        )
                        .onAppear {
                            onTranslate(message)
                        }
                    }
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .id("\(message.id)-\(message.translatedContent ?? "")-\(message.isTranslating ? "translating" : "idle")")
        .onDisappear {
            stopSpeaking()
        }
    }
    
    private func speakText(_ text: String, language: String? = nil) {
        // Stop any current speech first
        stopSpeaking()
        
        // Configure audio session explicitly
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to set up audio session: \(error)")
            return
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Burada dil kodunu ayarlıyoruz - eksik olan kısım buydu
        if let languageCode = language {
            utterance.voice = AVSpeechSynthesisVoice(language: languageCode)
        } else {
            // Varsayılan olarak verilen speakLanguage kullanılıyor
            utterance.voice = AVSpeechSynthesisVoice(language: getLanguageCode(for: speakLanguage))
        }
        
        // Diğer ayarlar (opsiyonel)
        utterance.rate = 0.5  // Normal konuşma hızı
        utterance.pitchMultiplier = 1.0  // Normal ses tonu
        utterance.volume = 1.0  // Tam ses
        
        // Use main thread to start speaking
        DispatchQueue.main.async {
            self.speechSynthesizer.speak(utterance)
            self.isSpeaking = true
        }
    }
    
    // Modify the stop function
    private func stopSpeaking() {
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }
    
    
    // Helper function to get language code for AVSpeechSynthesizer
    private func getLanguageCode(for language: String) -> String {
        switch language {
        case "English": return "en-US"
        case "Turkish": return "tr-TR"
        case "Spanish": return "es-ES"
        case "French": return "fr-FR"
        case "German": return "de-DE"
        case "Italian": return "it-IT"
        case "Japanese": return "ja-JP"
        case "Chinese": return "zh-CN"
        case "Russian": return "ru-RU"
        case "Korean": return "ko-KR"
        case "Arabic": return "ar-SA"
        case "Portuguese": return "pt-PT"
        default: return "en-US"
        }
    }
}

// Speech delegate to handle callbacks
class SpeechSynthesizerDelegate: NSObject, AVSpeechSynthesizerDelegate {
    var onFinish: () -> Void
    
    init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
        super.init()
    }
    
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        onFinish()
    }
}



