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
    let taskModel: TaskModel
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
            Text(taskModel.taskType.displayName)
                .font(Constants.Typography.h3)
                .foregroundColor(Constants.Colors.primaryText)
            
            Text("請上傳手寫練習照片")
                .font(Constants.Typography.body)
                .foregroundColor(Constants.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
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
                            .fill(Constants.Colors.primaryAccent.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(Constants.Colors.primaryAccent)
                    }
                    
                    Text("拍照")
                        .font(Constants.Typography.h3)
                        .foregroundColor(Constants.Colors.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(Constants.Spacing.xl)
                .background(Constants.Colors.cardBackground)
                .cornerRadius(Constants.CornerRadius.medium)
            }
            
            // Photo Library Button
            PhotosPicker(selection: $selectedItem, matching: .images) {
                VStack(spacing: Constants.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(Constants.Colors.orange.opacity(0.1))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 50))
                            .foregroundColor(Constants.Colors.orange)
                    }
                    
                    Text("從相簿選擇")
                        .font(Constants.Typography.h3)
                        .foregroundColor(Constants.Colors.primaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(Constants.Spacing.xl)
                .background(Constants.Colors.cardBackground)
                .cornerRadius(Constants.CornerRadius.medium)
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
                    .cornerRadius(Constants.CornerRadius.medium)
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
                    .foregroundColor(Constants.Colors.primaryAccent)
                    .padding(Constants.Spacing.md)
                    .frame(maxWidth: .infinity)
                    .background(Constants.Colors.primaryAccent.opacity(0.1))
                    .cornerRadius(Constants.CornerRadius.medium)
                }
                
                // Delete Button
                Button {
                    viewModel.deleteImage()
                } label: {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(Constants.Colors.red)
                        .padding(Constants.Spacing.md)
                        .background(Constants.Colors.red.opacity(0.1))
                        .cornerRadius(Constants.CornerRadius.medium)
                }
            }
        }
        .padding(Constants.Spacing.md)
        .background(Constants.Colors.cardBackground)
        .cornerRadius(Constants.CornerRadius.medium)
    }
    
    // MARK: - Submit Section
    
    private var submitSection: some View {
        PrimaryButton(
            title: "提交審核",
            icon: "checkmark.circle.fill",
            action: {
                Task {
                    await viewModel.submitImage(taskId: taskModel.id, userId: userId)
                    
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
                        .font(Constants.Typography.h3)
                        .foregroundColor(.white)
                    
                    if viewModel.isUploading {
                        SwiftUI.ProgressView(value: viewModel.uploadProgress, total: 1.0)
                            .tint(.white)
                            .frame(width: 200)
                    }
                }
            }
            .padding(Constants.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: Constants.CornerRadius.medium)
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
        taskModel: TaskModel(
            id: UUID(),
            userId: UUID(),
            taskType: .kanaLearn,
            content: .kanaLearn(KanaLearnContent(kanaList: [], kanaType: .hiragana)),
            status: .pending,
            dueDate: Date(),
            skipped: false,
            createdAt: Date(),
            updatedAt: Date()
        ),
        userId: UUID()
    )
}
