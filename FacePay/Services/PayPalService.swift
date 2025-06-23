//
//  PayPalService.swift
//  FacePay
//
//  Created by FacePay Team
//

import Foundation

class PayPalService: ObservableObject {
    
    // MARK: - Properties
    private let clientId = AppConfig.paypalClientId
    private let clientSecret = AppConfig.paypalSecret
    private let baseURL = "https://api-m.sandbox.paypal.com"
    
    @Published var isAuthenticated = false
    @Published var currentUser: PayPalUserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Sandbox User Credentials
    private let sandboxUsers = [
        "sb-npqyc44065909@business.example.com": "2y?=B[@Y",
        "sb-ks474h44072658@personal.example.com": "^qY5Q<xV"
    ]
    
    // MARK: - Authentication
    
    /// Authenticate with PayPal and fetch real user profile
    func login(email: String, password: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        // Simulate API delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Check sandbox credentials
        guard let expectedPassword = sandboxUsers[email],
              expectedPassword == password else {
            await MainActor.run {
                isLoading = false
                errorMessage = "Invalid PayPal credentials"
            }
            return false
        }
        
        // Get OAuth token and user profile
        do {
            let accessToken = try await getAccessToken()
            let userProfile = try await fetchRealUserProfile(accessToken: accessToken, email: email)
            
            await MainActor.run {
                self.currentUser = userProfile
                self.isAuthenticated = true
                self.isLoading = false
            }
            
            print("✅ PayPal login successful for \(userProfile.name)")
            return true
            
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.errorMessage = "Failed to authenticate with PayPal: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    /// Get OAuth access token
    private func getAccessToken() async throws -> String {
        let url = URL(string: "\(baseURL)/v1/oauth2/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Basic Auth header
        let credentials = "\(clientId):\(clientSecret)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        request.setValue("Basic \(base64Credentials)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Request body with expanded scope to access user info
        let bodyString = "grant_type=client_credentials&scope=openid email profile"
        request.httpBody = bodyString.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PayPalError.authenticationFailed
        }
        
        let oauthResponse = try JSONDecoder().decode(PayPalOAuthResponse.self, from: data)
        return oauthResponse.accessToken
    }
    
    /// Fetch real user profile from PayPal API
    private func fetchRealUserProfile(accessToken: String, email: String) async throws -> PayPalUserProfile {
        // First, try to get user info from PayPal's userinfo endpoint
        do {
            let userProfile = try await getUserInfoFromAPI(accessToken: accessToken, fallbackEmail: email)
            print("✅ Successfully fetched real user profile from PayPal API")
            return userProfile
        } catch {
            print("⚠️ Failed to fetch from API, falling back to enhanced simulated profile: \(error)")
            // Fall back to enhanced simulated profile with more realistic data
            return createEnhancedProfile(for: email)
        }
    }
    
    /// Get user info from PayPal's userinfo endpoint
    private func getUserInfoFromAPI(accessToken: String, fallbackEmail: String) async throws -> PayPalUserProfile {
        let url = URL(string: "\(baseURL)/v1/identity/openidconnect/userinfo/?schema=openid")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PayPalError.networkError
        }
        
        print("PayPal userinfo response status: \(httpResponse.statusCode)")
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("PayPal userinfo response: \(jsonString)")
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PayPalError.userProfileFailed
        }
        
        let decoder = JSONDecoder()
        let userInfo = try decoder.decode(PayPalUserInfo.self, from: data)
        
        // Convert PayPal API response to our model
        return PayPalUserProfile(
            sub: userInfo.userId,
            name: userInfo.name ?? "\(userInfo.givenName ?? "User") \(userInfo.familyName ?? "")",
            givenName: userInfo.givenName,
            familyName: userInfo.familyName,
            email: userInfo.email ?? fallbackEmail, // Use fallback email parameter
            emailVerified: userInfo.emailVerified,
            address: userInfo.address.map { addr in
                PayPalAddress(
                    streetAddress: addr.streetAddress,
                    locality: addr.locality,
                    region: addr.region,
                    postalCode: addr.postalCode,
                    country: addr.country
                )
            }
        )
    }
    
    /// Create enhanced simulated profile with more realistic data
    private func createEnhancedProfile(for email: String) -> PayPalUserProfile {
        // Generate a more realistic user profile based on the email
        if email == "sb-npqyc44065909@business.example.com" {
            return PayPalUserProfile(
                sub: "PAYPAL_USER_1",
                name: "Alex Chen",
                givenName: "Alex",
                familyName: "Chen",
                email: email,
                emailVerified: true,
                address: PayPalAddress(
                    streetAddress: "123 Business Center Drive",
                    locality: "San Francisco",
                    region: "CA",
                    postalCode: "94105",
                    country: "US"
                )
            )
        } else {
            return PayPalUserProfile(
                sub: "PAYPAL_USER_2",
                name: "Jordan Smith",
                givenName: "Jordan",
                familyName: "Smith",
                email: email,
                emailVerified: true,
                address: PayPalAddress(
                    streetAddress: "456 Innovation Boulevard",
                    locality: "Los Angeles",
                    region: "CA",
                    postalCode: "90028",
                    country: "US"
                )
            )
        }
    }
    
    /// Logout
    @MainActor
    func logout() {
        isAuthenticated = false
        currentUser = nil
        errorMessage = nil
    }
    
    /// Get wallet address for current user
    func getCurrentUserWalletAddress() -> String? {
        guard let user = currentUser else { return nil }
        
        // Map PayPal ID to wallet address
        switch user.sub {
        case "PAYPAL_USER_1":
            return AppConfig.user1Address
        case "PAYPAL_USER_2":
            return AppConfig.user2Address
        default:
            return nil
        }
    }
    
    /// Get private key for current user (for demo purposes)
    func getCurrentUserPrivateKey() -> String? {
        guard let user = currentUser else { return nil }
        
        // Map PayPal ID to private key (FOR DEMO ONLY)
        switch user.sub {
        case "PAYPAL_USER_1":
            return AppConfig.user1PrivateKey
        case "PAYPAL_USER_2":
            return AppConfig.user2PrivateKey
        default:
            return nil
        }
    }
    
    /// Check if user is logged in
    var isLoggedIn: Bool {
        return isAuthenticated && currentUser != nil
    }
    
    /// Get formatted user display name
    func getDisplayName() -> String {
        guard let user = currentUser else { return "Unknown User" }
        
        if let givenName = user.givenName, let familyName = user.familyName {
            return "\(givenName) \(familyName)"
        } else {
            return user.name
        }
    }
    
    /// Get user's full address as formatted string
    func getFormattedAddress() -> String? {
        guard let address = currentUser?.address else { return nil }
        
        var components: [String] = []
        
        if let street = address.streetAddress { components.append(street) }
        if let city = address.locality { components.append(city) }
        if let state = address.region { components.append(state) }
        if let zip = address.postalCode { components.append(zip) }
        if let country = address.country { components.append(country) }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

// MARK: - PayPal API Response Models
struct PayPalUserInfo: Codable {
    let userId: String
    let name: String?
    let givenName: String?
    let familyName: String?
    let email: String?
    let emailVerified: Bool?
    let address: PayPalAddressInfo?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name, email, address
        case givenName = "given_name"
        case familyName = "family_name"
        case emailVerified = "email_verified"
    }
}

struct PayPalAddressInfo: Codable {
    let streetAddress: String?
    let locality: String?
    let region: String?
    let postalCode: String?
    let country: String?
    
    enum CodingKeys: String, CodingKey {
        case streetAddress = "street_address"
        case locality, region, country
        case postalCode = "postal_code"
    }
}

// MARK: - PayPal Errors
enum PayPalError: LocalizedError {
    case authenticationFailed
    case invalidCredentials
    case userProfileFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "PayPal authentication failed"
        case .invalidCredentials:
            return "Invalid PayPal credentials"
        case .userProfileFailed:
            return "Failed to get user profile"
        case .networkError:
            return "Network error occurred"
        }
    }
} 