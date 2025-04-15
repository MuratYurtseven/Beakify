import Foundation
import CoreData

extension WordGroup {
    // Define computed properties that handle optionality safely
    var nameValue: String {
        get { name ?? "" }
        set { name = newValue }
    }
    
    var descriptionValue: String {
        get { groupDescription ?? "" }
        set { groupDescription = newValue }
    }
    
    var colorValue: String {
        get { color ?? "blue" }
        set { color = newValue }
    }
    
    var createdAtValue: Date {
        get { createdAt ?? Date() }
        set { createdAt = newValue }
    }
    
    var idValue: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }
    
    var selectedLanguageValue:String{
        get{selectedLanguage ?? ""}
        set{selectedLanguage = newValue}
    }
    
    var wordsArray: [UserWord] {
        let set = words as? Set<UserWord> ?? []
        return set.sorted { $0.createdAtValue > $1.createdAtValue }
    }
    
    // Default color options
    static let colorOptions = ["blue", "green", "red", "orange", "purple", "pink", "teal"]
    
    // Convenience methods for adding/removing words
    func addWord(_ word: UserWord) {
        let currentWords = self.words?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
        currentWords.add(word)
        self.words = currentWords
        
        // Update the other side of the relationship if needed
        if !word.isInGroup(self) {
            word.addToGroup(self)
        }
    }
    
    func removeWord(_ word: UserWord) {
        let currentWords = self.words?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
        currentWords.remove(word)
        self.words = currentWords
        
        // Update the other side of the relationship if needed
        if word.isInGroup(self) {
            word.removeFromGroup(self)
        }
    }
    
    // Fetch Requests
    static func getAllGroupsRequest() -> NSFetchRequest<WordGroup> {
        let request: NSFetchRequest<WordGroup> = WordGroup.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WordGroup.createdAt, ascending: false)]
        return request
    }
    

} 
