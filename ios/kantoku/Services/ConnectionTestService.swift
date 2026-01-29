//
//  ConnectionTestService.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation
import Supabase
import Auth

/// 連接測試服務
/// 用於測試 Supabase 和 n8n 的連接狀態
class ConnectionTestService {
    static let shared = ConnectionTestService()
    
    private let supabase = SupabaseService.shared.client
    private let apiService = APIService.shared
    
    // 記錄測試中創建的資源，用於清理
    private var testTaskIds: [String] = []
    private var testUserId: String?  // 測試帳號的 user_id
    
    private init() {}
    
    // MARK: - 測試結果模型
    
    struct TestResult {
        let name: String
        let success: Bool
        let message: String
        let duration: TimeInterval
        let details: String?
        
        var emoji: String {
            success ? "✅" : "❌"
        }
    }
    
    // MARK: - Supabase 測試
    
    /// 測試 Supabase 基礎連接
    func testSupabaseConnection() async -> TestResult {
        let startTime = Date()
        
        do {
            // 測試基本的連接 - 查詢 learning_stages 表（公開讀取）
            // 這個表應該始終存在且可讀
            _ = try await supabase
                .from("learning_stages")
                .select("id")
                .limit(1)
                .execute()
            
            let duration = Date().timeIntervalSince(startTime)
            
            return TestResult(
                name: "Supabase 基礎連接",
                success: true,
                message: "連接成功",
                duration: duration,
                details: "URL: \(Constants.Environment.supabaseURL)"
            )
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            return TestResult(
                name: "Supabase 基礎連接",
                success: false,
                message: "連接失敗",
                duration: duration,
                details: error.localizedDescription
            )
        }
    }
    
    /// 測試 Supabase Auth
    func testSupabaseAuth() async -> TestResult {
        let startTime = Date()
        
        do {
            // 從配置讀取測試帳號
            let testEmail = Constants.Environment.testEmail
            let testPassword = Constants.Environment.testPassword
            
            // 嘗試用測試帳號登入
            let session = try await supabase.auth.signIn(
                email: testEmail,
                password: testPassword
            )
            
            let duration = Date().timeIntervalSince(startTime)
            
            // 記錄測試用戶 ID，用於後續清理測試數據
            testUserId = session.user.id.uuidString
            
            return TestResult(
                name: "Supabase Auth",
                success: true,
                message: "認證成功",
                duration: duration,
                details: "Test user ID: \(session.user.id.uuidString.prefix(8))..."
            )
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // 檢查錯誤類型
            let errorMessage = error.localizedDescription
            if errorMessage.contains("Invalid login credentials") {
                return TestResult(
                    name: "Supabase Auth",
                    success: false,
                    message: "測試帳號登入失敗",
                    duration: duration,
                    details: "請確認測試帳號已創建：\(Constants.Environment.testEmail)"
                )
            } else if errorMessage.contains("Email not confirmed") {
                return TestResult(
                    name: "Supabase Auth",
                    success: false,
                    message: "Email 未驗證",
                    duration: duration,
                    details: "請在 Supabase Dashboard 驗證測試帳號"
                )
            }
            
            return TestResult(
                name: "Supabase Auth",
                success: false,
                message: "Auth 服務錯誤",
                duration: duration,
                details: errorMessage
            )
        }
    }
    
    /// 測試 Supabase Database 查詢
    func testSupabaseDatabase() async -> TestResult {
        let startTime = Date()
        
        do {
            // 嘗試查詢 tasks 表（如果存在）
            try await supabase
                .from("tasks")
                .select()
                .limit(1)
                .execute()
            
            let duration = Date().timeIntervalSince(startTime)
            
            return TestResult(
                name: "Supabase Database",
                success: true,
                message: "資料庫查詢成功",
                duration: duration,
                details: "成功查詢 tasks 表"
            )
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // 如果是因為未登入導致的錯誤，這是正常的
            if error.localizedDescription.contains("JWT") {
                return TestResult(
                    name: "Supabase Database",
                    success: true,
                    message: "資料庫可用（需要登入）",
                    duration: duration,
                    details: "RLS 政策正常運作"
                )
            }
            
            return TestResult(
                name: "Supabase Database",
                success: false,
                message: "資料庫查詢失敗",
                duration: duration,
                details: error.localizedDescription
            )
        }
    }
    
    /// 測試 Supabase Storage
    func testSupabaseStorage() async -> TestResult {
        let startTime = Date()
        
        do {
            // 直接嘗試列出 submissions bucket 中的檔案
            // 這個操作不需要 admin 權限，只需要 bucket 的讀取權限
            _ = try await supabase.storage
                .from("submissions")
                .list()
            
            let duration = Date().timeIntervalSince(startTime)
            
            return TestResult(
                name: "Supabase Storage",
                success: true,
                message: "Storage 可用",
                duration: duration,
                details: "成功訪問 submissions bucket"
            )
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            let errorMessage = error.localizedDescription
            
            // 檢查是否為 bucket 不存在的錯誤
            if errorMessage.contains("not found") || errorMessage.contains("does not exist") {
                return TestResult(
                    name: "Supabase Storage",
                    success: false,
                    message: "submissions bucket 不存在",
                    duration: duration,
                    details: "請在 Supabase Dashboard 創建 submissions bucket"
                )
            }
            
            // 檢查是否為權限問題
            if errorMessage.contains("JWT") || errorMessage.contains("unauthorized") || errorMessage.contains("permission") || errorMessage.contains("policy") {
                return TestResult(
                    name: "Supabase Storage",
                    success: false,
                    message: "Storage 權限不足",
                    duration: duration,
                    details: "submissions bucket 存在但沒有讀取權限。請檢查 Storage Policies。"
                )
            }
            
            return TestResult(
                name: "Supabase Storage",
                success: false,
                message: "Storage 服務錯誤",
                duration: duration,
                details: errorMessage
            )
        }
    }
    
    // MARK: - n8n 測試
    
    /// 測試 n8n 基礎連接
    func testN8NConnection() async -> TestResult {
        let startTime = Date()
        
        do {
            // 測試 test-environment endpoint
            let response = try await apiService.post(
                endpoint: "/webhook/test-environment",
                body: ["test": true]
            )
            
            let duration = Date().timeIntervalSince(startTime)
            
            // 檢查回應
            if let responseDict = response as? [String: Any],
               let success = responseDict["success"] as? Bool,
               success {
                return TestResult(
                    name: "n8n 基礎連接",
                    success: true,
                    message: "連接成功",
                    duration: duration,
                    details: "Base URL: \(apiService.baseURL)"
                )
            } else {
                return TestResult(
                    name: "n8n 基礎連接",
                    success: true,
                    message: "n8n 服務可用",
                    duration: duration,
                    details: "收到回應但格式異常"
                )
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // n8n 可能回傳 404 但服務是可用的
            let errorMessage = error.localizedDescription
            if errorMessage.contains("404") {
                return TestResult(
                    name: "n8n 基礎連接",
                    success: true,
                    message: "n8n 服務可用",
                    duration: duration,
                    details: "test-environment endpoint 不存在，但服務正常運行"
                )
            }
            
            return TestResult(
                name: "n8n 基礎連接",
                success: false,
                message: "連接失敗",
                duration: duration,
                details: errorMessage
            )
        }
    }
    
    /// 測試 generate-tasks webhook
    func testGenerateTasksWebhook() async -> TestResult {
        let startTime = Date()
        
        do {
            // 使用測試帳號的 user_id（從 Auth 測試獲取）
            guard let userId = testUserId else {
                return TestResult(
                    name: "generate-tasks webhook",
                    success: false,
                    message: "測試失敗",
                    duration: 0,
                    details: "找不到測試帳號 user_id，請先執行 Auth 測試"
                )
            }
            
            let response = try await apiService.post(
                endpoint: "/webhook/generate-tasks",
                body: [
                    "user_id": userId,
                    "daily_goal_minutes": 30
                ]
            )
            
            let duration = Date().timeIntervalSince(startTime)
            
            // 檢查回應格式
            // n8n 可能返回陣列或物件
            
            // 格式 1: 直接返回任務陣列 [{kana: "き", ...}, ...]
            if let responseArray = response as? [[String: Any]] {
                // 檢查是否為有效的任務陣列（至少有一個必要欄位）
                let isValidTaskArray = responseArray.allSatisfy { task in
                    task["kana"] != nil || task["word"] != nil || task["task_type"] != nil
                }
                
                if isValidTaskArray {
                    // 記錄任務 ID（如果存在）
                    for task in responseArray {
                        if let taskId = task["id"] as? String {
                            testTaskIds.append(taskId)
                        }
                    }
                    
                    return TestResult(
                        name: "generate-tasks webhook",
                        success: true,
                        message: "Webhook 正常運作",
                        duration: duration,
                        details: "生成了 \(responseArray.count) 個任務"
                    )
                } else {
                    return TestResult(
                        name: "generate-tasks webhook",
                        success: false,
                        message: "任務格式錯誤",
                        duration: duration,
                        details: "收到陣列但缺少必要欄位（kana, word, task_type）"
                    )
                }
            }
            
            // 格式 2: 包裹在物件中 {tasks: [...]}
            else if let responseDict = response as? [String: Any],
                    let tasksArray = responseDict["tasks"] as? [[String: Any]] {
                // 記錄任務 ID
                for task in tasksArray {
                    if let taskId = task["id"] as? String {
                        testTaskIds.append(taskId)
                    }
                }
                
                return TestResult(
                    name: "generate-tasks webhook",
                    success: true,
                    message: "Webhook 正常運作",
                    duration: duration,
                    details: "生成了 \(tasksArray.count) 個任務"
                )
            }
            
            // 格式 3: 其他字典格式（錯誤）
            else if let responseDict = response as? [String: Any] {
                let responseKeys = responseDict.keys.joined(separator: ", ")
                return TestResult(
                    name: "generate-tasks webhook",
                    success: false,
                    message: "回應格式錯誤",
                    duration: duration,
                    details: "預期 [{task}...] 或 {tasks: [...]}, 收到: {\(responseKeys)}"
                )
            }
            
            // 未知格式
            else {
                return TestResult(
                    name: "generate-tasks webhook",
                    success: false,
                    message: "未知的回應格式",
                    duration: duration,
                    details: "無法解析回應數據類型"
                )
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            return TestResult(
                name: "generate-tasks webhook",
                success: false,
                message: "Webhook 調用失敗",
                duration: duration,
                details: error.localizedDescription
            )
        }
    }
    

    
    // MARK: - 清理測試數據
    
    /// 清理測試帳號創建的所有測試數據
    private func cleanupTestData() async {
        guard let userId = testUserId else {
            print("⚠️ 無測試 user_id，跳過清理")
            return
        }
        
        // 清空記錄的 IDs
        defer {
            testTaskIds.removeAll()
            testUserId = nil
        }
        
        do {
            // 刪除測試帳號創建的所有 tasks
            // submissions 會通過 CASCADE 自動刪除
            try await supabase
                .from("tasks")
                .delete()
                .eq("user_id", value: userId)
                .execute()
            
            print("✅ 已清理測試帳號 \(userId.prefix(8))... 的所有測試任務")
        } catch {
            print("⚠️ 清理測試數據失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 全部測試
    
    /// 執行所有測試
    func runAllTests() async -> [TestResult] {
        var results: [TestResult] = []
        
        // 清空之前的記錄
        testTaskIds.removeAll()
        testUserId = nil
        
        // Supabase 測試
        results.append(await testSupabaseConnection())
        results.append(await testSupabaseAuth())  // 這會設置 testUserId
        results.append(await testSupabaseDatabase())
        results.append(await testSupabaseStorage())
        
        // n8n 測試
        results.append(await testN8NConnection())
        results.append(await testGenerateTasksWebhook())  // 使用 testUserId 創建任務
        
        // 清理測試數據（刪除測試帳號的所有 tasks）
        await cleanupTestData()
        
        // 清理 auth session（最後執行）
        try? await supabase.auth.signOut()
        
        return results
    }
}
