//
//  StorageService.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation
import Supabase

/// 文件存儲服務
/// 負責 Supabase Storage 檔案上傳、下載、刪除
class StorageService {
    static let shared = StorageService()
    
    private let supabase = SupabaseService.shared.client
    private let bucketName = "submissions"
    
    private init() {}
    
    // MARK: - Upload
    
    /// 上傳音訊文件
    /// - Parameters:
    ///   - fileURL: 本地文件 URL
    ///   - userId: 用戶 ID
    ///   - taskId: 任務 ID
    /// - Returns: 儲存路徑
    func uploadAudio(fileURL: URL, userId: UUID, taskId: UUID) async throws -> String {
        let fileExtension = fileURL.pathExtension
        let fileName = "\(userId.uuidString)/audio/\(taskId.uuidString)_\(Date().timeIntervalSince1970).\(fileExtension)"
        
        let fileData = try Data(contentsOf: fileURL)
        
        let file = File(
            name: fileName,
            data: fileData,
            fileName: fileName,
            contentType: "audio/m4a"
        )
        
        try await supabase.storage
            .from(bucketName)
            .upload(path: fileName, file: file, options: FileOptions(upsert: true))
        
        return fileName
    }
    
    /// 上傳圖片文件
    /// - Parameters:
    ///   - imageData: 圖片資料
    ///   - userId: 用戶 ID
    ///   - taskId: 任務 ID
    /// - Returns: 儲存路徑
    func uploadImage(imageData: Data, userId: UUID, taskId: UUID) async throws -> String {
        let fileName = "\(userId.uuidString)/images/\(taskId.uuidString)_\(Date().timeIntervalSince1970).jpg"
        
        let file = File(
            name: fileName,
            data: imageData,
            fileName: fileName,
            contentType: "image/jpeg"
        )
        
        try await supabase.storage
            .from(bucketName)
            .upload(path: fileName, file: file, options: FileOptions(upsert: true))
        
        return fileName
    }
    
    // MARK: - Download
    
    /// 獲取公開 URL
    /// - Parameter path: 文件路徑
    /// - Returns: 公開 URL
    func getPublicURL(path: String) -> URL? {
        return try? supabase.storage
            .from(bucketName)
            .getPublicURL(path: path)
    }
    
    /// 下載文件
    /// - Parameter path: 文件路徑
    /// - Returns: 文件資料
    func downloadFile(path: String) async throws -> Data {
        return try await supabase.storage
            .from(bucketName)
            .download(path: path)
    }
    
    // MARK: - Delete
    
    /// 刪除文件
    /// - Parameter path: 文件路徑
    func deleteFile(path: String) async throws {
        try await supabase.storage
            .from(bucketName)
            .remove(paths: [path])
    }
    
    /// 刪除用戶的所有文件
    /// - Parameter userId: 用戶 ID
    func deleteUserFiles(userId: UUID) async throws {
        let files = try await supabase.storage
            .from(bucketName)
            .list(path: userId.uuidString)
        
        let paths = files.map { "\(userId.uuidString)/\($0.name)" }
        try await supabase.storage
            .from(bucketName)
            .remove(paths: paths)
    }
}

// MARK: - Error Handling

extension StorageService {
    enum StorageError: LocalizedError {
        case invalidFileURL
        case uploadFailed(Error)
        case downloadFailed(Error)
        case deleteFailed(Error)
        
        var errorDescription: String? {
            switch self {
            case .invalidFileURL:
                return "無效的文件 URL"
            case .uploadFailed(let error):
                return "上傳失敗: \(error.localizedDescription)"
            case .downloadFailed(let error):
                return "下載失敗: \(error.localizedDescription)"
            case .deleteFailed(let error):
                return "刪除失敗: \(error.localizedDescription)"
            }
        }
    }
}
