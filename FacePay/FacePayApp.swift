//
//  FacePayApp.swift
//  FacePay
//
//  Created by Atharva Lade on 6/22/25.
//

import SwiftUI

@main
struct FacePayApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var paypalService = PayPalService()
    @State private var showingSplash = true
    @State private var currentUser: SupabaseUser?
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showingSplash {
                    SplashScreenView()
                        .transition(.asymmetric(
                            insertion: .identity,
                            removal: .scale.combined(with: .opacity)
                        ))
                } else if !paypalService.isLoggedIn || currentUser == nil {
                    PayPalLoginView { paypalUser, supabaseUser in
                        currentUser = supabaseUser
                        appState.setupWithPayPalUser(paypalUser: paypalUser, supabaseUser: supabaseUser)
                    }
                    .transition(.move(edge: .leading))
                } else {
                    ContentView(appState: appState)
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.easeInOut(duration: 1.0), value: showingSplash)
            .animation(.easeInOut(duration: 0.6), value: paypalService.isLoggedIn)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showingSplash = false
                }
            }
            .environmentObject(paypalService)
        }
    }
}

// MARK: - Splash Screen
struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showingTagline = false
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                colors: [
                    .blue.opacity(0.8),
                    .purple.opacity(0.6),
                    .green.opacity(0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Main Logo
                FacePayLogo(size: .hero)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                // Tagline
                VStack(spacing: 8) {
                    Text("Instant Face-Based Payments")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .opacity(showingTagline ? 1.0 : 0.0)
                    
                    Text("Powered by PYUSD & Ethereum")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(showingTagline ? 1.0 : 0.0)
                }
                
                Spacer()
                
                // Loading Indicator
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    Text("Loading FacePay...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(showingTagline ? 1.0 : 0.0)
            }
            .padding(40)
        }
        .onAppear {
            withAnimation(.spring(duration: 1.0)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    showingTagline = true
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SplashScreenView()
}
