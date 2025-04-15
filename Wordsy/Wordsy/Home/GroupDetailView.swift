import SwiftUI
import CoreData

struct GroupDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) private var presentationMode
    
    let group: WordGroup
    
    @FetchRequest private var words: FetchedResults<UserWord>
    @State private var showingAddWords = false
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    
    init(group: WordGroup) {
        self.group = group
        // Create a fetch request for the words in this group
        let fetchRequest: NSFetchRequest<UserWord> = UserWord.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "ANY groups.id == %@", group.idValue as CVarArg)
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \UserWord.word, ascending: true)]
        
        _words = FetchRequest<UserWord>(fetchRequest: fetchRequest)
    }
    
    var body: some View {
        VStack {
            headerView
            
            if words.isEmpty {
                emptyStateView
            } else {
                wordsList
            }
        }
        .navigationTitle(group.nameValue)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(UIColor.systemGray6))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button(action: {
                        showingAddWords = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.darkDustyBlue.gradient)
                            .font(.title3)
                            .fontWeight(.semibold)
                            
                    }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundStyle(Color.russetColor.gradient)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    

                }
            }
        }
        .sheet(isPresented: $showingAddWords) {
            // Open AddWordView instead of AddWordsToGroupView, passing the current group
            AddWordView(preSelectedGroup: group)
        }
        .alert(isPresented: $showingDeleteAlert) {
            Alert(
                title: Text("Delete Group"),
                message: Text("Are you sure you want to delete '\(group.nameValue)'? This action cannot be undone."),
                primaryButton: .destructive(Text("Delete")) {
                    deleteGroup()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.fromStringStatus(group.colorValue))
                    .frame(width: 16, height: 16)
                
                Text(group.nameValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.darkOliveGreen.gradient)
                
            }
            
            if !group.descriptionValue.isEmpty {
                Text(group.descriptionValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text("\(words.count) words in this group")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Words in This Group")
                .font(.headline)
            
            Text("Tap + to add words to this group")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showingAddWords = true
            }) {
                Text("Add Words")
                    .font(.headline)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(LinearGradient(colors: [.darkOliveGreen,.oliveGreenColor], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    private var wordsList: some View {
        List {
            ForEach(words) { word in
                HStack {
                    VStack(alignment: .leading) {
                        Text(word.wordValue)
                            .font(.headline)
                        
                        if !word.noteValue.isEmpty {
                            Text(word.noteValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        removeWordFromGroup(word)
                    }) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
        }
    }
    
    private func removeWordFromGroup(_ word: UserWord) {
        word.removeFromGroup(group)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error removing word from group: \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func deleteGroup() {
        // First, delete all words that belong only to this group
        for word in words {
            // Check if this word belongs ONLY to this group
            if word.groups?.count == 1 {
                // If word belongs only to this group, delete the word
                viewContext.delete(word)
            }
            // If word belongs to multiple groups, it will remain in other groups
        }
        
        // Then delete the group
        viewContext.delete(group)
        
        do {
            try viewContext.save()
            // Navigate back to previous screen
            presentationMode.wrappedValue.dismiss()
        } catch {
            let nsError = error as NSError
            print("Error deleting group and its words: \(nsError), \(nsError.userInfo)")
        }
    }
}
