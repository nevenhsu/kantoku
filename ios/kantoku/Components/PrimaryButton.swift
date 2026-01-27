//
//  PrimaryButton.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 主要按鈕樣式
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    var isDisabled: Bool = false
    var isLoading: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let iconName = icon {
                    Image(systemName: iconName)
                }
                
                Text(title)
                    .font(Constants.Typography.body)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Constants.Button.height)
            .foregroundColor(.white)
            .background(isDisabled ? Constants.Colors.disabledText : Constants.Colors.primary)
            .cornerRadius(Constants.CornerRadius.medium)
        }
        .disabled(isDisabled || isLoading)
        .scaleEffect(isDisabled ? 1.0 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

/// 次要按鈕樣式
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Constants.Typography.body)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.Button.height)
                .foregroundColor(isDisabled ? Constants.Colors.disabledText : Constants.Colors.primary)
                .background(Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
                        .stroke(isDisabled ? Constants.Colors.disabledText : Constants.Colors.primary, lineWidth: 2)
                )
        }
        .disabled(isDisabled)
        .scaleEffect(isDisabled ? 1.0 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

/// 文字按鈕樣式
struct TextButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Constants.Typography.caption)
                .foregroundColor(Constants.Colors.secondaryText)
        }
    }
}

/// 危險按鈕樣式
struct DangerButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Constants.Typography.body)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.Button.height)
                .foregroundColor(.white)
                .background(isDisabled ? Constants.Colors.disabledText : Constants.Colors.red)
                .cornerRadius(Constants.CornerRadius.medium)
        }
        .disabled(isDisabled)
        .scaleEffect(isDisabled ? 1.0 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

/// 圖標按鈕
struct IconButton: View {
    let iconName: String
    let action: () -> Void
    var size: CGFloat = Constants.Button.iconButtonSize
    var backgroundColor: Color = Constants.Colors.primary.opacity(0.1)
    var iconColor: Color = Constants.Colors.primary
    
    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
        }
    }
}

// MARK: - Previews
#Preview("Primary Button") {
    VStack(spacing: 20) {
        PrimaryButton(title: "登入", action: {})
        PrimaryButton(title: "處理中...", action: {}, isLoading: true)
        PrimaryButton(title: "已禁用", action: {}, isDisabled: true)
    }
    .padding()
}

#Preview("Secondary Button") {
    VStack(spacing: 20) {
        SecondaryButton(title: "取消", action: {})
        SecondaryButton(title: "已禁用", action: {}, isDisabled: true)
    }
    .padding()
}

#Preview("Icon Button") {
    HStack(spacing: 20) {
        IconButton(iconName: "speaker.wave.2.fill", action: {})
        IconButton(iconName: "heart.fill", action: {}, iconColor: .red)
    }
    .padding()
}
