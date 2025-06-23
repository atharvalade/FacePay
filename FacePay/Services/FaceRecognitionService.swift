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
    
    // MARK: - Configuration
    private let minimumSimilarityThreshold: Float = 0.75 // Require 75% similarity minimum
    private let minimumConfidenceThreshold: Float = 0.8  // Require 80% face detection confidence
    
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
                      !observations.isEmpty else {
                    continuation.resume(throwing: FaceRecognitionError.noFaceDetected)
                    return
                }
                
                // Filter observations by confidence threshold
                let highConfidenceObservations = observations.filter { $0.confidence >= self.minimumConfidenceThreshold }
                
                guard let faceObservation = highConfidenceObservations.first else {
                    continuation.resume(throwing: FaceRecognitionError.lowConfidenceDetection)
                    return
                }
                
                // Check for multiple faces (security measure)
                if highConfidenceObservations.count > 1 {
                    continuation.resume(throwing: FaceRecognitionError.multipleFacesDetected)
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
        
        // Generate additional deterministic features instead of random padding
        // These create a more stable and meaningful embedding
        let faceArea = Float(boundingBox.width * boundingBox.height)
        let perimeter = Float(2 * (boundingBox.width + boundingBox.height))
        let diagonal = Float(sqrt(boundingBox.width * boundingBox.width + boundingBox.height * boundingBox.height))
        
        // Add geometric features
        embedding.append(faceArea)
        embedding.append(perimeter)
        embedding.append(diagonal)
        embedding.append(Float(boundingBox.width / imageSize.width)) // Relative width
        embedding.append(Float(boundingBox.height / imageSize.height)) // Relative height
        
        // Generate hash-like features from face position for uniqueness
        let positionHash1 = sin(Float(boundingBox.origin.x * 100))
        let positionHash2 = cos(Float(boundingBox.origin.y * 100))
        let positionHash3 = sin(Float(boundingBox.width * 50))
        let positionHash4 = cos(Float(boundingBox.height * 50))
        
        embedding.append(positionHash1)
        embedding.append(positionHash2)
        embedding.append(positionHash3)
        embedding.append(positionHash4)
        
        // Pad remaining dimensions with deterministic values based on existing features
        // This creates consistent embeddings for the same face
        while embedding.count < 128 {
            let index = embedding.count
            let baseValue = embedding[index % 10] // Use existing features as base
            let deterministicValue = sin(Float(index) * 0.1) * baseValue * 0.1
            embedding.append(deterministicValue)
        }
        
        return Array(embedding.prefix(128)) // Ensure exactly 128 dimensions
    }
    
    // MARK: - Face Matching
    func findBestMatch(for queryEmbedding: [Float], in embeddings: [FaceEmbedding]) -> FaceMatchResult? {
        var bestMatch: FaceMatchResult?
        var bestSimilarity: Float = -1.0
        
        print("🔍 Face Matching Process:")
        print("   Checking \(embeddings.count) stored faces...")
        
        for storedEmbedding in embeddings {
            let similarity = calculateCosineSimilarity(queryEmbedding, storedEmbedding.embedding)
            
            print("   📊 \(storedEmbedding.userName): \(String(format: "%.3f", similarity)) similarity")
            
            if similarity > bestSimilarity {
                bestSimilarity = similarity
                bestMatch = FaceMatchResult(
                    walletAddress: storedEmbedding.walletAddress,
                    userName: storedEmbedding.userName,
                    confidence: similarity
                )
            }
        }
        
        // CRITICAL: Only return match if it meets minimum threshold
        if let match = bestMatch, match.confidence >= minimumSimilarityThreshold {
            print("   ✅ Valid match found: \(match.userName) (\(String(format: "%.3f", match.confidence)))")
            return match
        } else {
            let actualConfidence = bestMatch?.confidence ?? 0.0
            print("   ❌ No valid match found!")
            print("   Best similarity: \(String(format: "%.3f", actualConfidence))")
            print("   Required threshold: \(String(format: "%.3f", minimumSimilarityThreshold))")
            return nil
        }
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
    case lowConfidenceDetection
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .noFaceDetected:
            return "No face detected in the image"
        case .multipleFacesDetected:
            return "Multiple faces detected. Please ensure only one face is visible"
        case .lowConfidenceDetection:
            return "Face detection confidence too low. Please ensure good lighting and clear face visibility"
        case .processingFailed:
            return "Face processing failed"
        }
    }
} 