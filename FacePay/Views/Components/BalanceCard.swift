//
//  BalanceCard.swift
//  FacePay
//
//  Created by FacePay Team
//

import SwiftUI

struct BalanceCard: View {
    let balance: Double
    let isLoading: Bool
    let title: String
    let onRefresh: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("PYUSD Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                }
                .disabled(isLoading)
            }
            
            // Balance Display
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading...")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("$")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.2f", balance))
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .contentTransition(.numericText(value: balance))
                    
                    Text("PYUSD")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                }
            }
            
            // PYUSD Logo/Info
            HStack {
                Image(systemName: "p.circle.fill")
                    .foregroundColor(.blue)
                
                Text("PayPal USD")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Network indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    
                    Text("Sepolia")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .onChange(of: isLoading) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.3)) {
                    isAnimating = false
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        BalanceCard(
            balance: 187.50,
            isLoading: false,
            title: "Your Balance",
            onRefresh: {}
        )
        
        BalanceCard(
            balance: 0.0,
            isLoading: true,
            title: "Merchant Balance",
            onRefresh: {}
        )
    }
    .padding()
    .background(.gray.opacity(0.1))
} 