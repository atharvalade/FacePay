import Foundation

extension JSONDecoder.DateDecodingStrategy {
    static let supabase = custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)

        let formatter = ISO8601DateFormatter()
        
        // Attempt to decode with fractional seconds
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Attempt to decode without fractional seconds as a fallback
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: dateString) {
            return date
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(dateString) is not a valid ISO-8601 date")
    }
} 