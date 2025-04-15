import SwiftUI

struct WordItem: View {
    @ObservedObject var word: UserWord
    var onDelete: () -> Void
    
    var body: some View {
        NavigationLink(destination: WordDetailView(word: word)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(word.wordValue)
                        .font(.headline)
                    Spacer()
                    Text(word.typeValue)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(4)
                }
                
                if !word.noteValue.isEmpty {
                    Text(word.noteValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(word.createdAtValue, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        // This prevents the navigation from triggering when delete is tapped
                        onDelete()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
            }
            .padding(.vertical, 4)
        }
        // This ensures the entire row gets the navigation link styling
        .buttonStyle(PlainButtonStyle())
    }
} 