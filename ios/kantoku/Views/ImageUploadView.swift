//
//  ImageUploadView.swift
//  kantoku
//
//  Created by AI Assistant on 2026/1/27.
//

import SwiftUI
import PhotosUI

/// 圖片上傳視圖
/// 提供圖片選擇、預覽、提交功能
struct ImageUploadView: View {
    @ObservedObject var viewModel: SubmissionViewModel
    let task: TaskModel
    let userId: UUID
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Constants.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Constants.Spacing.xl) {
                        // Task Info
                        taskInfoSection
                        
                        // Image Picker
                        if viewModel.selectedImage == nil {
                            imagePickerSection
                        } else {
                            imagePreviewSection
                        }
                        
                        // Submit Button
                        if viewModel.selectedImage != nil {
                            submitSection
                        }
                        
                        Spacer()
                    }
                    .padding(Constants.Spacing.lg)
                }
            }
            .navigationTitle("圖片提交")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(image: $viewModel.selectedImage, sourceType: .camera)
            }
            .onChange(of: selectedItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.selectImage(image)
                    }
                }
            }
            .alert("錯誤", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("確定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .overlay {
                if viewModel.isSubmitting {
                    submittingOverlay
                }
            }
        }
    }
    
    // MARK: - Task Info Section
    
    private var taskInfoSection: some View {
        VStack(alignment: .leading, spacing: Constants.Spacing.sm) {
            Text(task.taskType.displayName)
                .font(Constants.Typography.headline)
                .foregroundColor(Constants.Colors.textPrimary)
            
            Text("請上傳手寫練習照片")
                .font(Constants.Typography.body)
                .foregroundColor(Constants.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    // MARK: - Image Picker Section
    
    private var imagePickerSection: some View {
        VStack(spacing: Constants.Spacing.md) {
            // Camera Button
            Button {
                showCamera = true
            } label: {
                VStack(spacing: Constants.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Constants.Colors.accent.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Constants.Colors.accent)
                    }
                    
                    Text("拍照")
                        .font(Constants.Typography.headline)
                        .foregroundColor(Constants.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(Constants.Spacing.xl)
                .background(Constants.Colors.cardBackground)
                .cornerRadius(Constants.UI.cornerRadius)
            }
            
            // Photo Library Button
            PhotosPicker(selection: $selectedItem, matching: .images) {
                VStack(spacing: Constants.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Constants.Colors.secondary.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(Constants.Colors.secondary)
                    }
                    
                    Text("從相簿選擇")
                        .font(Constants.Typography.headline)
                        .foregroundColor(Constants.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(Constants.Spacing.xl)
                .background(Constants.Colors.cardBackground)
                .cornerRadius(Constants.UI.cornerRadius)
            }
        }
    }
    
    // MARK: - Image Preview Section
    
    private var imagePreviewSection: some View {
        VStack(spacing: Constants.Spacing.md) {
            // Image Preview
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 400)
                    .cornerRadius(Constants.UI.cornerRadius)
            }
            
            // Action Buttons
            HStack(spacing: Constants.Spacing.md) {
                // Retake Button
                Button {
                    viewModel.deleteImage()
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("重新選擇")
                    }
                    .font(Constants.Typography.body)
                    .foregroundColor(Constants.Colors.accent)
                    .padding(Constants.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Constants.Colors.accent.opacity(0.1))
                    .cornerRadius(Constants.UI.cornerRadius)
                }
                
                // Delete Button
                Button {
                    viewModel.deleteImage()
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(Constants.Colors.danger)
                        .padding(Constants.Spacing.md)
                        .background(Constants.Colors.danger.opacity(0.1))
                        .cornerRadius(Constants.UI.cornerRadius)
                }
            }
        }
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.UI.cornerRadius)
    }
    
    // MARK: - Submit Section
    
    private var submitSection: some View {
        PrimaryButton(
            title: "提交審核",
            icon: "checkmark.circle.fill",
            action: {
                Task {
                    await viewModel.submitImage(taskId: task.id, userId: userId)
                    
                    // 如果提交成功，關閉視圖
                    if viewModel.successMessage != nil {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }
                }
            },
            isLoading: viewModel.isSubmitting
        )
    }
    
    // MARK: - Submitting Overlay
    
    private var submittingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            VStack(spacing: Constants.Spacing.lg) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                VStack(spacing: Constants.Spacing.sm) {
                    Text(viewModel.isUploading ? "上傳中..." : "提交中...")
                        .font(Constants.Typography.headline)
                        .foregroundColor(.white)
                    
                    if viewModel.isUploading {
                        ProgressView(value: viewModel.uploadProgress)
                            .tint(.white)
                            .frame(width: 200)
                    }
                }
            }
            .padding(Constants.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: Constants.UI.cornerRadius)
                    .fill(Color.black.opacity(0.8))
            )
        }
    }
}

// MARK: - ImagePicker (UIKit Wrapper)

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    ImageUploadView(
        viewModel: SubmissionViewModel(),
        task: TaskModel(
            id: UUID(),
            taskType: .kanaLearn,
            status: .pending,
            content: .kana(KanaContent(kanaType: .hiragana, characters: [])),
            createdAt: Date(),
            dueDate: Date()
        ),
        userId: UUID()
    )
}
