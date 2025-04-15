//
//  QuizViewWithWords.swift
//  Wordsy
//
//  Created by Murat on 11.04.2025.
//

import SwiftUI


struct QuizViewWithWords: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    let words: [UserWord]
    let language: String
    let groupName: String
    @State private var quizSession = QuizSession(questions: [], currentQuestionIndex: 0)
    @State private var selectedOption: String? = nil
    @State private var showAnswer: Bool = false
    @State private var selectedOptionCorrect: Bool = false
    @State private var showingResults: Bool = false
    @State private var shakeOptions: Bool = false
    @State private var animatingProgress: Bool = false
    @State private var showingCelebration: Bool = false
    @State private var quizLoading: Bool = true
    @State private var quizError: String? = nil
    
    init(language: String, words: [UserWord],groupName:String) {
        self.words = words.filter { $0 != nil }
        self.language = language
        self.groupName = groupName
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()
            
            if quizLoading {
                // Loading state
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Preparing your quiz...")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.DarkDustyBlueColor.gradient)
                        .padding(.top, 20)
                }
            } else if let error = quizError {
                // Error state
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .fontWeight(.bold)
                        .foregroundColor(.russetColor)
                    
                    Text("Something went wrong")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Go back")
                            .fontWeight(.medium)
                            .padding()
                            .frame(width: 200)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 20)
                }
                .padding()
            } else if words.count < 3 {
                // Not enough words view
                VStack(spacing: 20) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 70))
                        .foregroundColor(.orange)
                    
                    Text("Not Enough Words")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Add at least 3 words to this group to start a quiz.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Go Back")
                            .fontWeight(.medium)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 20)
                }
                .padding()
            } else if showingResults {
                // Quiz results - same as in QuizView
                quizResultsView
            } else {
                // Quiz content - with support for different question types
                VStack {
                    // Progress bar
                    VStack(alignment: .leading, spacing: 8) {
                        Text(groupName)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.DarkDustyBlueColor.gradient)
                            
                        Text("Question \(quizSession.currentQuestionIndex + 1) of \(quizSession.questions.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                Rectangle()
                                    .foregroundColor(Color.secondary.opacity(0.2))
                                    .cornerRadius(10)
                                
                                // Progress
                                Rectangle()
                                    .frame(width: geometry.size.width * quizSession.progress)
                                    .foregroundStyle(Color.oliveGreenColor.gradient)
                                    .cornerRadius(10)
                                    .animation(.spring(), value: quizSession.progress)
                            }
                            .frame(height: 12)
                        }
                        .frame(height: 12)
                    }
                    .padding(.horizontal)
                    .padding(.top)
                    
                    // Question card - switch between question types
                    if let currentQuestion = quizSession.currentQuestion {
                        ScrollView {
                            // Display appropriate question view based on type
                            questionView(for: currentQuestion)
                        }
                    }
                }
                .animation(.spring(), value: quizSession.currentQuestionIndex)
                .animation(.spring(), value: showAnswer)
            }
        }
        .onAppear {
            // Generate quiz on appear using only the words from this group
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                generateQuiz()
            }
        }
    }
    
    // MARK: - Question Views
    
    // Choose the appropriate view based on question type
    @ViewBuilder
    private func questionView(for question: QuizQuestion) -> some View {
        switch question.questionType {
        case .multipleChoice, .fillInBlank:
            multipleChoiceView(for: question)
        case .audio:
            AudioQuestionView(question: question) { isCorrect in
                handleAnswer(isCorrect: isCorrect)
            }
            .padding()
        case .dragAndDrop:
            DragDropQuizView(question: question) { isCorrect in
                handleAnswer(isCorrect: isCorrect)
            }
            .padding()
        default:
            // Fallback to multiple choice if type is unknown
            multipleChoiceView(for: question)
        }
    }
    
    // Handle answer from any question type
    private func handleAnswer(isCorrect: Bool) {
        // Process the answer
        quizSession.answerQuestion(isCorrect: isCorrect)
        
        // Reset for next question
        selectedOption = nil
        showAnswer = false
        
        // Check if quiz is complete
        if quizSession.isComplete {
            finishQuiz()
        }
    }
    
    // MARK: - Multiple Choice Question View
    
    // Update the multipleChoiceView function in QuizViewWithWords.swift to use emojis from OpenAI

    private func multipleChoiceView(for question: QuizQuestion) -> some View {
        VStack(spacing: 24) {
            // Question
            VStack(alignment: .leading, spacing: 16) {
                // Question-relevant emojis from OpenAI
                HStack {
                    Text(question.questionEmojis ?? "🤔📚📝")
                        .font(.system(size: 24))
                        .padding(12)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    Spacer()
                }
                
                // Question text
                Text(question.question)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(LinearGradient(colors: [Color.black,Color.black.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .padding(.bottom, 4)
                
                // Fill in the blank sentence
                if question.questionType == .fillInBlank, let sentence = question.sentence {
                    Text(sentence)
                        .font(.body)
                        .padding()
                        .background(Color.dustyBlueColor.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.dustyBlueColor.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            
            // Options
            VStack(spacing: 14) {
                ForEach(question.options, id: \.self) { option in
                    optionButton(option, for: question)
                }
            }
            .modifier(ShakeEffect(animatableData: shakeOptions ? 1 : 0))
            .animation(.default, value: shakeOptions)
            
            // Continue button (when answer shown)
            if showAnswer {
                Button(action: {
                    handleAnswer(isCorrect: selectedOptionCorrect)
                }) {
                    Text("CONTINUE")
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(LinearGradient(colors: [Color.DarkDustyBlueColor, Color.DarkDustyBlueColor.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Color.DarkOliveGreenColor.opacity(0.4), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 20)
            }
        }
        .padding()
    }
    
    // Option button for multiple choice
    func optionButton(_ option: String, for question: QuizQuestion) -> some View {
        Button(action: {
            if !showAnswer {
                selectedOption = option
                selectedOptionCorrect = (option == question.correctAnswer)
                
                // Show feedback with animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showAnswer = true
                    
                    if !selectedOptionCorrect {
                        shakeOptions = true
                        // Haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)
                        
                        // Reset shake after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            shakeOptions = false
                        }
                    } else {
                        // Success haptic
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                    }
                }
            }
        }) {
            HStack {
                // Add icon based on state
                ZStack {
                    Circle()
                        .fill(showAnswer ?
                              (selectedOption == option ?
                               (selectedOptionCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                               : Color.white.opacity(0.1))
                              : Color.white.opacity(0.1))
                        .frame(width: 40, height: 40)
                    
                    if showAnswer {
                        if option == question.correctAnswer {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.green.gradient)
                                .font(.system(size: 20, weight: .bold))
                        } else if option == selectedOption && !selectedOptionCorrect {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.red.gradient)
                                .font(.system(size: 20, weight: .bold))
                        } else {
                            Text(String(question.options.firstIndex(of: option)! + 1))
                                .foregroundStyle(Color.dustyBlueColor.gradient)
                                .font(.system(size: 18, weight: .bold))
                        }
                    } else {
                        Text(String(question.options.firstIndex(of: option)! + 1))
                            .foregroundStyle(Color.dustyBlueColor.gradient)
                            .font(.system(size: 18, weight: .bold))
                    }
                }
                
                Text(option)
                    .font(.body)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(buttonTextColor(option, for: question))
                    .padding(.leading, 8)
                
                Spacer()
                
                // Show check or X when answer is revealed
                if showAnswer {
                    if option == question.correctAnswer {
                        Image(systemName: "party.popper.fill")
                            .foregroundStyle(Color.green.gradient)
                            .font(.system(size: 24))
                            .padding(.trailing, 4)
                    } else if option == selectedOption && !selectedOptionCorrect {
                        Image(systemName: "hand.thumbsdown.fill")
                            .foregroundStyle(Color.red.gradient)
                            .font(.system(size: 20))
                            .padding(.trailing, 4)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(buttonBackgroundColor(option, for: question))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(buttonBorderColor(option, for: question), lineWidth: 2)
            )
            .shadow(color: showAnswer && option == question.correctAnswer ?
                    Color.green.opacity(0.5) : Color.black.opacity(0.1),
                    radius: showAnswer && option == question.correctAnswer ? 8 : 4,
                    x: 0, y: 2)
            .scaleEffect(selectedOption == option && !showAnswer ? 1.02 : 1.0)
            .animation(.spring(), value: selectedOption)
        }
        .disabled(showAnswer)
    }
    
    // MARK: - Results View
    
    var quizResultsView: some View {
        ScrollView(.vertical) {
            VStack(spacing: 24) {
                // Results header
                VStack(spacing: 8) {
                    Image(systemName: showingCelebration ? "star.fill" : "checkmark.circle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(showingCelebration ? .yellow : .green)
                        .scaleEffect(showingCelebration ? 1.1 : 1.0)
                        .animation(Animation.spring(response: 0.3, dampingFraction: 0.6).repeatCount(3, autoreverses: true), value: showingCelebration)
                    
                    Text("Quiz Completed!")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.DarkDustyBlueColor.gradient)
                    
                    Text("You got \(quizSession.correctAnswers) out of \(quizSession.questions.count) questions correct")
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Results circle
                ZStack {
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.3)
                        .foregroundColor(Color.dustyBlueColor)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(quizSession.correctAnswers) / CGFloat(quizSession.questions.count))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        .foregroundColor(Color.oliveGreenColor)
                        .rotationEffect(Angle(degrees: 270.0))
                        .animation(.easeInOut(duration: 1.0), value: animatingProgress)
                    
                    Text("\(Int(Double(quizSession.correctAnswers) / Double(quizSession.questions.count) * 100))%")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .frame(width: 200, height: 200)
                .padding()
                
                // Review words section
                if !quizSession.reviewWords.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Words to Review")
                                .font(.headline)
                                .foregroundStyle(Color.DarkDustyBlueColor.gradient)
                            
                            Spacer()
                            
                            Button(action: reviewAllWords) {
                                Label("Add All to Learning", systemImage: "arrow.clockwise")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                        }
                        
                        ForEach(quizSession.reviewWords, id: \.idValue) { word in
                            HStack {
                                Text(word.wordValue)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Text(word.typeValue)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(4)
                                
                                Button(action: {
                                    reviewWord(word)
                                }) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(.blue)
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .padding(.horizontal)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: generateQuiz) {
                        Text("Take Another Quiz")
                            .fontWeight(.medium)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(colors: [Color.DarkDustyBlueColor, Color.DarkDustyBlueColor.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: Color.DarkOliveGreenColor.opacity(0.4), radius: 4, x: 0, y: 2)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Return to Group")
                            .fontWeight(.medium)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(LinearGradient(colors: [Color.gray, Color.gray.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: Color.gray.opacity(0.4), radius: 4, x: 0, y: 2)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .onAppear {
                // Trigger animations when results view appears
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    animatingProgress = true
                    showingCelebration = true
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // In QuizViewWithWords.swift
    // Add this after the init() method but before the body property

    // MARK: - Lifecycle Methods
    private func generateQuiz() {
        // Check if we have enough words
        guard words.count >= 3 else {
            // Not enough words, just use empty quiz session
            quizSession = QuizSession(questions: [], currentQuestionIndex: 0)
            showingResults = false
            resetState()
            return
        }
        
        // Start loading state
        quizLoading = true
        quizError = nil
        
        // Use the API-powered quiz generator with the specific group words
        QuizGenerator.generateQuizWithAPI(from: words, language: language, context: viewContext) { session in
            // Update on main thread
            DispatchQueue.main.async {
                quizLoading = false
                
                if session.questions.isEmpty {
                    quizError = "Couldn't generate quiz questions. Please try again."
                } else {
                    // Create a new session with randomized options for each question
                    var randomizedQuestions = [QuizQuestion]()
                    
                    for question in session.questions {
                        // Create a copy of the question with shuffled options
                        let shuffledOptions = question.options.shuffled()
                        
                        // Create a new question with the shuffled options
                        let randomizedQuestion = QuizQuestion(
                            questionType: question.questionType,
                            word: question.word,
                            question: question.question,
                            correctAnswer: question.correctAnswer,
                            options: shuffledOptions,
                            sentence: question.sentence,
                            blankPosition: question.blankPosition,
                            matchPairs: question.matchPairs,
                            audioURL: question.audioURL,
                            audioText: question.audioText, questionEmojis: question.questionEmojis
                        )
                        
                        randomizedQuestions.append(randomizedQuestion)
                    }
                    
                    // Create a new session with the randomized questions
                    let randomizedSession = QuizSession(
                        questions: randomizedQuestions,
                        currentQuestionIndex: session.currentQuestionIndex,
                        correctAnswers: session.correctAnswers,
                        incorrectAnswers: session.incorrectAnswers,
                        reviewWords: session.reviewWords,
                        questionResults: session.questionResults
                    )
                    
                    quizSession = randomizedSession
                    showingResults = false
                    resetState()
                }
            }
        }
    }
    
    private func resetState() {
        selectedOption = nil
        showAnswer = false
        shakeOptions = false
        selectedOptionCorrect = false
        animatingProgress = false
        showingCelebration = false
    }
    
    private func buttonBackgroundColor(_ option: String, for question: QuizQuestion) -> Color {
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
    
    private func buttonBorderColor(_ option: String, for question: QuizQuestion) -> Color {
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
    
    private func buttonTextColor(_ option: String, for question: QuizQuestion) -> Color {
        if showAnswer && option == question.correctAnswer {
            return .green
        } else if showAnswer && option == selectedOption && !selectedOptionCorrect {
            return .red
        } else {
            return .primary
        }
    }
    
    // Save quiz results when completed
    private func finishQuiz() {
        // Save results to progress tracker
        ProgressTracker.shared.saveCompletedQuizSession(quizSession)
        
        // Show celebration and results
        showingResults = true
        
        // Trigger animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animatingProgress = true
            showingCelebration = true
        }
    }
    
    // Helper methods for review words
    private func reviewWord(_ word: UserWord) {
        // Set the word status to learning
        ProgressTracker.shared.setWordStatus(.learning, for: word.idValue)
        
        // Remove from review list
        if let index = quizSession.reviewWords.firstIndex(where: { $0.idValue == word.idValue }) {
            quizSession.reviewWords.remove(at: index)
        }
    }
    
    private func reviewAllWords() {
        // Set all review words to learning status
        for word in quizSession.reviewWords {
            ProgressTracker.shared.setWordStatus(.learning, for: word.idValue)
        }
        
        // Clear the review list
        quizSession.reviewWords.removeAll()
    }
}



