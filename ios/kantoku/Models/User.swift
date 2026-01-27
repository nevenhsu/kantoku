//
//  User.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation

/// 用戶資料模型
struct UserProfile: Codable, Identifiable {
    let id: UUID
    var displayName: String?
    var dailyGoalMinutes: Int
    var streakDays: Int
    var skipRemaining: Int
    var settings: [String: String]
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case dailyGoalMinutes = "daily_goal_minutes"
        case streakDays = "streak_days"
        case skipRemaining = "skip_remaining"
        case settings
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// 用戶學習進度
struct UserProgress: Codable {
    let userId: UUID
    var currentStageId: Int
    var lastActivityAt: Date
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case currentStageId = "current_stage_id"
        case lastActivityAt = "last_activity_at"
    }
}

/// 學習統計
struct LearningStats: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let category: KanaType
    var totalItems: Int
    var masteredItems: Int
    var progressPercent: Int
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case category
        case totalItems = "total_items"
        case masteredItems = "mastered_items"
        case progressPercent = "progress_percent"
        case updatedAt = "updated_at"
    }
}

/// 假名類型
enum KanaType: String, Codable {
    case hiragana
    case katakana
}

/// 學習狀態
enum LearningStatus: String, Codable {
    case notStarted = "not_started"
    case learning
    case reviewing
    case mastered
}
