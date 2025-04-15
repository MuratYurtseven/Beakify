//
//  UserViewModel.swift
//  Wordsy
//
//  Created by Murat on 13.04.2025.
//
import SwiftUI
import RevenueCat
import StoreKit
import UserNotifications

class UserViewModel: ObservableObject {
    @Published var isSubscriptionActive = false
    @Published var hasUsedFreeTrial = false
    
    init() {
        // Check subscription status on launch
        Purchases.shared.getCustomerInfo { (customerInfo, error) in
            self.isSubscriptionActive = customerInfo?.entitlements.all["pro"]?.isActive == true
            self.checkPreviousFreeTrialUsage()
        }
    }
    
    func checkPreviousFreeTrialUsage() {
        // Check UserDefaults as simple method for onboarding
        if UserDefaults.standard.bool(forKey: "hasUsedFreeTrial") {
            self.hasUsedFreeTrial = true
        }
    }
    
    func recordFreeTrialUsage() {
        UserDefaults.standard.set(true, forKey: "hasUsedFreeTrial")
        self.hasUsedFreeTrial = true
    }
}

// Helper to schedule reminder for free trial
func scheduleReminderNotification() {
    let center = UNUserNotificationCenter.current()
    
    center.requestAuthorization(options: [.alert, .sound]) { granted, error in
        if granted {
            let content = UNMutableNotificationContent()
            content.title = "Your Free Trial Ends Tomorrow"
            content.body = "Your 3-day free trial will end tomorrow. Enjoy premium features with no interruption!"
            content.sound = .default
            
            // Set trigger for 2 days from now
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60 * 60 * 24 * 2, repeats: false)
            let request = UNNotificationRequest(identifier: "trialReminder", content: content, trigger: trigger)
            
            center.add(request) { error in
                if let error = error {
                    print("Error scheduling notification: \(error)")
                }
            }
        }
    }
}

extension Package {
    var displayPrice: String {
        if self.packageType == .annual {
            return "\(self.localizedPriceString)/yr"
        } else {
            return "\(self.localizedPriceString)/wk"
        }
    }
    
    var hasFreeTrial: Bool {
        if let intro = self.storeProduct.introductoryDiscount {
            return intro.price == 0
        }
        return false
    }
    
    var bottomPriceText: String {
        if self.packageType == .annual {
            return "3 days free, then \(self.localizedPriceString) per year"
        } else {
            return "Just \(self.localizedPriceString) per week"
        }
    }
}

struct OnboardingPaywall: View {
    @Binding var isPaywallPresented: Bool
    @State private var currentOffering: Offering?
    @State private var selectedPackage: Package?
    @State private var isLoading = true
    @State private var loadingError: Error?
    @State private var showErrorAlert = false
    @State private var isPurchasing = false
    
    // Animation properties
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
    
    // Get current date plus 3 days for the billing start date
    private var billingStartDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMM yyyy"
        let date = Calendar.current.date(byAdding: .day, value: 3, to: Date())!
        return dateFormatter.string(from: date)
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
                
                // Schedule notification only for annual with free trial
                if self.selectedPackage?.packageType == .annual && !self.userViewModel.hasUsedFreeTrial {
                    scheduleReminderNotification()
                }
                
                // Mark onboarding as complete and save subscription status
                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                self.hasCompletedOnboarding = true
                
                // Dismiss the paywall
                self.isPaywallPresented = false
            }
        } else {
            loadingError = NSError(domain: "PaywallError", code: 3,
                                  userInfo: [NSLocalizedDescriptionKey: "Subscription processed but not activated. Please restart the app."])
            showErrorAlert = true
        }
    }
    
    var body: some View {
        ZStack {
            // Loading state
            if isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.black)
                    Text("Loading subscription options...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
            // Purchase in progress state
            else if isPurchasing {
                VStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.black)
                    Text("Processing your subscription...")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 20)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.white)
            }
            // Main content
            else {
                VStack(spacing: 20) {
                    // Header
                    VStack(spacing: 15) {
                        Text("Start your fitness journey")
                            .font(.system(size: 28, weight: .bold))
                            .multilineTextAlignment(.center)
                            .padding(.top, 30)
                        
                        Text(userViewModel.hasUsedFreeTrial ?
                            "Subscribe to unlock all features" :
                            "Try free for 3 days")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    .opacity(animateFeatures ? 1 : 0)
                    .offset(y: animateFeatures ? 0 : 20)
                    
                    // Features section
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(
                            title: "Smart Calorie Tracking",
                            description: "Scan food with your camera for instant tracking"
                        )
                        
                        FeatureRow(
                            title: "Personalized Workouts",
                            description: "Get custom workouts based on your goals"
                        )
                        
                        FeatureRow(
                            title: "Progress Tracking",
                            description: "See your improvement with detailed analytics"
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
                                SubscriptionOptionView(
                                    title: "Weekly",
                                    price: weekly.displayPrice,
                                    isSelected: selectedPackage == weekly,
                                    hasFreeTrial: weekly.hasFreeTrial && !userViewModel.hasUsedFreeTrial
                                )
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedPackage = weekly
                                    }
                                }
                                
                                // Annual option
                                SubscriptionOptionView(
                                    title: "Annual",
                                    price: annual.displayPrice,
                                    isSelected: selectedPackage == annual,
                                    hasFreeTrial: annual.hasFreeTrial && !userViewModel.hasUsedFreeTrial,
                                    isBestValue: true
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
                                    
                                    if pkg.hasFreeTrial && !userViewModel.hasUsedFreeTrial {
                                        userViewModel.recordFreeTrialUsage()
                                    }
                                    
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
                                        .foregroundColor(.black)
                                        .cornerRadius(10)
                                    
                                    Text(userViewModel.hasUsedFreeTrial ?
                                         "Subscribe Now" :
                                         (selectedPackage?.packageType == .annual ? "Start Free Trial" : "Start Now"))
                                        .foregroundColor(.white)
                                        .font(.system(size: 18, weight: .bold))
                                }
                            }
                            .padding(.horizontal, 30)
                            .scaleEffect(animateOptions ? 1 : 0.9)
                            .opacity(animateOptions ? 1 : 0)
                            .disabled(isPurchasing)
                            
                            // Price details
                            if let pkg = selectedPackage {
                                Text(pkg.bottomPriceText)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                                    .padding(.top, 5)
                                    .padding(.horizontal, 30)
                                    .opacity(animateOptions ? 1 : 0)
                            }
                            
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
                                            hasCompletedOnboarding = true
                                            isPaywallPresented = false
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
                                
                            }
                            .padding(.top, 15)
                            .padding(.bottom, 30)
                            .opacity(animateOptions ? 1 : 0)
                        }
                    }
                }
            }
        }
        .onAppear {
            isLoading = true
            loadingError = nil
            
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
            
            Button("Skip") {
                // Allow skipping during onboarding
                hasCompletedOnboarding = true
                isPaywallPresented = false
            }
        } message: {
            Text(loadingError?.localizedDescription ?? "An error occurred while loading subscription options.")
        }
    }
}

struct FeatureRow: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct SubscriptionOptionView: View {
    let title: String
    let price: String
    let isSelected: Bool
    let hasFreeTrial: Bool
    var isBestValue: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.black : Color.gray.opacity(0.3), lineWidth: 2)
                .background(isSelected ? Color.gray.opacity(0.1) : Color.gray.opacity(0.05))
                .cornerRadius(10)
                .frame(height: 100)
            
            VStack(alignment: .center, spacing: 8) {
                if isBestValue {
                    Text("BEST VALUE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.black)
                        .cornerRadius(4)
                        .padding(.bottom, 4)
                } else {
                    Spacer()
                        .frame(height: 24)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                
                Text(price)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.black)
                        .font(.system(size: 20))
                } else {
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        .frame(width: 20, height: 20)
                }
            }
            
            if hasFreeTrial {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Capsule()
                                .fill(Color.orange)
                                .frame(width: 80, height: 24)
                            
                            Text("3 DAYS FREE")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, -10)
                        .padding(.trailing, -5)
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
