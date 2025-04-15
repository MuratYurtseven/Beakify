import Foundation

struct AppConfig {
    // Fetch the OpenAI API key from Info.plist
    static let openAIApiKey: String = {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OpenAIApiKey") as? String else {
            fatalError("OpenAI API key is missing in Info.plist")
        }
        return apiKey
    }()
    
    // Singleton instance of the OpenAI service
    static let openAIService = OpenAIService(apiKey: openAIApiKey)
}

