//
//  Test.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation

/// 測驗
struct Test: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let category: TestCategory
    let progressMilestone: Int
    let questions: [TestQuestion]
    var answers: [String: String]?
    var score: Int?
    var passed: Bool?
    var weaknessItems: [String]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case category
        case progressMilestone = "progress_milestone"
        case questions
        case answers
        case score
        case passed
        case weaknessItems = "weakness_items"
        case createdAt = "created_at"
    }
}

/// 測驗類別
enum TestCategory: String, Codable {
    case hiragana
    case katakana
    case vocabularyN5 = "vocabulary_n5"
    
    var displayName: String {
        switch self {
        case .hiragana: return "平假名"
        case .katakana: return "片假名"
        case .vocabularyN5: return "N5 單字"
        }
    }
}

/// 測驗題目
struct TestQuestion: Codable, Identifiable {
    let id: UUID
    let questionType: QuestionType
    let prompt: String
    let options: [String]?
    let correctAnswer: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case questionType = "question_type"
        case prompt
        case options
        case correctAnswer = "correct_answer"
    }
}

/// 題目類型
enum QuestionType: String, Codable {
    case multipleChoice = "multiple_choice"
    case fillInBlank = "fill_in_blank"
    case matching
    case listening
    
    var displayName: String {
        switch self {
        case .multipleChoice: return "選擇題"
        case .fillInBlank: return "填空題"
        case .matching: return "配對題"
        case .listening: return "聽力題"
        }
    }
}
