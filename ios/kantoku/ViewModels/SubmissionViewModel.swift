//
//  SubmissionViewModel.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation
import SwiftUI
import UIKit
import Combine
import Supabase

/// 提交視圖模型
/// 管理任務提交、AI 審核、輪詢狀態
@MainActor
class SubmissionViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var isSubmitting = false
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Audio Recording
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var recordedAudioURL: URL?
    
    // Image Upload
    @Published var selectedImage: UIImage?
    
    // Submission Result
    @Published var currentSubmission: Submission?
    @Published var isPolling = false
    @Published var reviewResult: AIFeedback?
    
    // MARK: - Services
    
    private let audioService = AudioService.shared
    private let storageService = StorageService.shared
    private let apiService = APIService.shared
    private let supabase = SupabaseService.shared.client
    
    // MARK: - Timer
    
    private var recordingTimer: Timer?
    private var pollingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Audio Recording
    
    /// 開始錄音
    func startRecording() async {
        // 請求麥克風權限
        let hasPermission = await audioService.requestMicrophonePermission()
        guard hasPermission else {
            errorMessage = "需要麥克風權限才能錄音"
            return
        }
        
        do {
            try audioService.startRecording()
            isRecording = true
            recordingDuration = 0
            
            // 開始計時器
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.recordingDuration += 0.1
            }
        } catch {
            errorMessage = "錄音失敗: \(error.localizedDescription)"
        }
    }
    
    /// 停止錄音
    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        recordedAudioURL = audioService.stopRecording()
        isRecording = false
    }
    
    /// 播放錄音
    func playRecording() {
        guard let url = recordedAudioURL else { return }
        
        do {
            try audioService.playAudio(url: url)
        } catch {
            errorMessage = "播放失敗: \(error.localizedDescription)"
        }
    }
    
    /// 刪除錄音
    func deleteRecording() {
        if audioService.isPlaying {
            audioService.stopPlaying()
        }
        recordedAudioURL = nil
        recordingDuration = 0
    }
    
    // MARK: - Image Upload
    
    /// 選擇圖片
    func selectImage(_ image: UIImage) {
        selectedImage = image
    }
    
    /// 刪除圖片
    func deleteImage() {
        selectedImage = nil
    }
    
    // MARK: - Submission
    
    /// 提交音訊
    /// - Parameters:
    ///   - taskId: 任務 ID
    ///   - userId: 用戶 ID
    func submitAudio(taskId: UUID, userId: UUID) async {
        guard let audioURL = recordedAudioURL else {
            errorMessage = "請先錄製音訊"
            return
        }
        
        isSubmitting = true
        isUploading = true
        errorMessage = nil
        
        do {
            // 1. 上傳到 Supabase Storage
            uploadProgress = 0.3
            let storagePath = try await storageService.uploadAudio(
                fileURL: audioURL,
                userId: userId,
                taskId: taskId
            )
            
            // 2. 創建提交記錄
            uploadProgress = 0.6
            let submission = try await createSubmission(
                taskId: taskId,
                submissionType: .audio,
                content: storagePath
            )
            
            // 3. 調用 n8n AI 審核
            uploadProgress = 0.8
            try await triggerAIReview(submissionId: submission.id)
            
            // 4. 開始輪詢審核結果
            uploadProgress = 1.0
            currentSubmission = submission
            startPolling(submissionId: submission.id)
            
            successMessage = "提交成功！AI 正在審核中..."
            
        } catch {
            errorMessage = "提交失敗: \(error.localizedDescription)"
        }
        
        isSubmitting = false
        isUploading = false
    }
    
    /// 提交圖片
    /// - Parameters:
    ///   - taskId: 任務 ID
    ///   - userId: 用戶 ID
    func submitImage(taskId: UUID, userId: UUID) async {
        guard let image = selectedImage else {
            errorMessage = "請先選擇圖片"
            return
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            errorMessage = "圖片處理失敗"
            return
        }
        
        isSubmitting = true
        isUploading = true
        errorMessage = nil
        
        do {
            // 1. 上傳到 Supabase Storage
            uploadProgress = 0.3
            let storagePath = try await storageService.uploadImage(
                imageData: imageData,
                userId: userId,
                taskId: taskId
            )
            
            // 2. 創建提交記錄
            uploadProgress = 0.6
            let submission = try await createSubmission(
                taskId: taskId,
                submissionType: .image,
                content: storagePath
            )
            
            // 3. 調用 n8n AI 審核
            uploadProgress = 0.8
            try await triggerAIReview(submissionId: submission.id)
            
            // 4. 開始輪詢審核結果
            uploadProgress = 1.0
            currentSubmission = submission
            startPolling(submissionId: submission.id)
            
            successMessage = "提交成功！AI 正在審核中..."
            
        } catch {
            errorMessage = "提交失敗: \(error.localizedDescription)"
        }
        
        isSubmitting = false
        isUploading = false
    }
    
    // MARK: - Database Operations
    
    /// 創建提交記錄到資料庫
    private func createSubmission(
        taskId: UUID,
        submissionType: SubmissionType,
        content: String
    ) async throws -> Submission {
        let submission = Submission(
            id: UUID(),
            taskId: taskId,
            submissionType: submissionType,
            content: content,
            aiFeedback: nil,
            score: nil,
            passed: nil,
            createdAt: Date()
        )
        
        try await supabase
            .from("submissions")
            .insert(submission)
            .execute()
        
        return submission
    }
    
    /// 調用 n8n AI 審核
    private func triggerAIReview(submissionId: UUID) async throws {
        // 調用 n8n webhook 觸發 AI 審核流程
        // AI 會異步處理並將結果寫回資料庫
        let url = URL(string: "\(Constants.API.reviewSubmission)?submission_id=\(submissionId.uuidString)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw SubmissionError.reviewTriggerFailed
        }
    }
    
    // MARK: - Polling
    
    /// 開始輪詢審核結果
    /// - Parameter submissionId: 提交 ID
    private func startPolling(submissionId: UUID) {
        isPolling = true
        
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.checkReviewStatus(submissionId: submissionId)
            }
        }
    }
    
    /// 檢查審核狀態
    /// - Parameter submissionId: 提交 ID
    private func checkReviewStatus(submissionId: UUID) async {
        do {
            // 從資料庫查詢提交記錄
            let response: [Submission] = try await supabase
                .from("submissions")
                .select()
                .eq("id", value: submissionId.uuidString)
                .execute()
                .value
            
            guard let submission = response.first else { return }
            
            // 如果已經有 AI 反饋，停止輪詢
            if let feedback = submission.aiFeedback {
                stopPolling()
                currentSubmission = submission
                reviewResult = feedback
                
                if submission.passed == true {
                    successMessage = "恭喜通過！"
                } else {
                    errorMessage = "未通過，請查看反饋並再試一次"
                }
            }
            
        } catch {
            print("輪詢錯誤: \(error.localizedDescription)")
        }
    }
    
    /// 停止輪詢
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isPolling = false
    }
    
    // MARK: - Cleanup
    
    /// 重置所有狀態
    func reset() {
        stopPolling()
        deleteRecording()
        deleteImage()
        
        currentSubmission = nil
        reviewResult = nil
        errorMessage = nil
        successMessage = nil
        uploadProgress = 0
    }
    
    deinit {
        stopPolling()
        recordingTimer?.invalidate()
    }
}

// MARK: - Errors

extension SubmissionViewModel {
    enum SubmissionError: LocalizedError {
        case noAudioRecorded
        case noImageSelected
        case uploadFailed
        case reviewTriggerFailed
        case pollingTimeout
        
        var errorDescription: String? {
            switch self {
            case .noAudioRecorded:
                return "請先錄製音訊"
            case .noImageSelected:
                return "請先選擇圖片"
            case .uploadFailed:
                return "文件上傳失敗"
            case .reviewTriggerFailed:
                return "AI 審核啟動失敗"
            case .pollingTimeout:
                return "審核超時，請稍後查看結果"
            }
        }
    }
}

// MARK: - Helper

extension SubmissionViewModel {
    /// 格式化錄音時長
    var formattedDuration: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
