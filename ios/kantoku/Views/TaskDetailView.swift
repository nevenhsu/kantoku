//
//  TaskDetailView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 任務詳情視圖 - 根據不同任務類型顯示不同內容
struct TaskDetailView: View {
    let taskModel: TaskModel
    let userId: UUID
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAudioRecording = false
    @State private var showImageUpload = false
    @StateObject private var submissionViewModel = SubmissionViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Spacing.lg) {
                    // Task Header
                    taskHeader
                    
                    // Task Content (根據任務類型顯示)
                    taskContent
                    
                    // Action Buttons
                    if taskModel.status == .pending {
                        actionButtons
                    }
                    
                    // Submission History (if exists)
                    if taskModel.status == .submitted || taskModel.status == .passed || taskModel.status == .failed {
                        submissionHistorySection
                    }
                    
                    Spacer()
                }
                .padding(Constants.Spacing.md)
            }
            .background(Constants.Colors.background)
            .navigationTitle(taskModel.taskType.displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showAudioRecording) {
                AudioRecordingView(
                    viewModel: submissionViewModel,
                    taskModel: taskModel,
                    userId: userId
                )
            }
            .sheet(isPresented: $showImageUpload) {
                ImageUploadView(
                    viewModel: submissionViewModel,
                    taskModel: taskModel,
                    userId: userId
                )
            }
        }
    }
    
    // MARK: - Task Header
    private var taskHeader: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
            HStack {
                Image(systemName: taskModel.taskType.iconName)
                    .font(.title2)
                    .foregroundColor(Constants.Colors.primary)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(taskModel.taskType.displayName)
                        .font(Constants.Typography.h3)
                        .foregroundColor(Constants.Colors.primaryText)
                    
                    Text("到期日：\(formattedDate(taskModel.dueDate))")
                        .font(Constants.Typography.caption)
                        .foregroundColor(Constants.Colors.secondaryText)
                }
                
                Spacer()
                
                TaskStatusBadge(status: taskModel.status)
            }
        }
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
    }
    
    // MARK: - Task Content
    @ViewBuilder
    private var taskContent: some View {
        switch taskModel.content {
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
        VStack(spacing: Constants.Spacing.md) {
            // Submission Type Selection
            Text("選擇提交方式")
                .font(Constants.Typography.h3)
                .foregroundColor(Constants.Colors.primaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: Constants.Spacing.md) {
                // Audio Submission Button
                Button {
                    showAudioRecording = true
                } label: {
                    VStack(spacing: Constants.Spacing.sm) {
                        Image(systemName: "mic.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Constants.Colors.primaryAccent)
                        
                        Text("音訊提交")
                            .font(Constants.Typography.body)
                            .foregroundColor(Constants.Colors.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Constants.Spacing.md)
                    .background(Constants.Colors.cardBackground)
                    .cornerRadius(Constants.CornerRadius.medium)
                }
                
                // Image Submission Button
                Button {
                    showImageUpload = true
                } label: {
                    VStack(spacing: Constants.Spacing.sm) {
                        Image(systemName: "photo.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Constants.Colors.orange)
                        
                        Text("圖片提交")
                            .font(Constants.Typography.body)
                            .foregroundColor(Constants.Colors.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(Constants.Spacing.md)
                    .background(Constants.Colors.cardBackground)
                    .cornerRadius(Constants.CornerRadius.medium)
                }
            }
            
            // Skip Button
            SecondaryButton(
                title: "跳過此任務",
                action: {
                    Task {
                        await viewModel.completeTask(taskModel)
                        dismiss()
                    }
                }
            )
        }
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
    }
    
    // MARK: - Submission History Section
    private var submissionHistorySection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            Text("提交狀態")
                .font(Constants.Typography.h3)
                .foregroundColor(Constants.Colors.primaryText)
            
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                
                Text(statusText)
                    .font(Constants.Typography.body)
                    .foregroundColor(Constants.Colors.secondaryText)
                
                Spacer()
                
                if taskModel.status == .submitted {
                    ProgressView()
                }
            }
            .padding(Constants.Spacing.md)
            .background(statusColor.opacity(0.1))
            .cornerRadius(Constants.CornerRadius.medium)
        }
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
    }
    
    // MARK: - Status Helpers
    private var statusIcon: String {
        switch taskModel.status {
        case .submitted:
            return "clock.fill"
        case .passed:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        default:
            return "circle"
        }
    }
    
    private var statusColor: Color {
        switch taskModel.status {
        case .submitted:
            return Constants.Colors.orange
        case .passed:
            return Constants.Colors.green
        case .failed:
            return Constants.Colors.red
        default:
            return Constants.Colors.secondaryText
        }
    }
    
    private var statusText: String {
        switch taskModel.status {
        case .submitted:
            return "AI 正在審核中，請稍候..."
        case .passed:
            return "恭喜通過！"
        case .failed:
            return "未通過，請查看反饋並重新提交"
        default:
            return "待提交"
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
                
                StatusBadge(text: word.level, color: Constants.Colors.primaryAccent)
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
        taskModel: TaskModel(
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
        userId: UUID(),
        viewModel: TaskViewModel()
    )
}
