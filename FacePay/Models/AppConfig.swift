//
//  AppConfig.swift
//  FacePay
//
//  Created by FacePay Team
//

import Foundation

struct AppConfig {
    // MARK: - Network Configuration
    static let network = "sepolia"
    static let chainId = 11155111
    static let rpcUrl = "https://sepolia.infura.io/v3/40f21c9a3e114c7d880efefc7d9b04be" // Replace with your key
    
    // MARK: - Contract Addresses (Deployed on Sepolia)
    static let pyusdAddress = "0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9"
    static let paymentHubAddress = "0x728d0f06Bf6D63B4bC9ca7C879D042DDAC66e8A3"
    
    // MARK: - PayPal Configuration
    static let paypalClientId = "AflhgYo-nF7EpxGO_JYjADDHabPPhegssyt3JPILIDs5bwOTryriWevfAUGUcj5imYtKWqH6FJf73Bsc"
    static let paypalSecret = "EBGerYC-X6fbBTuV6R_7M9D5CGqzzoZoNe-3oFRJQ8Z6AyxfE-n4Gb7Ga0kpOmrshIsXM4NoZXbAuVDo"
    static let paypalEnvironment = "sandbox"
    
    // MARK: - Supabase Configuration  
    static let supabaseURL = "https://nugfkvafpxuaspphxxmd.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51Z2ZrdmFmcHh1YXNwcGh4eG1kIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA2ODY1NDksImV4cCI6MjA2NjI2MjU0OX0.rGssg1k9zAPHG_aoe2MHc4LpevdQUh8uxlbaGOq6hCM"
    
    // MARK: - Wallet Addresses (Demo)
    static let user1Address = "0x9f93EebD463d4B7c991986a082d974E77b5a02Dc"
    static let user1PrivateKey = "15953296e322c945eaa0c215f8740fcdb1cb18231d19e477efa91ae4310becdf"
    
    static let user2Address = "0xa999F0CB16b55516BD82fd77Dc19f495b41f0770"
    static let user2PrivateKey = "dcf06adcd2d997d57bfb5275ae3493d8afdb606d7c51c66eafbb7c5abff04d2c"
    
    static let merchantAddress = "0x27A7A44250C6Eb3C84d1d894c8A601742827C7C7"
    static let merchantPrivateKey = "ffc39a39c2d5436985f83336fe8710c38a50ab49171e19ea5ca9968e7fff2492"
    
    // MARK: - Contract ABIs
    static let paymentHubABI = [
        "function charge(address customer, uint256 amount) external",
        "function getBalance(address customer) external view returns (uint256)",
        "function hasApproval(address customer, uint256 amount) external view returns (bool)",
        "function getAllowance(address customer) external view returns (uint256)"
    ]
    
    static let pyusdABI = [
        "function balanceOf(address account) external view returns (uint256)",
        "function approve(address spender, uint256 amount) external returns (bool)",
        "function allowance(address owner, address spender) external view returns (uint256)"
    ]
    
    // MARK: - PYUSD Configuration
    static let pyusdDecimals = 6
    
    // MARK: - Face Recognition Configuration
    static let faceMatchThreshold: Float = 0.75 // Increased for better security
    static let embeddingsFileName = "face_embeddings.json"
    
    // MARK: - Demo Users (PayPal Sandbox with Real Names)
    static let demoUsers: [DemoUser] = [
        DemoUser(
            id: "PAYPAL_USER_1",
            name: "Alex Chen", 
            email: "sb-npqyc44065909@business.example.com",
            address: "0x9f93EebD463d4B7c991986a082d974E77b5a02Dc",
            privateKey: "0x15953296e322c945eaa0c215f8740fcdb1cb18231d19e477efa91ae4310becdf"
        ),
        DemoUser(
            id: "PAYPAL_USER_2", 
            name: "Jordan Smith",
            email: "sb-ks474h44072658@personal.example.com", 
            address: "0xa999F0CB16b55516BD82fd77Dc19f495b41f0770",
            privateKey: "0xdcf06adcd2d997d57bfb5275ae3493d8afdb606d7c51c66eafbb7c5abff04d2c"
        )
    ]
    
    // MARK: - PayPal Colors
    static let paypalBlue = "#0070ba"
    static let paypalDarkBlue = "#003087"
    static let paypalLightBlue = "#009cde"
    static let paypalYellow = "#ffc439"
    static let paypalGray = "#f7f7f7"
}

// MARK: - Demo User Model
struct DemoUser: Identifiable, Equatable {
    let id: String
    let name: String
    let email: String
    let address: String
    let privateKey: String
} 