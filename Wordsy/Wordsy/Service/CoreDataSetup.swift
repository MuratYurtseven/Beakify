import Foundation
import CoreData

// This class provides utility functions for Core Data
class CoreDataSetup {
    // Instead of modifying the Core Data model at runtime, we'll create a utility function
    // to save sentences without relying on the formal relationship
    static func saveSentences(_ sentences: [Sentence], for wordID: UUID, in context: NSManagedObjectContext) -> Bool {
        do {
            // Store sentences in UserDefaults as a workaround
            // In a real app, you would want to properly add the ExampleSentence entity to your .xcdatamodeld file
            let sentencesData = try JSONEncoder().encode(sentences)
            UserDefaults.standard.set(sentencesData, forKey: "sentences_\(wordID.uuidString)")
            return true
        } catch {
            print("Error saving sentences: \(error)")
            return false
        }
    }
    
    static func getSentences(for wordID: UUID) -> [Sentence] {
        guard let data = UserDefaults.standard.data(forKey: "sentences_\(wordID.uuidString)") else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([Sentence].self, from: data)
        } catch {
            print("Error retrieving sentences: \(error)")
            return []
        }
    }
    
    static func deleteSentences(for wordID: UUID) {
        UserDefaults.standard.removeObject(forKey: "sentences_\(wordID.uuidString)")
    }
    
    // Favorite word functions
    static func setFavorite(_ isFavorite: Bool, for wordID: UUID) {
        UserDefaults.standard.set(isFavorite, forKey: "favorite_\(wordID.uuidString)")
    }
    
    static func isFavorite(wordID: UUID) -> Bool {
        return UserDefaults.standard.bool(forKey: "favorite_\(wordID.uuidString)")
    }
    
    // Learning status functions
    enum LearningStatus: String {
        case unknown = "unknown"
        case knew = "knew"
        case didntKnow = "didntKnow"
    }
    
    static func setLearningStatus(_ status: LearningStatus, for wordID: UUID) {
        UserDefaults.standard.set(status.rawValue, forKey: "learning_\(wordID.uuidString)")
    }
    
    static func getLearningStatus(for wordID: UUID) -> LearningStatus {
        let statusString = UserDefaults.standard.string(forKey: "learning_\(wordID.uuidString)") ?? LearningStatus.unknown.rawValue
        return LearningStatus(rawValue: statusString) ?? .unknown
    }
    
    // Get all favorite words
    static func getAllFavoriteWordIDs() -> [UUID] {
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        return allKeys.compactMap { key -> UUID? in
            guard key.starts(with: "favorite_"), userDefaults.bool(forKey: key) else {
                return nil
            }
            
            let idString = String(key.dropFirst("favorite_".count))
            return UUID(uuidString: idString)
        }
    }
    
    // Get all words by learning status
    static func getAllWordIDs(with status: LearningStatus) -> [UUID] {
        let userDefaults = UserDefaults.standard
        let allKeys = userDefaults.dictionaryRepresentation().keys
        
        return allKeys.compactMap { key -> UUID? in
            guard key.starts(with: "learning_"), 
                  let storedStatus = userDefaults.string(forKey: key),
                  storedStatus == status.rawValue else {
                return nil
            }
            
            let idString = String(key.dropFirst("learning_".count))
            return UUID(uuidString: idString)
        }
    }
} 