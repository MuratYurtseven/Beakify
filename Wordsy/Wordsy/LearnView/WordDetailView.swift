import SwiftUI

struct WordDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var word: UserWord
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showIncompatibleGroupAlert = false
    // State to track sentences
    @State private var showingOnlyStoredSentences = true
    @State private var apiSentences: [Sentence] = []
    @State private var storedSentences: [Sentence] = []
    
    // New state variables for favorites and learning
    @State private var isFavorite = false
    @State private var wordStatus: WordStatus = .new
    @State private var selectedSentenceID: UUID? = nil
    @State private var translations: [UUID: Translation] = [:]
    @State private var loadingTranslations: Set<UUID> = []
    @State private var showingQuizPrompt = false
    
    // Group management
    @State private var showingGroupSelector = false
    @State private var selectedGroups: Set<WordGroup> = []
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WordGroup.name, ascending: true)],
        animation: .default)
    private var allGroups: FetchedResults<WordGroup>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserPreferences.createdAt, ascending: false)],
        animation: .default)
    private var preferences: FetchedResults<UserPreferences>

    
    var body: some View {
        
        ZStack{
            List {
                // Use extracted subviews
                WordDetailSectionView(word: word)
                
                GroupSectionView(
                    word: word,
                    selectedGroups: $selectedGroups,
                    showingGroupSelector: $showingGroupSelector,
                    removeFromGroup: removeFromGroup
                )
                
                LearningOptionsView(
                    word: word,
                    isFavorite: $isFavorite,
                    wordStatus: $wordStatus
                )
                
                ExampleSentencesView(
                    word: word,
                    isLoading: $isLoading,
                    errorMessage: $errorMessage,
                    showingOnlyStoredSentences: $showingOnlyStoredSentences,
                    apiSentences: $apiSentences,
                    storedSentences: $storedSentences,
                    selectedSentenceID: $selectedSentenceID,
                    translations: $translations,
                    loadingTranslations: $loadingTranslations,
                    getTranslation: getTranslation,
                    generateSentences: generateSentences,
                    saveSentence: saveSentence,
                    saveAllSentences: saveAllSentences
                )
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Word Details")
            .background(Color(UIColor.systemGray6))
            .toolbar {
                if !storedSentences.isEmpty || !apiSentences.isEmpty {
                    Toggle(isOn: $showingOnlyStoredSentences) {
                        Text(showingOnlyStoredSentences ? "Saved" : "New")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .darkDustyBlue))
                }
            }
            .onAppear {
                // Load stored sentences
                loadStoredSentences()
                
                // Load favorite and learning status
                isFavorite = CoreDataSetup.isFavorite(wordID: word.idValue)
                wordStatus = ProgressTracker.shared.getWordStatus(for: word.idValue)
                
                // If no sentences yet, generate them automatically
                if storedSentences.isEmpty && apiSentences.isEmpty {
                    generateSentences()
                }
            }
            .sheet(isPresented: $showingGroupSelector) {
                GroupSelectorView(
                    selectedGroups: $selectedGroups,
                    groups: allGroups,
                    // Pass the current language to filter by
                    currentLanguage: word.groupsArray.first?.selectedLanguageValue ?? ""
                )
                .onDisappear {
                    updateWordGroups()
                }
            }
        }

    }
    
    // MARK: - Functions
    
    private func loadStoredSentences() {
        guard let wordID = word.id else { return }
        storedSentences = CoreDataSetup.getSentences(for: wordID)
    }
    private func getTranslation(for sentence: Sentence) {
        loadingTranslations.insert(sentence.id)
        
        // Get user's preferred translation language
        let translateLanguage = preferences.first?.translateLanguageValue ?? "en"
        
        // Get group's language for explanation and vocabulary
        let (_, _, groupLanguage) = getGroupContextInfo()
        let explanationLanguage = groupLanguage.isEmpty ? "English" : groupLanguage
        
        // Construct prompt for explanation and translation
        let prompt = """
        For this sentence: "\(sentence.text)"
        
        Please provide:
        1. A translation to \(translateLanguage)
        2. A detailed explanation of what the sentence means in \(explanationLanguage)
        3. Key vocabulary words with their meanings in \(explanationLanguage)
        
        Format your response as follows:
        
        ## Translation
        [Translation to \(translateLanguage) here]
        
        ## Explanation
        [Explanation in \(explanationLanguage)]
        
        ## Key Vocabulary
        [Key words from the sentence] - [Their meanings in \(explanationLanguage)]
        
        Keep the explanation clear and concise, suitable for language learners.
        """
        
        AppConfig.openAIService.generateTranslation(prompt: prompt, translateLanguage: translateLanguage) { result in
            DispatchQueue.main.async {
                self.loadingTranslations.remove(sentence.id)
                
                switch result {
                case .success(let translationText):
                    // Parse the translation text into our structured model
                    let parsedTranslation = Translation.parse(from: translationText)
                    self.translations[sentence.id] = parsedTranslation
                    
                case .failure(let error):
                    print("Translation error: \(error)")
                    // Create a simple error translation
                    self.translations[sentence.id] = Translation(
                        selectedTransText: "Translation failed",
                        explanation: "Error: \(error.localizedDescription)",
                        vocabulary: []
                    )
                }
            }
        }
    }
    
    private func generateSentences() {
        isLoading = true
        errorMessage = nil
        showingOnlyStoredSentences = false
        
        // Get group context information
        let (groupTitle, groupDescription,selectedLanguage) = getGroupContextInfo()
        
        AppConfig.openAIService.generateSentences(
            for: word.wordValue,
            groupTitle: groupTitle,
            groupDescription: groupDescription, groupLanguage: selectedLanguage
        ) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let newSentences):
                    apiSentences = newSentences
                case .failure(let error):
                    errorMessage = "Failed to generate sentences: \(error.localizedDescription)"
                    // If error, show stored sentences if available
                    if !storedSentences.isEmpty {
                        showingOnlyStoredSentences = true
                    }
                }
            }
        }
    }
    
    private func getGroupContextInfo() -> (String, String, String) {
        // Default values for general vocabulary
        var groupTitle = "General Vocabulary"
        var groupDescription = "General English vocabulary words"
        var selectedLanguage = "English"
        
        // Use the word's group info if available
        if let firstGroup = word.groupsArray.first {
            groupTitle = firstGroup.nameValue
            groupDescription = firstGroup.descriptionValue
            selectedLanguage = firstGroup.selectedLanguageValue
        }
        
        return (groupTitle, groupDescription, selectedLanguage)
    }
    
    private func saveSentence(_ sentence: Sentence) {
        guard let wordID = word.id else { return }
        
        // Add to stored sentences
        var updatedSentences = storedSentences
        updatedSentences.append(sentence)
        
        // Save to UserDefaults
        if CoreDataSetup.saveSentences(updatedSentences, for: wordID, in: viewContext) {
            // Update local array
            storedSentences = updatedSentences
            
            // Remove from API sentences
            if let index = apiSentences.firstIndex(where: { $0.text == sentence.text }) {
                apiSentences.remove(at: index)
            }
            
            if apiSentences.isEmpty {
                showingOnlyStoredSentences = true
            }
        }
    }
    
    private func saveAllSentences() {
        guard let wordID = word.id else { return }
        
        // Combine existing and new sentences
        var updatedSentences = storedSentences
        updatedSentences.append(contentsOf: apiSentences)
        
        // Save to UserDefaults
        if CoreDataSetup.saveSentences(updatedSentences, for: wordID, in: viewContext) {
            storedSentences = updatedSentences
            apiSentences = []
            showingOnlyStoredSentences = true
        }
    }
    
    private func removeFromGroup(_ group: WordGroup) {
        word.removeFromGroup(group)
        
        do {
            try viewContext.save()
        } catch {
            print("Error removing word from group: \(error)")
        }
    }
    
    private func updateWordGroups() {
        // Get current groups
        let currentGroups = Set(word.groupsArray)
        
        // If no current group, allow any new group
        if let currentGroup = currentGroups.first {
            // Get current language
            let currentLanguage = currentGroup.selectedLanguageValue
            
            // Filter selected groups to only those with matching language
            let compatibleGroups = selectedGroups.filter { $0.selectedLanguageValue == currentLanguage }
            
            // If the user selected an incompatible group, keep the current group
            if compatibleGroups.isEmpty && !selectedGroups.isEmpty {
                // User selected incompatible group(s), don't change anything
                // Optionally show an alert here about language mismatch
                return
            }
            
            // Use compatible groups only
            let newGroup = compatibleGroups.first
            
            // Remove from current group
            word.removeFromGroup(currentGroup)
            
            // Add to the new group if one was selected
            if let newGroup = newGroup {
                word.addToGroup(newGroup)
            }
        } else {
            // No current group, just add to whatever was selected
            if let newGroup = selectedGroups.first {
                word.addToGroup(newGroup)
            }
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error updating word groups: \(error)")
        }
    }
}

// MARK: - Component Views

struct WordDetailSectionView: View {
    @ObservedObject var word: UserWord
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    var body: some View {
        Section(header: Text("Word")) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(word.wordValue)
                        .font(.title)
                        .bold()
                    Text(word.wordTranslateValue)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.darkDustyBlue.gradient)
                        .padding(.horizontal,5)
                        .offset(y:5)
                    Spacer()
                    Text(word.typeValue)
                        .font(.subheadline)
                        .foregroundStyle(Color.white.gradient)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.darkDustyBlue.gradient.opacity(0.2))
                        .cornerRadius(6)
                }
                
                if !word.noteValue.isEmpty {
                    Text(word.noteValue)
                        .font(.body)
                        .padding(.top, 4)
                }
                
                Text("Added on \(word.createdAtValue, formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            .padding(.vertical, 8)
        }
    }
}

// In GroupSectionView, modify to only show one group
struct GroupSectionView: View {
    @ObservedObject var word: UserWord
    @Binding var selectedGroups: Set<WordGroup>
    @Binding var showingGroupSelector: Bool
    var removeFromGroup: (WordGroup) -> Void
    
    var body: some View {
        Section(header: Text("Group")) { // Changed from "Groups" to "Group"
            if word.groupsArray.isEmpty {
                HStack {
                    Text("This word is not in any group")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        // Pre-populate selected groups
                        selectedGroups = Set(word.groupsArray)
                        showingGroupSelector = true
                    }) {
                        Text("Add to Group")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            } else {
                // Only show the one group the word is in
                if let group = word.groupsArray.first {
                    HStack {
                        Circle()
                            .fill(Color(group.colorValue))
                            .frame(width: 12, height: 12)
                        
                        Text(group.nameValue)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.darkOliveGreen.gradient)
                        
                        Spacer()
                        
                        Button(action: {
                            removeFromGroup(group)
                        }) {
                            Image(systemName: "minus.circle")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                
                Button(action: {
                    // Pre-populate selected groups
                    selectedGroups = Set(word.groupsArray)
                    showingGroupSelector = true
                }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Change Group")
                        
                    }
                    .font(.caption)
                    .foregroundStyle(Color.darkDustyBlue.gradient)
                }
                .padding(.top, 4)
            }
        }
    }
}



struct LearningOptionsView: View {
    @ObservedObject var word: UserWord
    @Binding var isFavorite: Bool
    @Binding var wordStatus: WordStatus
    
    var body: some View {
        Section {
            HStack(spacing: 20) {
                // Favorite button
                Button(action: {
                    isFavorite.toggle()
                    // Save favorite status
                    CoreDataSetup.setFavorite(isFavorite, for: word.idValue)
                }) {
                    VStack {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .font(.title2)
                            .foregroundColor(isFavorite ? .yellow : .gray)
                        Text("Favorite")
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Spacer()
                
                // Learning status selector
                Menu {
                    ForEach(WordStatus.allCases) { status in
                        Button(action: {
                            wordStatus = status
                            ProgressTracker.shared.setWordStatus(status, for: word.idValue)
                        }) {
                            HStack {
                                if wordStatus == status {
                                    Image(systemName: "checkmark")
                                }
                                Text(status.displayName)
                            }
                        }
                    }
                } label: {
                    VStack {
                        ZStack {
                            Circle()
                                .fill(wordStatus.colorName)
                                .frame(width: 32, height: 32)
                            Image(systemName: getLearningStatusIcon())
                                .foregroundColor(.white)
                        }
                        Text(wordStatus.displayName)
                            .font(.caption)
                    }
                }
                
                Spacer()
                
            }
            .padding(.vertical, 8)
            
            // Show learning progress if the word has been quizzed
            if ProgressTracker.shared.getQuizResults(for: word.idValue).count > 0 {
                let successRate = ProgressTracker.shared.getSuccessRate(for: word.idValue)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Learning Progress")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(Int(successRate * 100))%")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    ProgressView(value: successRate)
                        .progressViewStyle(LinearProgressViewStyle(tint: wordStatus.colorName))
                }
                .padding(.top, 4)
            }
        }
    }
    
    // Helper method for status icon
    private func getLearningStatusIcon() -> String {
        switch wordStatus {
        case .new:
            return "plus"
        case .learning:
            return "book.fill"
        case .mastered:
            return "star.fill"
        }
    }
}

struct ExampleSentencesView: View {
    @ObservedObject var word: UserWord
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?
    @Binding var showingOnlyStoredSentences: Bool
    @Binding var apiSentences: [Sentence]
    @Binding var storedSentences: [Sentence]
    @Binding var selectedSentenceID: UUID?
    @Binding var translations: [UUID: Translation]
    @Binding var loadingTranslations: Set<UUID>
    
    var getTranslation: (Sentence) -> Void
    var generateSentences: () -> Void
    var saveSentence: (Sentence) -> Void
    var saveAllSentences: () -> Void
    
    var body: some View {
        Section(
            header: HStack {
                Text("Example Sentences")
                Spacer()
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Button(action: generateSentences) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        ) {
            // Use further subviews for content complexity
            SentencesContentView(
                errorMessage: errorMessage,
                isLoading: isLoading,
                showingOnlyStoredSentences: showingOnlyStoredSentences,
                storedSentences: storedSentences,
                apiSentences: apiSentences,
                selectedSentenceID: $selectedSentenceID,
                translations: translations,
                loadingTranslations: loadingTranslations,
                getTranslation: getTranslation,
                saveSentence: saveSentence,
                saveAllSentences: saveAllSentences
            )
        }
    }
}

// Further breakdown of sentence content
struct SentencesContentView: View {
    let errorMessage: String?
    let isLoading: Bool
    let showingOnlyStoredSentences: Bool
    let storedSentences: [Sentence]
    let apiSentences: [Sentence]
    @Binding var selectedSentenceID: UUID?
    let translations: [UUID: Translation]
    let loadingTranslations: Set<UUID>
    
    var getTranslation: (Sentence) -> Void
    var saveSentence: (Sentence) -> Void
    var saveAllSentences: () -> Void
    
    var body: some View {
        Group {
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.footnote)
            } else if storedSentences.isEmpty && apiSentences.isEmpty && !isLoading {
                Text("No example sentences yet. Tap the refresh button to generate examples.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                // Now use either StoredSentencesView or ApiSentencesView
                if showingOnlyStoredSentences {
                    StoredSentencesView(
                        sentences: storedSentences,
                        selectedSentenceID: $selectedSentenceID,
                        translations: translations,
                        loadingTranslations: loadingTranslations,
                        getTranslation: getTranslation
                    )
                } else {
                    ApiSentencesView(
                        sentences: apiSentences,
                        selectedSentenceID: $selectedSentenceID,
                        translations: translations,
                        loadingTranslations: loadingTranslations,
                        getTranslation: getTranslation,
                        saveSentence: saveSentence,
                        saveAllSentences: saveAllSentences
                    )
                }
            }
        }
    }
}

struct StoredSentencesView: View {
    let sentences: [Sentence]
    @Binding var selectedSentenceID: UUID?
    let translations: [UUID: Translation]
    let loadingTranslations: Set<UUID>
    var getTranslation: (Sentence) -> Void
    
    var body: some View {
        ForEach(sentences) { sentence in
            SentenceRowView(
                sentence: sentence,
                selectedSentenceID: $selectedSentenceID,
                translations: translations,
                loadingTranslations: loadingTranslations,
                getTranslation: getTranslation
            )
        }
    }
}

struct ApiSentencesView: View {
    let sentences: [Sentence]
    @Binding var selectedSentenceID: UUID?
    let translations: [UUID: Translation]
    let loadingTranslations: Set<UUID>
    var getTranslation: (Sentence) -> Void
    var saveSentence: (Sentence) -> Void
    var saveAllSentences: () -> Void
    
    var body: some View {
        ForEach(sentences) { sentence in
            VStack(alignment: .leading, spacing: 0) {
                // Sentence row content
                Button(action: {
                    if selectedSentenceID == sentence.id {
                        selectedSentenceID = nil
                    } else {
                        selectedSentenceID = sentence.id
                        if translations[sentence.id] == nil {
                            getTranslation(sentence)
                        }
                    }
                }) {
                    exampleSentenceView(text: sentence.text, difficulty: sentence.difficulty)
                }
                .buttonStyle(PlainButtonStyle())
                .contextMenu {
                    Button(action: {
                        saveSentence(sentence)
                    }) {
                        Label("Save", systemImage: "square.and.arrow.down")
                    }
                }
                
                // Translation expandable content
                if selectedSentenceID == sentence.id {
                    translationView(for: sentence.id)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 4)
                        .background(Color.blue.opacity(0.05))
                        .cornerRadius(8)
                }
            }
            .padding(.vertical, 2)
        }
        
        if !sentences.isEmpty {
            Button("Save All Sentences") {
                saveAllSentences()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }
    
    private func translationView(for sentenceID: UUID) -> some View {
        TranslationView(
            translation: translations[sentenceID],
            isLoading: loadingTranslations.contains(sentenceID)
        )
    }
    
    private func exampleSentenceView(text: String, difficulty: String) -> some View {
        let difficultyColor: Color = {
            switch difficulty.lowercased() {
            case "easy": return .green
            case "medium": return .orange
            case "hard": return .red
            default: return .gray
            }
        }()
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.body)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            HStack {
                Image(systemName: "hand.tap")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Tap for translation")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(difficulty.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(difficultyColor.opacity(0.2))
                    .foregroundColor(difficultyColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

struct SentenceRowView: View {
    let sentence: Sentence
    @Binding var selectedSentenceID: UUID?
    let translations: [UUID: Translation]
    let loadingTranslations: Set<UUID>
    var getTranslation: (Sentence) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Sentence row content
            Button(action: {
                if selectedSentenceID == sentence.id {
                    selectedSentenceID = nil
                } else {
                    selectedSentenceID = sentence.id
                    if translations[sentence.id] == nil {
                        getTranslation(sentence)
                    }
                }
            }) {
                exampleSentenceView(text: sentence.text, difficulty: sentence.difficulty)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Translation expandable content
            if selectedSentenceID == sentence.id {
                translationView(for: sentence.id)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding(.vertical, 2)
    }
    
    private func translationView(for sentenceID: UUID) -> some View {
        TranslationView(
            translation: translations[sentenceID],
            isLoading: loadingTranslations.contains(sentenceID)
        )
    }
    
    private func exampleSentenceView(text: String, difficulty: String) -> some View {
        let difficultyColor: Color = {
            switch difficulty.lowercased() {
            case "easy": return .oliveGreenColor
            case "medium": return .amberColor
            case "hard": return .russetColor
            default: return .gray
            }
        }()
        
        return VStack(alignment: .leading, spacing: 4) {
            Text(text)
                .font(.body)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            
            HStack {
                Image(systemName: "hand.tap")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Tap for translation")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text(difficulty.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(difficultyColor.opacity(0.2))
                    .foregroundColor(difficultyColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}


