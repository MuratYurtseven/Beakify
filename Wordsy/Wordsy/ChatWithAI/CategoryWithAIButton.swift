//
//  CategoryWithAIButton 2.swift
//  Wordsy
//
//  Created by Murat on 11.04.2025.
//

import SwiftUI

struct CategoryWithAIButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    // Icon for each category
    var categoryIcon: String {
        switch category {
        case "All": return "square.grid.2x2"
        case "Daily Life": return "sun.max"
        case "Food": return "fork.knife"
        case "Travel": return "airplane"
        default: return "bubble.left"
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: categoryIcon)
                    .font(.subheadline)
                
                Text(category)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}
