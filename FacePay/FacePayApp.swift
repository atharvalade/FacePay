//
//  FacePayApp.swift
//  FacePay
//
//  Created by Atharva Lade on 6/22/25.
//

import SwiftUI

@main
struct FacePayApp: App {
    @State private var showingSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showingSplash {
                    SplashScreenView()
                        .transition(.asymmetric(
                            insertion: .identity,
                            removal: .scale.combined(with: .opacity)
                        ))
                } else {
                    ContentView()
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .identity
                        ))
                }
            }
            .animation(.easeInOut(duration: 1.0), value: showingSplash)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    showingSplash = false
                }
            }
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
