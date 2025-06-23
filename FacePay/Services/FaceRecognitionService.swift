//
//  FaceRecognitionService.swift
//  FacePay
//
//  Created by FacePay Team
//

import Foundation
import Vision
import UIKit
import CoreImage

class FaceRecognitionService: ObservableObject {
    
    // MARK: - Properties
    @Published var isProcessing = false
    @Published var errorMessage: String?
    
    // MARK: - Face Detection and Embedding Generation
    func generateFaceEmbedding(from image: UIImage) async -> [Float]? {
        guard let cgImage = image.cgImage else {
            await MainActor.run {
                errorMessage = "Failed to convert image"
            }
            return nil
        }
        
        await MainActor.run {
            isProcessing = true
        }
        
        do {
            let embedding = try await performFaceEmbeddingGeneration(cgImage: cgImage)
            await MainActor.run {
                isProcessing = false
            }
            return embedding
        } catch {
            await MainActor.run {
                isProcessing = false
                errorMessage = "Face detection failed: \(error.localizedDescription)"
            }
            return nil
        }
    }
    
    private func performFaceEmbeddingGeneration(cgImage: CGImage) async throws -> [Float] {
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let observations = request.results as? [VNFaceObservation],
                      let faceObservation = observations.first else {
                    continuation.resume(throwing: FaceRecognitionError.noFaceDetected)
                    return
                }
                
                // Convert face observation to embedding (simplified version)
                let embedding = self.convertFaceObservationToEmbedding(faceObservation, imageSize: CGSize(width: cgImage.width, height: cgImage.height))
                continuation.resume(returning: embedding)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    private func convertFaceObservationToEmbedding(_ faceObservation: VNFaceObservation, imageSize: CGSize) -> [Float] {
        // Create a simplified embedding from face observation properties
        // This is a basic implementation - in production you'd want more sophisticated features
        var embedding: [Float] = []
        
        // Normalize bounding box coordinates
        let boundingBox = faceObservation.boundingBox
        embedding.append(Float(boundingBox.origin.x))
        embedding.append(Float(boundingBox.origin.y))
        embedding.append(Float(boundingBox.width))
        embedding.append(Float(boundingBox.height))
        
        // Add confidence
        embedding.append(faceObservation.confidence)
        
        // Add roll and yaw if available
        if let roll = faceObservation.roll {
            embedding.append(Float(truncating: roll))
        } else {
            embedding.append(0.0)
        }
        
        if let yaw = faceObservation.yaw {
            embedding.append(Float(truncating: yaw))
        } else {
            embedding.append(0.0)
        }
        
        // Create additional synthetic features for better matching
        // Add some computed features based on face geometry
        let centerX = Float(boundingBox.origin.x + boundingBox.width / 2)
        let centerY = Float(boundingBox.origin.y + boundingBox.height / 2)
        let aspectRatio = Float(boundingBox.width / boundingBox.height)
        
        embedding.append(centerX)
        embedding.append(centerY)
        embedding.append(aspectRatio)
        
        // Pad to consistent size (128 dimensions)
        while embedding.count < 128 {
            embedding.append(Float.random(in: -0.1...0.1)) // Small random values
        }
        
        return Array(embedding.prefix(128)) // Ensure exactly 128 dimensions
    }
    
    // MARK: - Face Matching
    func findBestMatch(for queryEmbedding: [Float], in embeddings: [FaceEmbedding]) -> FaceMatchResult? {
        var bestMatch: FaceMatchResult?
        var bestSimilarity: Float = -1.0
        
        for storedEmbedding in embeddings {
            let similarity = calculateCosineSimilarity(queryEmbedding, storedEmbedding.embedding)
            
            if similarity > bestSimilarity {
                bestSimilarity = similarity
                bestMatch = FaceMatchResult(
                    walletAddress: storedEmbedding.walletAddress,
                    userName: storedEmbedding.userName,
                    confidence: similarity
                )
            }
        }
        
        return bestMatch
    }
    
    private func calculateCosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
        guard a.count == b.count else { return 0.0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        guard magnitudeA > 0 && magnitudeB > 0 else { return 0.0 }
        
        return dotProduct / (magnitudeA * magnitudeB)
    }
    
    // MARK: - Multiple Frame Processing (for registration)
    func generateAverageEmbedding(from images: [UIImage]) async -> [Float]? {
        var embeddings: [[Float]] = []
        
        for image in images {
            if let embedding = await generateFaceEmbedding(from: image) {
                embeddings.append(embedding)
            }
        }
        
        guard !embeddings.isEmpty else { return nil }
        
        // Calculate average embedding
        let embeddingSize = embeddings[0].count
        var averageEmbedding = Array(repeating: Float(0), count: embeddingSize)
        
        for embedding in embeddings {
            for i in 0..<embeddingSize {
                averageEmbedding[i] += embedding[i]
            }
        }
        
        let count = Float(embeddings.count)
        for i in 0..<embeddingSize {
            averageEmbedding[i] /= count
        }
        
        return averageEmbedding
    }
}

// MARK: - Face Recognition Errors
enum FaceRecognitionError: LocalizedError {
    case noFaceDetected
    case multipleFacesDetected
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .noFaceDetected:
            return "No face detected in the image"
        case .multipleFacesDetected:
            return "Multiple faces detected. Please ensure only one face is visible"
        case .processingFailed:
            return "Face processing failed"
        }
    }
} 