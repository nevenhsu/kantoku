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
            if case .kanaLearn(let content) = task.content {
                return "\(content.kanaList.count) 個假名"
            }
            return "學習新的假名"
        case .kanaReview:
            if case .kanaReview(let content) = task.content {
                return "\(content.reviewKana.count) 個假名"
            }
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
    var hasAnyTasks: Bool = true // If false, user has no tasks at all (new user)
    var onGenerateTasks: (() -> Void)? = nil // Optional callback for generating tasks
    
    var body: some View {
        VStack(spacing: Constants.Spacing.md) {
            Image(systemName: hasAnyTasks ? "checkmark.circle.fill" : "tray")
                .font(.system(size: 60))
                .foregroundColor(hasAnyTasks ? Constants.Colors.green : Constants.Colors.secondaryText)
            
            Text(hasAnyTasks ? "所有任務已完成！" : "還沒有任務")
                .font(Constants.Typography.h3)
                .foregroundColor(Constants.Colors.primaryText)
            
            Text(hasAnyTasks ? "今天表現很棒！明天繼續加油！" : "生成今日學習任務開始學習")
                .font(Constants.Typography.body)
                .foregroundColor(Constants.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            // Generate Tasks Button (only for new users)
            if !hasAnyTasks, let action = onGenerateTasks {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("生成每日任務")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Constants.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(Constants.CornerRadius.button)
                }
                .padding(.top, Constants.Spacing.sm)
            }
        }
        .padding(Constants.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Grouped Task Card (練習/複習分組卡片)

/// 分組任務卡片（用於首頁顯示練習或複習）
struct GroupedTaskCard: View {
    let groupedTask: GroupedTask
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                // Header: Icon + Type + Progress
                HStack {
                    Image(systemName: groupedTask.groupType.iconName)
                        .font(.title2)
                        .foregroundColor(Constants.Colors.primary)
                        .frame(width: 36, height: 36)
                        .background(Constants.Colors.primary.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(groupedTask.groupType.displayName)
                            .font(Constants.Typography.h3)
                            .foregroundColor(Constants.Colors.primaryText)
                        
                        Text(taskDescription)
                            .font(Constants.Typography.caption)
                            .foregroundColor(Constants.Colors.secondaryText)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    // 進度指示
                    progressBadge
                }
                
                Divider()
                
                // 假名預覽
                kanaPreview
                    .font(Constants.Typography.body)
                    .foregroundColor(Constants.Colors.primaryText)
            }
            .padding(Constants.Spacing.md)
            .background(Constants.Colors.cardBackground)
            .cornerRadius(Constants.CornerRadius.medium)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(CardButtonStyle())
    }
    
    private var taskDescription: String {
        let kanaCount = groupedTask.totalKanaCount
        let kanaTypeStr = groupedTask.kanaType == .katakana ? "片假名" : "平假名"
        return "\(kanaCount) 個\(kanaTypeStr)"
    }
    
    private var progressBadge: some View {
        Group {
            if groupedTask.isCompleted {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("完成")
                }
                .font(Constants.Typography.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Constants.Colors.green)
                .cornerRadius(Constants.CornerRadius.small)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                    Text("待完成")
                }
                .font(Constants.Typography.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.orange)
                .cornerRadius(Constants.CornerRadius.small)
            }
        }
    }
    
    private var kanaPreview: some View {
        let kanaItems = groupedTask.allKana
        let displayKana = kanaItems.prefix(8)
        let kanaString = displayKana.map { $0.kana }.joined(separator: "  ")
        let moreCount = kanaItems.count - displayKana.count
        
        return HStack {
            Text(kanaString)
                .font(.system(size: 18, weight: .medium))
            
            if moreCount > 0 {
                Text("...(+\(moreCount))")
                    .font(Constants.Typography.caption)
                    .foregroundColor(Constants.Colors.secondaryText)
            }
            
            Spacer()
        }
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
