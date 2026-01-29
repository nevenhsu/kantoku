//
//  APIService.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation

/// API 服務
/// 負責與 n8n Webhook 通訊
class APIService {
    static let shared = APIService()
    
    let baseURL: String
    
    private init() {
        // 從 Constants 讀取 n8n URL
        self.baseURL = Constants.Environment.n8nBaseURL
    }
    
    // MARK: - Task Generation
    
    /// 生成每日任務
    /// - Parameters:
    ///   - userId: 用戶 ID
    ///   - dailyGoalMinutes: 每日目標分鐘數
    /// - Returns: 任務列表
    func generateTasks(userId: UUID, dailyGoalMinutes: Int) async throws -> [TaskModel] {
        let url = URL(string: "\(baseURL)\(Constants.API.generateTasks)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "user_id": userId.uuidString,
            "daily_goal_minutes": dailyGoalMinutes
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TaskGenerationResponse.self, from: data)
        
        return response.tasks
    }
    
    /// 通用的 POST 請求（用於測試）
    func post(endpoint: String, body: [String: Any]) async throws -> Any {
        let url = URL(string: "\(baseURL)\(endpoint)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 檢查 HTTP 狀態碼
        if let httpResponse = response as? HTTPURLResponse {
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NSError(domain: "APIService", code: httpResponse.statusCode, 
                            userInfo: [NSLocalizedDescriptionKey: "HTTP \(httpResponse.statusCode): \(errorMessage)"])
            }
        }
        
        // 檢查是否為空響應
        guard !data.isEmpty else {
            throw NSError(domain: "APIService", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Empty response from server. Please ensure the n8n workflow ends with a 'Respond to Webhook' node."])
        }
        
        // 嘗試解析 JSON（可能是物件或陣列）
        guard let json = try? JSONSerialization.jsonObject(with: data) else {
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode"
            throw NSError(domain: "APIService", code: -1, 
                        userInfo: [NSLocalizedDescriptionKey: "Invalid JSON: \(responseString)"])
        }
        
        return json
    }
    
    // MARK: - Submission Review
    
    /// 提交任務審核
    /// - Parameters:
    ///   - taskId: 任務 ID
    ///   - submissionType: 提交類型
    ///   - content: 提交內容
    /// - Returns: 審核結果
    func submitTaskReview(taskId: UUID, submissionType: SubmissionType, content: String) async throws -> SubmissionResult {
        let url = URL(string: "\(baseURL)\(Constants.API.reviewSubmission)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "task_id": taskId.uuidString,
            "submission_type": submissionType.rawValue,
            "content": content
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(SubmissionResult.self, from: data)
        
        return result
    }
    
    // MARK: - Test Generation & Grading
    
    /// 生成測驗
    /// - Parameter userId: 用戶 ID
    /// - Returns: 測驗內容
    func generateTest(userId: UUID) async throws -> Test {
        let url = URL(string: "\(baseURL)\(Constants.API.generateTest)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "user_id": userId.uuidString
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let test = try JSONDecoder().decode(Test.self, from: data)
        
        return test
    }
    
    /// 提交測驗評分
    /// - Parameters:
    ///   - testId: 測驗 ID
    ///   - answers: 答案列表
    /// - Returns: 評分結果
    func gradeTest(testId: UUID, answers: [TestAnswer]) async throws -> TestResult {
        let url = URL(string: "\(baseURL)\(Constants.API.gradeTest)")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "test_id": testId.uuidString,
            "answers": answers.map { ["question_id": $0.questionId.uuidString, "answer": $0.answer] }
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(TestResult.self, from: data)
        
        return result
    }
}

// MARK: - Response Models

struct TaskGenerationResponse: Codable {
    let tasks: [TaskModel]
}

struct SubmissionResult: Codable {
    let id: UUID
    let passed: Bool
    let score: Int
    let feedback: String
}

struct TestAnswer {
    let questionId: UUID
    let answer: String
}

struct TestResult: Codable {
    let id: UUID
    let score: Int
    let totalQuestions: Int
    let correctAnswers: Int
    let feedback: String
}
