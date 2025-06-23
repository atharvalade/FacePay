//
//  Web3Service.swift
//  FacePay
//
//  Created by FacePay Team
//

import Foundation
import Combine

// For this demo, we'll simulate Web3 calls since setting up web3swift requires additional configuration
// In production, you would use web3swift or similar library

class Web3Service: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var lastTransactionHash: String?
    @Published var errorMessage: String?
    
    // MARK: - PYUSD Balance Operations
    func getPYUSDBalance(for address: String) async -> Double {
        await MainActor.run { isLoading = true }
        
        // Simulate API call delay
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        await MainActor.run { isLoading = false }
        
        // Return demo balances based on our known addresses
        switch address {
        case AppConfig.user1Address:
            return 187.50 // Updated from our test transaction
        case AppConfig.user2Address:
            return 94.01  // Updated from our test transaction
        case AppConfig.merchantAddress:
            return 118.49 // Updated from our test transaction
        default:
            return 0.0
        }
    }
    
    // MARK: - Payment Operations
    func chargeCustomer(customerAddress: String, amount: Double, merchantPrivateKey: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate payment processing
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        // Simulate transaction hash
        let txHash = generateMockTransactionHash()
        
        await MainActor.run {
            isLoading = false
            lastTransactionHash = txHash
        }
        
        print("💰 Payment Processed:")
        print("   From: \(customerAddress)")
        print("   Amount: \(amount) PYUSD")
        print("   Tx Hash: \(txHash)")
        
        return true
    }
    
    // MARK: - Approval Operations
    func hasApproval(customerAddress: String, amount: Double) async -> Bool {
        // In our demo, User 1 and User 2 have MAX approval set
        return [AppConfig.user1Address, AppConfig.user2Address].contains(customerAddress)
    }
    
    // MARK: - Transaction History
    func getRecentTransactions(for address: String) async -> [TransactionRecord] {
        await MainActor.run { isLoading = true }
        
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        await MainActor.run { isLoading = false }
        
        // Return mock transaction history
        return getMockTransactions(for: address)
    }
    
    // MARK: - Helper Methods
    private func generateMockTransactionHash() -> String {
        let chars = "0123456789abcdef"
        return "0x" + String((0..<64).compactMap { _ in chars.randomElement() })
    }
    
    private func getMockTransactions(for address: String) -> [TransactionRecord] {
        let calendar = Calendar.current
        let now = Date()
        
        switch address {
        case AppConfig.user1Address:
            return [
                TransactionRecord(
                    hash: "0x9d1445be00557d4d6458f92cbe555224c416c63cbca8babe1110a7c7b30b55a2",
                    from: AppConfig.user1Address,
                    to: AppConfig.merchantAddress,
                    amount: 12.50,
                    timestamp: calendar.date(byAdding: .minute, value: -15, to: now) ?? now,
                    type: .payment
                )
            ]
            
        case AppConfig.user2Address:
            return [
                TransactionRecord(
                    hash: "0x76b0bec8166b64298641fffa10a983d6ab71fcd865c82cf9aaa06dad197414f7",
                    from: AppConfig.user2Address,
                    to: AppConfig.merchantAddress,
                    amount: 5.99,
                    timestamp: calendar.date(byAdding: .minute, value: -5, to: now) ?? now,
                    type: .payment
                )
            ]
            
        case AppConfig.merchantAddress:
            return [
                TransactionRecord(
                    hash: "0x76b0bec8166b64298641fffa10a983d6ab71fcd865c82cf9aaa06dad197414f7",
                    from: AppConfig.user2Address,
                    to: AppConfig.merchantAddress,
                    amount: 5.99,
                    timestamp: calendar.date(byAdding: .minute, value: -5, to: now) ?? now,
                    type: .received
                ),
                TransactionRecord(
                    hash: "0x9d1445be00557d4d6458f92cbe555224c416c63cbca8babe1110a7c7b30b55a2",
                    from: AppConfig.user1Address,
                    to: AppConfig.merchantAddress,
                    amount: 12.50,
                    timestamp: calendar.date(byAdding: .minute, value: -15, to: now) ?? now,
                    type: .received
                )
            ]
            
        default:
            return []
        }
    }
}

// MARK: - Transaction Record Model
struct TransactionRecord: Identifiable {
    let id = UUID()
    let hash: String
    let from: String
    let to: String
    let amount: Double
    let timestamp: Date
    let type: TransactionType
    
    enum TransactionType {
        case payment
        case received
        case approval
        
        var displayName: String {
            switch self {
            case .payment: return "Payment"
            case .received: return "Received"
            case .approval: return "Approval"
            }
        }
        
        var color: String {
            switch self {
            case .payment: return "red"
            case .received: return "green"
            case .approval: return "blue"
            }
        }
    }
} 