import SwiftUI

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            WordStatusView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Learning", systemImage: "graduationcap.fill")
                }
                .tag(1)
            
            QuizSelectionView()
                .environment(\.managedObjectContext,viewContext)
                .tabItem {
                    Label("Quiz", systemImage: "gamecontroller.fill")
                }
                .tag(2)
            
            LanguageSelectionChatView()
                .environment(\.managedObjectContext, viewContext)
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(3)
            
            

            
        }
        .accentColor(.dustyBlueColor)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 
