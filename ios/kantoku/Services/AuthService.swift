//
//  AuthService.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation
import Supabase
import Combine
import Auth

/// 認證服務
/// 處理用戶註冊、登入、登出等操作
@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()
    
    private let supabase = SupabaseService.shared.client
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    
    private init() {
        Task {
            await checkAuthStatus()
        }
    }
    
    /// 檢查認證狀態
    func checkAuthStatus() async {
        do {
            let session = try await supabase.auth.session
            self.currentUser = session.user
            self.isAuthenticated = true
        } catch {
            self.currentUser = nil
            self.isAuthenticated = false
        }
    }
    
    /// 註冊新用戶
    /// - Parameters:
    ///   - email: 電子郵件
    ///   - password: 密碼
    func signUp(email: String, password: String) async throws {
        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        
        self.currentUser = response.user
        self.isAuthenticated = true
    }
    
    /// 登入
    /// - Parameters:
    ///   - email: 電子郵件
    ///   - password: 密碼
    func signIn(email: String, password: String) async throws {
        let response = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        
        self.currentUser = response.user
        self.isAuthenticated = true
    }
    
    /// 登出
    func signOut() async throws {
        try await supabase.auth.signOut()
        self.currentUser = nil
        self.isAuthenticated = false
    }
    
    /// 重設密碼（發送郵件）
    /// - Parameter email: 電子郵件
    func resetPassword(email: String) async throws {
        try await supabase.auth.resetPasswordForEmail(email)
    }
    
    /// 更新密碼
    /// - Parameter newPassword: 新密碼
    func updatePassword(newPassword: String) async throws {
        try await supabase.auth.update(user: UserAttributes(password: newPassword))
    }
}
