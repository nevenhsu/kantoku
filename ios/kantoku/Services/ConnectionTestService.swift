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
            // 測試基本的 health check
            try await supabase
                .rpc("ping")
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
            // 檢查是否有當前 session
            if let session = try? await supabase.auth.session {
                let duration = Date().timeIntervalSince(startTime)
                return TestResult(
                    name: "Supabase Auth",
                    success: true,
                    message: "已登入",
                    duration: duration,
                    details: "User ID: \(session.user.id)"
                )
            } else {
                let duration = Date().timeIntervalSince(startTime)
                return TestResult(
                    name: "Supabase Auth",
                    success: true,
                    message: "未登入（正常狀態）",
                    duration: duration,
                    details: "可以進行註冊或登入測試"
                )
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            return TestResult(
                name: "Supabase Auth",
                success: false,
                message: "Auth 服務錯誤",
                duration: duration,
                details: error.localizedDescription
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
            // 列出 buckets
            let buckets = try await supabase.storage.listBuckets()
            let submissionsBucket = buckets.first { $0.name == "submissions" }
            
            let duration = Date().timeIntervalSince(startTime)
            
            if let bucket = submissionsBucket {
                return TestResult(
                    name: "Supabase Storage",
                    success: true,
                    message: "Storage 可用",
                    duration: duration,
                    details: "找到 submissions bucket (public: \(bucket.isPublic))"
                )
            } else {
                return TestResult(
                    name: "Supabase Storage",
                    success: false,
                    message: "submissions bucket 不存在",
                    duration: duration,
                    details: "找到 \(buckets.count) 個 buckets"
                )
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            return TestResult(
                name: "Supabase Storage",
                success: false,
                message: "Storage 服務錯誤",
                duration: duration,
                details: error.localizedDescription
            )
        }
    }
    
    // MARK: - n8n 測試
    
    /// 測試 n8n 基礎連接
    func testN8NConnection() async -> TestResult {
        let startTime = Date()
        
        do {
            // 測試 generate-tasks endpoint
            let response = try await apiService.post(
                endpoint: "/webhook/test-connection",
                body: ["test": true]
            )
            
            let duration = Date().timeIntervalSince(startTime)
            
            return TestResult(
                name: "n8n 基礎連接",
                success: true,
                message: "連接成功",
                duration: duration,
                details: "Base URL: \(apiService.baseURL)"
            )
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            
            // n8n 可能回傳 404 但服務是可用的
            if error.localizedDescription.contains("404") {
                return TestResult(
                    name: "n8n 基礎連接",
                    success: true,
                    message: "n8n 服務可用",
                    duration: duration,
                    details: "test-connection endpoint 不存在，但服務正常運行"
                )
            }
            
            return TestResult(
                name: "n8n 基礎連接",
                success: false,
                message: "連接失敗",
                duration: duration,
                details: error.localizedDescription
            )
        }
    }
    
    /// 測試 generate-tasks webhook
    func testGenerateTasksWebhook() async -> TestResult {
        let startTime = Date()
        
        do {
            let testUserId = UUID().uuidString
            let response = try await apiService.post(
                endpoint: "/webhook/generate-tasks",
                body: [
                    "user_id": testUserId,
                    "daily_goal_minutes": 30
                ]
            )
            
            let duration = Date().timeIntervalSince(startTime)
            
            if let tasks = response["tasks"] as? [[String: Any]] {
                return TestResult(
                    name: "generate-tasks webhook",
                    success: true,
                    message: "Webhook 正常運作",
                    duration: duration,
                    details: "生成了 \(tasks.count) 個任務"
                )
            } else {
                return TestResult(
                    name: "generate-tasks webhook",
                    success: false,
                    message: "回應格式錯誤",
                    duration: duration,
                    details: "無法解析 tasks 陣列"
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
    
    /// 測試 review-submission webhook
    func testReviewSubmissionWebhook() async -> TestResult {
        let startTime = Date()
        
        do {
            let testTaskId = UUID().uuidString
            let response = try await apiService.post(
                endpoint: "/webhook/review-submission",
                body: [
                    "task_id": testTaskId,
                    "submission_type": "text",
                    "content": "test"
                ]
            )
            
            let duration = Date().timeIntervalSince(startTime)
            
            if let success = response["success"] as? Bool, success {
                return TestResult(
                    name: "review-submission webhook",
                    success: true,
                    message: "Webhook 正常運作",
                    duration: duration,
                    details: "成功完成審核測試"
                )
            } else {
                return TestResult(
                    name: "review-submission webhook",
                    success: false,
                    message: "回應格式錯誤",
                    duration: duration,
                    details: "無法解析審核結果"
                )
            }
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            return TestResult(
                name: "review-submission webhook",
                success: false,
                message: "Webhook 調用失敗",
                duration: duration,
                details: error.localizedDescription
            )
        }
    }
    
    // MARK: - 全部測試
    
    /// 執行所有測試
    func runAllTests() async -> [TestResult] {
        var results: [TestResult] = []
        
        // Supabase 測試
        results.append(await testSupabaseConnection())
        results.append(await testSupabaseAuth())
        results.append(await testSupabaseDatabase())
        results.append(await testSupabaseStorage())
        
        // n8n 測試
        results.append(await testN8NConnection())
        results.append(await testGenerateTasksWebhook())
        results.append(await testReviewSubmissionWebhook())
        
        return results
    }
}
