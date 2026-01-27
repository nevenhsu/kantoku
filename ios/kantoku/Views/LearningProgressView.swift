//
//  ProgressView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 進度追蹤視圖
struct LearningProgressView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.md) {
                Text("學習進度")
                    .font(Constants.Typography.h2)
            }
            .padding(Constants.Spacing.md)
        }
        .navigationTitle("進度")
    }
}

#Preview {
    NavigationStack {
        LearningProgressView()
    }
}
