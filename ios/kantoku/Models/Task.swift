//
//  Task.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation

/// 任務模型
struct TaskModel: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let taskType: TaskType
    let content: TaskContent
    var status: TaskStatus
    let dueDate: Date
    var skipped: Bool
    let createdAt: Date
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case taskType = "task_type"
        case content
        case status
        case dueDate = "due_date"
        case skipped
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// 任務類型
enum TaskType: String, Codable {
    case kanaLearn = "kana_learn"
    case kanaReview = "kana_review"
    case vocabulary
    case externalResource = "external_resource"
    
    var displayName: String {
        switch self {
        case .kanaLearn: return "假名學習"
        case .kanaReview: return "假名複習"
        case .vocabulary: return "單字學習"
        case .externalResource: return "外部資源"
        }
    }
    
    var iconName: String {
        switch self {
        case .kanaLearn: return "text.book.closed"
        case .kanaReview: return "arrow.clockwise"
        case .vocabulary: return "character.book.closed"
        case .externalResource: return "link"
        }
    }
}

/// 任務狀態
enum TaskStatus: String, Codable {
    case pending
    case submitted
    case passed
    case failed
    
    var displayName: String {
        switch self {
        case .pending: return "待完成"
        case .submitted: return "審核中"
        case .passed: return "已通過"
        case .failed: return "未通過"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .submitted: return "blue"
        case .passed: return "green"
        case .failed: return "red"
        }
    }
}

/// 任務內容（根據不同類型有不同結構）
enum TaskContent: Codable {
    case kanaLearn(KanaLearnContent)
    case kanaReview(KanaReviewContent)
    case vocabulary(VocabularyContent)
    case externalResource(ExternalResourceContent)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let json = try container.decode([String: AnyCodable].self)
        
        // 根據內容判斷類型
        if let kanaList = json["kana_list"] {
            let content = try JSONDecoder().decode(KanaLearnContent.self, from: JSONEncoder().encode(json))
            self = .kanaLearn(content)
        } else if let reviewKana = json["review_kana"] {
            let content = try JSONDecoder().decode(KanaReviewContent.self, from: JSONEncoder().encode(json))
            self = .kanaReview(content)
        } else if let words = json["words"] {
            let content = try JSONDecoder().decode(VocabularyContent.self, from: JSONEncoder().encode(json))
            self = .vocabulary(content)
        } else {
            let content = try JSONDecoder().decode(ExternalResourceContent.self, from: JSONEncoder().encode(json))
            self = .externalResource(content)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .kanaLearn(let content):
            try container.encode(content)
        case .kanaReview(let content):
            try container.encode(content)
        case .vocabulary(let content):
            try container.encode(content)
        case .externalResource(let content):
            try container.encode(content)
        }
    }
}

/// 假名學習內容
struct KanaLearnContent: Codable {
    let kanaList: [KanaItem]
    let kanaType: KanaType
    
    enum CodingKeys: String, CodingKey {
        case kanaList = "kana_list"
        case kanaType = "kana_type"
    }
}

/// 假名複習內容
struct KanaReviewContent: Codable {
    let reviewKana: [KanaItem]
    let kanaType: KanaType
    
    enum CodingKeys: String, CodingKey {
        case reviewKana = "review_kana"
        case kanaType = "kana_type"
    }
}

/// 單字學習內容
struct VocabularyContent: Codable {
    let words: [VocabularyWord]
}

/// 外部資源內容
struct ExternalResourceContent: Codable {
    let resourceType: String
    let url: String
    let title: String
    let description: String?
    let durationMinutes: Int?
    
    enum CodingKeys: String, CodingKey {
        case resourceType = "resource_type"
        case url
        case title
        case description
        case durationMinutes = "duration_minutes"
    }
}

/// 假名項目
struct KanaItem: Codable, Identifiable {
    var id: String { kana }
    let kana: String
    let romaji: String
}

/// 單字
struct VocabularyWord: Codable, Identifiable {
    let id: UUID
    let word: String
    let wordKanji: String?
    let reading: String
    let meaning: String
    let level: String
    let exampleSentence: String?
    let exampleSentenceMeaning: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case word
        case wordKanji = "word_kanji"
        case reading
        case meaning
        case level
        case exampleSentence = "example_sentence"
        case exampleSentenceMeaning = "example_sentence_meaning"
    }
}

// Helper for decoding dynamic JSON
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}
