//
//  DashboardView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 首頁儀表板
struct DashboardView: View {
    @StateObject private var viewModel = TaskViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.lg) {
                // Header Section
                headerSection
                
                // Daily Progress Card
                dailyProgressCard
                
                // Today's Tasks
                todayTasksSection
                
                Spacer()
            }
            .padding(Constants.Spacing.md)
        }
        .background(Constants.Colors.background)
        .navigationTitle("今日學習")
        .navigationBarTitleDisplayMode(.large)
        .task {
            await viewModel.loadDashboardData()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("おはようございます")
                    .font(Constants.Typography.caption)
                    .foregroundColor(Constants.Colors.secondaryText)
                
                Text("學習者")
                    .font(Constants.Typography.h2)
                    .foregroundColor(Constants.Colors.primaryText)
            }
            
            Spacer()
            
            // Streak Badge
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(viewModel.currentStreak)")
                    .font(Constants.Typography.h3)
                    .fontWeight(.bold)
                Text("天")
                    .font(Constants.Typography.caption)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Constants.Colors.cardBackground)
            .cornerRadius(Constants.CornerRadius.small)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Daily Progress Card
    private var dailyProgressCard: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("今日目標")
                .font(Constants.Typography.h3)
                .foregroundColor(Constants.Colors.primaryText)
            
            HStack(spacing: Constants.Spacing.md) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Constants.Colors.primary.opacity(0.2), lineWidth: 8)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.progressPercentage)
                        .stroke(Constants.Colors.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.progressPercentage * 100))")
                            .font(Constants.Typography.h2)
                            .fontWeight(.bold)
                        Text("%")
                            .font(Constants.Typography.caption)
                            .foregroundColor(Constants.Colors.secondaryText)
                    }
                }
                .frame(width: 80, height: 80)
                
                VStack(alignment: .leading, spacing: 8) {
                    progressItem(icon: "checkmark.circle.fill", text: "已完成 \(viewModel.completedTasksCount) 個任務", color: .green)
                    progressItem(icon: "clock.fill", text: "剩餘 \(viewModel.totalTasksCount - viewModel.completedTasksCount) 個任務", color: .orange)
                    progressItem(icon: "chart.bar.fill", text: "學習時間 \(viewModel.todayMinutes) 分鐘", color: .blue)
                }
            }
        }
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func progressItem(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
            Text(text)
                .font(Constants.Typography.caption)
                .foregroundColor(Constants.Colors.secondaryText)
        }
    }
    
    // MARK: - Today's Tasks Section
    private var todayTasksSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
            HStack {
                Text("今日任務")
                    .font(Constants.Typography.h3)
                    .foregroundColor(Constants.Colors.primaryText)
                
                Spacer()
                
                Button(action: {}) {
                    Text("查看全部")
                        .font(Constants.Typography.caption)
                        .foregroundColor(Constants.Colors.primary)
                }
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(Constants.Spacing.xl)
            } else if viewModel.todayTasks.isEmpty {
                EmptyTaskCard()
            } else {
                ForEach(viewModel.todayTasks) { task in
                    TaskCard(task: task) {
                        // Navigate to task detail
                    }
                }
            }
        }
    }
    

}

// MARK: - Preview
#Preview {
    NavigationStack {
        DashboardView()
    }
}
