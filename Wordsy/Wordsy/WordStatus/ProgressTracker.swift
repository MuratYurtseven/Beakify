import Foundation
import CoreData
import SwiftUI
// Extended learning status with more granular tracking
enum WordStatus: String, CaseIterable, Identifiable {
    case new = "new"
    case learning = "learning"
    case mastered = "mastered"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .new: return "New"
        case .learning: return "Learning"
        case .mastered: return "Mastered"
        }
    }
    
    var colorName: Color {
        switch self {
        case .new: return Color.oliveGreenColor
        case .learning: return Color.dustyBlueColor
        case .mastered: return Color.russetColor
        }
    }
}

// Model for tracking quiz results for a word
struct WordQuizResult: Codable {
    let date: Date
    let wordID: UUID
    let isCorrect: Bool
}

// Model for tracking daily progress
struct DailyProgress: Codable, Identifiable {
    var id: String { dateString }
    let date: Date
    let dateString: String
    var wordsLearned: Int
    var wordsReviewed: Int
    var quizzesTaken: Int
    var correctAnswers: Int
    var incorrectAnswers: Int
    
    init(date: Date, wordsLearned: Int = 0, wordsReviewed: Int = 0, quizzesTaken: Int = 0, correctAnswers: Int = 0, incorrectAnswers: Int = 0) {
        self.date = date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
        self.wordsLearned = wordsLearned
        self.wordsReviewed = wordsReviewed
        self.quizzesTaken = quizzesTaken
        self.correctAnswers = correctAnswers
        self.incorrectAnswers = incorrectAnswers
    }
}

class ProgressTracker {
    // MARK: - Singleton and Keys
    static let shared = ProgressTracker()
    
    // UserDefaults Keys
    private let wordStatusKey = "wordStatus_"
    private let quizResultsKey = "quizResults"
    private let dailyProgressKey = "dailyProgress"
    private let quizSessionsKey = "quizSessions"
    
    // MARK: - Word Status Methods
    
    func setWordStatus(_ status: WordStatus, for wordID: UUID) {
        UserDefaults.standard.set(status.rawValue, forKey: "\(wordStatusKey)\(wordID.uuidString)")
        updateDailyProgress()
    }
    
    func getWordStatus(for wordID: UUID) -> WordStatus {
        let statusString = UserDefaults.standard.string(forKey: "\(wordStatusKey)\(wordID.uuidString)") ?? WordStatus.new.rawValue
        return WordStatus(rawValue: statusString) ?? .new
    }
    
    func getWordsWithStatus(_ status: WordStatus, in context: NSManagedObjectContext) -> [UserWord] {
        let wordIDs = getAllWordIDs(with: status)
        
        if wordIDs.isEmpty {
            return []
        }
        
        let fetchRequest: NSFetchRequest<UserWord> = UserWord.fetchRequest()
        // Convert UUIDs to strings to use in predicate
        let wordIDStrings = wordIDs.map { $0.uuidString }
        fetchRequest.predicate = NSPredicate(format: "id IN %@", wordIDStrings)
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Error fetching words with status \(status): \(error)")
            return []
        }
    }
    
    func getAllWordIDs(with status: WordStatus) -> [UUID] {
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        return allKeys.compactMap { key -> UUID? in
            guard key.starts(with: wordStatusKey),
                  let storedStatus = userDefaults.string(forKey: key),
                  storedStatus == status.rawValue else {
                return nil
            }
            
            let idString = String(key.dropFirst(wordStatusKey.count))
            return UUID(uuidString: idString)
        }
    }
    
    // MARK: - Quiz Results Methods
    
    func saveQuizResult(for wordID: UUID, isCorrect: Bool) {
        let result = WordQuizResult(date: Date(), wordID: wordID, isCorrect: isCorrect)
        
        // Get existing results
        var results = getQuizResults()
        
        // Add new result
        results.append(result)
        
        // Save to UserDefaults
        if let encodedData = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(encodedData, forKey: quizResultsKey)
        }
        
        // Update word status based on performance
        updateWordStatus(for: wordID)
        
        // Update daily progress
        updateDailyProgress(correctAnswers: isCorrect ? 1 : 0, incorrectAnswers: isCorrect ? 0 : 1)
    }
    
    func getQuizResults() -> [WordQuizResult] {
        guard let data = UserDefaults.standard.data(forKey: quizResultsKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([WordQuizResult].self, from: data)
        } catch {
            print("Error decoding quiz results: \(error)")
            return []
        }
    }
    
    func getQuizResults(for wordID: UUID) -> [WordQuizResult] {
        return getQuizResults().filter { $0.wordID == wordID }
    }
    
    func getSuccessRate(for wordID: UUID) -> Double {
        let results = getQuizResults(for: wordID)
        if results.isEmpty {
            return 0
        }
        
        let correctCount = results.filter { $0.isCorrect }.count
        return Double(correctCount) / Double(results.count)
    }
    
    func getOverallSuccessRate() -> Double {
        let results = getQuizResults()
        if results.isEmpty {
            return 0
        }
        
        let correctCount = results.filter { $0.isCorrect }.count
        return Double(correctCount) / Double(results.count)
    }
    
    private func updateWordStatus(for wordID: UUID) {
        let results = getQuizResults(for: wordID)
        let currentStatus = getWordStatus(for: wordID)
        
        // Only update if we have results
        if results.isEmpty {
            return
        }
        
        // Get the 5 most recent results
        let recentResults = Array(results.suffix(min(5, results.count)))
        let successRate = Double(recentResults.filter { $0.isCorrect }.count) / Double(recentResults.count)
        
        // Update status based on success rate
        var newStatus = currentStatus
        
        if successRate >= 0.8 && results.count >= 3 {
            newStatus = .mastered
        } else if successRate >= 0.5 || results.count >= 2 {
            newStatus = .learning
        } else {
            newStatus = .new
        }
        
        // Only update if status has changed
        if newStatus != currentStatus {
            setWordStatus(newStatus, for: wordID)
        }
    }
    
    // MARK: - Daily Progress Methods
    
    func saveCompletedQuizSession(_ session: QuizSession) {
        // Increment quiz count
        updateDailyProgress(quizzesTaken: 1, correctAnswers: session.correctAnswers, incorrectAnswers: session.incorrectAnswers)
        
        // Store quiz session ID for history
        var sessionIDs = UserDefaults.standard.stringArray(forKey: quizSessionsKey) ?? []
        sessionIDs.append(session.id.uuidString)
        UserDefaults.standard.set(sessionIDs, forKey: quizSessionsKey)
        
        // Update word statuses based on performance in this quiz
        for (questionID, isCorrect) in session.questionResults {
            if let question = session.questions.first(where: { $0.id == questionID }),
               let wordID = question.word.id {
                saveQuizResult(for: wordID, isCorrect: isCorrect)
            }
        }
    }
    
    func updateDailyProgress(wordsLearned: Int = 0, wordsReviewed: Int = 0, quizzesTaken: Int = 0, correctAnswers: Int = 0, incorrectAnswers: Int = 0) {
        var allProgress = getDailyProgressHistory()
        
        // Get today's progress or create a new one
        let today = Calendar.current.startOfDay(for: Date())
        if let todayIndex = allProgress.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            // Update existing progress
            allProgress[todayIndex].wordsLearned += wordsLearned
            allProgress[todayIndex].wordsReviewed += wordsReviewed
            allProgress[todayIndex].quizzesTaken += quizzesTaken
            allProgress[todayIndex].correctAnswers += correctAnswers
            allProgress[todayIndex].incorrectAnswers += incorrectAnswers
        } else {
            // Create new progress for today
            let todayProgress = DailyProgress(
                date: today,
                wordsLearned: wordsLearned,
                wordsReviewed: wordsReviewed,
                quizzesTaken: quizzesTaken,
                correctAnswers: correctAnswers,
                incorrectAnswers: incorrectAnswers
            )
            allProgress.append(todayProgress)
        }
        
        // Save to UserDefaults
        if let encodedData = try? JSONEncoder().encode(allProgress) {
            UserDefaults.standard.set(encodedData, forKey: dailyProgressKey)
        }
    }
    
    func getDailyProgressHistory() -> [DailyProgress] {
        guard let data = UserDefaults.standard.data(forKey: dailyProgressKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([DailyProgress].self, from: data)
        } catch {
            print("Error decoding daily progress: \(error)")
            return []
        }
    }
    
    func getTodayProgress() -> DailyProgress {
        let today = Calendar.current.startOfDay(for: Date())
        let allProgress = getDailyProgressHistory()
        
        if let todayProgress = allProgress.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            return todayProgress
        } else {
            return DailyProgress(date: today)
        }
    }
    
    func getCompletedQuizCount() -> Int {
        return UserDefaults.standard.stringArray(forKey: quizSessionsKey)?.count ?? 0
    }
    
    // MARK: - Statistics Methods
    
    func getStatistics(in context: NSManagedObjectContext) -> [String: Any] {
        // Fetch all words
        let fetchRequest: NSFetchRequest<UserWord> = UserWord.fetchRequest()
        var totalWords = 0
        
        do {
            totalWords = try context.count(for: fetchRequest)
        } catch {
            print("Error counting words: \(error)")
        }
        
        // Get counts by status
        let newCount = getWordsWithStatus(.new, in: context).count
        let learningCount = getWordsWithStatus(.learning, in: context).count
        let masteredCount = getWordsWithStatus(.mastered, in: context).count
        
        // Get quiz statistics
        let quizResults = getQuizResults()
        let totalQuizzes = getCompletedQuizCount()
        let correctAnswers = quizResults.filter { $0.isCorrect }.count
        let incorrectAnswers = quizResults.count - correctAnswers
        let overallSuccessRate = getOverallSuccessRate()
        
        // Daily progress
        let todayProgress = getTodayProgress()
        let allProgress = getDailyProgressHistory()
        
        // Return all stats in a dictionary
        return [
            "totalWords": totalWords,
            "newWords": newCount,
            "learningWords": learningCount,
            "masteredWords": masteredCount,
            "totalQuizzes": totalQuizzes,
            "correctAnswers": correctAnswers,
            "incorrectAnswers": incorrectAnswers,
            "successRate": overallSuccessRate,
            "todayProgress": todayProgress,
            "progressHistory": allProgress
        ]
    }
} 
