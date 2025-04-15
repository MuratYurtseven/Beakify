import SwiftUI

struct TranslationView: View {
    let translation: Translation?
    let isLoading: Bool
    
    var body: some View {
        VStack{
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    HStack {
                        Spacer()
                        VStack {
                            ProgressView()
                                .scaleEffect(1.0)
                            Text("Translating...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 4)
                        }
                        Spacer()
                    }
                    .padding()
                } else if let translation = translation {
                    // Translation Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image("translate")
                            
                            Text("Translation")
                                .font(.headline)
                                .foregroundStyle(Color.DarkLavenderPurpleColor.gradient)
                        }
                        
                        Text(translation.selectedTransText)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.DarkDustyBlueColor.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                }

            }
            .background(Color(UIColor.systemGray6))
            
        }

    }
}
