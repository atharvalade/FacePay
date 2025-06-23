//
//  FacePayLogo.swift
//  FacePay
//
//  Created by FacePay Team
//

import SwiftUI

struct FacePayLogo: View {
    let size: LogoSize
    @State private var isGlowing = false
    
    var body: some View {
        HStack(spacing: size.spacing) {
            // Face Icon
            Image(systemName: "face.smiling.inverse")
                .font(.system(size: size.iconSize, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(isGlowing ? 1.1 : 1.0)
            
            // Text
            VStack(alignment: .leading, spacing: -2) {
                Text("Face")
                    .font(.system(size: size.fontSize, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Pay")
                    .font(.system(size: size.fontSize, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
        .shadow(color: .black.opacity(0.1), radius: size.shadowRadius)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isGlowing = true
            }
        }
    }
}

enum LogoSize {
    case small
    case medium
    case large
    case hero
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 20
        case .medium: return 30
        case .large: return 40
        case .hero: return 60
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 16
        case .medium: return 24
        case .large: return 32
        case .hero: return 48
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        case .hero: return 16
        }
    }
    
    var shadowRadius: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 4
        case .large: return 6
        case .hero: return 8
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 30) {
        FacePayLogo(size: .hero)
        FacePayLogo(size: .large)
        FacePayLogo(size: .medium)
        FacePayLogo(size: .small)
    }
    .padding()
} 