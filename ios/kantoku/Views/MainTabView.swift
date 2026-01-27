//
//  MainTabView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 主要 Tab 視圖
struct MainTabView: View {
    @State private var selectedTab: Tab = .dashboard
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard
            NavigationStack {
                DashboardView()
            }
            .tabItem {
                Label("首頁", systemImage: "house.fill")
            }
            .tag(Tab.dashboard)
            
            // Tasks
            NavigationStack {
                TasksView()
            }
            .tabItem {
                Label("任務", systemImage: "list.bullet")
            }
            .tag(Tab.tasks)
            
            // Progress
            NavigationStack {
                LearningProgressView()
            }
            .tabItem {
                Label("進度", systemImage: "chart.bar.fill")
            }
            .tag(Tab.progress)
            
            // Tests
            NavigationStack {
                TestsView()
            }
            .tabItem {
                Label("測驗", systemImage: "checkmark.circle.fill")
            }
            .tag(Tab.tests)
            
            // Profile
            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("我的", systemImage: "person.fill")
            }
            .tag(Tab.profile)
        }
        .tint(Constants.Colors.primary)
    }
}

// MARK: - Tab Enum
enum Tab {
    case dashboard
    case tasks
    case progress
    case tests
    case profile
}

// MARK: - Preview
#Preview {
    MainTabView()
}
