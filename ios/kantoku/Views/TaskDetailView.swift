//
//  TaskDetailView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 任務詳情視圖 - 根據不同任務類型顯示不同內容
struct TaskDetailView: View {
    let task: TaskModel
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Spacing.lg) {
                    // Task Header
                    taskHeader
                    
                    // Task Content (根據任務類型顯示)
                    taskContent
                    
                    // Action Buttons
                    if task.status == .pending {
                        actionButtons
                    }
                    
                    Spacer()
                }
                .padding(Constants.Spacing.md)
            }
            .background(Constants.Colors.background)
            .navigationTitle(task.taskType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Task Header
    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
            HStack {
                Image(systemName: task.taskType.iconName)
                    .font(.title2)
                    .foregroundColor(Constants.Colors.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.taskType.displayName)
                        .font(Constants.Typography.h3)
                        .foregroundColor(Constants.Colors.primaryText)
                    
                    Text("到期日：\(formattedDate(task.dueDate))")
                        .font(Constants.Typography.caption)
                        .foregroundColor(Constants.Colors.secondaryText)
                }
                
                Spacer()
                
                StatusBadge(status: task.status.displayName, type: .task)
            }
        }
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
    }
    
    // MARK: - Task Content
    @ViewBuilder
    private var taskContent: some View {
        switch task.content {
        case .kanaLearn(let content):
            KanaLearnContentView(content: content)
        case .kanaReview(let content):
            KanaReviewContentView(content: content)
        case .vocabulary(let content):
            VocabularyContentView(content: content)
        case .externalResource(let content):
            ExternalResourceContentView(content: content)
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: Constants.Spacing.sm) {
            PrimaryButton(text: "開始任務", style: .primary) {
                Task {
                    await viewModel.submitTask(task)
                    dismiss()
                }
            }
            
            PrimaryButton(text: "跳過此任務", style: .secondary) {
                // TODO: Implement skip functionality
                dismiss()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

// MARK: - Kana Learn Content View
struct KanaLearnContentView: View {
    let content: KanaLearnContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("學習新假名")
                .font(Constants.Typography.h3)
                .foregroundColor(Constants.Colors.primaryText)
            
            Text("今天要學習以下 \(content.kanaType.displayName)：")
                .font(Constants.Typography.body)
                .foregroundColor(Constants.Colors.secondaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Constants.Spacing.md) {
                ForEach(content.kanaList) { kana in
                    KanaCard(kana: kana)
                }
            }
        }
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
    }
}

// MARK: - Kana Review Content View
struct KanaReviewContentView: View {
    let content: KanaReviewContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("複習假名")
                .font(Constants.Typography.h3)
                .foregroundColor(Constants.Colors.primaryText)
            
            Text("複習這些 \(content.kanaType.displayName)：")
                .font(Constants.Typography.body)
                .foregroundColor(Constants.Colors.secondaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: Constants.Spacing.md) {
                ForEach(content.reviewKana) { kana in
                    KanaCard(kana: kana)
                }
            }
        }
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
    }
}

// MARK: - Vocabulary Content View
struct VocabularyContentView: View {
    let content: VocabularyContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("學習單字")
                .font(Constants.Typography.h3)
                .foregroundColor(Constants.Colors.primaryText)
            
            ForEach(content.words) { word in
                VocabularyCard(word: word)
            }
        }
    }
}

// MARK: - External Resource Content View
struct ExternalResourceContentView: View {
    let content: ExternalResourceContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("外部資源")
                .font(Constants.Typography.h3)
                .foregroundColor(Constants.Colors.primaryText)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                Text(content.title)
                    .font(Constants.Typography.h4)
                    .foregroundColor(Constants.Colors.primaryText)
                
                if let description = content.description {
                    Text(description)
                        .font(Constants.Typography.body)
                        .foregroundColor(Constants.Colors.secondaryText)
                }
                
                if let duration = content.durationMinutes {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text("\(duration) 分鐘")
                            .font(Constants.Typography.caption)
                    }
                    .foregroundColor(Constants.Colors.secondaryText)
                }
                
                Link(destination: URL(string: content.url)!) {
                    HStack {
                        Text("開啟資源")
                        Image(systemName: "arrow.up.right.square")
                    }
                    .font(Constants.Typography.body)
                    .foregroundColor(Constants.Colors.primary)
                }
                .padding(.top, Constants.Spacing.sm)
            }
            .padding(Constants.Spacing.md)
            .background(Constants.Colors.cardBackground)
            .cornerRadius(Constants.CornerRadius.medium)
        }
    }
}

// MARK: - Kana Card Component
struct KanaCard: View {
    let kana: KanaItem
    @State private var showRomaji = false
    
    var body: some View {
        VStack(spacing: Constants.Spacing.sm) {
            Text(kana.kana)
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(Constants.Colors.primaryText)
            
            Text(showRomaji ? kana.romaji : "?")
                .font(Constants.Typography.caption)
                .foregroundColor(Constants.Colors.secondaryText)
                .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onTapGesture {
            withAnimation {
                showRomaji.toggle()
            }
        }
    }
}

// MARK: - Vocabulary Card Component
struct VocabularyCard: View {
    let word: VocabularyWord
    
    var body: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(word.word)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Constants.Colors.primaryText)
                        
                        if let kanji = word.wordKanji {
                            Text("(\(kanji))")
                                .font(Constants.Typography.body)
                                .foregroundColor(Constants.Colors.secondaryText)
                        }
                    }
                    
                    Text(word.reading)
                        .font(Constants.Typography.body)
                        .foregroundColor(Constants.Colors.secondaryText)
                }
                
                Spacer()
                
                StatusBadge(status: word.level, type: .learning)
            }
            
            Text(word.meaning)
                .font(Constants.Typography.h4)
                .foregroundColor(Constants.Colors.primary)
            
            if let example = word.exampleSentence,
               let exampleMeaning = word.exampleSentenceMeaning {
                Divider()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(example)
                        .font(Constants.Typography.body)
                        .foregroundColor(Constants.Colors.primaryText)
                    
                    Text(exampleMeaning)
                        .font(Constants.Typography.caption)
                        .foregroundColor(Constants.Colors.secondaryText)
                }
            }
        }
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - KanaType Extension
extension KanaType {
    var displayName: String {
        switch self {
        case .hiragana:
            return "平假名"
        case .katakana:
            return "片假名"
        }
    }
}

#Preview {
    TaskDetailView(
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
        viewModel: TaskViewModel()
    )
}
