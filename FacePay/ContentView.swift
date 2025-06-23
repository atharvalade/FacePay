//
//  ContentView.swift
//  FacePay
//
//  Created by Atharva Lade on 6/22/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        TabView(selection: $appState.currentMode) {
            // Consumer Tab
            ConsumerView(appState: appState)
                .tabItem {
                    Image(systemName: appState.currentMode == .consumer ? "person.circle.fill" : "person.circle")
                    Text("Consumer")
                }
                .tag(AppMode.consumer)
            
            // Merchant Tab
            MerchantView(appState: appState)
                .tabItem {
                    Image(systemName: appState.currentMode == .merchant ? "storefront.fill" : "storefront")
                    Text("Merchant")
                }
                .tag(AppMode.merchant)
        }
        .accentColor(appState.currentMode.color)
        .overlay(
            // Floating FacePay Logo
            VStack {
                HStack {
                    Spacer()
                    FacePayLogo(size: .small)
                        .padding(.trailing, 20)
                        .padding(.top, 10)
                }
                Spacer()
            }
            .allowsHitTesting(false)
        )
        .animation(.easeInOut(duration: 0.3), value: appState.currentMode)
    }
}

#Preview {
    ContentView()
}
