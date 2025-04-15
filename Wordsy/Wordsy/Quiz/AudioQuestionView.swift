import SwiftUI
import AVFoundation

struct AudioQuestionView: View {
    let question: QuizQuestion
    let onAnswer: (Bool) -> Void
    
    @State private var selectedOption: String? = nil
    @State private var showAnswer: Bool = false
    @State private var selectedOptionCorrect: Bool = false
    @State private var shakeOptions: Bool = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var speechSynthesizer = AVSpeechSynthesizer()
    @State private var isPlaying: Bool = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Audio player button
            audioPlayerButton
                .padding(.vertical, 10)
            
            // Options grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(question.options, id: \.self) { option in
                    audioOptionButton(option)
                }
            }
            .modifier(ShakeEffect(animatableData: shakeOptions ? 1 : 0))
            .animation(.default, value: shakeOptions)
            
            // "Can't listen" button
            Button(action: {
                let audioText = question.audioText ?? question.correctAnswer
                selectedOption = nil
                showTextOverlay(audioText)
            }) {
                Text("CAN'T LISTEN NOW")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(25)
            }
            .disabled(showAnswer)
            .padding(.top, 10)
            
            // Continue button when answer is shown
            if showAnswer {
                Button(action: {
                    onAnswer(selectedOptionCorrect)
                }) {
                    Text("CONTINUE")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.green.opacity(0.4), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 10)
            }
        }
        .onAppear {
            prepareAudioPlayer()
        }
    }
    
    // Audio player button
    private var audioPlayerButton: some View {
        Button(action: {
            playAudio()
        }) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.blue.opacity(0.4), radius: 4, x: 0, y: 2)
                
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(showAnswer)
    }
    
    // Option button
    private func audioOptionButton(_ option: String) -> some View {
        Button(action: {
            if !showAnswer {
                selectedOption = option
                selectedOptionCorrect = (option == question.correctAnswer)
                
                // Show feedback
                withAnimation {
                    showAnswer = true
                    
                    if !selectedOptionCorrect {
                        shakeOptions = true
                        // Reset shake after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            shakeOptions = false
                        }
                    }
                }
            }
        }) {
            VStack(alignment: .center) {
                Text(option)
                    .font(.title3)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(buttonTextColor(option))
                    .padding()
                    .frame(maxWidth: .infinity)
                
                // Show check or X when answer is revealed
                if showAnswer {
                    if option == question.correctAnswer {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 20))
                            .padding(.bottom, 4)
                    } else if option == selectedOption && !selectedOptionCorrect {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.system(size: 20))
                            .padding(.bottom, 4)
                    }
                }
            }
            .frame(height: 100)
            .background(buttonBackgroundColor(option))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(buttonBorderColor(option), lineWidth: 2)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .disabled(showAnswer)
    }
    
    // Prepare the audio player
    private func prepareAudioPlayer() {
        guard let audioURL = question.audioURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
        } catch {
            print("Failed to initialize audio player: \(error)")
        }
    }
    
    // Play audio
    private func playAudio() {
        // First try to play from audio file if available
        if let player = audioPlayer, player.isPlaying {
            player.pause()
            isPlaying = false
            return
        } else if let player = audioPlayer {
            player.play()
            isPlaying = true
            
            // Reset isPlaying when audio finishes
            DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) {
                self.isPlaying = false
            }
            return
        }
        
        // If no audio file is available, use text-to-speech
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.stopSpeaking(at: .immediate)
            isPlaying = false
        } else {
            // Use the correct answer or audio text as the text to speak
            let textToSpeak = question.audioText ?? question.correctAnswer
            
            let utterance = AVSpeechUtterance(string: textToSpeak)
            utterance.rate = 0.5
            utterance.pitchMultiplier = 1.0
            utterance.volume = 1.0
            
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            
            isPlaying = true
            speechSynthesizer.speak(utterance)
            
            // Set a timer to reset the isPlaying state after a reasonable time
            // This is a simpler approach than using notifications
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if !self.speechSynthesizer.isSpeaking {
                    self.isPlaying = false
                }
            }
        }
    }
    
    // Show text overlay when can't listen
    private func showTextOverlay(_ text: String) {
        // In a real app, you'd show a custom overlay with the text
        // For this example, we'll use a simple alert
        let alertController = UIAlertController(
            title: "Audio Text",
            message: text,
            preferredStyle: .alert
        )
        
        alertController.addAction(
            UIAlertAction(title: "OK", style: .default)
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alertController, animated: true)
        }
    }
    
    // Button background color
    private func buttonBackgroundColor(_ option: String) -> Color {
        if !showAnswer {
            return selectedOption == option ? Color.blue.opacity(0.1) : Color.white
        } else {
            if option == question.correctAnswer {
                return Color.green.opacity(0.2)
            } else if option == selectedOption {
                return selectedOptionCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2)
            } else {
                return Color.white
            }
        }
    }
    
    // Button border color
    private func buttonBorderColor(_ option: String) -> Color {
        if !showAnswer {
            return selectedOption == option ? Color.blue : Color.gray.opacity(0.3)
        } else {
            if option == question.correctAnswer {
                return Color.green
            } else if option == selectedOption {
                return selectedOptionCorrect ? Color.green : Color.red
            } else {
                return Color.gray.opacity(0.3)
            }
        }
    }
    
    // Button text color
    private func buttonTextColor(_ option: String) -> Color {
        if showAnswer && option == question.correctAnswer {
            return .green
        } else if showAnswer && option == selectedOption && !selectedOptionCorrect {
            return .red
        } else {
            return .primary
        }
    }
}
