import Foundation
import CoreData

// Response structure for OpenAI quiz generation
struct QuizAPIResponse: Codable {
    let questions: [APIQuizQuestion]
}

struct APIQuizQuestion: Codable {
    let type: String
    let question: String
    let correctAnswer: String
    let options: [String]
    let sentence: String?
    let matchPairs: [[String: String]]?  // For drag and drop questions
    let audioText: String?  // For audio questions
    let questionEmojis: String?  // Added field for question-relevant emojis
}
class QuizAPIService {
    // Reference to the shared OpenAI service
    private let openAIService = AppConfig.openAIService
    
    func generateQuiz(for words: [UserWord], quizType: QuizSelectionView.QuizType = .standard, language: String = "en", completion: @escaping (Result<[QuizQuestion], Error>) -> Void) {
        // Need at least 3 words to make a quiz
        guard words.count >= 3 else {
            completion(.success([]))
            return
        }
        
        // Select a subset of words to use for the quiz (at most 10)
        let selectedWords = Array(words.shuffled().prefix(min(10, words.count)))
        
        // Get group context information
        var groupContextInfo = ""
        var groupTheme = ""
        if let firstWord = selectedWords.first,
           let group = firstWord.groupsArray.first {
            groupTheme = group.nameValue
            groupContextInfo = "These words belong to a group called \"\(group.nameValue)\" with description: \"\(group.descriptionValue)\". Please make the quiz questions thematically connected to this context."
        }

        // Create formatted string of words
        var wordsWithInfo = selectedWords.map { word in
            """
            {
                "word": "\(word.wordValue)",
                "type": "\(word.typeValue)",
                "definition": "\(word.noteValue)",
                "examples": \(getExampleSentencesJSON(for: word))
            }
            """
        }.joined(separator: ",\n")

        // Format instructions
        let customFormatInstructions = """
        CRITICAL: Format ALL questions in one of these styles:
        1. Vocabulary application: "Which [scenario] can best be described as '[word]'?"
        2. Vocabulary attribution: "Who/what displays the most '[word]' [quality] in [theme]?"
        3. Imaginary scenario: "If '[word]' were a [category], which would it be?"
        4. Spot the Imposter: "Which of these does NOT exemplify '[word]'?"
        Distribute questions equally among these formats.
        """

        let languageInstructions = "IMPORTANT: Generate all content in '\(language)' language. Only definitions can remain in original language if needed."

        let thematicInstructions = !groupTheme.isEmpty ?
            "CRITICAL: ALL options must be thematically connected to \"\(groupTheme)\"." :
            "Make all options contextually appropriate and thematically consistent."

        let prompt = """
        Generate a vocabulary quiz with 10 questions for these words:

        [\(wordsWithInfo)]

        \(groupContextInfo)

        \(languageInstructions)

        \(customFormatInstructions)

        \(thematicInstructions)

        CRITICAL GUIDELINES:
        - Each question MUST have exactly 4 options
        - The correct answer MUST be included in the options array
        - The "correctAnswer" value MUST match exactly one of the options
        - Incorrect options should be plausible but distinguishable from the correct answer
        - All options must be thematically relevant
        - Include 3 relevant(question) emojis for each question in the "questionEmojis" field

        If fewer than 10 words, create multiple questions per word.

        Return JSON format:
        {
          "questions": [
            {
              "type": "multipleChoice",
              "question": "Question text here",
              "correctAnswer": "The correct answer text here",
              "options": ["Option 1", "Option 2", "The correct answer text here", "Option 4"],
              "questionEmojis": "🐶😜👊🏼"
            }
          ]
        }

        CRITICAL: Use '\(language)' language and ensure the correct answer is one of the options.
        IMPORTANT: For each question, provide 3 relevant emojis in the questionEmojis field that relate to the question's content.
        """
        
        // Call OpenAI service to generate the quiz
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are an expert language teacher creating engaging and fun themed vocabulary quizzes. Generate questions in the exact formats specified, with creative and entertaining options."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.8  // Slightly increased for more creative results
        ]
        
        // Make the API call
        callOpenAI(with: requestBody) { result in
            switch result {
            case .success(let content):
                do {
                    // Parse the JSON response
                    if let jsonData = content.data(using: .utf8) {
                        let quizResponse = try JSONDecoder().decode(QuizAPIResponse.self, from: jsonData)
                        
                        // Convert API questions to our QuizQuestion model
                        let quizQuestions = self.convertToQuizQuestions(apiQuestions: quizResponse.questions, words: selectedWords)
                        completion(.success(quizQuestions))
                    } else {
                        completion(.failure(NSError(domain: "QuizAPIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode JSON content"])))
                    }
                } catch {
                    print("JSON parsing error: \(error)")
                    completion(.failure(error))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    
    // Validate that all options fit the thematic context
    private func validateThematicContext(options: [String], theme: String) -> Bool {
        guard !theme.isEmpty else {
            return true // No theme to validate against
        }
        
        // Check if all options have some connection to the theme
        // This is simplified - in reality, this would require more sophisticated analysis
        for option in options {
            if !option.lowercased().contains(theme.lowercased()) {
                // No direct mention of the theme - might not be thematic
                // In real implementation, this would need more sophisticated NLP
                print("Warning: Option '\(option)' may not be thematically connected to '\(theme)'")
            }
        }
        
        return true // Simplified - always return true but log warnings
    }
    
    private func callOpenAI(with requestBody: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "https://api.openai.com/v1/chat/completions"
        
        // Create the request
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(AppConfig.openAIApiKey)", forHTTPHeaderField: "Authorization")
        
        // Convert request body to JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        // Create the data task
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "QuizAPIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                // Parse the OpenAI response
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                
                if let content = openAIResponse.choices.first?.message.content {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "QuizAPIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "No content in response"])))
                }
            } catch {
                print("Decoding error: \(error)")
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    // Convert API questions to our app model
    private func convertToQuizQuestions(apiQuestions: [APIQuizQuestion], words: [UserWord]) -> [QuizQuestion] {
        var quizQuestions: [QuizQuestion] = []
        
        // Get the group theme if available
        var groupTheme = ""
        if let firstWord = words.first,
           !firstWord.groupsArray.isEmpty,
           let group = firstWord.groupsArray.first {
            groupTheme = group.nameValue
        }
        
        for apiQuestion in apiQuestions {
            // Find the corresponding word
            if let word = findWord(for: apiQuestion, in: words) {
                
                let questionType: QuestionType
                switch apiQuestion.type.lowercased() {
                case "multiplechoice":
                    questionType = .multipleChoice
                case "fillinblank":
                    questionType = .fillInBlank
                case "draganddrop":
                    questionType = .dragAndDrop
                case "audio":
                    questionType = .audio
                default:
                    questionType = .multipleChoice
                }
                
                // Calculate blank position for fill-in-blank questions
                var blankPosition: Int? = nil
                if questionType == .fillInBlank, let sentence = apiQuestion.sentence {
                    blankPosition = sentence.firstIndex(of: "_")?.utf16Offset(in: sentence) ?? 0
                }
                
                // Convert match pairs for drag and drop questions
                var matchPairs: [(term: String, definition: String)]? = nil
                if questionType == .dragAndDrop, let apiMatchPairs = apiQuestion.matchPairs {
                    matchPairs = apiMatchPairs.compactMap { pair in
                        if let term = pair["term"], let definition = pair["definition"] {
                            return (term: term, definition: definition)
                        }
                        return nil
                    }
                }
                
                // Create audio URL for audio questions
                var audioURL: URL? = nil
                if questionType == .audio {
                    // In a real implementation, you would generate or fetch the audio file
                    // For this example, we'll use a placeholder
                    // audioURL = createAudioURL(for: apiQuestion.correctAnswer)
                }
                
                // Validate that all options maintain thematic connection
                if (questionType == .multipleChoice || questionType == .fillInBlank) && !groupTheme.isEmpty {
                    // Check if options all fit the thematic context
                    validateThematicContext(options: apiQuestion.options, theme: groupTheme)
                }
                
                // Use emojis from API or provide default
                let emojis = apiQuestion.questionEmojis ?? "🤔📚📝"
                
                let quizQuestion = QuizQuestion(
                    questionType: questionType,
                    word: word,
                    question: apiQuestion.question,
                    correctAnswer: apiQuestion.correctAnswer,
                    options: apiQuestion.options,
                    sentence: apiQuestion.sentence,
                    blankPosition: blankPosition,
                    matchPairs: matchPairs,
                    audioURL: audioURL,
                    audioText: apiQuestion.audioText,
                    questionEmojis: emojis
                )
                
                quizQuestions.append(quizQuestion)
            }
        }
        
        return quizQuestions
    }
    
    // Find the corresponding word from our word list
    private func findWord(for question: APIQuizQuestion, in words: [UserWord]) -> UserWord? {
        // Try to find the word in the correct answer or question
        for word in words {
            let wordText = word.wordValue.lowercased()
            
            // Check if word appears in the correct answer
            if question.correctAnswer.lowercased().contains(wordText) {
                return word
            }
            
            // Check if word appears in the question
            if question.question.lowercased().contains(wordText) {
                return word
            }
            
            // For fill-in-blank, the word is often the correct answer
            if question.type.lowercased() == "fillinblank" &&
               question.correctAnswer.lowercased() == wordText {
                return word
            }
        }
        
        // If we can't determine the word, use the first one (fallback)
        return words.first
    }
    
    // Format example sentences as a JSON array for the prompt
    private func getExampleSentencesJSON(for word: UserWord) -> String {
        guard let wordID = word.id else { return "[]" }
        
        let sentences = CoreDataSetup.getSentences(for: wordID)
        if sentences.isEmpty {
            return "[]"
        }
        
        let sentenceTexts = sentences.map { "\"\($0.text)\"" }
        return "[\(sentenceTexts.joined(separator: ", "))]"
    }
}
