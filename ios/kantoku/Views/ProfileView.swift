//
//  ProfileView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 個人資料視圖
struct ProfileView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.md) {
                Text("個人設定")
                    .font(Constants.Typography.h2)
            }
            .padding(Constants.Spacing.md)
        }
        .navigationTitle("我的")
    }
}

#Preview {
    NavigationStack {
        ProfileView()
    }
}
