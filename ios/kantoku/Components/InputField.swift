//
//  InputField.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 標準輸入框
struct InputField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var icon: String?
    var errorMessage: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(label)
                .font(Constants.Typography.caption)
                .foregroundColor(Constants.Colors.secondaryText)
            
            // Input Field
            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(Constants.Colors.secondaryText)
                        .frame(width: 20)
                }
                
                TextField(placeholder, text: $text)
                    .font(Constants.Typography.body)
                    .foregroundColor(Constants.Colors.primaryText)
            }
            .padding(.horizontal, Constants.Spacing.sm)
            .padding(.vertical, Constants.Spacing.sm)
            .background(Constants.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                    .stroke(errorMessage != nil ? Constants.Colors.red : Constants.Colors.secondaryText.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(Constants.CornerRadius.small)
            
            // Error Message
            if let errorMessage = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(Constants.Typography.small)
                    Text(errorMessage)
                        .font(Constants.Typography.small)
                }
                .foregroundColor(Constants.Colors.red)
            }
        }
    }
}

/// 密碼輸入框
struct PasswordField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var errorMessage: String?
    
    @State private var isSecure: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(label)
                .font(Constants.Typography.caption)
                .foregroundColor(Constants.Colors.secondaryText)
            
            // Input Field
            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .foregroundColor(Constants.Colors.secondaryText)
                    .frame(width: 20)
                
                if isSecure {
                    SecureField(placeholder, text: $text)
                        .font(Constants.Typography.body)
                        .foregroundColor(Constants.Colors.primaryText)
                } else {
                    TextField(placeholder, text: $text)
                        .font(Constants.Typography.body)
                        .foregroundColor(Constants.Colors.primaryText)
                }
                
                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye.slash" : "eye")
                        .foregroundColor(Constants.Colors.secondaryText)
                        .frame(width: 20)
                }
            }
            .padding(.horizontal, Constants.Spacing.sm)
            .padding(.vertical, Constants.Spacing.sm)
            .background(Constants.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                    .stroke(errorMessage != nil ? Constants.Colors.red : Constants.Colors.secondaryText.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(Constants.CornerRadius.small)
            
            // Error Message
            if let errorMessage = errorMessage {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(Constants.Typography.small)
                    Text(errorMessage)
                        .font(Constants.Typography.small)
                }
                .foregroundColor(Constants.Colors.red)
            }
        }
    }
}

/// 多行文字輸入框
struct TextAreaField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var maxCharacters: Int = 500
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label
            Text(label)
                .font(Constants.Typography.caption)
                .foregroundColor(Constants.Colors.secondaryText)
            
            // Text Editor
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(Constants.Typography.body)
                        .foregroundColor(Constants.Colors.disabledText)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                
                TextEditor(text: $text)
                    .font(Constants.Typography.body)
                    .foregroundColor(Constants.Colors.primaryText)
                    .frame(minHeight: 120)
                    .padding(4)
            }
            .background(Constants.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.small)
                    .stroke(Constants.Colors.secondaryText.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(Constants.CornerRadius.small)
            
            // Character Count
            HStack {
                Spacer()
                Text("\(text.count) / \(maxCharacters)")
                    .font(Constants.Typography.small)
                    .foregroundColor(text.count > maxCharacters ? Constants.Colors.red : Constants.Colors.secondaryText)
            }
        }
    }
}

// MARK: - Previews
#Preview("Input Fields") {
    VStack(spacing: 24) {
        InputField(
            label: "電子郵件",
            text: .constant("test@example.com"),
            placeholder: "請輸入電子郵件",
            icon: "envelope"
        )
        
        InputField(
            label: "錯誤狀態",
            text: .constant(""),
            placeholder: "請輸入文字",
            errorMessage: "此欄位為必填"
        )
        
        PasswordField(
            label: "密碼",
            text: .constant(""),
            placeholder: "請輸入密碼"
        )
        
        TextAreaField(
            label: "心得",
            text: .constant("今天學習了平假名的「あ行」..."),
            placeholder: "請輸入學習心得"
        )
    }
    .padding()
}
