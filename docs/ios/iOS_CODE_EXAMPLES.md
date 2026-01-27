# Kantoku - 代碼範例參考

本文件包含 Swift 與後端串接的代碼範例，供開發時參考。

---

## Swift Services

### APIService - n8n Webhook 呼叫

```swift
import Foundation

class APIService {
    static let shared = APIService()
    
    private let n8nBaseURL = "http://localhost:5678" // 開發環境
    
    // 生成任務
    func generateTasks(userId: UUID, dailyGoalMinutes: Int) async throws -> [Task] {
        let url = URL(string: "\(n8nBaseURL)/webhook/generate-tasks")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "user_id": userId.uuidString,
            "daily_goal_minutes": dailyGoalMinutes
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TaskGenerationResponse.self, from: data)
        
        return response.tasks
    }
    
    // 提交任務審核
    func submitTask(taskId: UUID, type: SubmissionType, content: String) async throws -> SubmissionResult {
        let url = URL(string: "\(n8nBaseURL)/webhook/review-submission")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "task_id": taskId.uuidString,
            "submission_type": type.rawValue,
            "content": content
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let result = try JSONDecoder().decode(SubmissionResult.self, from: data)
        
        return result
    }
}
```

---

### AudioService - 音訊錄製/播放

```swift
import AVFoundation

class AudioService: NSObject, ObservableObject {
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    
    @Published var isRecording = false
    @Published var isPlaying = false
    
    // 開始錄音
    func startRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.record()
        isRecording = true
    }
    
    // 停止錄音
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        return audioRecorder?.url
    }
    
    // 播放音訊
    func playAudio(url: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.play()
        isPlaying = true
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
```

---

### AuthService - Supabase Auth 整合

```swift
import Supabase

class AuthService: ObservableObject {
    let client = SupabaseClient(
        supabaseURL: URL(string: "YOUR_SUPABASE_URL")!,
        supabaseKey: "YOUR_SUPABASE_ANON_KEY"
    )
    
    @Published var currentUser: User?
    
    // 註冊
    func signUp(email: String, password: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password
        )
        currentUser = response.user
    }
    
    // 登入
    func signIn(email: String, password: String) async throws {
        let response = try await client.auth.signIn(
            email: email,
            password: password
        )
        currentUser = response.user
    }
    
    // 登出
    func signOut() async throws {
        try await client.auth.signOut()
        currentUser = nil
    }
}
```

---

### TTSService - 文字轉語音（iOS 內建 TTS）

```swift
import AVFoundation

class TTSService {
    let synthesizer = AVSpeechSynthesizer()
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = 0.4  // 放慢速度方便學習
        synthesizer.speak(utterance)
    }
}

// 使用範例
// ttsService.speak("あ")      // 唸出「あ」
// ttsService.speak("さかな")  // 唸出「魚」
```

---

## 間隔重複演算法

```swift
import Foundation

struct SpacedRepetition {
    // 間隔天數
    static let intervals = [1, 3, 7, 14, 30, 60, 120]
    
    // 計算下次複習時間
    static func calculateNextReview(correctCount: Int, wasCorrect: Bool) -> Date {
        if !wasCorrect {
            // 答錯：重置到第一個間隔
            return Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        }
        
        // 答對：進入下一個間隔
        let intervalIndex = min(correctCount, intervals.count - 1)
        let days = intervals[intervalIndex]
        return Calendar.current.date(byAdding: .day, value: days, to: Date())!
    }
    
    // 計算 mastery score
    static func calculateMasteryScore(correct: Int, incorrect: Int) -> Int {
        let total = correct + incorrect
        if total == 0 { return 0 }
        
        let accuracy = Double(correct) / Double(total)
        let recency = min(Double(correct), 10.0) / 10.0
        
        return Int(accuracy * recency * 100)
    }
}
```

---

## 環境常數

```swift
enum Constants {
    // n8n
    static let n8nBaseURL = "http://localhost:5678" // 開發環境
    static let n8nWebhookTaskGeneration = "/webhook/generate-tasks"
    static let n8nWebhookSubmissionReview = "/webhook/review-submission"
    static let n8nWebhookTestGeneration = "/webhook/generate-test"
    static let n8nWebhookTestGrading = "/webhook/grade-test"
    
    // Supabase
    static let supabaseURL = "YOUR_SUPABASE_URL"
    static let supabaseAnonKey = "YOUR_SUPABASE_ANON_KEY"
}
```

---

## Swift Package Manager 依賴

```swift
// Package.swift dependencies
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.0.0")
]
```

---

## n8n 教學

### 啟動 n8n

```bash
cd /Users/neven/Documents/projects/kantoku
docker-compose up -d
```

### 停止 n8n

```bash
docker-compose down
```

### 查看 n8n 狀態

```bash
docker-compose ps
```

### 訪問 n8n

```
http://localhost:5678
```

---

## n8n 環境變數設定

在 n8n 的 Credentials 中設定：
- Supabase URL
- Supabase Service Role Key
- Gemini API Key

---

## 單字資料結構範例

```json
{
  "id": "uuid",
  "word": "さかな",
  "word_kanji": "魚",
  "reading": "sakana",
  "meaning": "魚",
  "level": "N5",
  "category": "名詞",
  "required_kana": ["さ", "か", "な"],
  "required_kana_types": ["hiragana"],
  "min_stage": 5,
  "has_dakuten": false,
  "has_youon": false,
  "example_sentence": "さかなをたべます。",
  "example_sentence_meaning": "吃魚。"
}
```

---

## AI 任務生成邏輯

```
1. 查詢使用者當前階段
   - 已學會的假名清單（mastery_score > 70）
   - 當前學習階段編號

2. 生成今日任務
   - 新學習：選擇下一行的 5 個假名
   - 複習：根據間隔重複演算法選擇待複習假名
   - 弱項加強：選擇錯誤率高的假名

3. 選擇相關單字
   - 查詢 required_kana ⊆ 已學假名 的單字
   - 優先選擇：
     a. 使用最新學會假名的單字
     b. 高頻實用單字
     c. 尚未學過的單字
   - 每次 3-5 個單字

4. 任務組合
   - 假名學習/複習任務 (60%)
   - 相關單字學習任務 (40%)
```
