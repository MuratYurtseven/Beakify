import SwiftUI

struct SentenceView: View {
    let sentence: Sentence
    
    var difficultyColor: Color {
        switch sentence.difficulty.lowercased() {
        case "easy":
            return .green
        case "medium":
            return .orange
        case "hard":
            return .red
        default:
            return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sentence.text)
                .font(.body)
                .lineLimit(3)
            
            HStack {
                Spacer()
                Text(sentence.difficulty.capitalized)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(difficultyColor.opacity(0.2))
                    .foregroundColor(difficultyColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 4)
    }
}

// Preview provider
struct SentenceView_Previews: PreviewProvider {
    static var previews: some View {
        let sentence = Sentence(text: "This is an example sentence to illustrate how the view will look.", difficulty: "medium")
        return SentenceView(sentence: sentence)
            .previewLayout(.sizeThatFits)
            .padding()
    }
} 