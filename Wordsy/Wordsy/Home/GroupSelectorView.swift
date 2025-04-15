import SwiftUI
import CoreData

struct GroupSelectorView: View {
    @Binding var selectedGroups: Set<WordGroup>
    var groups: FetchedResults<WordGroup>
    var currentLanguage: String
    
    // Computed property to filter groups by language
    private var compatibleGroups: [WordGroup] {
        // If no current language, show all groups
        if currentLanguage.isEmpty {
            return Array(groups)
        }
        
        // Otherwise, filter by matching language
        return groups.filter { $0.selectedLanguageValue == currentLanguage }
    }
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationView {
            List {
                if compatibleGroups.isEmpty {
                    // Show a message if no compatible groups
                    Text("No compatible groups found for the current language")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .padding()
                } else {
                    // Show only compatible groups
                    ForEach(compatibleGroups, id: \.self) { group in
                        HStack {
                            Circle()
                                .fill(Color(group.colorValue))
                                .frame(width: 12, height: 12)
                            
                            Text(group.nameValue)
                            
                            Spacer()
                            
                            if selectedGroups.contains(group) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if selectedGroups.contains(group) {
                                selectedGroups.remove(group)
                            } else {
                                // Since we only want one group, replace any existing selection
                                selectedGroups = [group]
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Select Group")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct GroupSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let fetchRequest = NSFetchRequest<WordGroup>(entityName: "WordGroup")
        
        return Group {
            // Accessing FetchResults directly in preview isn't possible
            // This is just a placeholder to demonstrate structure
            Text("GroupSelectorView Preview")
                .previewLayout(.sizeThatFits)
                .padding()
        }
    }
} 
