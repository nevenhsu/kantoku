//
//  AuthViewModel.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import Foundation
import SwiftUI
import Combine

/// 認證視圖模型
/// 處理登入、註冊、登出的業務邏輯和狀態管理
@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var displayName = ""
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    // Validation state
    @Published var emailError: String?
    @Published var passwordError: String?
    @Published var confirmPasswordError: String?
    
    private let authService = AuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Listen to auth state changes
        authService.$isAuthenticated
            .sink { [weak self] _ in
                self?.clearForm()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    
    private func validateEmail() -> Bool {
        email = email.trimmingCharacters(in: .whitespaces)
        
        if email.isEmpty {
            emailError = "請輸入電子郵件"
            return false
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            emailError = "電子郵件格式不正確"
            return false
        }
        
        emailError = nil
        return true
    }
    
    private func validatePassword() -> Bool {
        if password.isEmpty {
            passwordError = "請輸入密碼"
            return false
        }
        
        if password.count < 8 {
            passwordError = "密碼至少需要 8 個字符"
            return false
        }
        
        passwordError = nil
        return true
    }
    
    private func validateConfirmPassword() -> Bool {
        if confirmPassword.isEmpty {
            confirmPasswordError = "請確認密碼"
            return false
        }
        
        if password != confirmPassword {
            confirmPasswordError = "密碼不一致"
            return false
        }
        
        confirmPasswordError = nil
        return true
    }
    
    // MARK: - Actions
    
    /// 登入
    func signIn() async {
        // Clear previous errors
        clearErrors()
        
        // Validate
        guard validateEmail() && validatePassword() else {
            return
        }
        
        isLoading = true
        
        do {
            try await authService.signIn(email: email, password: password)
            // Success - navigation will be handled by the app based on isAuthenticated state
        } catch {
            errorMessage = handleAuthError(error)
            showError = true
        }
        
        isLoading = false
    }
    
    /// 註冊
    func signUp() async {
        // Clear previous errors
        clearErrors()
        
        // Validate
        guard validateEmail() && validatePassword() && validateConfirmPassword() else {
            return
        }
        
        isLoading = true
        
        do {
            try await authService.signUp(email: email, password: password)
            // Success - will need to create user profile in Supabase
            // For now, just let the auth state change handle navigation
        } catch {
            errorMessage = handleAuthError(error)
            showError = true
        }
        
        isLoading = false
    }
    
    /// 登出
    func signOut() async {
        isLoading = true
        
        do {
            try await authService.signOut()
        } catch {
            errorMessage = "登出失敗: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    /// 重設密碼
    func resetPassword() async {
        // Clear previous errors
        clearErrors()
        
        // Validate email only
        guard validateEmail() else {
            return
        }
        
        isLoading = true
        
        do {
            try await authService.resetPassword(email: email)
            errorMessage = "密碼重設郵件已發送，請檢查您的信箱"
            showError = true
        } catch {
            errorMessage = handleAuthError(error)
            showError = true
        }
        
        isLoading = false
    }
    
    // MARK: - Helpers
    
    private func clearForm() {
        email = ""
        password = ""
        confirmPassword = ""
        displayName = ""
        clearErrors()
    }
    
    private func clearErrors() {
        errorMessage = nil
        emailError = nil
        passwordError = nil
        confirmPasswordError = nil
        showError = false
    }
    
    private func handleAuthError(_ error: Error) -> String {
        // Map Supabase errors to user-friendly messages
        let errorDescription = error.localizedDescription.lowercased()
        
        if errorDescription.contains("invalid") && errorDescription.contains("credentials") {
            return "電子郵件或密碼不正確"
        } else if errorDescription.contains("user") && errorDescription.contains("already") {
            return "此電子郵件已被註冊"
        } else if errorDescription.contains("network") {
            return "網路連接失敗，請檢查網路設定"
        } else if errorDescription.contains("email") && errorDescription.contains("not") && errorDescription.contains("confirmed") {
            return "請先驗證您的電子郵件"
        } else {
            return "發生錯誤: \(error.localizedDescription)"
        }
    }
}
