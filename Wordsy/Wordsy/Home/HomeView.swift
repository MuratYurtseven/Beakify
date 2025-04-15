import SwiftUI
import CoreData

struct HomeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WordGroup.name, ascending: true)],
        animation: .default)
    private var groups: FetchedResults<WordGroup>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserWord.createdAt, ascending: false)],
        animation: .default)
    private var words: FetchedResults<UserWord>
    
    @FetchRequest(
        entity: UserPreferences.entity(),
        sortDescriptors: [],
        animation: .default
    ) private var preferences: FetchedResults<UserPreferences>
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    title
                    headerSection
                    
                    statsSection
                    
                    if !groups.isEmpty {
                        groupsSection
                    } else {
                        emptyStateView
                    }
                    
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .background(Color(UIColor.systemGray6))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: Settings()) {
                        Image(systemName: "gear")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.darkDustyBlue.gradient)
                            
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: StatisticsView()
                        .environment(\.managedObjectContext, viewContext)) {
                        Image(systemName: "chart.bar.fill")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundStyle(.darkDustyBlue.gradient)
                            
                    }
                }
            }
        }
    }

    private var title:some View {
        HStack{
            Text("Beakify")
                .font(.system(size: 50, weight: .bold))
                .imageForegroundStyle(Image("backTextImage"))
                .shadow(color: Color.russetColor, radius: 0.75, x: 0.2, y: 0.2)
                
            Spacer()
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let prefs = preferences.first {
                    Text("Hello \(prefs.nameValue)! 👋")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.darkOliveGreen.gradient)

                    HStack(spacing: 4) {
                        HStack(spacing: 4){
                            Text("You added ")
                            Text("\(words.count)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.darkOliveGreen.gradient)
                                .offset(x:-2)
                            Text("words.")
                                .offset(x: words.count > 100 ? 5 : 0)
                        }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if !prefs.translateLanguageValue.isEmpty {
                            Text(getFlagEmoji(for: prefs.translateLanguageValue))
                                .font(.headline)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }


    // Helper function to convert language code to flag emoji
    private func getFlagEmoji(for languageCode: String) -> String {
        // Dictionary mapping language codes to flag emojis
        let languageToFlag: [String: String] = [
            "en-US": "🇺🇸",
            "zh": "🇨🇳",
            "ja": "🇯🇵",
            "en-GB": "🇬🇧",
            "en-CA": "🇨🇦",
            "de": "🇩🇪",
            "en-AU": "🇦🇺",
            "fr": "🇫🇷",
            "ko": "🇰🇷",
            "hi": "🇮🇳",
            "pt-BR": "🇧🇷",
            "ru": "🇷🇺",
            "it": "🇮🇹",
            "es": "🇪🇸",
            "es-MX": "🇲🇽",
            "tr": "🇹🇷",
            "ar-AE": "🇦🇪",
            "zh-TW": "🇹🇼"
        ]
        
        // If we have a language code with a region (e.g., en-US), try that first
        if let flag = languageToFlag[languageCode] {
            return flag
        }
        
        // If we can't find the exact match, try to match just the language part
        if languageCode.contains("-") {
            let baseLang = languageCode.split(separator: "-")[0]
            if let flag = languageToFlag[String(baseLang)] {
                return flag
            }
        }
        
        // Default flag if we can't match
        return "🌐"
    }
    
    // Stats overview section
    private var statsSection: some View {
        HStack(spacing: 16) {
            statCard(title: "Words", value: "\(words.count)", icon: "textformat.abc")
            statCard(title: "Groups", value: "\(groups.count)", icon: "folder.fill")
        }
    }
    
    // Individual stat card
    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                    .foregroundStyle(LinearGradient(colors: [Color.DarkOliveGreenColor,Color.oliveGreenColor], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // Groups section
    private var groupsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Word Groups", icon: "folder.fill")
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(groups, id: \.idValue) { group in
                    groupCard(for: group)
                }
                
                NavigationLink(destination: CreateGroupView()) {
                    addGroupCard
                }
            }
        }
    }
    
    private func groupCard(for group: WordGroup) -> some View {
        NavigationLink(destination: GroupDetailView(group: group)) {
            VStack(alignment: .leading, spacing: 12) {
                // Group color and count
                HStack {
                    Circle()
                        .fill(Color.fromString(group.color ?? "blue"))
                        .frame(width: 12, height: 12)
                    
                    Text(getFlagForLanguage(group.selectedLanguageValue))
                        .font(.title3)
                    
                    Spacer()
                    
                    Text("\(group.wordsArray.count) word")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Group name
                Text(group.nameValue)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding()
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // Helper function to convert language name to flag emoji
    private func getFlagForLanguage(_ language: String) -> String {
        switch language.lowercased() {
        case "english": return "🇬🇧"
        case "spanish": return "🇪🇸"
        case "french": return "🇫🇷"
        case "german": return "🇩🇪"
        case "italian": return "🇮🇹"
        case "turkish": return "🇹🇷"
        case "chinese": return "🇨🇳"
        case "japanese": return "🇯🇵"
        case "russian": return "🇷🇺"
        case "korean": return "🇰🇷"
        case "arabic": return "🇸🇦"
        case "portuguese": return "🇵🇹"
        default: return "🌐" // Default globe emoji for unknown languages
        }
    }
    
    // Add new group card
    private var addGroupCard: some View {
        VStack {
            Image(systemName: "plus.circle")
                .font(.system(size: 24))
                .foregroundStyle(.darkOliveGreen.gradient)
            
            Text("New Group")
                .font(.headline)
                .foregroundStyle(.darkOliveGreen.gradient)
        }
        .padding()
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.darkOliveGreen.gradient.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
                )
        )
    }
    

    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 50))
                .fontWeight(.semibold)
                .foregroundStyle(.darkOliveGreen.gradient)
                .padding(.bottom, 5)
            
            Text("No Groups Yet")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Create your first group to organize your words.")
                .font(.subheadline)
                .fontWeight(.thin)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: CreateGroupView()) {
                Text("Add Group")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(colors: [.DarkOliveGreenColor,.oliveGreenColor], startPoint: .topLeading, endPoint: .bottomTrailing))
                    )
            }
        }
        .padding(.vertical, 40)
        .padding(.horizontal)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    // Section header
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .fontWeight(.semibold)
                .foregroundStyle(.darkOliveGreen.gradient)
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
            
            Spacer()
        }
    }
}

extension Color {
    static func fromString(_ string: String) -> Color {
        switch string.lowercased() {
        case "red": return Color(red: 0.95, green: 0.3, blue: 0.3)
        case "green": return Color(red: 0.3, green: 0.85, blue: 0.5)
        case "blue": return Color(red: 0.2, green: 0.5, blue: 0.95)
        case "orange": return Color(red: 1.0, green: 0.6, blue: 0.2)
        case "purple": return Color(red: 0.7, green: 0.3, blue: 0.9)
        case "pink": return Color(red: 0.95, green: 0.4, blue: 0.7)
        case "teal": return Color(red: 0.2, green: 0.7, blue: 0.7)
        case "yellow": return Color(red: 1.0, green: 0.85, blue: 0.2)
        default: return Color(red: 0.3, green: 0.6, blue: 0.9)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
