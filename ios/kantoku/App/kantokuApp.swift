//
//  kantokuApp.swift
//  kantoku
//
//  Created by NAI WEN HSU on 2026/1/23.
//

import SwiftUI

@main
struct kantokuApp: App {
    @StateObject private var authService = AuthService.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
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
            .onAppear {
                // Show onboarding only on first launch
                if !hasCompletedOnboarding {
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
