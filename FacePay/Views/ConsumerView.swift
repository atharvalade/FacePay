//
//  ConsumerView.swift
//  FacePay
//
//  Created by FacePay Team
//

import SwiftUI

struct ConsumerView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header with User Selection
                    HeaderSection()
                    
                    // Balance Card
                    BalanceCard(
                        balance: appState.currentBalance,
                        isLoading: appState.web3Service.isLoading,
                        title: "Your Balance"
                    ) {
                        Task {
                            await appState.refreshBalance()
                        }
                    }
                    
                    // Face Registration Section
                    FaceRegistrationSection()
                    
                    // Quick Actions
                    QuickActionsSection()
                    
                    // Recent Transactions
                    TransactionHistorySection()
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .navigationTitle("Consumer")
            .navigationBarTitleDisplayMode(.large)
            .background(
                LinearGradient(
                    colors: [.blue.opacity(0.05), .purple.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
        }
        .sheet(isPresented: $appState.showingCamera) {
            CameraView(
                onImageCaptured: { image in
                    appState.handleCapturedImage(image)
                },
                onError: { error in
                    appState.showAlert(title: "Camera Error", message: error)
                }
            )
        }
        .alert(appState.alertTitle, isPresented: $appState.showingAlert) {
            Button("OK") { }
        } message: {
            Text(appState.alertMessage)
        }
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private func HeaderSection() -> some View {
        VStack(spacing: 16) {
            // User Selection
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text(appState.selectedUser.name)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        appState.switchUser()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "person.2.circle")
                            .font(.title2)
                        Text("Switch")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.blue.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            // Address Display
            HStack {
                Text("Wallet:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(appState.selectedUser.address.prefix(6) + "..." + appState.selectedUser.address.suffix(4))
                    .font(.caption.monospaced())
                    .foregroundColor(.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.gray.opacity(0.1))
                    .clipShape(Capsule())
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Face Registration Section
    @ViewBuilder
    private func FaceRegistrationSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "face.smiling.inverse")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Face Recognition")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            let isRegistered = appState.storageService.isUserRegistered(address: appState.selectedUser.address)
            
            if isRegistered {
                // Already Registered
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Face Registered ✨")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("You're ready for instant payments!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Remove") {
                        appState.removeUserFace()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
                .padding(16)
                .background(.green.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                // Need to Register
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Face Not Registered")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("Register your face for instant payments")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Button(action: {
                        appState.startFaceRegistration()
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Register Face")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(16)
                .background(.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            if appState.isRegistering {
                RegistrationProgressView()
                    .environmentObject(appState)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
    
    // MARK: - Quick Actions Section
    @ViewBuilder
    private func QuickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ActionButton(
                    icon: "arrow.clockwise",
                    title: "Refresh Balance",
                    color: .blue
                ) {
                    Task {
                        await appState.refreshBalance()
                    }
                }
                
                ActionButton(
                    icon: "list.bullet.rectangle",
                    title: "View History",
                    color: .green
                ) {
                    Task {
                        await appState.loadRecentTransactions()
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
    
    // MARK: - Transaction History Section
    @ViewBuilder
    private func TransactionHistorySection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Transactions")
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
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No transactions yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Your payments will appear here")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(appState.recentTransactions) { transaction in
                        TransactionRow(transaction: transaction)
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
struct RegistrationProgressView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Processing face registration...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if appState.capturedImages.count > 0 {
                    Text("\(appState.capturedImages.count)/3 images captured")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.blue.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct TransactionRow: View {
    let transaction: TransactionRecord
    
    var body: some View {
        HStack {
            Image(systemName: transaction.type == .payment ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                .foregroundColor(transaction.type == .payment ? .red : .green)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.type.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("$\(String(format: "%.2f", transaction.amount))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(transaction.type == .payment ? .red : .green)
                
                Text("PYUSD")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.gray.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview
#Preview {
    ConsumerView(appState: AppState())
} 