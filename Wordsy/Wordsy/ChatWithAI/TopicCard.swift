//
//  TopicCard.swift
//  Wordsy
//
//  Created by Murat on 11.04.2025.
//

import SwiftUI

struct TopicCard: View {
    let topic: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var categoryIcon: String {
        switch topic {
        case "Morning Routine": return "☕"
        case "Travel Plans": return "✈️"
        case "Commuting to Work": return "🚗"
        case "Weekend Activities": return "🌳"
        case "Favorite Foods": return "🍜"
        case "Cooking": return "🍳"
        case "Restaurants": return "🍽️"
        case "Recipes": return "📖"
        case "Destinations": return "🗺️"
        case "Travel Tips": return "💡"
        case "Cultural Experiences": return "🎭"
        case "Hobbies": return "🎨"
        default: return "💬"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(categoryIcon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.DarkLavenderPurpleColor : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }
}
