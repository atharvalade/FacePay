//
//  AppState.swift
//  FacePay
//
//  Created by FacePay Team
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentMode: AppMode = .consumer
    @Published var selectedUser: DemoUser = AppConfig.demoUsers[0]
    @Published var currentBalance: Double = 0.0
    @Published var isAuthenticated = false
    @Published var showingCamera = false
    @Published var showingAlert = false
    @Published var alertMessage = ""
    @Published var alertTitle = ""
    @Published var recentTransactions: [TransactionRecord] = []
    
    // PayPal Integration
    @Published var currentPayPalUser: PayPalUserProfile?
    @Published var currentSupabaseUser: SupabaseUser?
    @Published var isUserSetup = false
    
    // Face Registration Status
    @Published var faceRegistrationStatusChanged = false
    
    // MARK: - Services
    @Published var faceService = FaceRecognitionService()
    @Published var storageService = StorageService()
    @Published var web3Service = Web3Service()
    @Published var supabaseService = SupabaseService()
    
    // MARK: - Merchant State
    @Published var merchantAmount: String = ""
    @Published var lastCustomerMatch: FaceMatchResult?
    @Published var showingPaymentSuccess = false
    @Published var lastPaymentAmount: Double = 0.0
    
    // MARK: - Camera State
    @Published var capturedImages: [UIImage] = []
    @Published var isRegistering = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupBindings()
        loadInitialData()
    }
    
    private func setupBindings() {
        // Listen to user changes and update balance
        $selectedUser
            .sink { [weak self] user in
                Task {
                    await self?.refreshBalance()
                }
            }
            .store(in: &cancellables)
        
        // Listen to mode changes
        $currentMode
            .sink { [weak self] mode in
                self?.handleModeChange(mode)
            }
            .store(in: &cancellables)
    }
    
    private func loadInitialData() {
        Task {
            await refreshBalance()
            await loadRecentTransactions()
        }
    }
    
    // MARK: - Balance Management
    @MainActor
    func refreshBalance() async {
        let address = currentMode == .merchant ? AppConfig.merchantAddress : selectedUser.address
        let balance = await web3Service.getPYUSDBalance(for: address)
        
        // Ensure UI update happens on next run loop to avoid SwiftUI conflicts
        DispatchQueue.main.async { [weak self] in
            self?.currentBalance = balance
        }
    }
    
    // MARK: - Transaction Management
    @MainActor
    func loadRecentTransactions() async {
        let address = currentMode == .merchant ? AppConfig.merchantAddress : selectedUser.address
        let transactions = await web3Service.getRecentTransactions(for: address)
        
        // Ensure UI update happens on next run loop to avoid SwiftUI conflicts
        DispatchQueue.main.async { [weak self] in
            self?.recentTransactions = transactions
        }
    }
    
    // MARK: - Face Registration
    @MainActor
    func startFaceRegistration() {
        guard let paypalUser = currentPayPalUser else {
            showAlert(title: "Error", message: "PayPal user not found. Please login again.")
            return
        }
        
        // Check if user is already registered in Supabase
        Task {
            let hasEmbedding = await supabaseService.hasFaceEmbedding(paypalId: paypalUser.sub)
            await MainActor.run {
                if hasEmbedding {
                    showAlert(title: "Already Registered", message: "\(paypalUser.name) already has a face registered. Remove the existing registration first.")
                    return
                }
                
                guard !isRegistering else {
                    print("⚠️ Registration already in progress")
                    return
                }
                
                capturedImages = []
                isRegistering = true
                showingCamera = true
            }
        }
    }
    
    @MainActor
    func handleCapturedImage(_ image: UIImage) {
        capturedImages.append(image)
        showingCamera = false
        
        if capturedImages.count >= 3 {
            // We have enough images, process them
            Task {
                await processFaceRegistration()
            }
        } else {
            // Need more images
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                if !self.showingCamera { // Only show if not already showing
                    self.showingCamera = true
                }
            }
        }
    }
    
    private func processFaceRegistration() async {
        guard !capturedImages.isEmpty else { 
            return 
        }
        
        guard let paypalUser = currentPayPalUser,
              let supabaseUser = currentSupabaseUser else {
            await MainActor.run {
                isRegistering = false
                capturedImages = []
                showAlert(title: "Error", message: "User information not found.")
            }
            return
        }
        
        if let averageEmbedding = await faceService.generateAverageEmbedding(from: capturedImages) {
            
            do {
                // Save to Supabase
                _ = try await supabaseService.saveFaceEmbedding(
                    userId: supabaseUser.id ?? UUID(),
                    paypalId: paypalUser.sub,
                    walletAddress: selectedUser.address,
                    embedding: averageEmbedding
                )
                
                // Also save locally for backwards compatibility
                storageService.addFaceEmbedding(
                    walletAddress: selectedUser.address,
                    embedding: averageEmbedding,
                    userName: selectedUser.name
                )
                
                await MainActor.run {
                    isRegistering = false
                    capturedImages = []
                }
                
                print("✅ Face registration completed for \(paypalUser.name)")
                
                // Trigger UI refresh for registration status
                await MainActor.run {
                    faceRegistrationStatusChanged.toggle()
                }
                
                // Delay alert to avoid presentation conflicts
                await MainActor.run {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        guard let self = self else { return }
                        self.showAlert(title: "Registration Complete! 🎉", message: "\(paypalUser.name)'s face has been successfully registered for payments.")
                    }
                }
                
            } catch {
                await MainActor.run {
                    isRegistering = false
                    capturedImages = []
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                        guard let self = self else { return }
                        self.showAlert(title: "Registration Failed", message: "Failed to save face data: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            await MainActor.run {
                isRegistering = false
                capturedImages = []
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self = self else { return }
                    self.showAlert(title: "Registration Failed", message: "Could not process face images. Please try again.")
                }
            }
        }
    }
    
    // MARK: - Face Recognition (Merchant)
    @MainActor
    func startFaceRecognition() {
        guard !merchantAmount.isEmpty, let amount = Double(merchantAmount), amount > 0 else {
            showAlert(title: "Invalid Amount", message: "Please enter a valid payment amount.")
            return
        }
        
        showingCamera = true
    }
    
    @MainActor
    func handleMerchantFaceCapture(_ image: UIImage) async {
        // Convert image to JPEG data for API
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            showAlert(title: "Image Processing Failed", message: "Could not process the captured image. Please try again.")
            return
        }
        
        print("🎯 Face captured, using API for neural network matching...")
        
        // Use API-based face recognition with face-api.js neural networks
        if let match = await web3Service.matchFaceViaAPI(imageData: imageData) {
            print("✅ API Face match found!")
            print("   - User: \(match.userName)")
            print("   - Wallet: \(match.walletAddress)")
            print("   - Confidence: \(String(format: "%.1f", match.confidence * 100))%")
            print("   - Payment amount: \(merchantAmount) PYUSD")
            
            lastCustomerMatch = match
            
            // Process payment with proper async handling
            Task {
                await processPayment(match: match)
            }
        } else {
            print("❌ No face match found by API")
            showAlert(title: "No Match Found", message: "Face not recognized by neural network. Customer may need to register first with proper lighting and clear face visibility.")
        }
    }
    
    // MARK: - Payment Processing
    private func processPayment(match: FaceMatchResult) async {
        guard let amount = Double(merchantAmount) else { 
            print("❌ Invalid merchant amount: \(merchantAmount)")
            return 
        }
        
        print("💳 Processing payment:")
        print("   - Customer: \(match.walletAddress)")
        print("   - Amount: \(amount) PYUSD")
        print("   - Merchant key: \(AppConfig.merchantPrivateKey.prefix(10))...")
        
        let success = await web3Service.chargeCustomer(
            customerAddress: match.walletAddress,
            amount: amount,
            merchantPrivateKey: AppConfig.merchantPrivateKey
        )
        
        print("💰 Payment result: \(success ? "SUCCESS" : "FAILED")")
        if let errorMsg = web3Service.errorMessage {
            print("   Error: \(errorMsg)")
        }

        await MainActor.run {
            if success {
                print("🎉 Payment successful, updating UI...")
                self.lastPaymentAmount = amount
                self.showingPaymentSuccess = true
                self.merchantAmount = ""
                
                // Refresh balances and transactions after a delay
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    await self.refreshBalance()
                    await self.loadRecentTransactions()
                }

            } else {
                print("💥 Payment failed, showing error...")
                let errorMessage = self.web3Service.errorMessage ?? "Could not process payment. Please try again."
                self.showAlert(title: "Payment Failed", message: errorMessage)
            }
        }
    }
    
    // MARK: - Mode Management
    private func handleModeChange(_ mode: AppMode) {
        Task {
            await refreshBalance()
            await loadRecentTransactions()
        }
    }
    
    // MARK: - User Management
    @MainActor
    func switchUser() {
        let currentIndex = AppConfig.demoUsers.firstIndex { $0.address == selectedUser.address } ?? 0
        let nextIndex = (currentIndex + 1) % AppConfig.demoUsers.count
        selectedUser = AppConfig.demoUsers[nextIndex]
    }
    

    
    // MARK: - User Registration Status
    func isUserRegistered() async -> Bool {
        guard let paypalUser = currentPayPalUser else { 
            print("⚠️ No PayPal user found for registration check")
            return false 
        }
        
        let hasEmbedding = await supabaseService.hasFaceEmbedding(paypalId: paypalUser.sub)
        print("🔍 Checking face registration for PayPal ID: \(paypalUser.sub)")
        print("   Result: \(hasEmbedding ? "REGISTERED" : "NOT REGISTERED")")
        
        return hasEmbedding
    }
    
    // MARK: - Alert Management
    @MainActor
    func showAlert(title: String, message: String) {
        // Simple approach: only show if no alert is currently showing
        guard !showingAlert else {
            print("⚠️ Alert already showing, skipping: \(title) - \(message)")
            return
        }
        
        alertTitle = title
        alertMessage = message
        showingAlert = true
        print("📱 Showing alert: \(title) - \(message)")
    }
    
    // MARK: - PayPal Integration
    @MainActor
    func setupWithPayPalUser(paypalUser: PayPalUserProfile, supabaseUser: SupabaseUser) {
        currentPayPalUser = paypalUser
        currentSupabaseUser = supabaseUser
        isUserSetup = true
        
        // Update selected user based on PayPal user with real name
        if let demoUser = AppConfig.demoUsers.first(where: { $0.id == paypalUser.sub }) {
            // Create an updated user with the real PayPal name
            selectedUser = DemoUser(
                id: demoUser.id,
                name: paypalUser.name, // Use real PayPal name
                email: demoUser.email,
                address: demoUser.address,
                privateKey: demoUser.privateKey
            )
        }
        
        print("✅ Setup complete for PayPal user: \(paypalUser.name)")
        print("   Email: \(paypalUser.email)")
        print("   Wallet: \(selectedUser.address)")
        
        // Load user data
        Task {
            await refreshBalance()
            await loadRecentTransactions()
        }
    }
    
    // MARK: - Demo Reset
    @MainActor
    func resetDemo() {
        if let paypalId = currentPayPalUser?.sub {
            Task {
                try? await supabaseService.deleteFaceEmbedding(paypalId: paypalId)
            }
        }
        storageService.clearAllEmbeddings()
        merchantAmount = ""
        lastCustomerMatch = nil
        capturedImages = []
        showAlert(title: "Demo Reset", message: "All face registrations have been cleared.")
    }
}

// MARK: - App Mode
enum AppMode: String, CaseIterable {
    case consumer = "Consumer"
    case merchant = "Merchant"
    
    var icon: String {
        switch self {
        case .consumer: return "person.circle.fill"
        case .merchant: return "storefront.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .consumer: return .blue
        case .merchant: return .green
        }
    }
} 