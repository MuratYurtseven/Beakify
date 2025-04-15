//
//  UserPreferences+Extensions.swift
//  Wordsy
//
//  Created by Murat on 11.04.2025.
//
import Foundation
import CoreData

extension UserPreferences {
    // Define computed properties that handle optionality safely
    var nameValue: String {
        get { name ?? "" }
        set { name = newValue }
    }
    
    var translateLanguageValue: String {
        get { translateLanguage ?? "" }
        set { translateLanguage = newValue }
    }
    
    
    var idValue: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }
    
    var createdAtValue: Date {
        get { createdAt ?? Date() }
        set { createdAt = newValue }
    }
    
    // Helper method to check if user preferences exist
    static func preferencesExist(in context: NSManagedObjectContext) -> Bool {
        let request: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        request.fetchLimit = 1
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("Error checking for preferences: \(error)")
            return false
        }
    }
    
    // Helper method to get current preferences or create if they don't exist
    static func getCurrentPreferences(in context: NSManagedObjectContext) -> UserPreferences {
        let request: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try context.fetch(request)
            if let existingPreferences = results.first {
                return existingPreferences
            } else {
                // Create new preferences with default values
                let newPreferences = UserPreferences(context: context)
                newPreferences.id = UUID()
                newPreferences.createdAt = Date()
                newPreferences.name = "Your name"
                newPreferences.translateLanguage = "en" // Default language
                // Image is nil by default
                return newPreferences
            }
        } catch {
            print("Error fetching preferences: \(error)")
            
            // Create new preferences with default values
            let newPreferences = UserPreferences(context: context)
            newPreferences.id = UUID()
            newPreferences.createdAt = Date()
            newPreferences.name = "Default"
            newPreferences.translateLanguage = "en" // Default language
            return newPreferences
        }
    }
    
    // Fetch request
    static func getPreferencesRequest() -> NSFetchRequest<UserPreferences> {
        let request: NSFetchRequest<UserPreferences> = UserPreferences.fetchRequest()
        return request
    }
    
    
    // Update translate language
    func updateTranslateLanguage(_ language: String) {
        self.translateLanguage = language
    }
}
