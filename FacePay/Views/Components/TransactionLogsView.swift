//
//  TransactionLogsView.swift
//  FacePay
//
//  Created by FacePay Team
//

import SwiftUI

struct TransactionLogsView: View {
    @ObservedObject var web3Service: Web3Service
    @State private var shouldAutoScroll = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("🔗 Blockchain Transaction Logs")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !web3Service.streamingLogs.isEmpty {
                    Button(action: {
                        web3Service.streamingLogs.removeAll()
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            
            if web3Service.streamingLogs.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("Waiting for transaction logs...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 6) {
                            ForEach(web3Service.streamingLogs) { log in
                                TransactionLogRow(log: log)
                                    .id(log.id)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .frame(maxHeight: 200)
                    .onChange(of: web3Service.streamingLogs.count) { _ in
                        if shouldAutoScroll, let lastLog = web3Service.streamingLogs.last {
                            withAnimation(.easeOut(duration: 0.3)) {
                                proxy.scrollTo(lastLog.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

struct TransactionLogRow: View {
    let log: TransactionLog
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(log.type.icon)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(log.message)
                    .font(.caption)
                    .foregroundColor(Color(log.type.color))
                    .fixedSize(horizontal: false, vertical: true)
                
                if !log.timestamp.isEmpty {
                    Text(formatTimestamp(log.timestamp))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: timestamp) {
            let displayFormatter = DateFormatter()
            displayFormatter.timeStyle = .medium
            return displayFormatter.string(from: date)
        }
        return timestamp
    }
}

#Preview {
    let web3Service = Web3Service()
    
    // Add some sample logs for preview
    web3Service.streamingLogs = [
        TransactionLog(
            type: .info,
            message: "🚀 EXECUTING REAL BLOCKCHAIN TRANSACTION",
            timestamp: "2024-01-23T12:00:00Z"
        ),
        TransactionLog(
            type: .info,
            message: "⚙️ Setting up wallet connection...",
            timestamp: "2024-01-23T12:00:01Z"
        ),
        TransactionLog(
            type: .success,
            message: "✅ Wallet connected: 0x9f93EebD463d4B7c991986a082d974E77b5a02Dc",
            timestamp: "2024-01-23T12:00:02Z"
        ),
        TransactionLog(
            type: .info,
            message: "💰 Checking balance...",
            timestamp: "2024-01-23T12:00:03Z"
        ),
        TransactionLog(
            type: .success,
            message: "✅ TRANSACTION SUBMITTED!",
            timestamp: "2024-01-23T12:00:05Z"
        )
    ]
    
    return TransactionLogsView(web3Service: web3Service)
        .padding()
} 