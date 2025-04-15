//
//  OnboardingView1.swift
//  Wordsy
//
//  Created by Murat on 12.04.2025.
//


import SwiftUI
import AVKit

struct OnboardingView1: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var player = AVPlayer(url: Bundle.main.url(forResource: "appIntro", withExtension: "mp4") ?? URL(fileURLWithPath: ""))
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing:5){
                Text("Welcome to ")
                Text("Beakify")
                    .font(.system(size: 36, weight: .bold))
                    .imageForegroundStyle(Image("backTextImage"))
                    .shadow(color: Color.russetColor, radius: 0.75, x: 0.2, y: 0.2)
                
            }
            .font(.system(size: 28, weight: .bold))
            .padding(.top, 40)
            
            
            Text("Watch this short video to see how our app works")
                .font(.system(size: 18))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Spacer()
            VideoPlayer(player: player)
                .frame(height: 400)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 20)
                .onAppear {
                    player.play()
                }
                .onDisappear {
                    player.pause()
                }
            
            Spacer()
            
            Button(action: {
                viewModel.currentPage = 1
            }) {
                Text("Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.oliveGreenColor, Color.DarkOliveGreenColor]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .shadow(color: Color.russetColor, radius: 0.75, x: 0.2, y: 0.2)
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .background(Color.white.edgesIgnoringSafeArea(.all))
    }
}
