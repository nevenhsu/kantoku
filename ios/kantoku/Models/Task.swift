//
//  Task.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation

/// 任務模型
struct TaskModel: Identifiable {
    let id: UUID
    let userId: UUID
    let taskType: TaskType
    let content: TaskContent
    var status: TaskStatus
    let dueDate: Date
    var skipped: Bool
    let createdAt: Date
    var updatedAt: Date
    
    // Default initializer
    init(
        id: UUID,
        userId: UUID,
        taskType: TaskType,
        content: TaskContent,
        status: TaskStatus,
        dueDate: Date,
        skipped: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.taskType = taskType
        self.content = content
        self.status = status
        self.dueDate = dueDate
        self.skipped = skipped
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Codable
extension TaskModel: Codable {
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
    
    // Custom decoder to handle both string and object content formats
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        userId = try container.decode(UUID.self, forKey: .userId)
        taskType = try container.decode(TaskType.self, forKey: .taskType)
        status = try container.decode(TaskStatus.self, forKey: .status)
        skipped = try container.decode(Bool.self, forKey: .skipped)
        
        // Handle date decoding
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let createdAtString = try? container.decode(String.self, forKey: .createdAt) {
            createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        } else {
            createdAt = try container.decode(Date.self, forKey: .createdAt)
        }
        
        if let updatedAtString = try? container.decode(String.self, forKey: .updatedAt) {
            updatedAt = dateFormatter.date(from: updatedAtString) ?? Date()
        } else {
            updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        }
        
        if let dueDateString = try? container.decode(String.self, forKey: .dueDate) {
            let dueDateFormatter = DateFormatter()
            dueDateFormatter.dateFormat = "yyyy-MM-dd"
            dueDate = dueDateFormatter.date(from: dueDateString) ?? Date()
        } else {
            dueDate = try container.decode(Date.self, forKey: .dueDate)
        }
        
        // Handle content: can be either a string (from Supabase JSONB) or object (from n8n)
        if let contentString = try? container.decode(String.self, forKey: .content) {
            // Content is stored as string in Supabase, need to parse it
            print("📦 Decoding content from string: \(contentString)")
            guard let contentData = contentString.data(using: .utf8) else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Content string cannot be converted to data"
                    )
                )
            }
            let contentDecoder = JSONDecoder()
            content = try contentDecoder.decode(TaskContent.self, from: contentData)
        } else {
            // Content is already an object (from n8n response)
            print("📦 Decoding content from object")
            content = try container.decode(TaskContent.self, forKey: .content)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(taskType, forKey: .taskType)
        try container.encode(content, forKey: .content)
        try container.encode(status, forKey: .status)
        try container.encode(dueDate, forKey: .dueDate)
        try container.encode(skipped, forKey: .skipped)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
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
        if json["kana_list"] != nil {
            // New format: array of kana items
            let content = try JSONDecoder().decode(KanaLearnContent.self, from: JSONEncoder().encode(json))
            self = .kanaLearn(content)
        } else if json["review_kana"] != nil {
            // New format: array of review kana items
            let content = try JSONDecoder().decode(KanaReviewContent.self, from: JSONEncoder().encode(json))
            self = .kanaReview(content)
        } else if json["kana"] != nil && json["type"] != nil {
            // Old format: single kana item (from n8n legacy format)
            // Convert to new format
            let kanaItem = KanaItem(
                kana: (json["kana"]?.value as? String) ?? "",
                romaji: (json["romaji"]?.value as? String) ?? ""
            )
            let kanaTypeStr = (json["type"]?.value as? String) ?? "hiragana"
            let kanaType = KanaType(rawValue: kanaTypeStr) ?? .hiragana
            
            // Check if it's a review or learn task based on description/prompt
            if let description = json["description"]?.value as? String, description.contains("複習") {
                let content = KanaReviewContent(reviewKana: [kanaItem], kanaType: kanaType)
                self = .kanaReview(content)
            } else {
                let content = KanaLearnContent(kanaList: [kanaItem], kanaType: kanaType)
                self = .kanaLearn(content)
            }
        } else if json["words"] != nil {
            let content = try JSONDecoder().decode(VocabularyContent.self, from: JSONEncoder().encode(json))
            self = .vocabulary(content)
        } else if json["resource_type"] != nil {
            let content = try JSONDecoder().decode(ExternalResourceContent.self, from: JSONEncoder().encode(json))
            self = .externalResource(content)
        } else {
            // Unknown content type, print for debugging
            print("⚠️ Unknown task content type. Keys: \(json.keys)")
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Unknown task content type. Available keys: \(json.keys)"
                )
            )
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

/// 假名類型
enum KanaType: String, Codable {
    case hiragana
    case katakana
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

// MARK: - Grouped Task for Dashboard

/// 任務分組類型
enum TaskGroupType: String {
    case learn = "learn"
    case review = "review"
    
    var displayName: String {
        switch self {
        case .learn: return "今日練習"
        case .review: return "今日複習"
        }
    }
    
    var iconName: String {
        switch self {
        case .learn: return "text.book.closed"
        case .review: return "arrow.clockwise"
        }
    }
    
    var description: String {
        switch self {
        case .learn: return "學習新的假名"
        case .review: return "複習已學假名"
        }
    }
}

/// 分組任務模型（用於首頁顯示）
struct GroupedTask: Identifiable {
    let id = UUID()
    let groupType: TaskGroupType
    let tasks: [TaskModel]
    
    /// 總假名數量
    var totalKanaCount: Int {
        tasks.reduce(0) { count, task in
            switch task.content {
            case .kanaLearn(let content):
                return count + content.kanaList.count
            case .kanaReview(let content):
                return count + content.reviewKana.count
            default:
                return count
            }
        }
    }
    
    /// 所有假名列表
    var allKana: [KanaItem] {
        tasks.flatMap { task -> [KanaItem] in
            switch task.content {
            case .kanaLearn(let content):
                return content.kanaList
            case .kanaReview(let content):
                return content.reviewKana
            default:
                return []
            }
        }
    }
    
    /// 假名類型
    var kanaType: KanaType? {
        for task in tasks {
            switch task.content {
            case .kanaLearn(let content):
                return content.kanaType
            case .kanaReview(let content):
                return content.kanaType
            default:
                continue
            }
        }
        return nil
    }
    
    /// 是否所有任務都已完成
    var isCompleted: Bool {
        tasks.allSatisfy { $0.status == .passed }
    }
    
    /// 完成進度 (0.0 - 1.0)
    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        let completedCount = tasks.filter { $0.status == .passed }.count
        return Double(completedCount) / Double(tasks.count)
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
