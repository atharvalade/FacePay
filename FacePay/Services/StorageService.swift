//
//  StorageService.swift
//  FacePay
//
//  Created by FacePay Team
//

import Foundation

class StorageService: ObservableObject {
    
    // MARK: - Properties
    @Published var embeddingsStorage = FaceEmbeddingsStorage()
    private let fileManager = FileManager.default
    
    init() {
        loadEmbeddings()
    }
    
    // MARK: - File Path
    private var embeddingsFileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent(AppConfig.embeddingsFileName)
    }
    
    // MARK: - Load Embeddings
    func loadEmbeddings() {
        do {
            let data = try Data(contentsOf: embeddingsFileURL)
            embeddingsStorage = try JSONDecoder().decode(FaceEmbeddingsStorage.self, from: data)
            print("✅ Loaded \(embeddingsStorage.embeddings.count) face embeddings")
        } catch {
            if !fileManager.fileExists(atPath: embeddingsFileURL.path) {
                print("📝 No existing embeddings file found. Starting fresh.")
            } else {
                print("❌ Failed to load embeddings: \(error)")
            }
            embeddingsStorage = FaceEmbeddingsStorage()
        }
    }
    
    // MARK: - Save Embeddings
    func saveEmbeddings() {
        do {
            let data = try JSONEncoder().encode(embeddingsStorage)
            try data.write(to: embeddingsFileURL)
            print("✅ Saved \(embeddingsStorage.embeddings.count) face embeddings")
        } catch {
            print("❌ Failed to save embeddings: \(error)")
        }
    }
    
    // MARK: - Add New Embedding
    func addFaceEmbedding(walletAddress: String, embedding: [Float], userName: String) {
        let faceEmbedding = FaceEmbedding(
            walletAddress: walletAddress,
            embedding: embedding,
            userName: userName
        )
        
        embeddingsStorage.addEmbedding(faceEmbedding)
        saveEmbeddings()
        
        print("✅ Added face embedding for \(userName) (\(walletAddress))")
    }
    
    // MARK: - Remove Embedding
    func removeFaceEmbedding(for address: String) {
        embeddingsStorage.removeEmbedding(for: address)
        saveEmbeddings()
        
        print("🗑️ Removed face embedding for \(address)")
    }
    
    // MARK: - Get All Embeddings
    func getAllEmbeddings() -> [FaceEmbedding] {
        return embeddingsStorage.getAllEmbeddings()
    }
    
    // MARK: - Check if User is Registered
    func isUserRegistered(address: String) -> Bool {
        return embeddingsStorage.getEmbedding(for: address) != nil
    }
    
    // MARK: - Get Embedding for Address
    func getEmbedding(for address: String) -> FaceEmbedding? {
        return embeddingsStorage.getEmbedding(for: address)
    }
    
    // MARK: - Clear All Data (for demo reset)
    func clearAllEmbeddings() {
        embeddingsStorage = FaceEmbeddingsStorage()
        saveEmbeddings()
        print("🗑️ Cleared all face embeddings")
    }
    
    // MARK: - Get Storage Stats
    func getStorageStats() -> (count: Int, fileSizeKB: Double) {
        let count = embeddingsStorage.embeddings.count
        
        var fileSizeKB: Double = 0
        if let attributes = try? fileManager.attributesOfItem(atPath: embeddingsFileURL.path),
           let fileSize = attributes[.size] as? Int64 {
            fileSizeKB = Double(fileSize) / 1024.0
        }
        
        return (count: count, fileSizeKB: fileSizeKB)
    }
    
    // MARK: - Demo Setup
    func setupDemoData() {
        // This can be used to pre-populate demo data if needed
        print("📊 Demo data setup - embeddings ready for registration")
    }
} 