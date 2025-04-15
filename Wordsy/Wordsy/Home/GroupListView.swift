import SwiftUI
import CoreData

struct GroupListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        fetchRequest: WordGroup.getAllGroupsRequest(),
        animation: .default)
    private var groups: FetchedResults<WordGroup>
    
    @State private var showingAddGroup = false
    @State private var groupToEdit: WordGroup?
    
    var body: some View {
        NavigationStack {
            List {
                if groups.isEmpty {
                    Text("No groups created yet")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(groups) { group in
                        NavigationLink(destination: GroupDetailView(group: group)) {
                            HStack {
                                Circle()
                                    .fill(Color(group.colorValue))
                                    .frame(width: 12, height: 12)
                                
                                VStack(alignment: .leading) {
                                    Text(group.nameValue)
                                        .font(.headline)
                                    
                                    if !group.descriptionValue.isEmpty {
                                        Text(group.descriptionValue)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Text("\(group.wordsArray.count) words")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .contextMenu {
                            Button(action: {
                                groupToEdit = group
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: {
                                deleteGroup(group)
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete(perform: deleteGroups)
                }
            }
            .navigationTitle("Word Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddGroup = true
                    }) {
                        Label("Add Group", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                CreateGroupView()
            }
            .sheet(item: $groupToEdit) { group in
                CreateGroupView(groupToEdit: group)
            }
        }
    }
    
    private func deleteGroups(offsets: IndexSet) {
        withAnimation {
            offsets.map { groups[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Error deleting groups: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func deleteGroup(_ group: WordGroup) {
        viewContext.delete(group)
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            print("Error deleting group: \(nsError), \(nsError.userInfo)")
        }
    }
}

struct GroupListView_Previews: PreviewProvider {
    static var previews: some View {
        GroupListView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 