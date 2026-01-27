//
//  OnboardingView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 引導頁面內容
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

/// 歡迎引導視圖
struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "book.fill",
            title: "歡迎來到 Kantoku",
            description: "您的專屬日語學習小助手，陪伴您踏上日語學習之旅",
            color: Constants.Colors.primary
        ),
        OnboardingPage(
            icon: "calendar.badge.clock",
            title: "每日任務系統",
            description: "AI 根據您的進度每天生成個性化學習任務，讓學習更有條理",
            color: Constants.Colors.orange
        ),
        OnboardingPage(
            icon: "waveform",
            title: "語音 & 手寫練習",
            description: "透過語音錄製和手寫練習，全方位提升日語能力",
            color: Constants.Colors.primary
        ),
        OnboardingPage(
            icon: "chart.line.uptrend.xyaxis",
            title: "智能追蹤進度",
            description: "詳細記錄學習數據，視覺化呈現您的進步軌跡",
            color: Constants.Colors.green
        )
    ]
    
    var body: some View {
        ZStack {
            // Background
            Constants.Colors.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip Button
                HStack {
                    Spacer()
                    if currentPage < pages.count - 1 {
                        Button(action: {
                            withAnimation {
                                currentPage = pages.count - 1
                            }
                        }) {
                            Text("跳過")
                                .font(Constants.Typography.caption)
                                .foregroundColor(Constants.Colors.secondaryText)
                        }
                        .padding(.trailing, Constants.Spacing.lg)
                        .padding(.top, Constants.Spacing.md)
                    }
                }
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? pages[currentPage].color : Constants.Colors.secondaryText.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(currentPage == index ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, Constants.Spacing.lg)
                
                // Bottom Buttons
                VStack(spacing: Constants.Spacing.md) {
                    if currentPage == pages.count - 1 {
                        // Get Started Button
                        PrimaryButton(
                            title: "開始使用",
                            action: {
                                withAnimation {
                                    showOnboarding = false
                                }
                            }
                        )
                        .padding(.horizontal, Constants.Spacing.lg)
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        // Next Button
                        PrimaryButton(
                            title: "下一步",
                            action: {
                                withAnimation {
                                    currentPage += 1
                                }
                            }
                        )
                        .padding(.horizontal, Constants.Spacing.lg)
                    }
                }
                .padding(.bottom, Constants.Spacing.xl)
            }
        }
    }
}

/// 單頁內容視圖
struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: Constants.Spacing.xl) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(page.color.opacity(0.1))
                    .frame(width: 160, height: 160)
                
                Image(systemName: page.icon)
                    .font(.system(size: 70))
                    .foregroundColor(page.color)
            }
            .padding(.bottom, Constants.Spacing.md)
            
            // Title
            Text(page.title)
                .font(Constants.Typography.h1)
                .foregroundColor(Constants.Colors.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.Spacing.xl)
            
            // Description
            Text(page.description)
                .font(Constants.Typography.body)
                .foregroundColor(Constants.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Constants.Spacing.xl)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview("Onboarding View") {
    OnboardingView(showOnboarding: .constant(true))
}

#Preview("Onboarding Page") {
    OnboardingPageView(
        page: OnboardingPage(
            icon: "book.fill",
            title: "歡迎來到 Kantoku",
            description: "您的專屬日語學習小助手，陪伴您踏上日語學習之旅",
            color: Constants.Colors.primary
        )
    )
}
