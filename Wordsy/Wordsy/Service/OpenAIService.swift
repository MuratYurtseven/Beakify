import Foundation

struct SentenceResponse: Codable {
    let sentences: [Sentence]
}

struct Sentence: Codable, Identifiable {
    let id = UUID()
    let text: String
    let difficulty: String
    
    enum CodingKeys: String, CodingKey {
        case text, difficulty
    }
}

// Updated structure for word information response with translation
struct WordInfoResponse: Codable {
    let type: String
    let meaning: String
    let translation: String
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let isUser: Bool
    var translatedContent: String?
    var isTranslating: Bool = false  // Add this new flag
    
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id &&
               lhs.translatedContent == rhs.translatedContent &&
               lhs.isTranslating == rhs.isTranslating
    }
}

class OpenAIService {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func chatWithAI(messages: [ChatMessage], selectedLanguage: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Create the request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Convert our ChatMessage array to OpenAI format
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": "You are a helpful language practice assistant. You MUST follow these strict rules: 1) ONLY respond in \(selectedLanguage) language. 2) Keep ALL responses under 20 words maximum. 3) NEVER use any other language than \(selectedLanguage)."]
        ]
        
        // Add conversation history
        for message in messages {
            let role = message.isUser ? "user" : "assistant"
            apiMessages.append(["role": role, "content": message.content])
        }
        
        // Create the request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": apiMessages,
            "temperature": 0.7,
            "max_tokens": 100  // Reduced max tokens to encourage shorter responses
        ]
        
        // Convert request body to JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Print the request for debugging
        if let requestData = request.httpBody, let requestString = String(data: requestData, encoding: .utf8) {
            print("API Request: \(requestString)")
        }
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            // Debug: Print raw response
            if let responseString = String(data: data, encoding: .utf8) {
                print("API Response: \(responseString)")
            }
            
            do {
                // Try parsing as error response first
                if let errorResponse = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                    let errorMessage = errorResponse.error.message
                    print("API Error: \(errorMessage)")
                    completion(.failure(NSError(domain: "OpenAIAPI", code: 400, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    return
                }
                
                // Parse the OpenAI response
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                
                if let content = openAIResponse.choices.first?.message.content {
                    // Process the response to validate it meets requirements
                    let wordCount = content.split(separator: " ").count
                    
                    if wordCount > 20 {
                        // If response is too long, make another request with more strict instruction
                        self.retryWithStricterConstraints(messages: messages, selectedLanguage: selectedLanguage, completion: completion)
                    } else {
                        completion(.success(content))
                    }
                } else {
                    completion(.failure(NSError(domain: "OpenAIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No content in response"])))
                }
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    private func retryWithStricterConstraints(messages: [ChatMessage], selectedLanguage: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create a more strict system message
        var apiMessages: [[String: String]] = [
            ["role": "system", "content": "CRITICAL INSTRUCTION: You are a language practice assistant that MUST follow these rules EXACTLY: 1) ONLY respond in \(selectedLanguage). 2) Your response MUST be UNDER 20 WORDS - this is a hard requirement. 3) Keep responses extremely brief and concise. 4) NEVER explain or apologize about length restrictions."]
        ]
        
        // Add conversation history
        for message in messages {
            let role = message.isUser ? "user" : "assistant"
            apiMessages.append(["role": role, "content": message.content])
        }
        
        // Create the request body with reduced max_tokens
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": apiMessages,
            "temperature": 0.7,
            "max_tokens": 60  // Further reduced to force compliance
        ]
        
        // Convert request body to JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                // Parse the OpenAI response
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                
                if let content = openAIResponse.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "OpenAIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No content in response"])))
                }
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
 
    // In OpenAIService.swift - Updated getWordInfo function for better language handling
    func getWordInfo(word: String, sourceLanguage: String = "", translateLanguage: String, completion: @escaping (Result<WordInfoResponse, Error>) -> Void) {
        // Create the request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Get display name for the languages
        let sourceLanguageDisplay = sourceLanguage.isEmpty ? "" : getLanguageDisplayName(for: sourceLanguage)
        let targetLanguageDisplay = getLanguageDisplayName(for: translateLanguage)
        
        // Create a more specific prompt based on source language info
        let prompt: String
        if !sourceLanguage.isEmpty {
            prompt = """
            The word "\(word)" is in \(sourceLanguageDisplay). Please provide:
            1. Its most common word type (noun, verb, adjective, adverb, or other) in English classification
            2. A short clear meaning in \(sourceLanguageDisplay)
            3. A translation to \(targetLanguageDisplay)
            
            Return only valid JSON with this structure:
            {
              "type": "The word type (noun/verb/adjective/adverb/other)",
              "meaning": "A brief definition or explanation in \(sourceLanguageDisplay)",
              "translation": "The translation of the word to \(targetLanguageDisplay)"
            }
            """
        } else {
            prompt = """
            Analyze the word "\(word)" and determine its language. Then provide:
            1. Its most common word type (noun, verb, adjective, adverb, or other) in English classification
            2. A short clear meaning in the original language of the word
            3. A translation to \(targetLanguageDisplay)
            
            Return only valid JSON with this structure:
            {
              "type": "The word type (noun/verb/adjective/adverb/other)",
              "meaning": "A brief definition or explanation in the original language",
              "translation": "The translation of the word to \(targetLanguageDisplay)"
            }
            """
        }
        
        // Create the request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a multilingual language assistant that provides word information and translations between various languages."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.3
        ]
        
        // Convert request body to JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                // Parse the OpenAI response
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                
                if let content = openAIResponse.choices.first?.message.content {
                    // Extract the JSON from the response content
                    if let jsonData = content.data(using: .utf8) {
                        let wordInfo = try JSONDecoder().decode(WordInfoResponse.self, from: jsonData)
                        completion(.success(wordInfo))
                    } else {
                        completion(.failure(NSError(domain: "OpenAIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode JSON content"])))
                    }
                } else {
                    completion(.failure(NSError(domain: "OpenAIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No content in response"])))
                }
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    // Helper function to get display name for language codes
    private func getLanguageDisplayName(for languageCode: String) -> String {
        switch languageCode.lowercased() {
        case "tr", "turkish":
            return "Turkish"
        case "en", "english":
            return "English"
        case "es", "spanish":
            return "Spanish"
        case "fr", "french":
            return "French"
        case "de", "german":
            return "German"
        case "it", "italian":
            return "Italian"
        case "pt", "portuguese":
            return "Portuguese"
        case "ru", "russian":
            return "Russian"
        case "zh", "chinese":
            return "Chinese"
        case "ja", "japanese":
            return "Japanese"
        case "ko", "korean":
            return "Korean"
        case "ar", "arabic":
            return "Arabic"
        default:
            return languageCode.capitalized
        }
    }
    
    func generateSentences(for word: String, groupTitle: String, groupDescription: String, groupLanguage: String, completion: @escaping (Result<[Sentence], Error>) -> Void) {
        // Create the request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Determine language for sentence generation
        let language = groupLanguage.isEmpty ? "English" : groupLanguage
        
        // Construct the prompt with context from group title, description and language
        let prompt = """
        Write 5 \(language) sentences using the word "\(word)" in contexts related to "\(groupTitle)": "\(groupDescription)".
        The sentences should be thematically connected to this context and use the word naturally.
        Use a mix of difficulty levels and tenses if possible.
        Give this in JSON format with the following structure:
        {
          "sentences": [
            {"text": "The sentence here", "difficulty": "easy|medium|hard"}
          ]
        }
        Only return valid JSON without any other text or explanation.
        """
        
        // Create the request body
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant that generates contextually relevant example sentences in multiple languages."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        // Convert request body to JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                // Parse the OpenAI response
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                
                if let content = openAIResponse.choices.first?.message.content {
                    // Extract the JSON from the response content
                    if let jsonData = content.data(using: .utf8) {
                        let sentenceResponse = try JSONDecoder().decode(SentenceResponse.self, from: jsonData)
                        completion(.success(sentenceResponse.sentences))
                    } else {
                        completion(.failure(NSError(domain: "OpenAIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode JSON content"])))
                    }
                } else {
                    completion(.failure(NSError(domain: "OpenAIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No content in response"])))
                }
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    func generateTranslation(prompt: String, translateLanguage: String, completion: @escaping (Result<String, Error>) -> Void) {
        // Create the request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Create the request body with language-specific system prompt
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful language assistant that provides translations and explanations in various languages. The user will specify the target languages in their prompt."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 300
        ]
        
        // Convert request body to JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "OpenAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                // Parse the OpenAI response
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                
                if let content = openAIResponse.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "OpenAIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No content in response"])))
                }
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
}

// OpenAI API response models
struct OpenAIResponse: Codable {
    let id: String?
    let object: String?
    let created: Int?
    let model: String?
    let choices: [Choice]
    let usage: Usage?
}

struct Choice: Codable {
    let index: Int?
    let message: Message
    let finishReason: String?
    
    enum CodingKeys: String, CodingKey {
        case index, message
        case finishReason = "finish_reason"
    }
}

struct Message: Codable {
    let role: String?
    let content: String
}

struct Usage: Codable {
    let promptTokens: Int?
    let completionTokens: Int?
    let totalTokens: Int?
    
    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
    }
}

// Simple API error response structure
struct OpenAIErrorResponse: Codable {
    let error: OpenAIError
}

struct OpenAIError: Codable {
    let message: String
    let type: String?
    let param: String?
    let code: String?
}
