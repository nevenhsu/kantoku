//
//  TaskViewModel.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation
import SwiftUI
import Combine
import Supabase
import Auth
import PostgREST
import Storage

/// 任務視圖模型 - 管理任務相關的業務邏輯和狀態
@MainActor
class TaskViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var tasks: [TaskModel] = []
    @Published var todayTasks: [TaskModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Statistics
    @Published var completedTasksCount = 0
    @Published var totalTasksCount = 0
    @Published var todayMinutes = 0
    @Published var dailyGoalMinutes = 30
    @Published var currentStreak = 0
    
    // Filtering
    @Published var selectedType: TaskType?
    @Published var selectedStatus: TaskStatus?
    @Published var searchText = ""
    
    // MARK: - Dependencies
    private let apiService: APIService
    private let supabaseService: SupabaseService
    
    // MARK: - Initialization
    init(apiService: APIService = .shared, supabaseService: SupabaseService = .shared) {
        self.apiService = apiService
        self.supabaseService = supabaseService
    }
    
    // MARK: - Computed Properties
    var filteredTasks: [TaskModel] {
        var filtered = tasks
        
        // Filter by type
        if let type = selectedType {
            filtered = filtered.filter { $0.taskType == type }
        }
        
        // Filter by status
        if let status = selectedStatus {
            filtered = filtered.filter { $0.status == status }
        }
        
        // Filter by search text (based on task type display name)
        if !searchText.isEmpty {
            filtered = filtered.filter { task in
                task.taskType.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var progressPercentage: Double {
        guard totalTasksCount > 0 else { return 0 }
        return Double(completedTasksCount) / Double(totalTasksCount)
    }
    
    var timeProgressPercentage: Double {
        guard dailyGoalMinutes > 0 else { return 0 }
        return min(Double(todayMinutes) / Double(dailyGoalMinutes), 1.0)
    }
    
    // MARK: - Public Methods
    
    /// 載入儀表板資料
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load today's tasks
            try await loadTodayTasks()
            
            // Load statistics
            try await loadStatistics()
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "載入資料失敗：\(error.localizedDescription)"
            print("❌ Dashboard load error: \(error)")
        }
    }
    
    /// 載入所有任務
    func loadAllTasks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = supabaseService.currentUser?.id else {
                throw TaskError.userNotAuthenticated
            }
            
            // TODO: Call Supabase to fetch all tasks
            // For now, using mock data
            tasks = generateMockTasks()
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "載入任務失敗：\(error.localizedDescription)"
            print("❌ Tasks load error: \(error)")
        }
    }
    
    /// 載入今日任務
    func loadTodayTasks() async throws {
        guard let userId = supabaseService.currentUser?.id else {
            throw TaskError.userNotAuthenticated
        }
        
        // TODO: Call Supabase to fetch today's tasks
        // For now, using mock data
        todayTasks = generateMockTasks().filter { task in
            Calendar.current.isDateInToday(task.createdAt)
        }
    }
    
    /// 載入統計資料
    func loadStatistics() async throws {
        guard let userId = supabaseService.currentUser?.id else {
            throw TaskError.userNotAuthenticated
        }
        
        // TODO: Call Supabase to fetch statistics
        // For now, using mock data
        completedTasksCount = 3
        totalTasksCount = 5
        todayMinutes = 18
        dailyGoalMinutes = 30
        currentStreak = 7
    }
    
    /// 生成每日任務（調用 n8n webhook）
    func generateDailyTasks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = supabaseService.currentUser?.id else {
                throw TaskError.userNotAuthenticated
            }
            
            // Call n8n webhook to generate tasks
            let generatedTasks = try await apiService.generateTasks(
                userId: userId,
                dailyGoalMinutes: dailyGoalMinutes
            )
            
            // Update local state
            tasks.append(contentsOf: generatedTasks)
            todayTasks = generatedTasks
            totalTasksCount += generatedTasks.count
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "生成任務失敗：\(error.localizedDescription)"
            print("❌ Task generation error: \(error)")
        }
    }
    
    /// 更新任務狀態
    func updateTaskStatus(_ task: TaskModel, status: TaskStatus) async {
        do {
            // TODO: Update in Supabase
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index].status = status
                
                // Update today's tasks if applicable
                if let todayIndex = todayTasks.firstIndex(where: { $0.id == task.id }) {
                    todayTasks[todayIndex].status = status
                }
                
                // Update statistics
                if status == .passed {
                    completedTasksCount += 1
                    // Note: estimatedMinutes needs to be calculated from task type
                }
            }
        } catch {
            errorMessage = "更新任務狀態失敗：\(error.localizedDescription)"
            print("❌ Task status update error: \(error)")
        }
    }
    
    /// 標記任務為已完成
    func completeTask(_ task: TaskModel) async {
        await updateTaskStatus(task, status: .passed)
    }
    
    /// 開始任務（提交審核）
    func submitTask(_ task: TaskModel) async {
        await updateTaskStatus(task, status: .submitted)
    }
    
    /// 重置過濾器
    func resetFilters() {
        selectedType = nil
        selectedStatus = nil
        searchText = ""
    }
    
    // MARK: - Private Methods
    
    /// 生成模擬任務資料（用於開發測試）
    private func generateMockTasks() -> [TaskModel] {
        let now = Date()
        let calendar = Calendar.current
        
        return [
            TaskModel(
                id: UUID(),
                userId: UUID(),
                taskType: .kanaLearn,
                content: .kanaLearn(KanaLearnContent(
                    kanaList: [
                        KanaItem(kana: "あ", romaji: "a"),
                        KanaItem(kana: "い", romaji: "i"),
                        KanaItem(kana: "う", romaji: "u"),
                        KanaItem(kana: "え", romaji: "e"),
                        KanaItem(kana: "お", romaji: "o")
                    ],
                    kanaType: .hiragana
                )),
                status: .pending,
                dueDate: calendar.date(byAdding: .day, value: 1, to: now)!,
                skipped: false,
                createdAt: now,
                updatedAt: now
            ),
            TaskModel(
                id: UUID(),
                userId: UUID(),
                taskType: .vocabulary,
                content: .vocabulary(VocabularyContent(
                    words: [
                        VocabularyWord(
                            id: UUID(),
                            word: "おはよう",
                            wordKanji: nil,
                            reading: "ohayou",
                            meaning: "早安",
                            level: "N5",
                            exampleSentence: "おはようございます。",
                            exampleSentenceMeaning: "早安。（禮貌）"
                        ),
                        VocabularyWord(
                            id: UUID(),
                            word: "こんにちは",
                            wordKanji: nil,
                            reading: "konnichiwa",
                            meaning: "你好",
                            level: "N5",
                            exampleSentence: "こんにちは、元気ですか。",
                            exampleSentenceMeaning: "你好，你好嗎？"
                        )
                    ]
                )),
                status: .pending,
                dueDate: calendar.date(byAdding: .day, value: 1, to: now)!,
                skipped: false,
                createdAt: now,
                updatedAt: now
            ),
            TaskModel(
                id: UUID(),
                userId: UUID(),
                taskType: .kanaReview,
                content: .kanaReview(KanaReviewContent(
                    reviewKana: [
                        KanaItem(kana: "か", romaji: "ka"),
                        KanaItem(kana: "き", romaji: "ki"),
                        KanaItem(kana: "く", romaji: "ku"),
                        KanaItem(kana: "け", romaji: "ke"),
                        KanaItem(kana: "こ", romaji: "ko")
                    ],
                    kanaType: .hiragana
                )),
                status: .passed,
                dueDate: now,
                skipped: false,
                createdAt: calendar.date(byAdding: .day, value: -1, to: now)!,
                updatedAt: now
            )
        ]
    }
}

// MARK: - Error Types
enum TaskError: LocalizedError {
    case userNotAuthenticated
    case invalidTaskData
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "使用者未登入"
        case .invalidTaskData:
            return "任務資料格式錯誤"
        case .networkError(let error):
            return "網路錯誤：\(error.localizedDescription)"
        }
    }
}
