//
//  SignUpView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 註冊視圖
struct SignUpView: View {
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var agreedToTerms = false
    
    var body: some View {
        ZStack {
            // Background
            Constants.Colors.background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Constants.Spacing.xl) {
                    // Header Section
                    VStack(spacing: Constants.Spacing.md) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(Constants.Colors.primary)
                            .padding(.top, Constants.Spacing.lg)
                        
                        Text("建立帳號")
                            .font(Constants.Typography.h1)
                            .foregroundColor(Constants.Colors.primaryText)
                        
                        Text("開始您的日語學習之旅")
                            .font(Constants.Typography.caption)
                            .foregroundColor(Constants.Colors.secondaryText)
                    }
                    
                    // Sign Up Form
                    VStack(spacing: Constants.Spacing.lg) {
                        InputField(
                            label: "電子郵件",
                            text: $viewModel.email,
                            placeholder: "example@email.com",
                            icon: "envelope",
                            errorMessage: viewModel.emailError
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        
                        PasswordField(
                            label: "密碼",
                            text: $viewModel.password,
                            placeholder: "至少 8 個字符",
                            errorMessage: viewModel.passwordError
                        )
                        
                        PasswordField(
                            label: "確認密碼",
                            text: $viewModel.confirmPassword,
                            placeholder: "再次輸入密碼",
                            errorMessage: viewModel.confirmPasswordError
                        )
                        
                        // Password Requirements
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.password.count >= 8 ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.password.count >= 8 ? Constants.Colors.green : Constants.Colors.secondaryText)
                                    .font(Constants.Typography.small)
                                
                                Text("至少 8 個字符")
                                    .font(Constants.Typography.small)
                                    .foregroundColor(Constants.Colors.secondaryText)
                            }
                            
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.password == viewModel.confirmPassword && !viewModel.confirmPassword.isEmpty ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(viewModel.password == viewModel.confirmPassword && !viewModel.confirmPassword.isEmpty ? Constants.Colors.green : Constants.Colors.secondaryText)
                                    .font(Constants.Typography.small)
                                
                                Text("密碼相符")
                                    .font(Constants.Typography.small)
                                    .foregroundColor(Constants.Colors.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Terms and Conditions
                        HStack(alignment: .top, spacing: 8) {
                            Button(action: { agreedToTerms.toggle() }) {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .foregroundColor(agreedToTerms ? Constants.Colors.primary : Constants.Colors.secondaryText)
                                    .font(.title3)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("我同意")
                                    .font(Constants.Typography.small)
                                    .foregroundColor(Constants.Colors.primaryText)
                                +
                                Text(" 使用條款 ")
                                    .font(Constants.Typography.small)
                                    .foregroundColor(Constants.Colors.primary)
                                    .underline()
                                +
                                Text("與")
                                    .font(Constants.Typography.small)
                                    .foregroundColor(Constants.Colors.primaryText)
                                +
                                Text(" 隱私政策")
                                    .font(Constants.Typography.small)
                                    .foregroundColor(Constants.Colors.primary)
                                    .underline()
                            }
                        }
                    }
                    .padding(.horizontal, Constants.Spacing.lg)
                    
                    // Sign Up Button
                    VStack(spacing: Constants.Spacing.md) {
                        PrimaryButton(
                            title: "註冊",
                            action: {
                                Task {
                                    await viewModel.signUp()
                                }
                            },
                            isDisabled: !isFormValid,
                            isLoading: viewModel.isLoading
                        )
                        .padding(.horizontal, Constants.Spacing.lg)
                        
                        // Back to Login
                        HStack(spacing: 4) {
                            Text("已經有帳號？")
                                .font(Constants.Typography.caption)
                                .foregroundColor(Constants.Colors.secondaryText)
                            
                            Button(action: { dismiss() }) {
                                Text("立即登入")
                                    .font(Constants.Typography.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Constants.Colors.primary)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical, Constants.Spacing.lg)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("提示", isPresented: $viewModel.showError) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "發生未知錯誤")
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        return !viewModel.email.isEmpty &&
               !viewModel.password.isEmpty &&
               !viewModel.confirmPassword.isEmpty &&
               viewModel.password.count >= 8 &&
               viewModel.password == viewModel.confirmPassword &&
               agreedToTerms
    }
}

// MARK: - Preview
#Preview("Sign Up View") {
    NavigationStack {
        SignUpView()
    }
}
