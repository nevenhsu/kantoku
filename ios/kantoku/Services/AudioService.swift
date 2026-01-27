//
//  AudioService.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation
import AVFoundation
import Combine

/// 音訊服務
/// 負責錄音、播放、TTS 功能
@MainActor
class AudioService: NSObject, ObservableObject {
    static let shared = AudioService()
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private let speechSynthesizer = AVSpeechSynthesizer()
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingURL: URL?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Recording
    
    /// 請求麥克風權限
    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    /// 開始錄音
    func startRecording() throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default)
        try audioSession.setActive(true)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording_\(Date().timeIntervalSince1970).m4a")
        audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
        audioRecorder?.record()
        
        isRecording = true
        recordingURL = audioFilename
    }
    
    /// 停止錄音
    /// - Returns: 錄音文件 URL
    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        return recordingURL
    }
    
    // MARK: - Playback
    
    /// 播放音訊
    /// - Parameter url: 音訊文件 URL
    func playAudio(url: URL) throws {
        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.play()
        isPlaying = true
    }
    
    /// 停止播放
    func stopPlaying() {
        audioPlayer?.stop()
        isPlaying = false
    }
    
    // MARK: - Text-to-Speech
    
    /// 朗讀日文文字
    /// - Parameters:
    ///   - text: 要朗讀的文字
    ///   - rate: 語速 (0.0 - 1.0)，預設 0.4
    func speak(_ text: String, rate: Float = 0.4) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "ja-JP")
        utterance.rate = rate
        speechSynthesizer.speak(utterance)
    }
    
    /// 停止朗讀
    func stopSpeaking() {
        speechSynthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Helper
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
        }
    }
}
