//
//  kantokuApp.swift
//  kantoku
//
//  Created by NAI WEN HSU on 2026/1/23.
//

import SwiftUI
import Auth

@main
struct kantokuApp: App {
    @StateObject private var authService = AuthService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showTestView") private var showTestView = true // 開發模式：顯示測試視圖
    @State private var showOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Development Mode: Show Test View
                if showTestView {
                    NavigationStack {
                        TestConnectionView()
                            .toolbar {
                                ToolbarItem(placement: .navigationBarTrailing) {
                                    Button("關閉測試") {
                                        showTestView = false
                                    }
                                }
                            }
                    }
                } else {
                    // Main Content
                    if authService.isAuthenticated {
                        MainTabView()
                    } else {
                        LoginView()
                    }
                    
                    // Onboarding Overlay
                    if showOnboarding && !hasCompletedOnboarding {
                        OnboardingView(showOnboarding: $showOnboarding)
                            .transition(.opacity)
                            .zIndex(1)
                    }
                }
            }
            .onAppear {
                // Show onboarding only on first launch
                if !hasCompletedOnboarding && !showTestView {
                    showOnboarding = true
                }
            }
            .onChange(of: showOnboarding) { _, newValue in
                // Mark onboarding as completed when dismissed
                if !newValue {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
