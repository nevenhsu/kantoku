//
//  ReviewResultView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// AI 審核結果視圖
/// 顯示 AI 反饋、評分、優缺點
struct ReviewResultView: View {
    let submission: Submission
    @Environment(\.dismiss) private var dismiss
    
    private var passed: Bool {
        submission.passed ?? false
    }
    
    private var score: Int {
        submission.score ?? 0
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Constants.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.Spacing.xl) {
                        // Result Header
                        resultHeaderSection
                        
                        // Score
                        scoreSection
                        
                        // Feedback
                        if let feedback = submission.aiFeedback {
                            feedbackSection(feedback)
                        }
                        
                        Spacer()
                    }
                    .padding(Constants.Spacing.lg)
                }
            }
            .navigationTitle("審核結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Result Header Section
    
    private var resultHeaderSection: some View {
        VStack(spacing: Constants.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(passed ? Constants.Colors.success.opacity(0.1) : Constants.Colors.danger.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(passed ? Constants.Colors.success : Constants.Colors.danger)
            }
            
            // Status Text
            Text(passed ? "恭喜通過！" : "未通過")
                .font(Constants.Typography.title1)
                .foregroundColor(Constants.Colors.textPrimary)
            
            if !passed {
                Text("請查看反饋並再試一次")
                    .font(Constants.Typography.body)
                    .foregroundColor(Constants.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Constants.Spacing.xl)
    }
    
    // MARK: - Score Section
    
    private var scoreSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                Text("得分")
                    .font(Constants.Typography.caption)
                    .foregroundColor(Constants.Colors.textSecondary)
                
                HStack(alignment: .firstTextBaseline, spacing: Constants.Spacing.xs) {
                    Text("\(score)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(scoreColor)
                    
                    Text("/ 100")
                        .font(Constants.Typography.title3)
                        .foregroundColor(Constants.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Constants.Colors.cardBackground, lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: Double(score) / 100.0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
            }
        }
        .padding(Constants.Spacing.lg)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    // MARK: - Feedback Section
    
    private func feedbackSection(_ feedback: AIFeedback) -> some View {
        VStack(spacing: Constants.Spacing.md) {
            // Overall Feedback
            FeedbackCard(
                title: "總體評價",
                icon: "text.bubble",
                iconColor: Constants.Colors.accent,
                content: feedback.overall
            )
            
            // Strengths
            if let strengths = feedback.strengths, !strengths.isEmpty {
                FeedbackCard(
                    title: "做得好的地方",
                    icon: "star.fill",
                    iconColor: Constants.Colors.success,
                    items: strengths
                )
            }
            
            // Improvements
            if let improvements = feedback.improvements, !improvements.isEmpty {
                FeedbackCard(
                    title: "可以改進的地方",
                    icon: "exclamationmark.triangle.fill",
                    iconColor: Constants.Colors.warning,
                    items: improvements
                )
            }
            
            // Encouragement
            if let encouragement = feedback.encouragement {
                VStack(spacing: Constants.Spacing.sm) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .foregroundColor(Constants.Colors.accent)
                        
                        Text("加油！")
                            .font(Constants.Typography.headline)
                            .foregroundColor(Constants.Colors.textPrimary)
                        
                        Spacer()
                    }
                    
                    Text(encouragement)
                        .font(Constants.Typography.body)
                        .foregroundColor(Constants.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Constants.Spacing.md)
                .background(Constants.Colors.accent.opacity(0.1))
                .cornerRadius(Constants.UI.cornerRadius)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var scoreColor: Color {
        if score >= 80 {
            return Constants.Colors.success
        } else if score >= 60 {
            return Constants.Colors.warning
        } else {
            return Constants.Colors.danger
        }
    }
}

// MARK: - Feedback Card Component

struct FeedbackCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    var content: String? = nil
    var items: [String]? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                
                Text(title)
                    .font(Constants.Typography.headline)
                    .foregroundColor(Constants.Colors.textPrimary)
                
                Spacer()
            }
            
            // Content
            if let content = content {
                Text(content)
                    .font(Constants.Typography.body)
                    .foregroundColor(Constants.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Items List
            if let items = items {
                VStack(alignment: .leading, spacing: Constants.Spacing.xs) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: Constants.Spacing.sm) {
                            Text("•")
                                .foregroundColor(Constants.Colors.textSecondary)
                            
                            Text(item)
                                .font(Constants.Typography.body)
                                .foregroundColor(Constants.Colors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

// MARK: - Preview

#Preview {
    ReviewResultView(
        submission: Submission(
            id: UUID(),
            taskId: UUID(),
            submissionType: .audio,
            content: "test.m4a",
            aiFeedback: AIFeedback(
                overall: "整體表現不錯！發音清晰，語調自然。",
                strengths: [
                    "發音準確，特別是「あ」和「い」的發音很標準",
                    "語速適中，容易理解",
                    "語調自然，聽起來很流暢"
                ],
                improvements: [
                    "「う」的發音可以更圓潤一些",
                    "注意「ん」的鼻音發音"
                ],
                encouragement: "繼續保持！多練習就會越來越好！"
            ),
            score: 85,
            passed: true,
            createdAt: Date()
        )
    )
}
