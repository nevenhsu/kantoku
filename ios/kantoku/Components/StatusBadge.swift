//
//  StatusBadge.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 狀態徽章
struct StatusBadge: View {
    let text: String
    let color: Color
    var icon: String?
    
    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(Constants.Typography.small)
            }
            Text(text)
                .font(Constants.Typography.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.2))
        .foregroundColor(color)
        .cornerRadius(Constants.CornerRadius.small)
    }
}

/// 任務狀態徽章
struct TaskStatusBadge: View {
    let status: TaskStatus
    
    var body: some View {
        StatusBadge(
            text: status.displayName,
            color: colorForStatus(status),
            icon: iconForStatus(status)
        )
    }
    
    private func colorForStatus(_ status: TaskStatus) -> Color {
        switch status {
        case .pending: return Constants.Colors.orange
        case .submitted: return Constants.Colors.primary
        case .passed: return Constants.Colors.green
        case .failed: return Constants.Colors.red
        }
    }
    
    private func iconForStatus(_ status: TaskStatus) -> String {
        switch status {
        case .pending: return "clock"
        case .submitted: return "hourglass"
        case .passed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        }
    }
}

/// 學習狀態徽章
struct LearningStatusBadge: View {
    let status: LearningStatus
    
    var body: some View {
        StatusBadge(
            text: status.displayName,
            color: colorForStatus(status),
            icon: iconForStatus(status)
        )
    }
    
    private func colorForStatus(_ status: LearningStatus) -> Color {
        switch status {
        case .notStarted: return Constants.Colors.secondaryText
        case .learning: return Constants.Colors.orange
        case .reviewing: return Constants.Colors.primary
        case .mastered: return Constants.Colors.green
        }
    }
    
    private func iconForStatus(_ status: LearningStatus) -> String {
        switch status {
        case .notStarted: return "circle"
        case .learning: return "book"
        case .reviewing: return "arrow.clockwise"
        case .mastered: return "star.fill"
        }
    }
}

extension LearningStatus {
    var displayName: String {
        switch self {
        case .notStarted: return "未開始"
        case .learning: return "學習中"
        case .reviewing: return "複習中"
        case .mastered: return "已掌握"
        }
    }
}

// MARK: - Previews
#Preview("Status Badges") {
    VStack(spacing: 12) {
        StatusBadge(text: "新任務", color: .blue, icon: "sparkles")
        StatusBadge(text: "已完成", color: .green, icon: "checkmark.circle.fill")
        StatusBadge(text: "警告", color: .orange, icon: "exclamationmark.triangle")
        
        Divider()
        
        TaskStatusBadge(status: .pending)
        TaskStatusBadge(status: .submitted)
        TaskStatusBadge(status: .passed)
        TaskStatusBadge(status: .failed)
    }
    .padding()
}
