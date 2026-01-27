//
//  SupabaseService.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation
import Supabase

/// Supabase 服務單例
/// 負責初始化 Supabase Client 並提供全局訪問
class SupabaseService {
    static let shared = SupabaseService()
    
    let client: SupabaseClient
    
    private init() {
        // 從 Info.plist 讀取配置
        guard let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let supabaseKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              let url = URL(string: supabaseURL) else {
            fatalError("Supabase configuration not found in Info.plist")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: supabaseKey
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
}
