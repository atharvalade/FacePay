//
//  AppState.swift
//  FacePay
//
//  Created by FacePay Team
//

import Foundation
import SwiftUI
import Combine

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
    
    // MARK: - Services
    @Published var faceService = FaceRecognitionService()
    @Published var storageService = StorageService()
    @Published var web3Service = Web3Service()
    
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
        currentBalance = await web3Service.getPYUSDBalance(for: address)
    }
    
    // MARK: - Transaction Management
    @MainActor
    func loadRecentTransactions() async {
        let address = currentMode == .merchant ? AppConfig.merchantAddress : selectedUser.address
        recentTransactions = await web3Service.getRecentTransactions(for: address)
    }
    
    // MARK: - Face Registration
    @MainActor
    func startFaceRegistration() {
        guard !storageService.isUserRegistered(address: selectedUser.address) else {
            showAlert(title: "Already Registered", message: "\(selectedUser.name) already has a face registered. Remove the existing registration first.")
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
        
        if let averageEmbedding = await faceService.generateAverageEmbedding(from: capturedImages) {
            
            // Process embedding addition on background queue to avoid publishing warnings
            storageService.addFaceEmbedding(
                walletAddress: selectedUser.address,
                embedding: averageEmbedding,
                userName: selectedUser.name
            )
            
            await MainActor.run {
                isRegistering = false
                capturedImages = []
            }
            
            // Delay alert to avoid presentation conflicts
            await MainActor.run {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                    guard let self = self else { return }
                    self.showAlert(title: "Registration Complete! 🎉", message: "\(self.selectedUser.name)'s face has been successfully registered for payments.")
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
        guard let queryEmbedding = await faceService.generateFaceEmbedding(from: image) else {
            showAlert(title: "Face Detection Failed", message: "Could not detect a face in the image. Please try again.")
            return
        }
        
        let allEmbeddings = storageService.getAllEmbeddings()
        
        if let match = faceService.findBestMatch(for: queryEmbedding, in: allEmbeddings), match.isMatch {
            lastCustomerMatch = match
            await processPayment(match: match)
        } else {
            showAlert(title: "No Match Found", message: "Face not recognized. Customer may need to register first.")
        }
    }
    
    // MARK: - Payment Processing
    private func processPayment(match: FaceMatchResult) async {
        guard let amount = Double(merchantAmount) else { return }
        
        let success = await web3Service.chargeCustomer(
            customerAddress: match.walletAddress,
            amount: amount,
            merchantPrivateKey: AppConfig.merchantPrivateKey
        )
        
        await MainActor.run {
            if success {
                lastPaymentAmount = amount
                showingPaymentSuccess = true
                merchantAmount = ""
                
                // Refresh balances and transactions
                Task {
                    await refreshBalance()
                    await loadRecentTransactions()
                }
            } else {
                showAlert(title: "Payment Failed", message: "Could not process payment. Please try again.")
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
    
    @MainActor
    func removeUserFace() {
        storageService.removeFaceEmbedding(for: selectedUser.address)
        showAlert(title: "Face Removed", message: "\(selectedUser.name)'s face registration has been removed.")
    }
    
    // MARK: - Alert Management
    @MainActor
    func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showingAlert = true
    }
    
    // MARK: - Demo Reset
    @MainActor
    func resetDemo() {
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