//
//  OnboardingViewModel.swift
//  Wordsy
//
//  Created by Murat on 12.04.2025.
//
//
//  OnboardingViewModel.swift
//  Wordsy
//
//  Created by Murat on 12.04.2025.
//
import SwiftUI
import RevenueCat

// ViewModel to store user data throughout onboarding
class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @Published var isOnboardingComplete = false
    @Published var showPaywall = false
    
    // Personal info
    @Published var name = ""
    @Published var age = 0
    @Published var gender = ""
    @Published var country = ""
    @Published var translationLanguage = ""
    
    // Learning preferences
    @Published var learningFrequency = ""
    @Published var selectedLanguages: [String] = []
    @Published var reviewFrequency = ""
    @Published var contentPreferences: [String] = []
    
    // Subscription info
    @Published var subscriptionType = "Free"
    
    // Generate learning plan based on user input
    func generateLearningPlan() {
        // This would contain logic to generate a personalized learning plan
        // based on the collected user preferences
        print("Generating learning plan for \(name)")
        print("Languages: \(selectedLanguages.joined(separator: ", "))")
        print("Learning frequency: \(learningFrequency)")
        print("Content preferences: \(contentPreferences.joined(separator: ", "))")
    }
    
    // Generate target information for the progress screen
    func generateTargetInfo(completion: @escaping (Result<Bool, Error>) -> Void) {
        // Simulate API call or calculations
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completion(.success(true))
        }
    }
    
    // Show paywall after learning plan generation
    func showPaywallScreen() {
        self.showPaywall = true
    }
    
    // Complete onboarding process
    func completeOnboarding() {
        // Show paywall instead of directly completing onboarding
        showPaywallScreen()
    }

    func finishOnboarding() {
        print("Finishing onboarding - subscription successful")
        
        // Save user preferences to UserDefaults or another persistence mechanism
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        UserDefaults.standard.set(self.name, forKey: "userName")
        UserDefaults.standard.set(self.selectedLanguages, forKey: "selectedLanguages")
        UserDefaults.standard.set(self.learningFrequency, forKey: "learningFrequency")
        UserDefaults.standard.set(self.reviewFrequency, forKey: "reviewFrequency")
        UserDefaults.standard.set(self.subscriptionType, forKey: "subscriptionType")
        
        // Ensure this is set to true to trigger navigation
        DispatchQueue.main.async {
            self.isOnboardingComplete = true
            self.showPaywall = false
        }
    }
    // Check if user has completed onboarding
    func checkOnboardingStatus() {
        if UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") {
            self.isOnboardingComplete = true
        }
    }
}
struct OnboardingContainer: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var userViewModel = UserViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        if hasCompletedOnboarding {
            // Navigate to main app after onboarding and subscription
            MainTabView()
                .environment(\.managedObjectContext, viewContext)
                .environmentObject(userViewModel)
        } else {
            ZStack {
                // Show appropriate onboarding page, but hide it when paywall is showing
                if !viewModel.showPaywall {
                    switch viewModel.currentPage {
                    case 0:
                        OnboardingView1(viewModel: viewModel)
                    case 1:
                        OnboardingView2(viewModel: viewModel)
                    case 2:
                        OnboardingView3(viewModel: viewModel)
                    case 3:
                        OnboardingView4(viewModel: viewModel)
                    case 4:
                        OnboardingView5(viewModel: viewModel)
                    default:
                        OnboardingView1(viewModel: viewModel)
                    }
                }
                
                // Show paywall when triggered
                if viewModel.showPaywall {
                    OnboardingPaywall(isPaywallPresented: $viewModel.showPaywall)
                        .environmentObject(userViewModel)
                        .transition(.opacity)
                        .zIndex(1) // Ensure paywall is on top
                }
            }
            .animation(.easeInOut, value: viewModel.showPaywall)
            .onReceive(userViewModel.$isSubscriptionActive) { isActive in
                print("Subscription status changed: \(isActive)")
                if isActive {
                    // Complete onboarding when subscription is active
                    viewModel.finishOnboarding()
                    // Force navigation to MainTabView by updating AppStorage directly
                    hasCompletedOnboarding = true
                }
            }
        }
    }
    
    // Initialize and check if user has completed onboarding
    init() {
        let viewModel = OnboardingViewModel()
        viewModel.checkOnboardingStatus()
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._userViewModel = StateObject(wrappedValue: UserViewModel())
    }
}
