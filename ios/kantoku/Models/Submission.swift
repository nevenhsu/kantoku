//
//  Submission.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation

/// 提交記錄
struct Submission: Codable, Identifiable {
    let id: UUID
    let taskId: UUID
    let submissionType: SubmissionType
    let content: String
    var aiFeedback: AIFeedback?
    var score: Int?
    var passed: Bool?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case taskId = "task_id"
        case submissionType = "submission_type"
        case content
        case aiFeedback = "ai_feedback"
        case score
        case passed
        case createdAt = "created_at"
    }
}

/// 提交類型
enum SubmissionType: String, Codable {
    case text
    case audio
    case image
    
    var displayName: String {
        switch self {
        case .text: return "文字提交"
        case .audio: return "音訊提交"
        case .image: return "圖片提交"
        }
    }
    
    var iconName: String {
        switch self {
        case .text: return "text.bubble"
        case .audio: return "mic.fill"
        case .image: return "photo"
        }
    }
}

/// AI 反饋
struct AIFeedback: Codable {
    let overall: String
    let strengths: [String]?
    let improvements: [String]?
    let encouragement: String?
    
    enum CodingKeys: String, CodingKey {
        case overall
        case strengths
        case improvements
        case encouragement
    }
}
