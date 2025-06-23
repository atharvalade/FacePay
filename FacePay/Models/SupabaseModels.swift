//
//  SupabaseModels.swift
//  FacePay
//
//  Created by FacePay Team
//

import Foundation

// MARK: - Supabase User Model
struct SupabaseUser: Codable, Identifiable {
    let id: UUID?
    let paypalId: String
    let walletAddress: String
    let name: String
    let email: String
    let phone: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let state: String?
    let country: String?
    let postalCode: String?
    let isMerchant: Bool
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case paypalId = "paypal_id"
        case walletAddress = "wallet_address"
        case name, email, phone
        case addressLine1 = "address_line1"
        case addressLine2 = "address_line2"
        case city, state, country
        case postalCode = "postal_code"
        case isMerchant = "is_merchant"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Supabase Face Embedding Model
struct SupabaseFaceEmbedding: Codable, Identifiable {
    let id: UUID?
    let userId: UUID?
    let paypalId: String
    let walletAddress: String
    let embedding: [Double]
    let confidenceScore: Double?
    let imageCount: Int?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case paypalId = "paypal_id"
        case walletAddress = "wallet_address"
        case embedding
        case confidenceScore = "confidence_score"
        case imageCount = "image_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - PayPal User Profile Response
struct PayPalUserProfile: Codable {
    let sub: String // PayPal user ID
    let name: String
    let givenName: String?
    let familyName: String?
    let email: String
    let emailVerified: Bool?
    let address: PayPalAddress?
    
    enum CodingKeys: String, CodingKey {
        case sub, name, email, address
        case givenName = "given_name"
        case familyName = "family_name"  
        case emailVerified = "email_verified"
    }
}

// MARK: - PayPal Address
struct PayPalAddress: Codable {
    let streetAddress: String?
    let locality: String? // city
    let region: String? // state
    let postalCode: String?
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case streetAddress = "street_address"
        case locality, region, country
        case postalCode = "postal_code"
    }
}

// MARK: - PayPal OAuth Response
struct PayPalOAuthResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case scope
    }
} 