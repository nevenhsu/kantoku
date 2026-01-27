//
//  LoginView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 登入視圖
struct LoginView: View {
    @StateObject private var viewModel = AuthViewModel()
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Constants.Colors.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.Spacing.xl) {
                        // Logo and Title Section
                        VStack(spacing: Constants.Spacing.md) {
                            // App Icon/Logo
                            Image(systemName: "book.fill")
                                .font(.system(size: 80))
                                .foregroundColor(Constants.Colors.primary)
                                .padding(.top, Constants.Spacing.xxl)
                            
                            Text("監督 Kantoku")
                                .font(Constants.Typography.h1)
                                .foregroundColor(Constants.Colors.primaryText)
                            
                            Text("日語學習小助手")
                                .font(Constants.Typography.caption)
                                .foregroundColor(Constants.Colors.secondaryText)
                        }
                        .padding(.bottom, Constants.Spacing.lg)
                        
                        // Login Form
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
                            
                            // Forgot Password Link
                            HStack {
                                Spacer()
                                Button(action: { showForgotPassword = true }) {
                                    Text("忘記密碼？")
                                        .font(Constants.Typography.caption)
                                        .foregroundColor(Constants.Colors.primary)
                                }
                            }
                        }
                        .padding(.horizontal, Constants.Spacing.lg)
                        
                        // Login Button
                        VStack(spacing: Constants.Spacing.md) {
                            PrimaryButton(
                                title: "登入",
                                action: {
                                    Task {
                                        await viewModel.signIn()
                                    }
                                },
                                isDisabled: viewModel.email.isEmpty || viewModel.password.isEmpty,
                                isLoading: viewModel.isLoading
                            )
                            .padding(.horizontal, Constants.Spacing.lg)
                            
                            // Sign Up Link
                            HStack(spacing: 4) {
                                Text("還沒有帳號？")
                                    .font(Constants.Typography.caption)
                                    .foregroundColor(Constants.Colors.secondaryText)
                                
                                Button(action: { showSignUp = true }) {
                                    Text("立即註冊")
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
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .alert("提示", isPresented: $viewModel.showError) {
                Button("確定", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "發生未知錯誤")
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordSheet(viewModel: viewModel)
            }
        }
    }
}

/// 忘記密碼彈窗
struct ForgotPasswordSheet: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: Constants.Spacing.lg) {
                // Icon
                Image(systemName: "envelope.badge")
                    .font(.system(size: 60))
                    .foregroundColor(Constants.Colors.primary)
                    .padding(.top, Constants.Spacing.xl)
                
                // Description
                VStack(spacing: Constants.Spacing.xs) {
                    Text("重設密碼")
                        .font(Constants.Typography.h2)
                        .foregroundColor(Constants.Colors.primaryText)
                    
                    Text("輸入您的電子郵件，我們將發送密碼重設連結")
                        .font(Constants.Typography.caption)
                        .foregroundColor(Constants.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Constants.Spacing.lg)
                }
                
                // Email Input
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
                .padding(.horizontal, Constants.Spacing.lg)
                .padding(.top, Constants.Spacing.md)
                
                Spacer()
                
                // Send Button
                PrimaryButton(
                    title: "發送重設連結",
                    action: {
                        Task {
                            await viewModel.resetPassword()
                            // Close after sending
                            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                            dismiss()
                        }
                    },
                    isDisabled: viewModel.email.isEmpty,
                    isLoading: viewModel.isLoading
                )
                .padding(.horizontal, Constants.Spacing.lg)
                .padding(.bottom, Constants.Spacing.lg)
            }
            .background(Constants.Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Constants.Colors.primaryText)
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview("Login View") {
    LoginView()
}

#Preview("Forgot Password Sheet") {
    ForgotPasswordSheet(viewModel: AuthViewModel())
}
