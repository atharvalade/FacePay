//
//  SupabaseService.swift
//  FacePay
//
//  Created by FacePay Team
//

import Foundation

class SupabaseService: ObservableObject {
    
    // MARK: - Properties
    private let supabaseURL = AppConfig.supabaseURL
    private let supabaseKey = AppConfig.supabaseAnonKey
    
    // MARK: - Headers
    private var headers: [String: String] {
        return [
            "apikey": supabaseKey,
            "Authorization": "Bearer \(supabaseKey)",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        ]
    }
    
    // MARK: - User Operations
    
    /// Create or update user in Supabase
    func createUser(paypalId: String, walletAddress: String, name: String, email: String, address: PayPalAddress? = nil) async throws -> SupabaseUser {
        let url = URL(string: "\(supabaseURL)/rest/v1/users")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Create user data with proper null handling
        var userData: [String: Any] = [
            "paypal_id": paypalId,
            "wallet_address": walletAddress,
            "name": name,
            "email": email,
            "is_merchant": false
        ]
        
        // Only add address fields if they exist
        if let streetAddress = address?.streetAddress {
            userData["address_line1"] = streetAddress
        }
        if let city = address?.locality {
            userData["city"] = city
        }
        if let state = address?.region {
            userData["state"] = state
        }
        if let country = address?.country {
            userData["country"] = country
        }
        if let postalCode = address?.postalCode {
            userData["postal_code"] = postalCode
        }
        
        print("📤 Sending user data: \(userData)")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: userData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SupabaseError.invalidResponse
        }
        
        if httpResponse.statusCode == 409 {
            // User already exists, fetch existing user
            return try await getUser(paypalId: paypalId)
        }
        
        guard httpResponse.statusCode == 201 else {
            print("❌ Supabase error: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            throw SupabaseError.createUserFailed
        }
        
        // Add debugging for the response
        if let responseString = String(data: data, encoding: .utf8) {
            print("✅ Supabase response: \(responseString)")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .supabase
        
        do {
            let users = try decoder.decode([SupabaseUser].self, from: data)
            guard let user = users.first else {
                throw SupabaseError.userNotFound
            }
            
            print("✅ Created user in Supabase: \(user.name)")
            return user
        } catch let decodingError {
            print("❌ JSON Decoding Error: \(decodingError)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response data: \(responseString)")
            }
            throw SupabaseError.createUserFailed
        }
    }
    
    /// Get user by PayPal ID
    func getUser(paypalId: String) async throws -> SupabaseUser {
        let url = URL(string: "\(supabaseURL)/rest/v1/users?paypal_id=eq.\(paypalId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.getUserFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .supabase
        
        let users = try decoder.decode([SupabaseUser].self, from: data)
        guard let user = users.first else {
            throw SupabaseError.userNotFound
        }
        
        return user
    }
    
    /// Get user by wallet address
    func getUser(walletAddress: String) async throws -> SupabaseUser {
        let url = URL(string: "\(supabaseURL)/rest/v1/users?wallet_address=eq.\(walletAddress)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.getUserFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .supabase
        let users = try decoder.decode([SupabaseUser].self, from: data)
        guard let user = users.first else {
            throw SupabaseError.userNotFound
        }
        
        return user
    }
    
    // MARK: - Face Embedding Operations
    
    /// Save face embedding to Supabase
    func saveFaceEmbedding(userId: UUID, paypalId: String, walletAddress: String, embedding: [Float]) async throws -> SupabaseFaceEmbedding {
        let url = URL(string: "\(supabaseURL)/rest/v1/face_embeddings")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let embeddingData: [String: Any] = [
            "user_id": userId.uuidString,
            "paypal_id": paypalId,
            "wallet_address": walletAddress,
            "embedding": embedding.map { Double($0) }, // Convert Float to Double
            "confidence_score": 0.0,
            "image_count": 3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: embeddingData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            print("❌ Save embedding failed: \(response)")
            throw SupabaseError.saveEmbeddingFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .supabase
        let embeddings = try decoder.decode([SupabaseFaceEmbedding].self, from: data)
        guard let embedding = embeddings.first else {
            throw SupabaseError.embeddingNotFound
        }
        
        print("✅ Saved face embedding to Supabase")
        return embedding
    }
    
    /// Get all face embeddings (for merchant recognition)
    func getAllFaceEmbeddings() async throws -> [SupabaseFaceEmbedding] {
        let url = URL(string: "\(supabaseURL)/rest/v1/face_embeddings")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.getEmbeddingsFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .supabase
        let embeddings = try decoder.decode([SupabaseFaceEmbedding].self, from: data)
        print("✅ Retrieved \(embeddings.count) face embeddings from Supabase")
        return embeddings
    }
    
    /// Get face embedding for specific user
    func getFaceEmbedding(paypalId: String) async throws -> SupabaseFaceEmbedding {
        let url = URL(string: "\(supabaseURL)/rest/v1/face_embeddings?paypal_id=eq.\(paypalId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw SupabaseError.getEmbeddingsFailed
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .supabase
        let embeddings = try decoder.decode([SupabaseFaceEmbedding].self, from: data)
        guard let embedding = embeddings.first else {
            throw SupabaseError.embeddingNotFound
        }
        
        return embedding
    }
    
    /// Check if user has face embedding
    func hasFaceEmbedding(paypalId: String) async -> Bool {
        do {
            _ = try await getFaceEmbedding(paypalId: paypalId)
            return true
        } catch {
            return false
        }
    }
    
    /// Delete face embedding
    func deleteFaceEmbedding(paypalId: String) async throws {
        let url = URL(string: "\(supabaseURL)/rest/v1/face_embeddings?paypal_id=eq.\(paypalId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 else {
            throw SupabaseError.deleteEmbeddingFailed
        }
        
        print("✅ Deleted face embedding from Supabase")
    }
}

// MARK: - Supabase Errors
enum SupabaseError: LocalizedError {
    case invalidResponse
    case createUserFailed
    case getUserFailed
    case userNotFound
    case saveEmbeddingFailed
    case getEmbeddingsFailed
    case embeddingNotFound
    case deleteEmbeddingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .createUserFailed:
            return "Failed to create user"
        case .getUserFailed:
            return "Failed to get user"
        case .userNotFound:
            return "User not found"
        case .saveEmbeddingFailed:
            return "Failed to save face embedding"
        case .getEmbeddingsFailed:
            return "Failed to get face embeddings"
        case .embeddingNotFound:
            return "Face embedding not found"
        case .deleteEmbeddingFailed:
            return "Failed to delete face embedding"
        }
    }
} 