import Foundation
import CoreData

extension UserWord {
    // Define computed properties that handle optionality safely
    var wordValue: String {
        get { word ?? "" }
        set { word = newValue }
    }
    
    var wordTranslateValue: String {
        get { wordTranslate ?? "" }
        set { wordTranslate = newValue }
    }
    
    var noteValue: String {
        get { note ?? "" }
        set { note = newValue }
    }
    
    var typeValue: String {
        get { type ?? "" }
        set { type = newValue }
    }
    
    var createdAtValue: Date {
        get { createdAt ?? Date() }
        set { createdAt = newValue }
    }
    
    var idValue: UUID {
        get { id ?? UUID() }
        set { id = newValue }
    }
    
    // Access sentences through UserDefaults instead of Core Data relationship
    var sentencesArray: [Sentence] {
        guard let id = id else { return [] }
        return CoreDataSetup.getSentences(for: id)
    }
    
    // Check if this word is in a specific group
    func isInGroup(_ group: WordGroup) -> Bool {
        return groupsArray.contains { $0.idValue == group.idValue }
    }
    
    // Get groups as an array
    var groupsArray: [WordGroup] {
        let set = groups as? Set<WordGroup> ?? []
        return set.sorted { $0.createdAtValue > $1.createdAtValue }
    }
    
    // Add to group
    func addToGroup(_ group: WordGroup) {
        let currentGroups = self.groups?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
        currentGroups.add(group)
        self.groups = currentGroups
        
        // Update the other side of the relationship if needed
        if !group.wordsArray.contains(where: { $0.idValue == self.idValue }) {
            group.addWord(self)
        }
    }
    
    // Remove from group
    func removeFromGroup(_ group: WordGroup) {
        let currentGroups = self.groups?.mutableCopy() as? NSMutableSet ?? NSMutableSet()
        currentGroups.remove(group)
        self.groups = currentGroups
        
        // Update the other side of the relationship if needed
        if group.wordsArray.contains(where: { $0.idValue == self.idValue }) {
            group.removeWord(self)
        }
    }
    
    // Fetch requests
    static func getAllWordsRequest() -> NSFetchRequest<UserWord> {
        let request: NSFetchRequest<UserWord> = UserWord.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \UserWord.createdAt, ascending: false)]
        return request
    }
}
