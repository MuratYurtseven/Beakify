//
//  QuizSelectionView.swift
//  Wordsy
//
//  Created by Murat on 12.04.2025.
//
import SwiftUI

struct QuizSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    
    @FetchRequest(
        entity: WordGroup.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WordGroup.createdAt, ascending: false)]
    ) private var groups: FetchedResults<WordGroup>
    
    @State private var selectedGroup: WordGroup? = nil
    @State private var selectedQuizType: QuizType = .standard
    @State private var selectedDifficulty: QuizDifficulty = .medium
    @State private var navigateToQuiz = false
    @State private var expandedGroupId: UUID? = nil
    
    enum QuizType: String, CaseIterable, Identifiable {
        case standard = "Standard"
        case vocabulary = "Vocabulary"
        case grammar = "Grammar"
        case pronunciation = "Pronunciation"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .standard: return "book.fill"
            case .vocabulary: return "textformat.abc"
            case .grammar: return "text.alignleft"
            case .pronunciation: return "waveform"
            }
        }
        
        var description: String {
            switch self {
            case .standard: return "Mixed questions from your entire vocabulary"
            case .vocabulary: return "Focus on word meanings and usage"
            case .grammar: return "Practice with sentence construction"
            case .pronunciation: return "Audio and speech questions"
            }
        }
        
        var color: Color {
            switch self {
            case .standard: return .blue
            case .vocabulary: return .purple
            case .grammar: return .green
            case .pronunciation: return .orange
            }
        }
    }
    
    enum QuizDifficulty: String, CaseIterable, Identifiable {
        case easy = "Easy"
        case medium = "Medium"
        case hard = "Hard"
        
        var id: String { self.rawValue }
        
        var iconName: String {
            switch self {
            case .easy: return "tortoise.fill"
            case .medium: return "hare.fill"
            case .hard: return "bolt.fill"
            }
        }
        
        var description: String {
            switch self {
            case .easy: return "Simple questions with clear options"
            case .medium: return "Balanced challenge for intermediate learners"
            case .hard: return "Challenging questions for advanced users"
            }
        }
        
        var color: Color {
            switch self {
            case .easy: return .green
            case .medium: return .orange
            case .hard: return .red
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom header with close button
                /*
                HStack {
                    
                    Spacer()
                    
                    Text("Quiz")
                        .font(.system(size: 18, weight: .bold))
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 32, height: 32)
                }
                .padding(.horizontal)
                .padding(.top, 8)*/
                
                    ScrollView {
                        VStack(spacing: 16) {
                            HStack{
                                Spacer()
                                Text("Choose Word Group")
                                    .font(.title)
                                    .fontWeight(.heavy)
                                    .foregroundStyle(LinearGradient(colors: [Color.DarkDustyBlueColor,Color.DarkDustyBlueColor.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .padding(.bottom, 8)
                                Spacer()
                            }
                            .padding(.horizontal,5)
                            if groups.isEmpty {
                                emptyGroupsView
                            } else {
                                // Group options
                                ForEach(groups) { group in
                                    groupCardWithDifficulty(group)
                                }
                            }
                        }
                        .padding()
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Start quiz button
                startQuizButton
                    .padding()
            }
            .navigationTitle("Quiz")
            //.navigationBarHidden(true)
            .background(Color(UIColor.systemGray6))
            .background(
                Group {
                NavigationLink(
                        destination: selectedGroup != nil ?
                        AnyView(QuizViewWithWords(
                            language: selectedGroup?.selectedLanguageValue ?? "en", words: Array(selectedGroup!.words?.allObjects as? [UserWord] ?? []), groupName: selectedGroup?.nameValue ?? ""
                            )
                        .environment(\.managedObjectContext, viewContext)) :
                            AnyView(EmptyView()),
                        isActive: $navigateToQuiz
                    ) { EmptyView() }
                }
            )
        }
    }
    
    // MARK: - UI Components
    
    func quizTypeCard(_ quizType: QuizType) -> some View {
        Button(action: {
            selectedQuizType = quizType
        }) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: quizType.iconName)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(quizType.color)
                    .clipShape(Circle())
                
                // Text content
                VStack(alignment: .leading, spacing: 4) {
                    Text(quizType.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(quizType.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: selectedQuizType == quizType ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(selectedQuizType == quizType ? quizType.color : Color.gray.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedQuizType == quizType ? quizType.color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(), value: selectedQuizType)
    }
    
    func difficultyCard(_ difficulty: QuizDifficulty) -> some View {
        Button(action: {
            selectedDifficulty = difficulty
            // Keep the group expanded after selecting difficulty
        }) {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: difficulty.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .background(difficulty.color)
                    .clipShape(Circle())
                
                // Text content
                Text(difficulty.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Selection indicator
                Image(systemName: selectedDifficulty == difficulty ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(selectedDifficulty == difficulty ? difficulty.color : Color.gray.opacity(0.3))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selectedDifficulty == difficulty ? difficulty.color : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(), value: selectedDifficulty)
    }
    
    func groupCardWithDifficulty(_ group: WordGroup) -> some View {
        // Main group card (without expansion functionality)
        Button(action: {
            // Simply select the group without expansion
            selectedGroup = group
        }) {
            HStack(spacing: 16) {
                // Word count badge
                ZStack {
                    Circle()
                        .fill(Color.fromStringStatus(group.colorValue).gradient)
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.fromStringStatus(group.colorValue), radius: 1, x: 0, y: 0.5)
                    
                    VStack {
                        Text("\(group.words?.count ?? 0)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("words")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                // Group info
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.nameValue ?? "Unnamed Group")
                        .font(.headline)
                        .foregroundStyle(Color.fromStringStatus(group.colorValue).gradient)
                    
                    Text(group.descriptionValue ?? "No description")
                        .font(.caption)
                        .foregroundStyle(Color.fromStringStatus(group.colorValue).gradient.opacity(0.75))
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Selection indicator (replaces expansion indicator)
                Image(systemName: selectedGroup?.id == group.id ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(selectedGroup?.id == group.id ? Color.fromStringStatus(group.colorValue).gradient.opacity(0.99) : Color.gray.gradient.opacity(0.3))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedGroup?.id == group.id ? Color.fromStringStatus(group.colorValue).gradient : Color.clear.gradient, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(group.words?.count ?? 0 < 3) // Disable if not enough words
        .opacity(group.words?.count ?? 0 < 3 ? 0.6 : 1.0) // Dim if not enough words
    }
    
    var emptyGroupsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.gray)
                .padding(.vertical)
            
            Text("No Word Groups")
                .font(.headline)
            
            Text("Create word groups to organize your vocabulary and take targeted quizzes")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Create Group")
                    .fontWeight(.medium)
                    .padding()
                    .frame(width: 200)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    var startQuizButton: some View {
        Button(action: {
            navigateToQuiz = true
        }) {
            Text("Start Quiz")
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(canStartQuiz ? LinearGradient(colors: [.DarkDustyBlueColor,.DarkDustyBlueColor.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) : LinearGradient(colors: [Color.gray,Color.gray.opacity(0.9)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: canStartQuiz ? Color.DarkDustyBlueColor.opacity(0.4) : Color.clear, radius: 4, x: 0, y: 2)
        }
        .disabled(!canStartQuiz)
    }
    
    var canStartQuiz: Bool {
        return selectedGroup != nil && (selectedGroup?.words?.count ?? 0) >= 3
    }
}

struct QuizSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        QuizSelectionView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
