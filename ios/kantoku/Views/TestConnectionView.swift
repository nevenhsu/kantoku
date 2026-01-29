//
//  TestConnectionView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI

/// 連接測試視圖
/// 用於測試 Supabase 和 n8n 的連接狀態
struct TestConnectionView: View {
    @State private var testResults: [ConnectionTestService.TestResult] = []
    @State private var isRunning = false
    @State private var expandedTests: Set<String> = []
    
    private let testService = ConnectionTestService.shared
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Constants.Spacing.lg) {
                    // 標題區
                    headerSection
                    
                    // 測試按鈕
                    runTestButton
                    
                    // 測試結果
                    if !testResults.isEmpty {
                        resultsSection
                    }
                    
                    // 使用指南
                    guideSection
                }
                .padding(Constants.Spacing.lg)
            }
            .navigationTitle("連接測試")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    // MARK: - 標題區
    
    private var headerSection: some View {
        VStack(spacing: Constants.Spacing.md) {
            Image(systemName: "network")
                .font(.system(size: 60))
                .foregroundStyle(Constants.Colors.primary)
            
            Text("Supabase & n8n 連接測試")
                .font(Constants.Typography.h2)
                .foregroundStyle(Constants.Colors.primaryText)
            
            Text("測試後端服務連接狀態")
                .font(Constants.Typography.body)
                .foregroundStyle(Constants.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(Constants.Spacing.lg)
        .background(Constants.Colors.surface)
        .cornerRadius(Constants.CornerRadius.large)
    }
    
    // MARK: - 測試按鈕
    
    private var runTestButton: some View {
        Button {
            runAllTests()
        } label: {
            HStack {
                if isRunning {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "play.circle.fill")
                }
                
                Text(isRunning ? "測試進行中..." : "開始測試")
                    .font(Constants.Typography.buttonText)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Constants.Button.heightLarge)
            .background(isRunning ? Constants.Colors.secondaryText : Constants.Colors.primary)
            .foregroundColor(.white)
            .cornerRadius(Constants.CornerRadius.button)
        }
        .disabled(isRunning)
    }
    
    // MARK: - 測試結果
    
    private var resultsSection: some View {
        VStack(spacing: Constants.Spacing.md) {
            // 摘要
            summaryCard
            
            // 詳細結果
            ForEach(testResults, id: \.name) { result in
                testResultCard(result)
            }
        }
    }
    
    private var summaryCard: some View {
        let successCount = testResults.filter { $0.success }.count
        let totalCount = testResults.count
        let allPassed = successCount == totalCount
        
        return VStack(spacing: Constants.Spacing.sm) {
            HStack {
                Image(systemName: allPassed ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                    .font(.title)
                    .foregroundStyle(allPassed ? Constants.Colors.green : Constants.Colors.orange)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("測試結果摘要")
                        .font(Constants.Typography.h3)
                        .foregroundStyle(Constants.Colors.primaryText)
                    
                    Text("\(successCount) / \(totalCount) 項測試通過")
                        .font(Constants.Typography.caption)
                        .foregroundStyle(Constants.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            // 進度條
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // 背景
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Constants.Colors.background)
                        .frame(height: 8)
                    
                    // 進度
                    RoundedRectangle(cornerRadius: 4)
                        .fill(allPassed ? Constants.Colors.green : Constants.Colors.orange)
                        .frame(width: geometry.size.width * CGFloat(successCount) / CGFloat(totalCount), height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(Constants.Spacing.lg)
        .background(Constants.Colors.surface)
        .cornerRadius(Constants.CornerRadius.large)
    }
    
    private func testResultCard(_ result: ConnectionTestService.TestResult) -> some View {
        let isExpanded = expandedTests.contains(result.name)
        
        return VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
            // 標題行
            Button {
                toggleExpanded(result.name)
            } label: {
                HStack {
                    Text(result.emoji)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.name)
                            .font(Constants.Typography.h4)
                            .foregroundStyle(Constants.Colors.primaryText)
                        
                        Text(result.message)
                            .font(Constants.Typography.caption)
                            .foregroundStyle(result.success ? Constants.Colors.green : Constants.Colors.red)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "%.2fs", result.duration))
                            .font(Constants.Typography.caption)
                            .foregroundStyle(Constants.Colors.secondaryText)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption)
                            .foregroundStyle(Constants.Colors.secondaryText)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // 詳細資訊（展開時顯示）
            if isExpanded, let details = result.details {
                Divider()
                    .padding(.vertical, Constants.Spacing.xs)
                
                Text("詳細資訊")
                    .font(Constants.Typography.caption)
                    .foregroundStyle(Constants.Colors.secondaryText)
                    .textCase(.uppercase)
                
                Text(details)
                    .font(Constants.Typography.small)
                    .foregroundStyle(Constants.Colors.primaryText)
                    .padding(Constants.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Constants.Colors.background)
                    .cornerRadius(Constants.CornerRadius.small)
            }
        }
        .padding(Constants.Spacing.lg)
        .background(Constants.Colors.surface)
        .cornerRadius(Constants.CornerRadius.large)
    }
    
    // MARK: - 使用指南
    
    private var guideSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.md) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(Constants.Colors.primary)
                Text("使用指南")
                    .font(Constants.Typography.h3)
                    .foregroundStyle(Constants.Colors.primaryText)
            }
            
            VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                guideItem(
                    icon: "1.circle.fill",
                    title: "點擊「開始測試」",
                    description: "執行所有連接測試"
                )
                
                guideItem(
                    icon: "2.circle.fill",
                    title: "查看測試結果",
                    description: "綠色勾號表示通過，紅色叉號表示失敗"
                )
                
                guideItem(
                    icon: "3.circle.fill",
                    title: "展開詳細資訊",
                    description: "點擊測試項目查看錯誤訊息或詳細內容"
                )
            }
            
            Divider()
                .padding(.vertical, Constants.Spacing.xs)
            
            Text("測試項目說明")
                .font(Constants.Typography.h4)
                .foregroundStyle(Constants.Colors.primaryText)
                .padding(.top, Constants.Spacing.xs)
            
            VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
                testExplanation(
                    title: "Supabase 基礎連接",
                    description: "測試是否能連接到 Supabase 伺服器"
                )
                
                testExplanation(
                    title: "Supabase Auth",
                    description: "測試認證服務是否正常運作"
                )
                
                testExplanation(
                    title: "Supabase Database",
                    description: "測試資料庫查詢功能"
                )
                
                testExplanation(
                    title: "Supabase Storage",
                    description: "測試檔案存儲服務（submissions bucket）"
                )
                
                testExplanation(
                    title: "n8n 基礎連接",
                    description: "測試是否能連接到 n8n 伺服器"
                )
                
                testExplanation(
                    title: "generate-tasks webhook",
                    description: "測試任務生成 API（使用測試帳號）"
                )
            }
        }
        .padding(Constants.Spacing.lg)
        .background(Constants.Colors.surface)
        .cornerRadius(Constants.CornerRadius.large)
    }
    
    private func guideItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: Constants.Spacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(Constants.Colors.primary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Constants.Typography.body)
                    .foregroundStyle(Constants.Colors.primaryText)
                
                Text(description)
                    .font(Constants.Typography.caption)
                    .foregroundStyle(Constants.Colors.secondaryText)
            }
        }
    }
    
    private func testExplanation(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("• \(title)")
                .font(Constants.Typography.small)
                .foregroundStyle(Constants.Colors.primaryText)
                .bold()
            
            Text(description)
                .font(Constants.Typography.caption)
                .foregroundStyle(Constants.Colors.secondaryText)
                .padding(.leading, Constants.Spacing.md)
        }
    }
    
    // MARK: - 操作
    
    private func runAllTests() {
        isRunning = true
        testResults = []
        expandedTests = []
        
        Task {
            let results = await testService.runAllTests()
            
            // 逐個顯示結果（動畫效果）
            for result in results {
                await MainActor.run {
                    self.testResults.append(result)
                }
                try? await Task.sleep(nanoseconds: 200_000_000) // 0.2秒
            }
            
            await MainActor.run {
                self.isRunning = false
            }
        }
    }
    
    private func toggleExpanded(_ name: String) {
        if expandedTests.contains(name) {
            expandedTests.remove(name)
        } else {
            expandedTests.insert(name)
        }
    }
}

// MARK: - Preview

#Preview {
    TestConnectionView()
}
