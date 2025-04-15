//
//  CategoryButton.swift
//  Wordsy
//
//  Created by Murat on 11.04.2025.
//
import SwiftUI

struct CategoryButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.DarkLavenderPurpleColor : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}
