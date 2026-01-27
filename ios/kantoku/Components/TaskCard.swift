//
//  TaskCard.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 任務卡片
struct TaskCard: View {
    let task: TaskModel
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                // Header: Icon + Type + Status
                HStack {
                    Image(systemName: task.taskType.iconName)
                        .font(.title2)
                        .foregroundColor(Constants.Colors.primary)
                        .frame(width: 36, height: 36)
                        .background(Constants.Colors.primary.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(task.taskType.displayName)
                            .font(Constants.Typography.h3)
                            .foregroundColor(Constants.Colors.primaryText)
                        
                        Text(taskTypeDescription(for: task))
                            .font(Constants.Typography.caption)
                            .foregroundColor(Constants.Colors.secondaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    TaskStatusBadge(status: task.status)
                }
                
                Divider()
                
                // Content Preview
                contentPreview(for: task)
                    .font(Constants.Typography.body)
                    .foregroundColor(Constants.Colors.primaryText)
                    .lineLimit(2)
            }
            .padding(Constants.Spacing.md)
            .background(Constants.Colors.cardBackground)
            .cornerRadius(Constants.CornerRadius.medium)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(CardButtonStyle())
    }
    
    private func taskTypeDescription(for task: TaskModel) -> String {
        switch task.taskType {
        case .kanaLearn:
            return "學習新的假名"
        case .kanaReview:
            return "複習已學假名"
        case .vocabulary:
            return "學習新單字"
        case .externalResource:
            return "外部學習資源"
        }
    }
    
    @ViewBuilder
    private func contentPreview(for task: TaskModel) -> some View {
        switch task.content {
        case .kanaLearn(let content):
            let kanaString = content.kanaList.map { $0.kana }.joined(separator: " ")
            Text("假名: \(kanaString)")
        case .kanaReview(let content):
            let kanaString = content.reviewKana.map { $0.kana }.joined(separator: " ")
            Text("複習: \(kanaString)")
        case .vocabulary(let content):
            let wordString = content.words.map { $0.word }.joined(separator: "、")
            Text("單字: \(wordString)")
        case .externalResource(let content):
            Text(content.title)
        }
    }
}

/// 卡片按鈕樣式
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Empty State Card
struct EmptyTaskCard: View {
    var body: some View {
        VStack(spacing: Constants.Spacing.md) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(Constants.Colors.green)
            
            Text("所有任務已完成！")
                .font(Constants.Typography.h3)
                .foregroundColor(Constants.Colors.primaryText)
            
            Text("今天表現很棒！明天繼續加油！")
                .font(Constants.Typography.body)
                .foregroundColor(Constants.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Constants.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview("Task Card") {
    VStack(spacing: 16) {
        TaskCard(
            task: TaskModel(
                id: UUID(),
                userId: UUID(),
                taskType: .kanaLearn,
                content: .kanaLearn(KanaLearnContent(
                    kanaList: [
                        KanaItem(kana: "あ", romaji: "a"),
                        KanaItem(kana: "い", romaji: "i"),
                        KanaItem(kana: "う", romaji: "u")
                    ],
                    kanaType: .hiragana
                )),
                status: .pending,
                dueDate: Date(),
                skipped: false,
                createdAt: Date(),
                updatedAt: Date()
            ),
            action: {}
        )
        
        EmptyTaskCard()
    }
    .padding()
}
