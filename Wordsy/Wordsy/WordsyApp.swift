//
//  WordsyApp.swift
//  Wordsy
//
//  Created by Murat on 9.04.2025.
//
import SwiftUI
import RevenueCat
import Combine

@main
struct WordsyApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @StateObject private var userViewModel = UserViewModel()
    
    init() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "")
    }
    
    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingContainer()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(userViewModel)
            } else {
                SplashScreenView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(userViewModel)
            }
        }
    }
}
