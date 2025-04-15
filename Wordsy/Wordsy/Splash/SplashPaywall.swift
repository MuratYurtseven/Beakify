//
//  SplashPaywall.swift
//  Wordsy
//
//  Created by Murat on 14.04.2025.
//


import SwiftUI
import RevenueCat
import Combine

// Splash screen with paywall functionality
struct SplashPaywall: View {
    @State private var isAnimating = false
    @State private var showPaywall = false
    @State private var currentOffering: Offering?
    @State private var selectedPackage: Package?
    @State private var isLoading = true
    @State private var loadingError: Error?
    @State private var showErrorAlert = false
    @State private var isPurchasing = false
    
    // Animation properties
    @State private var animateLogo = false
    @State private var animateOptions = false
    @State private var animateFeatures = false
    
    @EnvironmentObject var userViewModel: UserViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    // Helper to get packages
    private var weeklyPackage: Package? {
        return currentOffering?.package(identifier: "weekly") ??
               currentOffering?.availablePackages.first(where: { $0.packageType == .weekly })
    }
    
    private var annualPackage: Package? {
        return currentOffering?.package(identifier: "annual") ??
               currentOffering?.availablePackages.first(where: { $0.packageType == .annual })
    }
    
    // Timer for splash screen
    let timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Splash screen
            if !showPaywall {
                ZStack {
                    Color.black
                        .ignoresSafeArea()
                    
                    VStack {
                        Image(systemName: "text.word.spacing")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .scaleEffect(animateLogo ? 1.0 : 0.6)
                            .opacity(animateLogo ? 1 : 0)
                        
                        Text("Wordsy")
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 20)
                            .opacity(animateLogo ? 1 : 0)
                    }
                }
                .onAppear {
                    // Start splash screen animation
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        animateLogo = true
                    }
                    
                    // Check subscription status
                    Purchases.shared.getCustomerInfo { (customerInfo, error) in
                        if let error = error {
                            print("Error fetching subscription: \(error)")
                        }
                        
                        let isActive = customerInfo?.entitlements.all["pro"]?.isActive == true
                        DispatchQueue.main.async {
                            userViewModel.isSubscriptionActive = isActive
                        }
                    }
                }
                .onReceive(timer) { _ in
                    // When timer fires, check subscription and decide to show paywall or continue
                    timer.upstream.connect().cancel()
                    print("Subscried :" + userViewModel.isSubscriptionActive.description)
                    if !userViewModel.isSubscriptionActive {
                        // If not subscribed, show the paywall
                        withAnimation {
                            showPaywall = true
                        }
                        
                        // Load subscription offerings
                        Purchases.shared.getOfferings { offerings, error in
                            if let error = error {
                                loadingError = error
                                showErrorAlert = true
                                isLoading = false
                                return
                            }
                            
                            if let offer = offerings?.current {
                                currentOffering = offer
                                
                                if let annual = self.annualPackage {
                                    selectedPackage = annual
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        isLoading = false
                                        
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                            animateFeatures = true
                                        }
                                        
                                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                                            animateOptions = true
                                        }
                                    }
                                } else {
                                    loadingError = NSError(domain: "PaywallError", code: 1,
                                                   userInfo: [NSLocalizedDescriptionKey: "No subscription packages available."])
                                    showErrorAlert = true
                                    isLoading = false
                                }
                            } else {
                                loadingError = NSError(domain: "PaywallError", code: 2,
                                                userInfo: [NSLocalizedDescriptionKey: "No subscription offerings available."])
                                showErrorAlert = true
                                isLoading = false
                            }
                        }
                    } else {
                        // If already subscribed, continue to the main app
                        NotificationCenter.default.post(name: NSNotification.Name("ContinueToMainApp"), object: nil)
                    }
                }
            }
            
            // Paywall
            else {
                // Loading state
                if isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Loading subscription options...")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
                // Purchase in progress state
                else if isPurchasing {
                    VStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Processing your subscription...")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                            .padding(.top, 20)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                }
                // Main paywall content
                else {
                    ZStack {
                        Color.black.ignoresSafeArea()
                        
                        VStack(spacing: 20) {
                            // Header
                            VStack(spacing: 15) {
                                Text("Upgrade to Premium")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 30)
                                
                                Text("Unlock all premium features")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.horizontal, 20)
                            .opacity(animateFeatures ? 1 : 0)
                            .offset(y: animateFeatures ? 0 : 20)
                            
                            // Features section
                            VStack(alignment: .leading, spacing: 20) {
                                FeatureRowSplash(
                                    title: "Unlimited Vocabulary",
                                    description: "Access thousands of words and phrases",
                                    iconColor: .white,
                                    textColor: .white,
                                    secondaryColor: .gray
                                )
                                
                                FeatureRowSplash(
                                    title: "Ad-Free Experience",
                                    description: "Enjoy learning without interruptions",
                                    iconColor: .white,
                                    textColor: .white,
                                    secondaryColor: .gray
                                )
                                
                                FeatureRowSplash(
                                    title: "Personalized Progress",
                                    description: "Track your improvement with detailed analytics",
                                    iconColor: .white,
                                    textColor: .white,
                                    secondaryColor: .gray
                                )
                            }
                            .padding(.horizontal, 30)
                            .padding(.vertical, 20)
                            .opacity(animateFeatures ? 1 : 0)
                            .offset(y: animateFeatures ? 0 : 30)
                            
                            Spacer()
                            
                            // Subscription options
                            if let weekly = weeklyPackage, let annual = annualPackage {
                                VStack(spacing: 20) {
                                    HStack(spacing: 15) {
                                        // Weekly option
                                        SubscriptionOptionSplashView(
                                            title: "Weekly",
                                            price: weekly.displayPriceSplash,
                                            isSelected: selectedPackage == weekly,
                                            hasFreeTrial: false,
                                            isDarkMode: true
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedPackage = weekly
                                            }
                                        }
                                        
                                        // Annual option
                                        SubscriptionOptionSplashView(
                                            title: "Annual",
                                            price: annual.displayPriceSplash,
                                            isSelected: selectedPackage == annual,
                                            hasFreeTrial: false,
                                            isBestValue: true,
                                            isDarkMode: true
                                        )
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedPackage = annual
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                    .scaleEffect(animateOptions ? 1 : 0.9)
                                    .opacity(animateOptions ? 1 : 0)
                                    
                                    // Subscribe button
                                    Button {
                                        if let pkg = selectedPackage {
                                            isPurchasing = true
                                            
                                            Purchases.shared.purchase(package: pkg) { (transaction, customerInfo, error, userCancelled) in
                                                handlePurchaseCompletion(
                                                    transaction: transaction,
                                                    customerInfo: customerInfo,
                                                    error: error,
                                                    userCancelled: userCancelled
                                                )
                                            }
                                        }
                                    } label: {
                                        ZStack {
                                            Rectangle()
                                                .frame(height: 55)
                                                .foregroundColor(.white)
                                                .cornerRadius(10)
                                            
                                            Text("Subscribe Now")
                                                .foregroundColor(.black)
                                                .font(.system(size: 18, weight: .bold))
                                        }
                                    }
                                    .padding(.horizontal, 30)
                                    .scaleEffect(animateOptions ? 1 : 0.9)
                                    .opacity(animateOptions ? 1 : 0)
                                    .disabled(isPurchasing)
                                    
                                    // Price details
                                    if let pkg = selectedPackage {
                                        Text(pkg == annual ? "Billed annually" : "Billed weekly")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                            .multilineTextAlignment(.center)
                                            .padding(.top, 5)
                                            .padding(.horizontal, 30)
                                            .opacity(animateOptions ? 1 : 0)
                                    }
                                    
                                    // Continue without subscribing button
                                    Button {
                                        NotificationCenter.default.post(name: NSNotification.Name("ContinueToMainApp"), object: nil)
                                    } label: {
                                        Text("Continue without subscribing")
                                            .font(.system(size: 16))
                                            .foregroundColor(.gray)
                                            .padding(.vertical, 10)
                                    }
                                    .padding(.top, 10)
                                    .opacity(animateOptions ? 1 : 0)
                                    
                                    // Terms and restore
                                    HStack {
                                        Button("Restore Purchases") {
                                            isLoading = true
                                            Purchases.shared.restorePurchases { (customerInfo, error) in
                                                isLoading = false
                                                if let error = error {
                                                    loadingError = error
                                                    showErrorAlert = true
                                                    return
                                                }
                                                
                                                if customerInfo?.entitlements.all["pro"]?.isActive == true {
                                                    userViewModel.isSubscriptionActive = true
                                                    NotificationCenter.default.post(name: NSNotification.Name("ContinueToMainApp"), object: nil)
                                                } else {
                                                    loadingError = NSError(domain: "PaywallError", code: 4,
                                                                      userInfo: [NSLocalizedDescriptionKey: "No active subscription found."])
                                                    showErrorAlert = true
                                                }
                                            }
                                        }
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        
                                        Text("•")
                                            .foregroundColor(.gray)
                                        
                                        Button("Terms of Service") {
                                            // Open terms of service
                                        }
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                        
                                        Text("•")
                                            .foregroundColor(.gray)
                                        
                                        Button("Privacy Policy") {
                                            // Open privacy policy
                                        }
                                        .font(.system(size: 14))
                                        .foregroundColor(.gray)
                                    }
                                    .padding(.top, 15)
                                    .padding(.bottom, 30)
                                    .opacity(animateOptions ? 1 : 0)
                                }
                            }
                        }
                    }
                }
            }
        }
        .alert("Subscription Error", isPresented: $showErrorAlert) {
            Button("Try Again") {
                currentOffering = nil
                selectedPackage = nil
                isLoading = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    Purchases.shared.getOfferings { offerings, error in
                        if let error = error {
                            loadingError = error
                            showErrorAlert = true
                            isLoading = false
                            return
                        }
                        
                        if let offer = offerings?.current, let annual = offer.availablePackages.first(where: { $0.packageType == .annual }) {
                            currentOffering = offer
                            selectedPackage = annual
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isLoading = false
                                
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                    animateFeatures = true
                                }
                                
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.2)) {
                                    animateOptions = true
                                }
                            }
                        } else {
                            loadingError = NSError(domain: "PaywallError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No subscription packages available."])
                            showErrorAlert = true
                            isLoading = false
                        }
                    }
                }
            }
            
            Button("Continue without subscribing") {
                NotificationCenter.default.post(name: NSNotification.Name("ContinueToMainApp"), object: nil)
            }
        } message: {
            Text(loadingError?.localizedDescription ?? "An error occurred while loading subscription options.")
        }
    }
    
    private func handlePurchaseCompletion(transaction: StoreTransaction?, customerInfo: CustomerInfo?, error: Error?, userCancelled: Bool) {
        isPurchasing = false
        
        if userCancelled {
            print("User cancelled purchase")
            return
        }
        
        if let error = error {
            print("Purchase error: \(error.localizedDescription)")
            loadingError = error
            showErrorAlert = true
            return
        }
        
        if customerInfo?.entitlements.all["pro"]?.isActive == true {
            DispatchQueue.main.async {
                self.userViewModel.isSubscriptionActive = true
                NotificationCenter.default.post(name: NSNotification.Name("ContinueToMainApp"), object: nil)
            }
        } else {
            loadingError = NSError(domain: "PaywallError", code: 3,
                              userInfo: [NSLocalizedDescriptionKey: "Subscription processed but not activated. Please restart the app."])
            showErrorAlert = true
        }
    }
}

// Updated FeatureRow to support dark mode
struct FeatureRowSplash: View {
    let title: String
    let description: String
    var iconColor: Color = .black
    var textColor: Color = .black
    var secondaryColor: Color = .secondary
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(iconColor)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(textColor)
                
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(secondaryColor)
            }
        }
    }
}

// Updated SubscriptionOptionView to support dark mode
struct SubscriptionOptionSplashView: View {
    let title: String
    let price: String
    let isSelected: Bool
    let hasFreeTrial: Bool
    var isBestValue: Bool = false
    var isDarkMode: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? (isDarkMode ? Color.white : Color.black) : Color.gray.opacity(0.3), lineWidth: 2)
                .background(isSelected ? Color.gray.opacity(0.2) : Color.gray.opacity(0.05))
                .cornerRadius(10)
                .frame(height: 100)
            
            VStack(alignment: .center, spacing: 8) {
                if isBestValue {
                    Text("BEST VALUE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isDarkMode ? .black : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(isDarkMode ? Color.white : Color.black)
                        .cornerRadius(4)
                        .padding(.bottom, 4)
                } else {
                    Spacer()
                        .frame(height: 24)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isDarkMode ? .white : .black)
                
                Text(price)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(isDarkMode ? .white : .black)
                        .font(.system(size: 20))
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Package extension for price display
extension Package {
    var displayPriceSplash: String {
        if self.packageType == .annual {
            return "\(self.localizedPriceString)/yr"
        } else {
            return "\(self.localizedPriceString)/wk"
        }
    }
}
