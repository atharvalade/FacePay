//
//  MerchantView.swift
//  FacePay
//
//  Created by FacePay Team
//

import SwiftUI

struct MerchantView: View {
    @ObservedObject var appState: AppState
    @FocusState private var isAmountFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Merchant Header
                    MerchantHeaderSection()
                    
                    // Balance Card
                    BalanceCard(
                        balance: appState.currentBalance,
                        isLoading: appState.web3Service.isLoading,
                        title: "Merchant Balance"
                    ) {
                        Task {
                            await appState.refreshBalance()
                        }
                    }
                    
                    // Payment Input Section
                    PaymentInputSection()
                    
                    // Payment Actions
                    PaymentActionsSection()
                    
                    // Recent Sales
                    RecentSalesSection()
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("Merchant")
            .navigationBarTitleDisplayMode(.large)
            .background(
                LinearGradient(
                    colors: [.green.opacity(0.05), .mint.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
        .sheet(isPresented: $appState.showingCamera) {
            CameraView(
                onImageCaptured: { image in
                    Task {
                        await appState.handleMerchantFaceCapture(image)
                    }
                },
                onError: { error in
                    appState.showAlert(title: "Camera Error", message: error)
                }
            )
        }
        .sheet(isPresented: $appState.showingPaymentSuccess) {
            PaymentSuccessView()
        }
        .alert(appState.alertTitle, isPresented: $appState.showingAlert) {
            Button("OK") { }
        } message: {
            Text(appState.alertMessage)
        }
    }
    
    // MARK: - Merchant Header Section
    @ViewBuilder
    private func MerchantHeaderSection() -> some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FacePay Merchant")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Terminal")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Image(systemName: "storefront.circle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            // Status Indicator
            HStack {
                Circle()
                    .fill(.green)
                    .frame(width: 8, height: 8)
                
                Text("Ready to accept payments")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Sepolia Testnet")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.gray.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Payment Input Section
    @ViewBuilder
    private func PaymentInputSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                Text("Payment Amount")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 16) {
                // Amount Input
                HStack {
                    Text("$")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    TextField("0.00", text: $appState.merchantAmount)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .keyboardType(.decimalPad)
                        .focused($isAmountFocused)
                        .multilineTextAlignment(.leading)
                    
                    Text("PYUSD")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)
                }
                .padding()
                .background(.gray.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Quick Amount Buttons
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(["5.00", "10.00", "25.00", "50.00"], id: \.self) { amount in
                        Button(action: {
                            appState.merchantAmount = amount
                        }) {
                            Text("$\(amount)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(.green.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Payment Actions Section
    @ViewBuilder
    private func PaymentActionsSection() -> some View {
        VStack(spacing: 16) {
            // Main Scan Button
            Button(action: {
                isAmountFocused = false
                appState.startFaceRecognition()
            }) {
                HStack(spacing: 12) {
                    if appState.web3Service.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "camera.viewfinder")
                            .font(.title2)
                    }
                    
                    Text(appState.web3Service.isLoading ? "Processing Payment..." : "Scan Customer Face")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(appState.merchantAmount.isEmpty || appState.web3Service.isLoading)
            .scaleEffect(appState.merchantAmount.isEmpty ? 0.95 : 1.0)
            .animation(.spring(), value: appState.merchantAmount.isEmpty)
            
            // Helper Text
            Text("Customer will look at the camera for instant payment")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Last Customer Match Display
            if let match = appState.lastCustomerMatch {
                LastCustomerMatchView(match: match)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Recent Sales Section
    @ViewBuilder
    private func RecentSalesSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Sales")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if appState.web3Service.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if appState.recentTransactions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No sales yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Payments will appear here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(appState.recentTransactions) { transaction in
                        SalesTransactionRow(transaction: transaction)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Supporting Views
struct LastCustomerMatchView: View {
    let match: FaceMatchResult
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Last Customer: \(match.userName)")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("Confidence: \(Int(match.confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(12)
        .background(.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SalesTransactionRow: View {
    let transaction: TransactionRecord
    
    var body: some View {
        HStack {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sale")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("+$\(String(format: "%.2f", transaction.amount))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                
                Text("PYUSD")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.green.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PaymentSuccessView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState = AppState()
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Success Animation
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                    .scaleEffect(1.2)
                
                Text("Payment Successful! 🎉")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("$\(String(format: "%.2f", appState.lastPaymentAmount)) PYUSD")
                    .font(.title)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
            }
            
            // Transaction Details
            VStack(spacing: 12) {
                if let txHash = appState.web3Service.lastTransactionHash {
                    HStack {
                        Text("Transaction:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(txHash.prefix(10) + "...")
                            .font(.caption.monospaced())
                            .foregroundColor(.blue)
                    }
                }
                
                Text("Customer charged successfully via FacePay")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Close Button
            Button("Close") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(.green)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 40)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [.green.opacity(0.1), .mint.opacity(0.1)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Preview
#Preview {
    MerchantView(appState: AppState())
} 