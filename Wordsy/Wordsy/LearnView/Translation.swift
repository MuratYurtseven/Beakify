import Foundation

struct Translation {
    let selectedTransText: String
    let explanation: String
    let vocabulary: [VocabItem]
    
    struct VocabItem: Identifiable {
        let id = UUID()
        let word: String
        let meaning: String
    }
    
    // Parse the raw text response from OpenAI
    static func parse(from rawText: String) -> Translation {
        // Default empty values
        var turkishText = ""
        var explanation = ""
        var vocabularyText = ""
        
        // Split the response into sections based on markdown headers
        let sections = rawText.components(separatedBy: "##")
        
        for section in sections {
            let trimmedSection = section.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check for various possible translation headers
            if trimmedSection.lowercased().contains("translation") {
                let lines = trimmedSection.components(separatedBy: "\n").dropFirst()
                turkishText = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedSection.lowercased().starts(with: "explanation") {
                let lines = trimmedSection.components(separatedBy: "\n").dropFirst()
                explanation = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if trimmedSection.lowercased().starts(with: "key vocabulary") {
                let lines = trimmedSection.components(separatedBy: "\n").dropFirst()
                vocabularyText = lines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Parse vocabulary items
        let vocabItems = parseVocabularyItems(from: vocabularyText)
        
        return Translation(selectedTransText: turkishText, explanation: explanation, vocabulary: vocabItems)
    }
    
    private static func parseVocabularyItems(from text: String) -> [VocabItem] {
        var items: [VocabItem] = []
        
        // Split by new lines first
        let lines = text.components(separatedBy: "\n")
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty { continue }
            
            // Look for patterns like "word - meaning" or "word: meaning"
            if let dashRange = trimmedLine.range(of: " - ") {
                let word = trimmedLine[..<dashRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                let meaning = trimmedLine[dashRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                items.append(VocabItem(word: String(word), meaning: String(meaning)))
            } else if let colonRange = trimmedLine.range(of: ": ") {
                let word = trimmedLine[..<colonRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
                let meaning = trimmedLine[colonRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
                items.append(VocabItem(word: String(word), meaning: String(meaning)))
            } else {
                // If no standard format detected, just use the whole line as the word
                items.append(VocabItem(word: trimmedLine, meaning: ""))
            }
        }
        
        return items
    }
}
