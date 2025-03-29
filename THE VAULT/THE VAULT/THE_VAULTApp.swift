//
//  THE_VAULTApp.swift
//  THE VAULT
//
//  Created by Edafe on 18/03/2025.
//

import SwiftUI

@main
struct THE_VAULTApp: App {
    @StateObject private var authService = AuthenticationService()
    
    var body: some Scene {
        WindowGroup {
            if authService.isAuthenticated {
                ContentView()
            } else {
                AuthenticationView(authService: authService)
            }
        }
    }
}

struct AuthenticationView: View {
    @ObservedObject var authService: AuthenticationService
    @State private var isAuthenticating = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Image(systemName: "lock.shield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Text("THE VAULT")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                
                if isAuthenticating {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.blue)
                } else {
                    Button(action: authenticate) {
                        Label("Unlock with Face ID", systemImage: "faceid")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                }
                
                if let error = authService.error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .task {
            authenticate()
        }
    }
    
    private func authenticate() {
        isAuthenticating = true
        Task {
            _ = await authService.authenticate()
            isAuthenticating = false
        }
    }
}
