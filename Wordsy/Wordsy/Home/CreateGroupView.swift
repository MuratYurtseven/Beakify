import SwiftUI
import CoreData

struct CreateGroupView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var selectedColor = "blue"
    @State private var selectedLanguage = ""
    
    let languageOptions = ["English", "Spanish", "French", "German", "Italian", "Turkish", "Chinese", "Japanese", "Russian","Korean","Arabic","Portuguese"]
    
    var groupToEdit: WordGroup?
    
    init(groupToEdit: WordGroup? = nil) {
        self.groupToEdit = groupToEdit
        
        if let group = groupToEdit {
            _groupName = State(initialValue: group.nameValue)
            _groupDescription = State(initialValue: group.descriptionValue)
            _selectedColor = State(initialValue: group.colorValue)
            _selectedLanguage = State(initialValue: group.selectedLanguageValue)
        }
    }
    
    let colorOptions: [(name: String, color: Color)] = [
        ("red", .red),
        ("orange", .orange),
        ("yellow", .yellow),
        ("green", .green),
        ("blue", .blue),
        ("purple", .purple),
        ("pink", .pink),
        ("teal", .teal),
        ("cyan", .cyan),
        ("mint", .mint),
        ("indigo", .indigo),
        ("brown", .brown)
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Group Information")) {
                    TextField("Group Name", text: $groupName)
                    TextField("Description (Optional)", text: $groupDescription)
                }
                
                Section(header: Text("Language")) {
                    Picker("Select Language", selection: $selectedLanguage) {
                        Text("Select a language").tag("")
                        ForEach(languageOptions, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 10) {
                        ForEach(colorOptions, id: \.name) { colorOption in
                            Circle()
                                .fill(colorOption.color)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedColor == colorOption.name ? 3 : 0)
                                )
                                .padding(5)
                                .onTapGesture {
                                    selectedColor = colorOption.name
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(groupToEdit == nil ? "Create Group" : "Edit Group")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGray6))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(groupToEdit == nil ? "Create" : "Save") {
                        saveGroup()
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedLanguage.isEmpty)
                }
            }
        }
    }
    
    private func saveGroup() {
        let group: WordGroup
        
        if let existingGroup = groupToEdit {
            // Edit existing group
            group = existingGroup
        } else {
            // Create new group
            group = WordGroup(context: viewContext)
            group.id = UUID()
            group.createdAt = Date()
        }
        
        // Update properties
        group.nameValue = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        group.descriptionValue = groupDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        group.colorValue = selectedColor
        group.selectedLanguageValue = selectedLanguage
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            let nsError = error as NSError
            print("Error saving group: \(nsError), \(nsError.userInfo)")
        }
    }
}

struct CreateGroupView_Previews: PreviewProvider {
    static var previews: some View {
        CreateGroupView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
