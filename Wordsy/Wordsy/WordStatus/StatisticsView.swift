import SwiftUI
import Charts

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @State private var stats: [String: Any] = [:]
    @State private var selectedTimeRange: TimeRange = .day
    @State private var isLoading = true
    
    enum TimeRange: String, CaseIterable {
        case hours = "Hours"
        case day = "Day"
        case week = "Week"
    }
    
    // Theme colors
    private var primaryColor: Color { Color(hex: "4361ee") }
    private var secondaryColor: Color { Color(hex: "4cc9f0") }
    private var accentColor: Color { Color(hex: "f72585") }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if isLoading {
                    loadingView
                } else {
                    VStack(spacing: 24) {
                        // Summary cards
                        summaryCards
                        
                        // Learning progress
                        learningProgressCard
                        
                        // Today's activity
                        todayActivityCard
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color(UIColor.systemGray6))
            .navigationTitle("Statistics")
            
            .refreshable {
                await loadStatisticsAsync()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        loadStatistics()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(primaryColor)
                    }
                }
            }
            .onAppear {
                loadStatistics()
            }
        }

    }
    
    // Loading view
    var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Loading statistics...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // Summary cards
    var summaryCards: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    title: "Total Words",
                    value: "\(stats["totalWords"] as? Int ?? 0)",
                    icon: "book.fill",
                    color: primaryColor
                )
                
                StatCard(
                    title: "Mastered",
                    value: "\(stats["masteredWords"] as? Int ?? 0)",
                    icon: "star.fill",
                    color: secondaryColor
                )
                
                StatCard(
                    title: "Success Rate",
                    value: String(format: "%.0f%%", (stats["successRate"] as? Double ?? 0) * 100),
                    icon: "chart.bar.fill",
                    color: accentColor
                )
                
                StatCard(
                    title: "Quizzes",
                    value: "\(stats["totalQuizzes"] as? Int ?? 0)",
                    icon: "checkmark.square.fill",
                    color: primaryColor
                )
            }
        }
        .padding(.top)
    }
    
    // Learning progress card
    var learningProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Learning Progress")
                .font(.headline)
                .foregroundColor(.primary)
            
            SimpleProgressChart(stats: stats)
                .frame(height: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    
    // Today's activity card
    var todayActivityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Activity")
                .font(.headline)
                .foregroundColor(.primary)
            
            if let todayProgress = stats["todayProgress"] as? DailyProgress {
                HStack(spacing: 20) {
                    TodayStatItem(
                        title: "Words Learned",
                        value: "\(todayProgress.wordsLearned)",
                        color: secondaryColor
                    )
                    
                    Divider()
                    
                    TodayStatItem(
                        title: "Quizzes Taken",
                        value: "\(todayProgress.quizzesTaken)",
                        color: primaryColor
                    )
                    
                    if todayProgress.correctAnswers + todayProgress.incorrectAnswers > 0 {
                        Divider()
                        
                        let rate = Double(todayProgress.correctAnswers) / Double(todayProgress.correctAnswers + todayProgress.incorrectAnswers)
                        TodayStatItem(
                            title: "Success Rate",
                            value: String(format: "%.0f%%", rate * 100),
                            color: accentColor
                        )
                    }
                }
            } else {
                emptyDataView(message: "No activity today")
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // Empty data view
    func emptyDataView(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 28))
                .foregroundColor(Color.secondary.opacity(0.6))
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .padding()
    }
    
    // Load statistics
    func loadStatistics() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            let statistics = ProgressTracker.shared.getStatistics(in: self.viewContext)
            
            DispatchQueue.main.async {
                withAnimation {
                    self.stats = statistics
                    self.isLoading = false
                }
            }
        }
    }
    
    // Async version for refreshable
    func loadStatisticsAsync() async {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let statistics = ProgressTracker.shared.getStatistics(in: self.viewContext)
                
                DispatchQueue.main.async {
                    withAnimation {
                        self.stats = statistics
                        self.isLoading = false
                    }
                    continuation.resume()
                }
            }
        }
    }
    
    // Filter progress history based on selected time range
    func filteredProgressHistory(_ history: [DailyProgress]) -> [DailyProgress] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .hours:
            // Last 24 hours
            let yesterday = calendar.date(byAdding: .hour, value: -24, to: now)!
            return history.filter { $0.date >= yesterday }
            
        case .day:
            // Last 7 days
            let lastWeek = calendar.date(byAdding: .day, value: -6, to: now)!
            return history.filter { $0.date >= lastWeek }
            
        case .week:
            // Last 4 weeks
            let lastMonth = calendar.date(byAdding: .day, value: -27, to: now)!
            return history.filter { $0.date >= lastMonth }
        }
    }
}

// MARK: - Components

// Stat card component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(.title2, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(color)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
}

// Today's stat item
struct TodayStatItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// Simple progress chart component
struct SimpleProgressChart: View {
    let stats: [String: Any]
    
    var body: some View {
        let totalWords = stats["totalWords"] as? Int ?? 0
        let newWords = stats["newWords"] as? Int ?? 0
        let learningWords = stats["learningWords"] as? Int ?? 0
        let masteredWords = stats["masteredWords"] as? Int ?? 0
        
        return VStack {
            if totalWords > 0 {
                Chart {
                    SectorMark(
                        angle: .value("New", max(newWords, 1)),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(Color(hex: "adb5bd"))
                    
                    SectorMark(
                        angle: .value("Learning", max(learningWords, 1)),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(Color(hex: "4895ef"))
                    
                    SectorMark(
                        angle: .value("Mastered", max(masteredWords, 1)),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(Color(hex: "4cc9f0"))
                }
                .frame(height: 180)
                
                // Legend
                HStack(spacing: 16) {
                    legendItem(color: Color(hex: "adb5bd"), label: "New (\(newWords))")
                    legendItem(color: Color(hex: "4895ef"), label: "Learning (\(learningWords))")
                    legendItem(color: Color(hex: "4cc9f0"), label: "Mastered (\(masteredWords))")
                }
                .padding(.top, 8)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Text("Add words to see your progress")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 150)
            }
        }
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Simple performance chart component
struct SimplePerformanceChart: View {
    let history: [DailyProgress]
    
    var body: some View {
        let sortedHistory = history.sorted { $0.date < $1.date }
        
        if sortedHistory.isEmpty {
            return AnyView(
                Text("No data for selected period")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            )
        }
        
        return AnyView(
            Chart {
                ForEach(sortedHistory) { day in
                    // Words learned
                    BarMark(
                        x: .value("Date", day.dateString),
                        y: .value("Words", day.wordsLearned)
                    )
                    .foregroundStyle(Color(hex: "4cc9f0"))
                    
                    // Success rate line
                    if day.correctAnswers + day.incorrectAnswers > 0 {
                        let rate = Double(day.correctAnswers) / Double(day.correctAnswers + day.incorrectAnswers)
                        
                        LineMark(
                            x: .value("Date", day.dateString),
                            y: .value("Rate", rate)
                        )
                        .foregroundStyle(Color(hex: "f72585"))
                        .lineStyle(StrokeStyle(lineWidth: 2))
                    }
                }
            }
            .chartLegend(position: .top) {
                HStack(spacing: 16) {
                    legendItem(color: Color(hex: "4cc9f0"), label: "Words Learned")
                    legendItem(color: Color(hex: "f72585"), label: "Success Rate")
                }
            }
            .chartYScale(domain: 0...1)
        )
    }
    
    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 4)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Color extension for hex values
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct StatisticsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
