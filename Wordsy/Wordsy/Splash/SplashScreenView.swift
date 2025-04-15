//
//  SplashScreenView.swift
//  Wordsy
//
//  Created by Murat on 14.04.2025.
//
import SwiftUI
import Combine

struct SplashScreenView: View {
    @State private var navigateToMainApp = false
    @EnvironmentObject var userViewModel: UserViewModel
    
    var body: some View {
        ZStack {
            if navigateToMainApp {
                MainTabView()
            } else {
                SplashPaywall()
                    .environmentObject(userViewModel)
                    .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ContinueToMainApp"))) { _ in
                        withAnimation {
                            navigateToMainApp = true
                        }
                    }
            }
        }
    }
}
