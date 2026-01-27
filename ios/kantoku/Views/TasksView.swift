//
//  TasksView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 任務列表視圖
struct TasksView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Constants.Spacing.md) {
                Text("任務列表")
                    .font(Constants.Typography.h2)
            }
            .padding(Constants.Spacing.md)
        }
        .navigationTitle("任務")
    }
}

#Preview {
    NavigationStack {
        TasksView()
    }
}
