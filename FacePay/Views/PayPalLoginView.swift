//
//  PayPalLoginView.swift
//  FacePay
//
//  Created by FacePay Team
//

import SwiftUI

struct PayPalLoginView: View {
    
    // MARK: - Properties
    @EnvironmentObject var paypalService: PayPalService
    @StateObject private var supabaseService = SupabaseService()
    @State private var email = ""
    @State private var password = ""
    @State private var showingQuickLogin = false
    
    let onLoginSuccess: (PayPalUserProfile, SupabaseUser) -> Void
    
    // MARK: - PayPal Colors
    private let paypalBlue = Color(hex: "#0070ba")
    private let paypalDarkBlue = Color(hex: "#003087")
    private let paypalLightBlue = Color(hex: "#009cde")
    private let paypalYellow = Color(hex: "#ffc439")
    private let paypalGray = Color(hex: "#f7f7f7")
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [paypalBlue, paypalDarkBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 60)
                    
                    // PayPal Logo
                    PayPalLogoView()
                    
                    // Welcome Text
                    VStack(spacing: 12) {
                        Text("Welcome to FacePay")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Sign in with your PayPal account to get started")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                    }
                    
                    // Login Form
                    VStack(spacing: 20) {
                        LoginFormView()
                        
                        // Demo Users Quick Login
                        VStack(spacing: 12) {
                            HStack {
                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(height: 1)
                                
                                Text("Demo Users")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(height: 1)
                            }
                            
                            DemoUsersView()
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
        }
        .alert("Login Error", isPresented: .constant(paypalService.errorMessage != nil)) {
            Button("OK") {
                paypalService.errorMessage = nil
            }
        } message: {
            Text(paypalService.errorMessage ?? "")
        }
    }
    
    // MARK: - Login Form
    @ViewBuilder
    private func LoginFormView() -> some View {
        VStack(spacing: 16) {
            // Email Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                TextField("Enter your PayPal email", text: $email)
                    .textFieldStyle(PayPalTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                SecureField("Enter your password", text: $password)
                    .textFieldStyle(PayPalTextFieldStyle())
            }
            
            // Login Button
            Button(action: {
                Task {
                    await handleLogin()
                }
            }) {
                HStack {
                    if paypalService.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: paypalDarkBlue))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "person.circle.fill")
                        Text("Sign in with PayPal")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .foregroundColor(paypalBlue)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(paypalService.isLoading || email.isEmpty || password.isEmpty)
        }
    }
    
    // MARK: - Demo Users
    @ViewBuilder
    private func DemoUsersView() -> some View {
        VStack(spacing: 8) {
            DemoUserButton(
                title: "PayPal User 1",
                subtitle: "Business Account",
                email: "sb-npqyc44065909@business.example.com",
                password: "2y?=B[@Y"
            )
            
            DemoUserButton(
                title: "PayPal User 2", 
                subtitle: "Personal Account",
                email: "sb-ks474h44072658@personal.example.com",
                password: "^qY5Q<xV"
            )
        }
    }
    
    @ViewBuilder
    private func DemoUserButton(title: String, subtitle: String, email: String, password: String) -> some View {
        Button(action: {
            self.email = email
            self.password = password
            Task {
                await handleLogin()
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right.circle")
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding()
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Handle Login
    private func handleLogin() async {
        let success = await paypalService.login(email: email, password: password)
        
        if success, let paypalUser = paypalService.currentUser {
            // Create user in Supabase
            do {
                let walletAddress = paypalService.getCurrentUserWalletAddress() ?? ""
                let supabaseUser = try await supabaseService.createUser(
                    paypalId: paypalUser.sub,
                    walletAddress: walletAddress,
                    name: paypalUser.name,
                    email: paypalUser.email,
                    address: paypalUser.address
                )
                
                await MainActor.run {
                    onLoginSuccess(paypalUser, supabaseUser)
                }
                
            } catch {
                print("❌ User creation error: \(error)")
                print("Error type: \(type(of: error))")
                
                await MainActor.run {
                    if error.localizedDescription.contains("couldn't be read") || error.localizedDescription.contains("JSON") {
                        paypalService.errorMessage = "Data format issue. Please try again."
                    } else {
                        paypalService.errorMessage = "Failed to create user account: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

// MARK: - PayPal Logo
struct PayPalLogoView: View {
    var body: some View {
        HStack(spacing: 4) {
            Text("Pay")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Pal")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "#ffc439"))
        }
    }
}

// MARK: - PayPal Text Field Style
struct PayPalTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .foregroundColor(.black)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
#Preview {
    PayPalLoginView { paypalUser, supabaseUser in
        print("Login successful: \(paypalUser.name)")
    }
} 