//
//  RootView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/30.
//

import SwiftUI

/// Root view that handles all UI flow control logic
/// This view is a regular SwiftUI View, allowing @AppStorage and @State changes
/// to reliably trigger body recomputation, unlike when placed in the @main App struct
struct RootView: View {
    @EnvironmentObject private var authService: AuthService
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("showTestView") private var showTestView = true // Development mode: show test view
    @State private var showOnboarding = false
    @State private var internalShowTestView = true // Local state mirror for reliable UI updates
    
    var body: some View {
        ZStack {
            // Development Mode: Show Test View
            if internalShowTestView {
                testModeView
            } else {
                mainContentView
            }
        }
        .onAppear {
            // Sync internal state with AppStorage on appear
            internalShowTestView = showTestView
            
            // Show onboarding only on first launch
            if !hasCompletedOnboarding && !showTestView {
                showOnboarding = true
            }
        }
        .onChange(of: showTestView) { _, newValue in
            // Sync internal state when AppStorage changes
            withAnimation {
                internalShowTestView = newValue
            }
        }
        .onChange(of: showOnboarding) { _, newValue in
            // Mark onboarding as completed when dismissed
            if !newValue {
                hasCompletedOnboarding = true
            }
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var testModeView: some View {
        NavigationStack {
            TestConnectionView()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("關閉測試") {
                            showTestView = false
                            // Force internal state update immediately
                            internalShowTestView = false
                        }
                    }
                }
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
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
    }
}
