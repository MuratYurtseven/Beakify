import Foundation

// Question Types
enum QuestionType {
    case multipleChoice
    case fillInBlank
    case dragAndDrop
    case audio
}
struct QuizQuestion: Identifiable {
    let id = UUID()
    let questionType: QuestionType
    let word: UserWord
    let question: String
    let correctAnswer: String
    let options: [String]  // For multiple choice
    let sentence: String?  // For fill in the blank
    let blankPosition: Int?  // For fill in the blank
    
    // For drag and drop questions
    let matchPairs: [(term: String, definition: String)]?
    
    // For audio questions
    let audioURL: URL?
    let audioText: String?
    
    // Added field for question-relevant emojis
    let questionEmojis: String?
}
// Quiz Session
struct QuizSession {
    let id = UUID()
    let questions: [QuizQuestion]
    var currentQuestionIndex: Int = 0
    var correctAnswers: Int = 0
    var incorrectAnswers: Int = 0
    var reviewWords: [UserWord] = []
    
    // Track which questions were answered correctly/incorrectly
    var questionResults: [UUID: Bool] = [:]
    
    var isComplete: Bool {
        return currentQuestionIndex >= questions.count
    }
    
    var progress: Double {
        if questions.isEmpty {
            return 0
        }
        return Double(currentQuestionIndex) / Double(questions.count)
    }
    
    var currentQuestion: QuizQuestion? {
        guard currentQuestionIndex < questions.count else {
            return nil
        }
        return questions[currentQuestionIndex]
    }
    
    mutating func answerQuestion(isCorrect: Bool) {
        if let question = currentQuestion {
            if isCorrect {
                correctAnswers += 1
            } else {
                incorrectAnswers += 1
                reviewWords.append(question.word)
            }
            
            questionResults[question.id] = isCorrect
            currentQuestionIndex += 1
        }
    }
}

// Answer Result
struct AnswerResult {
    let isCorrect: Bool
    let correctAnswer: String
    let userAnswer: String
    let explanationMessage: String?
}

// Drag and Drop Item Model
struct DragItem: Identifiable {
    let id = UUID()
    let text: String
    let isCorrect: Bool
    var matched: Bool = false
}

// Drag and Drop Match Model
struct MatchPair: Identifiable {
    let id = UUID()
    let term: String
    let definition: String
} 
