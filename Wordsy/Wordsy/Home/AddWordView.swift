import SwiftUI
import CoreData

struct AddWordView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    // Add optional parameter for preselected group
    var preSelectedGroup: WordGroup?
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserWord.createdAt, ascending: false)],
        animation: .default)
    private var words: FetchedResults<UserWord>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserPreferences.createdAt, ascending: false)],
        animation: .default)
    private var preferences: FetchedResults<UserPreferences>

    @State private var word: String = ""
    @State private var note: String = ""
    @State private var translation: String = "" // New state for translation
    @State private var selectedWordType: WordType = .noun
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = "Duplicate Word"
    @State private var isFetchingSentences = false
    @State private var autoGenerateSentences = true // Set default to true
    @State private var showingGroupSelector = false
    @State private var selectedGroups: Set<WordGroup> = []
    @State private var isFetchingWordInfo = false
    @State private var wordInfoFetched = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WordGroup.name, ascending: true)],
        animation: .default)
    private var groups: FetchedResults<WordGroup>
    
    // Define word types for the Picker
    enum WordType: String, CaseIterable, Identifiable {
        case noun = "Noun"
        case verb = "Verb"
        case adjective = "Adjective"
        case adverb = "Adverb"
        case other = "Other"
        var id: String { self.rawValue }
    }
    
    // Initialize with the preselected group if provided
    init(preSelectedGroup: WordGroup? = nil) {
        self.preSelectedGroup = preSelectedGroup
        
        // Using _selectedGroups to initialize the @State property
        if let group = preSelectedGroup {
            _selectedGroups = State(initialValue: [group])
        }
    }

    var body: some View {
        NavigationStack {
            
            ScrollView(.vertical) {
                ZStack {
                    Color(UIColor.systemGray6)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        // Add Word Form
                        VStack(spacing: 20) {
                            wordInputSection
                            
                            if wordInfoFetched {
                                wordTypeSection
                                
                                // Translation Section - New
                                translationSection
                                
                                noteSection
                            }
                            
                            additionalOptionsSection
                            
                            saveButton
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Words List - Only show if not opened from a group
                        if preSelectedGroup == nil && !words.isEmpty {
                            wordListSection
                                .padding(.top)
                        }
                    }
                }
                .navigationTitle(preSelectedGroup == nil ? "My Words" : "Add to \(preSelectedGroup!.nameValue)")
                .alert(isPresented: $showingAlert) {
                    Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("OK")))
                }
                .sheet(isPresented: $showingGroupSelector) {
                    GroupSelectorView(selectedGroups: $selectedGroups, groups: groups, currentLanguage: groups.first?.selectedLanguageValue ?? "")
                }
            }
            .background(Color(UIColor.systemGray6))
        }
    }
    
    private var wordInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("New Word")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack(alignment: .trailing) {
                TextField("Enter word", text: $word)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemGray6))
                    )
                    .autocapitalization(.none)
                    .submitLabel(.done) // Set submit label to done
                    .onSubmit {
                        // Only fetch word info when user presses return/done
                        if !word.isEmpty && word.count > 2 {
                            getWordInfo()
                        }
                    }
                
                if isFetchingWordInfo {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.trailing, 12)
                }
            }
        }
    }
    
    // Word type section - read only display
    private var wordTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Word Type")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                ForEach(WordType.allCases) { type in
                    Text(type.rawValue)
                        .font(.caption2)
                        .fontWeight(selectedWordType == type ? .semibold : .regular)
                        .foregroundColor(selectedWordType == type ? .white : .primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedWordType == type ? Color.DarkOliveGreenColor.gradient : Color(UIColor.systemGray6).gradient)
                        )
                }
            }
        }
    }
    
    // Translation section - New
    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Translation")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(translation)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                )
        }
    }
    
    // Note section - read only display
    private var noteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meaning")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text(note)
                .font(.subheadline)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemGray6))
                )
        }
    }
    
    // Additional options section
    private var additionalOptionsSection: some View {
        VStack(spacing: 16) {
            // Auto-generate toggle
            HStack {
                Toggle("Auto-generate examples", isOn: $autoGenerateSentences)
                    .toggleStyle(SwitchToggleStyle(tint: .darkOliveGreen))
            }
            .padding(.vertical, 4)
            
            // Groups selector - only show when not opened with a preselected group
            // or show but disable if opened with a preselected group
            if !groups.isEmpty {
                Button(action: {
                    showingGroupSelector = true
                }) {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.darkOliveGreen.gradient)
                        
                        if preSelectedGroup != nil {
                            Text("Added to \(preSelectedGroup!.nameValue)")
                                .foregroundColor(.primary)
                        } else {
                            Text("Add to Groups")
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        if selectedGroups.isEmpty {
                            Text("Select")
                                .foregroundColor(.secondary)
                        } else {
                            Text("\(selectedGroups.count) selected")
                                .foregroundStyle(.darkOliveGreen.gradient)
                        }
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(UIColor.systemGray6))
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(preSelectedGroup != nil && selectedGroups.count == 1) // Disable if we have a preselected group
            }
        }
    }
    
    // Save button
    private var saveButton: some View {
        Button(action: addWord) {
            HStack {
                Spacer()
                
                if isFetchingSentences {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.trailing, 8)
                    
                    Text("Saving...")
                } else {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .padding(.trailing, 8)
                    
                    Text("Save Word")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !wordInfoFetched ? Color.gray.gradient : Color.darkOliveGreen.gradient)
            )
            .foregroundColor(.white)
        }
        .disabled(word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !wordInfoFetched || isFetchingSentences)
    }
    
    // Words list section
    private var wordListSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Quiz link
            HStack {
                Text("Your Words")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
            }
            .padding(.horizontal)
            
            // Words list
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(words) { word in
                        NavigationLink(destination: WordDetailView(word: word)) {
                            wordItem(word)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // Individual word item in the list
    private func wordItem(_ word: UserWord) -> some View {
        HStack(spacing: 16) {
            // Word status indicator
            let status = ProgressTracker.shared.getWordStatus(for: word.idValue)
            Circle()
                .fill(status == .new ? Color.gray.opacity(0.3) : status.colorName)
                .frame(width: 12, height: 12)
            
            // Word details
            VStack(alignment: .leading, spacing: 4) {
                Text(word.wordValue)
                    .font(.headline)
                
                // Show Turkish translation in the word list too
                if !word.wordTranslateValue.isEmpty {
                    Text(word.wordTranslateValue)
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
                
                if !word.noteValue.isEmpty {
                    Text(word.noteValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Word type badge
            Text(word.typeValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(Color(UIColor.systemGray5))
                )
                .foregroundColor(.secondary)
            
            // Delete button
            Button(action: {
                deleteWord(word)
            }) {
                Image(systemName: "trash")
                    .foregroundColor(.red.opacity(0.7))
                    .padding(8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
        )
    }
    // In AddWordView.swift - Updated getWordInfo method
    private func getWordInfo() {
        let trimmedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedWord.isEmpty {
            return
        }
        
        isFetchingWordInfo = true
        wordInfoFetched = false
        
        // Determine source and target languages
        var translateLanguage = preferences.first?.translateLanguageValue ?? "en"
        var sourceLanguage = ""
        
        // Language priority:
        // 1. First check if we have a preselected group (when adding directly to a group)
        if let group = preSelectedGroup, !group.selectedLanguageValue.isEmpty {
            sourceLanguage = group.selectedLanguageValue
        }
        // 2. Then check if other groups are selected and use the first one's language
        else if let firstGroup = selectedGroups.first, !firstGroup.selectedLanguageValue.isEmpty {
            sourceLanguage = firstGroup.selectedLanguageValue
        }
        
        print("Source language: \(sourceLanguage), Target language: \(translateLanguage)")
        
        // Call the updated getWordInfo method with both languages
        AppConfig.openAIService.getWordInfo(
            word: trimmedWord,
            sourceLanguage: sourceLanguage,
            translateLanguage: translateLanguage
        ) { result in
            DispatchQueue.main.async {
                isFetchingWordInfo = false
                
                switch result {
                case .success(let wordInfo):
                    // Set the word type based on the response
                    if let wordType = WordType.allCases.first(where: { $0.rawValue.lowercased() == wordInfo.type.lowercased() }) {
                        selectedWordType = wordType
                    } else {
                        selectedWordType = .other
                    }
                    
                    // Set the note (meaning) from the response
                    note = wordInfo.meaning
                    // Set the translation from the response
                    translation = wordInfo.translation
                    wordInfoFetched = true
                    
                case .failure(let error):
                    print("Error fetching word info: \(error.localizedDescription)")
                    // In case of error, allow manual entry
                    wordInfoFetched = true
                }
            }
        }
    }

    private func addWord() {
        withAnimation {
            // Create new word in Core Data
            let newWord = UserWord(context: viewContext)
            newWord.id = UUID()
            newWord.word = word
            newWord.type = selectedWordType.rawValue
            newWord.note = note
            newWord.wordTranslate = translation // Save the translation
            newWord.createdAt = Date()
            
            // Add to selected groups
            for group in selectedGroups {
                newWord.addToGroup(group)
            }
            
            // Save to Core Data
            do {
                try viewContext.save()
                
                // Set initial word status
                ProgressTracker.shared.setWordStatus(.new, for: newWord.idValue)
                
                // If auto-generate is enabled, fetch example sentences
                if autoGenerateSentences {
                    isFetchingSentences = true
                    fetchExampleSentences(for: newWord, word: word)
                }
                
                // Clear the form
                word = ""
                note = ""
                translation = ""
                wordInfoFetched = false
                
                // Only clear the selected groups if not opened with a preselected group
                if preSelectedGroup == nil {
                    selectedGroups = []
                }
                
                // If opened from a group view, dismiss after saving
                if preSelectedGroup != nil {
                    dismiss()
                }
                
                // Hide keyboard
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                
            } catch {
                let nsError = error as NSError
                print("Error saving word: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func fetchExampleSentences(for userWord: UserWord, word: String) {
        // Get group context if the word is added to any groups
        var groupTitle = "General Vocabulary"
        var groupDescription = "General English vocabulary words"
        var selectedLanguage = "English"
        
        // If word is added to groups, use the first group's info for context
        if let firstGroup = selectedGroups.first {
            groupTitle = firstGroup.nameValue
            groupDescription = firstGroup.descriptionValue
            selectedLanguage = firstGroup.selectedLanguageValue
        }
        
        AppConfig.openAIService.generateSentences(
            for: word,
            groupTitle: groupTitle,
            groupDescription: groupDescription, groupLanguage: selectedLanguage
            
        ) { result in
            DispatchQueue.main.async {
                isFetchingSentences = false
                
                switch result {
                case .success(let sentences):
                    // Save sentences to UserDefaults instead of Core Data
                    if let wordID = userWord.id {
                        CoreDataSetup.saveSentences(sentences, for: wordID, in: viewContext)
                    }
                    
                case .failure(let error):
                    print("Error fetching sentences: \(error.localizedDescription)")
                    // Still saved the word, just didn't get sentences
                }
            }
        }
    }
    
    private func deleteWord(_ userWord: UserWord) {
        viewContext.delete(userWord)
        
        do {
            try viewContext.save()
        } catch {
            print("Error deleting word: \(error.localizedDescription)")
            // Optionally show an error alert here
        }
    }
}

struct AddWordView_Previews: PreviewProvider {
    static var previews: some View {
        AddWordView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
