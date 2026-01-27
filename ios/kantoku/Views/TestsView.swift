//
//  TestsView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 測驗視圖
struct TestsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.md) {
                Text("階段測驗")
                    .font(Constants.Typography.h2)
            }
            .padding(Constants.Spacing.md)
        }
        .navigationTitle("測驗")
    }
}

#Preview {
    NavigationStack {
        TestsView()
    }
}
