//
//  SupabaseService.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation
import Supabase
import Auth

/// Supabase 服務單例
/// 負責初始化 Supabase Client 並提供全局訪問
class SupabaseService {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        // 從 Constants 讀取配置
        let supabaseURL = Constants.Environment.supabaseURL
        let supabaseKey = Constants.Environment.supabaseAnonKey
        
        guard let url = URL(string: supabaseURL), !supabaseKey.isEmpty else {
            fatalError("Supabase configuration not found or invalid in Config.local.xcconfig")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: .init(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
    
    /// 獲取當前用戶 Session
    var currentSession: Session? {
        get async throws {
            try await client.auth.session
        }
    }
    
    /// 獲取當前用戶 ID
    var currentUserId: UUID? {
        get async throws {
            try await client.auth.session.user.id
        }
    }
    
    /// 獲取當前用戶（同步獲取快取的 session）
    var currentUser: User? {
        // 這裡我們依賴於 Supabase SDK 的快取機制
        // 實際上 auth.session 是非同步的，但通常我們可以使用 AuthService 的狀態
        AuthService.shared.currentUser
    }
}
