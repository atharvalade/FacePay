//
//  FaceEmbedding.swift
//  FacePay
//
//  Created by FacePay Team
//

import Foundation

// MARK: - Face Embedding Data Structure
struct FaceEmbedding: Codable {
    let walletAddress: String
    let embedding: [Float]
    let userName: String
    let registrationDate: Date
    
    init(walletAddress: String, embedding: [Float], userName: String) {
        self.walletAddress = walletAddress
        self.embedding = embedding
        self.userName = userName
        self.registrationDate = Date()
    }
    
    init(walletAddress: String, embedding: [Float], userName: String, registrationDate: Date) {
        self.walletAddress = walletAddress
        self.embedding = embedding
        self.userName = userName
        self.registrationDate = registrationDate
    }
}

// MARK: - Face Embeddings Storage
struct FaceEmbeddingsStorage: Codable {
    var embeddings: [String: FaceEmbedding] = [:]
    
    mutating func addEmbedding(_ embedding: FaceEmbedding) {
        embeddings[embedding.walletAddress] = embedding
    }
    
    func getEmbedding(for address: String) -> FaceEmbedding? {
        return embeddings[address]
    }
    
    func getAllEmbeddings() -> [FaceEmbedding] {
        return Array(embeddings.values)
    }
    
    mutating func removeEmbedding(for address: String) {
        embeddings.removeValue(forKey: address)
    }
}

// MARK: - Face Match Result
struct FaceMatchResult {
    let walletAddress: String
    let userName: String
    let confidence: Float
    let isMatch: Bool
    
    init(walletAddress: String, userName: String, confidence: Float) {
        self.walletAddress = walletAddress
        self.userName = userName
        self.confidence = confidence
        self.isMatch = confidence >= AppConfig.faceMatchThreshold
    }
} 