//
//  QuizSelectionButton.swift
//  Wordsy
//
//  Created by Murat on 12.04.2025.
//



import SwiftUI

struct QuizSelectionButton: View {
    @State private var showingQuizSelection = false
    
    var body: some View {
        Button(action: {
            showingQuizSelection = true
        }) {
            VStack(spacing: 6) {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.orange)
                    .padding(12)
                    .background(Color.orange.opacity(0.2))
                    .clipShape(Circle())
                
                Text("Take a Quiz")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Test your knowledge")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingQuizSelection) {
            QuizSelectionView()
        }
    }
}