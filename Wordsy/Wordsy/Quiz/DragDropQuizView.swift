import SwiftUI

struct DragDropQuizView: View {
    let question: QuizQuestion
    let onAnswer: (Bool) -> Void
    
    @State private var terms: [MatchItem] = []
    @State private var definitions: [MatchItem] = []
    @State private var selectedTermID: UUID? = nil
    @State private var selectedDefID: UUID? = nil
    @State private var matchedPairs: [(UUID, UUID)] = []
    @State private var pairResults: [UUID: Bool] = [:]  // Store match correctness
    
    init(question: QuizQuestion, onAnswer: @escaping (Bool) -> Void) {
        self.question = question
        self.onAnswer = onAnswer
        
        // Check if this is a valid drag and drop question
        guard let pairs = question.matchPairs, !pairs.isEmpty else {
            _terms = State(initialValue: [])
            _definitions = State(initialValue: [])
            return
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Quiz question prompt
            Text(question.question)
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            
            // Side-by-side matching content
            HStack(alignment: .top, spacing: 15) {
                // Left column: Terms
                VStack(spacing: 12) {
                    Text("Terms")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    ForEach(terms) { term in
                        MatchItemButton(
                            item: term,
                            isSelected: selectedTermID == term.id,
                            isMatched: isMatched(term.id),
                            isCorrectMatch: pairResults[term.id] ?? false,
                            onTap: {
                                handleTermTap(term.id)
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                
                // Right column: Definitions
                VStack(spacing: 12) {
                    Text("Definitions")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    ForEach(definitions) { definition in
                        MatchItemButton(
                            item: definition,
                            isSelected: selectedDefID == definition.id,
                            isMatched: isMatched(definition.id),
                            isCorrectMatch: pairResults[definition.id] ?? false,
                            onTap: {
                                handleDefinitionTap(definition.id)
                            }
                        )
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // Continue button - appears when all items are matched
            if matchedPairs.count == terms.count {
                Button(action: {
                    onAnswer(allMatchesCorrect())
                }) {
                    Text("CONTINUE")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(16)
                        .shadow(color: Color.green.opacity(0.4), radius: 4, x: 0, y: 2)
                }
                .padding(.top, 20)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 3)
        .padding()
        .onAppear {
            setupItems()
        }
    }
    
    // Initialize items
    private func setupItems() {
        guard let pairs = question.matchPairs, !pairs.isEmpty else { return }
        
        var newTerms: [MatchItem] = []
        var newDefinitions: [MatchItem] = []
        
        // Create term and definition items
        for pair in pairs {
            let termItem = MatchItem(id: UUID(), text: pair.term, correctMatchText: pair.definition)
            let defItem = MatchItem(id: UUID(), text: pair.definition, correctMatchText: pair.term)
            
            newTerms.append(termItem)
            newDefinitions.append(defItem)
        }
        
        // Shuffle both arrays for randomization
        self.terms = newTerms.shuffled()
        self.definitions = newDefinitions.shuffled()
    }
    
    // Check if an item is already matched
    private func isMatched(_ id: UUID) -> Bool {
        for pair in matchedPairs {
            if pair.0 == id || pair.1 == id {
                return true
            }
        }
        return false
    }
    
    // Handle term tap
    private func handleTermTap(_ id: UUID) {
        if isMatched(id) { return }
        
        if selectedTermID == id {
            // Deselect if tapping the same term again
            selectedTermID = nil
        } else {
            selectedTermID = id
            
            // Check if we also have a definition selected
            if let defID = selectedDefID {
                // Try to match
                tryMatchPair(termID: id, defID: defID)
            }
        }
    }
    
    // Handle definition tap
    private func handleDefinitionTap(_ id: UUID) {
        if isMatched(id) { return }
        
        if selectedDefID == id {
            // Deselect if tapping the same definition again
            selectedDefID = nil
        } else {
            selectedDefID = id
            
            // Check if we also have a term selected
            if let termID = selectedTermID {
                // Try to match
                tryMatchPair(termID: termID, defID: id)
            }
        }
    }
    
    // Try to match a pair
    private func tryMatchPair(termID: UUID, defID: UUID) {
        guard
            let term = terms.first(where: { $0.id == termID }),
            let def = definitions.first(where: { $0.id == defID })
        else {
            return
        }
        
        // Check if this is a correct match and store the result
        let isCorrectMatch = term.correctMatchText == def.text
        
        // Add to matches
        matchedPairs.append((termID, defID))
        
        // Store the result
        pairResults[termID] = isCorrectMatch
        pairResults[defID] = isCorrectMatch
        
        // Reset selections
        selectedTermID = nil
        selectedDefID = nil
    }
    
    // Check if all matches are correct
    private func allMatchesCorrect() -> Bool {
        for (_, isCorrect) in pairResults {
            if !isCorrect {
                return false
            }
        }
        return true
    }
}

// Item for matching
struct MatchItem: Identifiable {
    let id: UUID
    let text: String
    let correctMatchText: String
}

// Button for a match item
struct MatchItemButton: View {
    let item: MatchItem
    let isSelected: Bool
    let isMatched: Bool
    let isCorrectMatch: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(item.text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(textColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(backgroundColor)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: 2)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        }
        .disabled(isMatched)
    }
    
    private var backgroundColor: Color {
        if isMatched {
            return isCorrectMatch ? Color.green.opacity(0.1) : Color.red.opacity(0.1)
        } else if isSelected {
            return Color.blue.opacity(0.2)
        } else {
            return Color.white
        }
    }
    
    private var borderColor: Color {
        if isMatched {
            return isCorrectMatch ? Color.green : Color.red
        } else if isSelected {
            return Color.blue
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private var textColor: Color {
        if isMatched {
            return isCorrectMatch ? Color.green : Color.red
        } else if isSelected {
            return Color.blue
        } else {
            return Color.primary
        }
    }
}

