import SwiftUI
import CoreData

struct WordStatusView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedStatus: WordStatus = .learning
    @State private var words: [UserWord] = []
    @State private var isLoading = false
    @State private var isStatusCardVisible = true

    // Search and filter states
    @State private var searchText = ""
    @State private var showingFilterSheet = false
    @State private var selectedWordType: String?
    @State private var selectedLanguage: String?
    @State private var isGroupedByLanguage = false
    
    // Cache available languages and types
    @State private var availableLanguages: [String] = []
    @State private var availableTypes: [String] = []
    
    var filteredWords: [UserWord] {
        var result = words
        
        // Filter by search text
        if !searchText.isEmpty {
            result = result.filter { word in
                word.wordValue.localizedCaseInsensitiveContains(searchText) ||
                word.wordTranslateValue.localizedCaseInsensitiveContains(searchText) ||
                word.noteValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by type if selected
        if let type = selectedWordType {
            result = result.filter { $0.typeValue == type }
        }
        
        // Filter by language if selected
        if let language = selectedLanguage, !isGroupedByLanguage {
            result = result.filter { word in
                word.groupsArray.contains { group in
                    group.selectedLanguageValue == language
                }
            }
        }
        
        return result
    }
    
    // Group words by language if enabled
    var groupedWords: [String: [UserWord]] {
        if !isGroupedByLanguage {
            return ["": filteredWords]
        }
        
        var result: [String: [UserWord]] = [:]
        
        for word in filteredWords {
            // Get all languages for this word from its groups
            let wordLanguages = Set(word.groupsArray.map { $0.selectedLanguageValue })
            
            if wordLanguages.isEmpty {
                // Add to "No Language" group for words without a language group
                let key = "No Language"
                if result[key] == nil {
                    result[key] = []
                }
                result[key]?.append(word)
            } else {
                // Add word to each of its language groups
                for language in wordLanguages {
                    let key = language.isEmpty ? "No Language" : language
                    if result[key] == nil {
                        result[key] = []
                    }
                    result[key]?.append(word)
                }
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGray6)
                    .ignoresSafeArea()
                
                ScrollView(.vertical){
                    VStack(spacing: 12) {
                        // Status selector
                        statusSelector
                        
                        // Search bar
                        searchBar
                        
                        // Status info card
                        statusInfoCard
                        
                        // Filter bar
                        filterBar
                        
                        // Words list
                        wordsListView
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Learning Status")
            .onAppear {
                loadWords()
                loadAvailableFilters()
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(
                    selectedWordType: $selectedWordType,
                    selectedLanguage: $selectedLanguage,
                    isGroupedByLanguage: $isGroupedByLanguage,
                    availableTypes: availableTypes,
                    availableLanguages: availableLanguages
                )
                .presentationDetents([.medium, .large])
            }
        }
    }
    
    // MARK: - Status Selector View
    
    private var statusSelector: some View {
        HStack(spacing: 8) {
            ForEach(WordStatus.allCases) { status in
                statusButton(status)
            }
        }
        .padding(.horizontal)
    }
    
    private func statusButton(_ status: WordStatus) -> some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedStatus = status
                loadWords()
            }
        }) {
            VStack(spacing: 8) {
                ZStack{
                    Circle()
                        .fill(status.colorName.gradient)
                        .frame(width: 14, height: 14)
                    
                    Circle()
                        .fill(Color.white.gradient)
                        .frame(width: 4,height: 4)
                }
                
                Text(status.displayName)
                    .font(.subheadline)
                    .foregroundStyle(selectedStatus == status ? status.colorName.gradient : Color.primary.gradient)
                    .fontWeight(selectedStatus == status ? .semibold : .regular)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedStatus == status ?
                          selectedStatus.colorName.opacity(0.15) :
                          Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search words", text: $searchText)
                .font(.subheadline)
                .fontWeight(.semibold)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .padding(.horizontal)
    }
    

    private var filterBar: some View {
        VStack(spacing: 12) {
            // Main filter button row
            HStack {
                // Primary filter button
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingFilterSheet = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.amberColor.gradient)
                        Text("Filter")
                            .font(.subheadline)
                            .foregroundStyle(Color.amberColor.gradient)
                            .fontWeight(.medium)
                        
                        // Badge showing active filter count
                        if hasActiveFilters {
                            ZStack {
                                Circle()
                                    .fill(Color.darkWalnutColor.gradient)
                                    .frame(width: 20, height: 20)
                                Text("\(activeFilterCount)")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(hasActiveFilters ? Color.dustyBlueColor.opacity(0.1) : Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    )
                    .foregroundColor(hasActiveFilters ? .blue : .primary)
                    .contentShape(Rectangle())
                    .accessibilityLabel(Text("Open filters"))
                    .accessibilityHint(Text("Double tap to manage word filters"))
                }
                .buttonStyle(ScaleButtonStyle())
                
                Spacer()
                
                // Clear filters button (only shown when filters are active)
                if hasActiveFilters {
                    Button(action: {
                        withAnimation(.spring()) {
                            selectedWordType = nil
                            selectedLanguage = nil
                            isGroupedByLanguage = false
                            // Add haptic feedback
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }) {
                        Text("Clear All")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(Color.russetColor.gradient)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.russetColor.gradient.opacity(0.3), lineWidth: 1)
                                    .background(Color.russetColor.gradient.opacity(0.05))
                                    .cornerRadius(10)
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .transition(.opacity.combined(with: .scale))
                    .accessibilityLabel(Text("Clear all filters"))
                }
            }
            .padding(.horizontal)
            
            // Active filters chips (only shown when filters are active)
            if hasActiveFilters {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Type filter chip
                        if let type = selectedWordType {
                            activeFilterChip(icon: "doc.text", text: "Type: \(type)") {
                                withAnimation(.spring()) {
                                    selectedWordType = nil
                                }
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                        
                        // Language filter chip
                        if let language = selectedLanguage {
                            activeFilterChip(icon: "globe", text: "Language: \(language)") {
                                withAnimation(.spring()) {
                                    selectedLanguage = nil
                                }
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                        
                        // Grouping filter chip
                        if isGroupedByLanguage {
                            activeFilterChip(icon: "folder", text: "Grouped by Language") {
                                withAnimation(.spring()) {
                                    isGroupedByLanguage = false
                                }
                            }
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .padding(.horizontal)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    // Helper to check if any filters are active
    private var hasActiveFilters: Bool {
        selectedWordType != nil || selectedLanguage != nil || isGroupedByLanguage
    }

    // Helper to count active filters
    private var activeFilterCount: Int {
        var count = 0
        if selectedWordType != nil { count += 1 }
        if selectedLanguage != nil { count += 1 }
        if isGroupedByLanguage { count += 1 }
        return count
    }

    // Helper for active filter chips
    private func activeFilterChip(icon: String, text: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color.white.gradient)
            
            Text(text)
                .font(.subheadline)
                .foregroundStyle(Color.white.gradient)
            
            Button(action: {
                onRemove()
                // Add haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .accessibilityLabel(Text("Remove filter"))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.lavenderPurple)
        )
        .foregroundColor(.blue)
    }

    // Custom button style with scale animation
    struct ScaleButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .scaleEffect(configuration.isPressed ? 0.95 : 1)
                .animation(.spring(), value: configuration.isPressed)
        }
    }
    

    private var statusInfoCard: some View {
        // Only show if visible
        Group {
            if isStatusCardVisible {
                VStack(alignment: .leading, spacing: 12) {
                    // Status header with dismiss button
                    HStack {
                        Circle()
                            .fill(selectedStatus.colorName)
                            .frame(width: 10, height: 10)
                        
                        Text(getStatusTitle())
                            .font(.headline)
                            .foregroundColor(selectedStatus.colorName)
                        
                        Spacer()
                        
                        Text("\(filteredWords.count) of \(words.count) words")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Add X mark button
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.2)) {
                                isStatusCardVisible = false
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 18))
                        }
                        .padding(.leading, 8)
                        .accessibilityLabel("Dismiss info card")
                    }
                    
                    Divider()
                    
                    // Status description
                    Text(getStatusDescription())
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
                )
                .padding(.horizontal)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Words List View
    
    private var wordsListView: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .scaleEffect(1.2)
            } else if filteredWords.isEmpty {
                emptyStateView
            } else if isGroupedByLanguage {
                // Grouped by language
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(groupedWords.keys.sorted(), id: \.self) { language in
                            if let languageWords = groupedWords[language], !languageWords.isEmpty {
                                languageSection(language: language, words: languageWords)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            } else {
                // Standard list view
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredWords, id: \.idValue) { word in
                            wordCard(for: word)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    // Language section for grouped view
    private func languageSection(language: String, words: [UserWord]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Language header
            HStack {
                Text(language)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(words.count) words")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            // Words in this language
            ForEach(words, id: \.idValue) { word in
                wordCard(for: word)
            }
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: getEmptyStateIcon())
                .font(.system(size: 50))
                .foregroundColor(selectedStatus.colorName.opacity(0.8))
            
            if searchText.isEmpty && selectedWordType == nil && selectedLanguage == nil {
                // Standard empty state (no words in this status)
                Text(getEmptyStateMessage())
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(getEmptyStateDescription())
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            } else {
                // Filtered empty state (no results for filters)
                Text("No matching words found")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Try adjusting your search or filters to find what you're looking for.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    // MARK: - Word Card View
    
    private func wordCard(for word: UserWord) -> some View {
        NavigationLink(destination: WordDetailView(word: word)) {
            VStack(alignment: .leading, spacing: 12) {
                // Word header with type badge
                HStack {
                    Text(word.wordValue)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.darkDustyBlue.gradient)
                    
                    if !word.wordTranslateValue.isEmpty {
                        Text(word.wordTranslateValue)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(word.typeValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color(UIColor.systemGray5))
                        )
                        .foregroundColor(.secondary)
                }
                
                // Language tags if available
                if !word.groupsArray.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(word.groupsArray.prefix(3), id: \.idValue) { group in
                                if !group.selectedLanguageValue.isEmpty {
                                    HStack(spacing: 4) {
                                        Circle()
                                            .fill(Color.fromStringStatus(group.colorValue))
                                            .frame(width: 8, height: 8)
                                        
                                        Text(group.selectedLanguageValue)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(group.colorValue).opacity(0.1))
                                    )
                                }
                            }
                            
                            if word.groupsArray.count > 3 {
                                Text("+\(word.groupsArray.count - 3) more")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color(UIColor.systemGray5))
                                    )
                            }
                        }
                    }
                }
                
                // Note if available
                if !word.noteValue.isEmpty {
                    Text(word.noteValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                // Progress indicator for learning words
                if selectedStatus == .learning {
                    let successRate = ProgressTracker.shared.getSuccessRate(for: word.idValue)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Learning Progress")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text("\(Int(successRate * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(Color.blue)
                        }
                        
                        // Custom progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(UIColor.systemGray5))
                                    .frame(height: 8)
                                
                                // Progress
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.blue, .purple]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: max(geometry.size.width * CGFloat(successRate), 0), height: 8)
                            }
                        }
                        .frame(height: 8)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func loadWords() {
        isLoading = true
        
        // Use background thread for fetching
        DispatchQueue.global(qos: .userInitiated).async {
            let wordsList = ProgressTracker.shared.getWordsWithStatus(self.selectedStatus, in: self.viewContext)
                .sorted { $0.wordValue < $1.wordValue }
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.words = wordsList
                self.isLoading = false
            }
        }
    }
    
    private func loadAvailableFilters() {
        // Reset data
        availableLanguages = []
        availableTypes = []
        
        // Fetch all words from all statuses to build filter lists
        let fetchRequest: NSFetchRequest<UserWord> = UserWord.fetchRequest()
        
        do {
            let allWords = try viewContext.fetch(fetchRequest)
            
            // Extract all types
            var types = Set<String>()
            for word in allWords where !word.typeValue.isEmpty {
                types.insert(word.typeValue)
            }
            availableTypes = Array(types).sorted()
            
            // Extract all languages from groups
            var languages = Set<String>()
            for word in allWords {
                for group in word.groupsArray where !group.selectedLanguageValue.isEmpty {
                    languages.insert(group.selectedLanguageValue)
                }
            }
            availableLanguages = Array(languages).sorted()
            
        } catch {
            print("Error loading filters: \(error)")
        }
    }
    
    private func getEmptyStateIcon() -> String {
        switch selectedStatus {
        case .new:
            return "plus.circle"
        case .learning:
            return "book.fill"
        case .mastered:
            return "star.fill"
        }
    }
    
    private func getEmptyStateMessage() -> String {
        switch selectedStatus {
        case .new:
            return "No New Words"
        case .learning:
            return "No Words Being Learned"
        case .mastered:
            return "No Mastered Words Yet"
        }
    }
    
    private func getEmptyStateDescription() -> String {
        switch selectedStatus {
        case .new:
            return "Add new vocabulary words to start learning them"
        case .learning:
            return "Complete quizzes to move words to the learning state"
        case .mastered:
            return "Master words by consistently answering quiz questions correctly"
        }
    }
    
    private func getStatusTitle() -> String {
        switch selectedStatus {
        case .new:
            return "New Words"
        case .learning:
            return "Learning in Progress"
        case .mastered:
            return "Mastered Words"
        }
    }
    
    private func getStatusDescription() -> String {
        switch selectedStatus {
        case .new:
            return "These are words you've recently added but haven't started learning yet. Take quizzes to begin learning these words."
        case .learning:
            return "You're actively learning these words. Continue taking quizzes to improve your mastery level."
        case .mastered:
            return "Congratulations! You've mastered these words by consistently answering them correctly in quizzes."
        }
    }
}

// MARK: - Supporting Views

struct ActiveFilterView: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(.footnote)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
        .foregroundColor(.blue)
    }
}

struct FilterSheetView: View {
    @Binding var selectedWordType: String?
    @Binding var selectedLanguage: String?
    @Binding var isGroupedByLanguage: Bool
    let availableTypes: [String]
    let availableLanguages: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Word Type")) {
                    Picker("Select Type", selection: Binding(
                        get: { selectedWordType ?? "" },
                        set: { selectedWordType = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("Any Type").tag("")
                        ForEach(availableTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }
                
                Section(header: Text("Language")) {
                    Picker("Select Language", selection: Binding(
                        get: { selectedLanguage ?? "" },
                        set: { selectedLanguage = $0.isEmpty ? nil : $0 }
                    )) {
                        Text("Any Language").tag("")
                        ForEach(availableLanguages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                }
                
                Section(header: Text("Grouping")) {
                    Toggle("Group by Language", isOn: $isGroupedByLanguage)
                        .foregroundStyle(Color.darkDustyBlue.gradient)
                }
                
                Section {
                    Button("Reset All Filters") {
                        selectedWordType = nil
                        selectedLanguage = nil
                        isGroupedByLanguage = false
                        dismiss()
                    }
                    .foregroundStyle(Color.russetColor.gradient)
                }
            }
            .navigationTitle("Filter Words")
            .navigationBarItems(
                trailing: Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                })
            )
        }
    }
}

extension Color {
    static func fromStringStatus(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "red":
            return .red
        case "orange":
            return .orange
        case "yellow":
            return .yellow
        case "green":
            return .green
        case "blue":
            return .blue
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "teal":
            return .teal
        case "cyan":
            return .cyan
        case "mint":
            return .mint
        case "indigo":
            return .indigo
        case "brown":
            return .brown
        default:
            return .gray // Default color if name doesn't match
        }
    }
}

struct WordStatusView_Previews: PreviewProvider {
    static var previews: some View {
        WordStatusView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
