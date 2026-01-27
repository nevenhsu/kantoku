//
//  AudioRecordingView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 音訊錄製視圖
/// 提供錄音、播放、提交功能
struct AudioRecordingView: View {
    @ObservedObject var viewModel: SubmissionViewModel
    let taskModel: TaskModel
    let userId: UUID
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Constants.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.Spacing.xl) {
                        // Task Info
                        taskInfoSection
                        
                        // Recording Control
                        recordingControlSection
                        
                        // Recording Display
                        if viewModel.recordedAudioURL != nil {
                            recordingDisplaySection
                        }
                        
                        // Submit Button
                        if viewModel.recordedAudioURL != nil {
                            submitSection
                        }
                        
                        Spacer()
                    }
                    .padding(Constants.Spacing.lg)
                }
            }
            .navigationTitle("音訊提交")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .alert("錯誤", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("確定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .overlay {
                if viewModel.isSubmitting {
                    submittingOverlay
                }
            }
        }
    }
    
    // MARK: - Task Info Section
    
    private var taskInfoSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
            Text(taskModel.taskType.displayName)
                .font(Constants.Typography.h3)
                .foregroundColor(Constants.Colors.primaryText)
            
            Text("請大聲朗讀以下內容")
                .font(Constants.Typography.body)
                .foregroundColor(Constants.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
    }
    
    // MARK: - Recording Control Section
    
    private var recordingControlSection: some View {
        VStack(spacing: Constants.Spacing.lg) {
            // Waveform Animation (Placeholder)
            ZStack {
                Circle()
                    .fill(viewModel.isRecording ? Constants.Colors.primaryAccent : Constants.Colors.cardBackground)
                    .frame(width: 200, height: 200)
                    .overlay {
                        Circle()
                            .stroke(Constants.Colors.primaryAccent.opacity(0.3), lineWidth: 2)
                            .scaleEffect(viewModel.isRecording ? 1.3 : 1.0)
                            .opacity(viewModel.isRecording ? 0 : 1)
                            .animation(
                                viewModel.isRecording ? 
                                    Animation.easeOut(duration: 1.5).repeatForever(autoreverses: false) : 
                                    .default,
                                value: viewModel.isRecording
                            )
                    }
                
                Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.white)
            }
            .onTapGesture {
                if viewModel.isRecording {
                    viewModel.stopRecording()
                } else {
                    Task {
                        await viewModel.startRecording()
                    }
                }
            }
            
            // Duration
            if viewModel.isRecording || viewModel.recordedAudioURL != nil {
                Text(viewModel.formattedDuration)
                    .font(Constants.Typography.h2)
                    .foregroundColor(Constants.Colors.primaryText)
                    .monospacedDigit()
            }
            
            // Instructions
            Text(viewModel.isRecording ? "點擊停止錄音" : "點擊開始錄音")
                .font(Constants.Typography.body)
                .foregroundColor(Constants.Colors.secondaryText)
        }
        .padding(Constants.Spacing.lg)
    }
    
    // MARK: - Recording Display Section
    
    private var recordingDisplaySection: some View {
        VStack(spacing: Constants.Spacing.md) {
            HStack {
                // Play/Pause Button
                Button {
                    if viewModel.isAudioPlaying {
                        viewModel.audioService.stopPlaying()
                    } else {
                        viewModel.playRecording()
                    }
                } label: {
                    HStack {
                        Image(systemName: viewModel.isAudioPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.title2)
                        
                        Text(viewModel.isAudioPlaying ? "暫停" : "播放錄音")
                            .font(Constants.Typography.body)
                    }
                    .foregroundColor(Constants.Colors.primaryAccent)
                    .padding(Constants.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Constants.Colors.primaryAccent.opacity(0.1))
                    .cornerRadius(Constants.CornerRadius.medium)
                }
                
                // Delete Button
                Button {
                    viewModel.deleteRecording()
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(Constants.Colors.red)
                        .padding(Constants.Spacing.md)
                        .background(Constants.Colors.red.opacity(0.1))
                        .cornerRadius(Constants.CornerRadius.medium)
                }
            }
        }
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
    }
    
    // MARK: - Submit Section
    
    private var submitSection: some View {
        PrimaryButton(
            title: "提交審核",
            icon: "checkmark.circle.fill",
            action: {
                Task {
                    await viewModel.submitAudio(taskId: taskModel.id, userId: userId)
                    
                    // 如果提交成功，關閉視圖
                    if viewModel.successMessage != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                }
            },
            isLoading: viewModel.isSubmitting
        )
    }
    
    // MARK: - Submitting Overlay
    
    private var submittingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: Constants.Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                VStack(spacing: Constants.Spacing.sm) {
                    Text(viewModel.isUploading ? "上傳中..." : "提交中...")
                        .font(Constants.Typography.h3)
                        .foregroundColor(.white)
                    
                    if viewModel.isUploading {
                        SwiftUI.ProgressView(value: viewModel.uploadProgress, total: 1.0)
                            .tint(.white)
                            .frame(width: 200)
                    }
                }
            }
            .padding(Constants.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// MARK: - Preview

#Preview {
    AudioRecordingView(
        viewModel: SubmissionViewModel(),
        taskModel: TaskModel(
            id: UUID(),
            userId: UUID(),
            taskType: .kanaLearn,
            content: .kanaLearn(KanaLearnContent(kanaList: [], kanaType: .hiragana)),
            status: .pending,
            dueDate: Date(),
            skipped: false,
            createdAt: Date(),
            updatedAt: Date()
        ),
        userId: UUID()
    )
}
