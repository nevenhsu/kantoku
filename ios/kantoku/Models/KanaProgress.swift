//
//  KanaProgress.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation

/// 假名學習進度
struct KanaProgress: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let kana: String
    let kanaType: KanaType
    var status: LearningStatus
    var correctCount: Int
    var incorrectCount: Int
    var masteryScore: Int
    var lastReviewed: Date?
    var nextReview: Date?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case kana
        case kanaType = "kana_type"
        case status
        case correctCount = "correct_count"
        case incorrectCount = "incorrect_count"
        case masteryScore = "mastery_score"
        case lastReviewed = "last_reviewed"
        case nextReview = "next_review"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    /// 正確率
    var accuracy: Double {
        let total = correctCount + incorrectCount
        guard total > 0 else { return 0 }
        return Double(correctCount) / Double(total)
    }
}

/// 單字學習進度
struct VocabularyProgress: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let wordId: UUID
    var status: VocabularyStatus
    var lastReviewed: Date?
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case wordId = "word_id"
        case status
        case lastReviewed = "last_reviewed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// 單字學習狀態
enum VocabularyStatus: String, Codable {
    case notStarted = "not_started"
    case learning
    case mastered
    
    var displayName: String {
        switch self {
        case .notStarted: return "未開始"
        case .learning: return "學習中"
        case .mastered: return "已掌握"
        }
    }
}
