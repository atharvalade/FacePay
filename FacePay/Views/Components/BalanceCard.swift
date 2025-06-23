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
    let walletAddress: String
    let web3Service: Web3Service
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
                
                HStack(spacing: 12) {
                    // Explorer link button
                    Button(action: {
                        if let url = URL(string: web3Service.getAddressExplorerURL(for: walletAddress)) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Image(systemName: "link.circle")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    // Refresh button
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    }
                    .disabled(isLoading)
                }
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
            
            // Wallet Address
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Wallet Address:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                HStack {
                    Text(formatAddress(walletAddress))
                        .font(.caption.monospaced())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        UIPasteboard.general.string = walletAddress
                    }) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            
            // Network Info
            HStack {
                Image(systemName: "p.circle.fill")
                    .foregroundColor(.blue)
                
                Text("PayPal USD")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                // Network indicator with real connection status
                HStack(spacing: 4) {
                    Circle()
                        .fill(isLoading ? .orange : .green)
                        .frame(width: 8, height: 8)
                    
                    Text("Sepolia")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    // Live indicator
                    if !isLoading {
                        Text("• Live")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
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
    
    private func formatAddress(_ address: String) -> String {
        return "\(address.prefix(6))...\(address.suffix(4))"
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        BalanceCard(
            balance: 187.50,
            isLoading: false,
            title: "Your Balance",
            walletAddress: "0x9f93EebD463d4B7c991986a082d974E77b5a02Dc",
            web3Service: Web3Service(),
            onRefresh: {}
        )
        
        BalanceCard(
            balance: 0.0,
            isLoading: true,
            title: "Merchant Balance",
            walletAddress: "0x27A7A44250C6Eb3C84d1d894c8A601742827C7C7",
            web3Service: Web3Service(),
            onRefresh: {}
        )
    }
    .padding()
    .background(.gray.opacity(0.1))
} 