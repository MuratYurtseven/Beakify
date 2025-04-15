//
//  OnboardingView5.swift
//  Wordsy
//
//  Created by Murat on 12.04.2025.
//
import SwiftUI

struct OnboardingView5: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    @State private var progress: CGFloat = 0
    @State private var percentage: Int = 0
    @State private var showMainText = false
    @State private var showProgressBar = false
    @State private var showSubText = false
    @State private var showLanguageCard = false
    
    // States for language learning items
    @State private var showVocabulary = false
    @State private var showGrammar = false
    @State private var showSpeaking = false
    @State private var showListening = false
    @State private var showReading = false
    @State private var showWriting = false
    @State private var showContinueButton = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.oliveGreenColor.opacity(0.1), Color.DarkOliveGreenColor.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            ScrollView(.vertical) {
                VStack(spacing: 25) {
                    Spacer()
                    
                    // Percentage counter
                    Text("\(percentage)%")
                        .font(.system(size: 70, weight: .bold))
                        .foregroundStyle(percentage == 100 ?
                        LinearGradient(colors: [Color.oliveGreenColor,Color.DarkOliveGreenColor], startPoint: .topLeading, endPoint: .bottomTrailing)
                                         : LinearGradient(colors: [Color.primary,Color.primary], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .shadow(color: percentage == 100 ? Color.russetColor :Color.black, radius: percentage == 100 ? 0.75 : 0, x: 0.3, y: 0.3)
                        .opacity(progress > 0 ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5), value: progress)
                    
                    // Main text
                    Text("Creating your\npersonalized learning plan")
                        .font(.system(size: 28, weight: .bold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                        .opacity(showMainText ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8), value: showMainText)
                    
                    // Progress bar with gradient
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(height: 8)
                            .foregroundColor(Color.gray.opacity(0.3))
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.oliveGreenColor, Color.DarkOliveGreenColor]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.russetColor, radius: 0.75, x: 0.2, y: 0.2)
                            .frame(width: min(UIScreen.main.bounds.width - 40, (UIScreen.main.bounds.width - 40) * progress), height: 8)
                    }
                    .padding(.horizontal, 20)
                    .opacity(showProgressBar ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8), value: showProgressBar)
                    
                    // Subtitle text
                    Text("Finalizing your learning journey...")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .opacity(showSubText ? 1 : 0)
                        .animation(.easeInOut(duration: 0.8), value: showSubText)
                    
                    Spacer()
                    
                    // Language learning card
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Your personalized plan includes:")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.top, 5)
                        
                        Divider()
                            .background(Color.white.opacity(0.3))
                        
                        LearningFeatureItem(
                            icon: "book.fill",
                            text: "Vocabulary Building",
                            description: "Learn new words daily",
                            isShowing: showVocabulary
                        )
                        
                        LearningFeatureItem(
                            icon: "textformat",
                            text: "Grammar Fundamentals",
                            description: "Master language structure",
                            isShowing: showGrammar
                        )
                        
                        LearningFeatureItem(
                            icon: "mic.fill",
                            text: "Speaking Practice",
                            description: "Improve pronunciation",
                            isShowing: showSpeaking
                        )
                        
                        LearningFeatureItem(
                            icon: "ear.fill",
                            text: "Listening Comprehension",
                            description: "Understand native speakers",
                            isShowing: showListening
                        )
                        
                        LearningFeatureItem(
                            icon: "doc.text.fill",
                            text: "Reading Skills",
                            description: "Practice with real content",
                            isShowing: showReading
                        )
                        
                        LearningFeatureItem(
                            icon: "pencil",
                            text: "Writing Exercises",
                            description: "Express yourself fluently",
                            isShowing: showWriting
                        )
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.oliveGreenColor, Color.DarkOliveGreenColor]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .shadow(color: Color.russetColor, radius: 0.75, x: 0.2, y: 0.2)
                        .cornerRadius(20)
                    )
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 10)
                    .padding(.horizontal, 20)
                    .opacity(showLanguageCard ? 1 : 0)
                    .scaleEffect(showLanguageCard ? 1 : 0.9)
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showLanguageCard)
                    
                    // Continue button (shown at the end) - Now shows paywall instead of completing directly
                    Button(action: {
                        viewModel.completeOnboarding() // This will now trigger the paywall
                    }) {
                        Text("Continue to Premium")
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
                    .opacity(showContinueButton ? 1 : 0)
                    .animation(.easeInOut(duration: 0.8), value: showContinueButton)
                }
            }

        }
        .onAppear {
            viewModel.generateLearningPlan()
            startAnimation()
        }
    }
    
    func startAnimation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showMainText = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showProgressBar = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showSubText = true
            }
        }
        
        // Animate progress bar and percentage
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            if self.progress < 1.0 {
                self.progress += 0.01
                self.percentage = Int(self.progress * 100)
            } else {
                timer.invalidate()
                self.animateLanguageCard()
            }
        }
    }
    
    func animateLanguageCard() {
        // Show language card
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                showLanguageCard = true
            }
            
            // Animate feature items one by one
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation { showVocabulary = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation { showGrammar = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation { showSpeaking = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation { showListening = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation { showReading = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                withAnimation {
                    showWriting = true
                    
                    // Show continue button after all features are shown
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation {
                            showContinueButton = true
                        }
                    }
                }
            }
        }
    }
}

// Component for showing learning features
struct LearningFeatureItem: View {
    let icon: String
    let text: String
    let description: String
    let isShowing: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.2))
                .cornerRadius(10)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(text)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            ZStack{
                Circle()
                    .stroke(lineWidth: 1)
                    .foregroundStyle(Color.white)
                    .frame(width: 21,height: 21)
                    
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 18))
            }
        }
        .padding(.vertical, 8)
        .opacity(isShowing ? 1 : 0)
        .offset(x: isShowing ? 0 : 50)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isShowing)
    }
}
