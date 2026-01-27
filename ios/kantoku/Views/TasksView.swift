//
//  TasksView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI
import Auth

/// 任務列表視圖
struct TasksView: View {
    @StateObject private var viewModel = TaskViewModel()
    @ObservedObject private var authService = AuthService.shared
    @State private var showFilterSheet = false
    @State private var selectedTask: TaskModel?
    
    var body: some View {
        ZStack {
            Constants.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                searchBar
                
                // Filter Chips
                if viewModel.selectedType != nil || viewModel.selectedStatus != nil {
                    filterChips
                }
                
                // Task List
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredTasks.isEmpty {
                    emptyState
                } else {
                    taskList
                }
            }
        }
        .navigationTitle("所有任務")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showFilterSheet = true }) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(Constants.Colors.primary)
                }
            }
        }
        .sheet(isPresented: $showFilterSheet) {
            FilterSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedTask) { task in
            if let userId = authService.currentUser?.id {
                TaskDetailView(taskModel: task, userId: userId, viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadAllTasks()
        }
    }
    
    // MARK: - Search Bar
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Constants.Colors.secondaryText)
            
            TextField("搜尋任務...", text: $viewModel.searchText)
                .font(Constants.Typography.body)
            
            if !viewModel.searchText.isEmpty {
                Button(action: { viewModel.searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Constants.Colors.secondaryText)
                }
            }
        }
        .padding(Constants.Spacing.sm)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.small)
        .padding(.horizontal, Constants.Spacing.md)
        .padding(.vertical, Constants.Spacing.sm)
    }
    
    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.Spacing.sm) {
                if let type = viewModel.selectedType {
                    FilterChip(text: type.displayName) {
                        viewModel.selectedType = nil
                    }
                }
                
                if let status = viewModel.selectedStatus {
                    FilterChip(text: status.displayName) {
                        viewModel.selectedStatus = nil
                    }
                }
                
                Button(action: { viewModel.resetFilters() }) {
                    Text("清除全部")
                        .font(Constants.Typography.caption)
                        .foregroundColor(Constants.Colors.red)
                }
                .padding(.leading, Constants.Spacing.xs)
            }
            .padding(.horizontal, Constants.Spacing.md)
            .padding(.bottom, Constants.Spacing.sm)
        }
    }
    
    // MARK: - Task List
    private var taskList: some View {
        ScrollView {
            LazyVStack(spacing: Constants.Spacing.md) {
                ForEach(viewModel.filteredTasks) { task in
                    TaskCard(task: task) {
                        selectedTask = task
                    }
                }
            }
            .padding(Constants.Spacing.md)
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: Constants.Spacing.md) {
            Image(systemName: "tray")
                .font(.system(size: 64))
                .foregroundColor(Constants.Colors.secondaryText)
            
            Text("沒有找到任務")
                .font(Constants.Typography.h3)
                .foregroundColor(Constants.Colors.primaryText)
            
            Text("嘗試調整搜尋條件或過濾器")
                .font(Constants.Typography.body)
                .foregroundColor(Constants.Colors.secondaryText)
            
            if viewModel.selectedType != nil || viewModel.selectedStatus != nil || !viewModel.searchText.isEmpty {
                SecondaryButton(title: "清除過濾器") {
                    viewModel.resetFilters()
                }
                .frame(width: 200)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Constants.Spacing.xl)
    }
}

// MARK: - Filter Chip Component
struct FilterChip: View {
    let text: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(text)
                .font(Constants.Typography.caption)
            
            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Constants.Colors.primary.opacity(0.1))
        .foregroundColor(Constants.Colors.primary)
        .cornerRadius(Constants.CornerRadius.small)
    }
}

// MARK: - Filter Sheet
struct FilterSheet: View {
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("任務類型") {
                    ForEach([nil] + TaskType.allCases, id: \.self) { type in
                        Button(action: {
                            viewModel.selectedType = type
                        }) {
                            HStack {
                                Text(type?.displayName ?? "全部")
                                    .foregroundColor(Constants.Colors.primaryText)
                                Spacer()
                                if viewModel.selectedType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Constants.Colors.primary)
                                }
                            }
                        }
                    }
                }
                
                Section("任務狀態") {
                    ForEach([nil] + TaskStatus.allCases, id: \.self) { status in
                        Button(action: {
                            viewModel.selectedStatus = status
                        }) {
                            HStack {
                                Text(status?.displayName ?? "全部")
                                    .foregroundColor(Constants.Colors.primaryText)
                                Spacer()
                                if viewModel.selectedStatus == status {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Constants.Colors.primary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("過濾任務")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("重置") {
                        viewModel.resetFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - TaskType Extension
extension TaskType: CaseIterable {
    static var allCases: [TaskType] {
        [.kanaLearn, .kanaReview, .vocabulary, .externalResource]
    }
}

// MARK: - TaskStatus Extension
extension TaskStatus: CaseIterable {
    static var allCases: [TaskStatus] {
        [.pending, .submitted, .passed, .failed]
    }
}

#Preview {
    NavigationStack {
        TasksView()
    }
}
