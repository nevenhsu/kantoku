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
    @Published var groupedTasks: [GroupedTask] = []  // 分組任務（練習/複習）
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
            // Load today's tasks from database
            try await loadTodayTasks()
            
            // Load statistics
            try await loadStatistics()
            
            // Check if we need to generate tasks for today
            // Check if any tasks were created today (regardless of status)
            // This prevents re-generating tasks when user completes all tasks
            let hasTasksToday = try await hasGeneratedTasksToday()
            
            if !hasTasksToday {
                print("📋 No tasks generated today, calling n8n to generate new tasks...")
                await generateDailyTasks()
            } else {
                print("✅ Tasks already generated for today")
            }
            
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
            guard let userId = try await supabaseService.currentUserId else {
                throw TaskError.userNotAuthenticated
            }
            
            // Only fetch tasks for this user
            let tasks: [TaskModel] = try await supabaseService.client
                .from("tasks")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.tasks = tasks
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "載入任務失敗：\(error.localizedDescription)"
            print("❌ Tasks load error: \(error)")
        }
    }
    
    /// 載入今日任務
    func loadTodayTasks() async throws {
        guard let userId = try await supabaseService.currentUserId else {
            throw TaskError.userNotAuthenticated
        }
        
        // Get today's date string (ISO format YYYY-MM-DD)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayStr = dateFormatter.string(from: Date())
        
        // Fetch tasks due today or pending overdue tasks
        // Note: For simplicity we fetch tasks due today. 
        // In a real app we might want specific logic for "today's view"
        print("🔍 Loading today's tasks for user: \(userId)")
        let tasks: [TaskModel] = try await supabaseService.client
            .from("tasks")
            .select()
            .eq("user_id", value: userId)
            .lte("due_date", value: todayStr) // Due today or earlier
            .neq("status", value: "passed")   // Not completed
            .order("due_date", ascending: true)
            .execute()
            .value
        
        print("✅ Loaded \(tasks.count) today's tasks")
        self.todayTasks = tasks
        
        // 更新分組任務
        updateGroupedTasks()
    }
    
    /// 檢查今天是否已經生成過任務（不論任務狀態）
    func hasGeneratedTasksToday() async throws -> Bool {
        guard let userId = try await supabaseService.currentUserId else {
            throw TaskError.userNotAuthenticated
        }
        
        // Get today's date range
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayStr = dateFormatter.string(from: today)
        
        // Check if there are any tasks created today (regardless of status)
        print("🔍 Checking if tasks were generated today: \(todayStr)")
        let count = try await supabaseService.client
            .from("tasks")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId)
            .gte("created_at", value: "\(todayStr)T00:00:00Z")
            .execute()
            .count ?? 0
        
        print("✅ Found \(count) tasks created today")
        return count > 0
    }
    
    /// 將任務分組為練習和複習
    private func updateGroupedTasks() {
        var groups: [GroupedTask] = []
        
        // 分組練習任務 (kana_learn)
        let learnTasks = todayTasks.filter { $0.taskType == .kanaLearn }
        if !learnTasks.isEmpty {
            groups.append(GroupedTask(groupType: .learn, tasks: learnTasks))
        }
        
        // 分組複習任務 (kana_review)
        let reviewTasks = todayTasks.filter { $0.taskType == .kanaReview }
        if !reviewTasks.isEmpty {
            groups.append(GroupedTask(groupType: .review, tasks: reviewTasks))
        }
        
        self.groupedTasks = groups
        print("✅ Grouped tasks: \(groups.count) groups (learn: \(learnTasks.count), review: \(reviewTasks.count))")
    }
    
    /// 載入統計資料
    func loadStatistics() async throws {
        guard let userId = try await supabaseService.currentUserId else {
            throw TaskError.userNotAuthenticated
        }
        
        // 1. Get Completed Tasks Count
        let completedCount = try await supabaseService.client
            .from("tasks")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId)
            .eq("status", value: "passed")
            .execute()
            .count ?? 0
            
        self.completedTasksCount = completedCount
        
        // 2. Get Total Tasks Count
        let totalCount = try await supabaseService.client
            .from("tasks")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId)
            .execute()
            .count ?? 0
            
        self.totalTasksCount = totalCount
        
        // 3. Fetch Profile for Streak & Goal info
        struct ProfileStats: Decodable {
            let dailyGoalMinutes: Int?
            let streakDays: Int?
            
            enum CodingKeys: String, CodingKey {
                case dailyGoalMinutes = "daily_goal_minutes"
                case streakDays = "streak_days"
            }
        }
        
        if let profile: ProfileStats = try? await supabaseService.client
            .from("profiles")
            .select("daily_goal_minutes, streak_days")
            .eq("id", value: userId)
            .single()
            .execute()
            .value {
            
            self.dailyGoalMinutes = profile.dailyGoalMinutes ?? 30
            self.currentStreak = profile.streakDays ?? 0
        }
        
        // Note: "todayMinutes" calculation would typically require summing up 
        // duration of completed tasks or fetching a separate 'daily_progress' table.
        // Keeping mock value for now as we don't have task duration easily available yet.
        self.todayMinutes = 0 
    }
    
    /// 生成每日任務（調用 n8n webhook）
    func generateDailyTasks() async {
        isLoading = true
        errorMessage = nil
        
        do {
            guard let userId = try await supabaseService.currentUserId else {
                throw TaskError.userNotAuthenticated
            }
            
            // Call n8n webhook to generate tasks
            // The webhook generates tasks and inserts them into Supabase
            let generatedTasks = try await apiService.generateTasks(
                userId: userId,
                dailyGoalMinutes: dailyGoalMinutes
            )
            
            print("✅ Generated \(generatedTasks.count) tasks, now reloading from database...")
            
            // Reload today's tasks from database to get the complete data
            try await loadTodayTasks()
            
            // Also reload statistics
            try await loadStatistics()
            
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
            // Update in Supabase
            struct StatusUpdate: Encodable {
                let status: TaskStatus
                let updated_at: Date = Date()
            }
            
            try await supabaseService.client
                .from("tasks")
                .update(StatusUpdate(status: status))
                .eq("id", value: task.id)
                .execute()
            
            // Update local state
            if let index = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[index].status = status
                tasks[index].updatedAt = Date()
                
                // Update today's tasks if applicable
                if let todayIndex = todayTasks.firstIndex(where: { $0.id == task.id }) {
                    todayTasks[todayIndex].status = status
                    todayTasks[todayIndex].updatedAt = Date()
                }
                
                // Reload stats if task is completed
                if status == .passed {
                    try? await loadStatistics()
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
