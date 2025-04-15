import Foundation
import CoreData

class QuizGenerator {
    
    private static let quizAPIService = QuizAPIService()
    
    // This method is kept for backward compatibility but simply forwards to the API version
    static func generateQuiz(from words: [UserWord], context: NSManagedObjectContext, questionCount: Int = 10) -> QuizSession {
        // This is now just a placeholder that returns an empty session
        // All quiz generation should use generateQuizWithAPI
        return QuizSession(questions: [])
    }
    
    // Generate quiz using the OpenAI API with contextual awareness of word groups and quiz type
    static func generateQuizWithAPI(from words: [UserWord],
                                    language: String? = nil,
                                   context: NSManagedObjectContext,
                                   quizType: QuizSelectionView.QuizType = .standard,
                                   completion: @escaping (QuizSession) -> Void) {
        // Ensure we have enough words for a quiz
        guard words.count >= 3 else {
            completion(QuizSession(questions: []))
            return
        }
        
        // Get the language from the word group (if available)
        var quizLanguage: String = language != nil ? language! : "en" // Default to English
        if let firstWord = words.first,
           let wordGroup = firstWord.groupsArray.first {
            quizLanguage = wordGroup.selectedLanguageValue ?? "en"
        }
        
        // Use the API service to generate quiz questions with the specified quiz type and language
        quizAPIService.generateQuiz(for: words, quizType: quizType, language: quizLanguage) { result in
            switch result {
            case .success(let questions):
                // Create a new quiz session with the generated questions
                let session = QuizSession(questions: questions)
                completion(session)
                
            case .failure(let error):
                print("Failed to generate quiz with API: \(error)")
                // Return empty session on error
                completion(QuizSession(questions: []))
            }
        }
    }
}
