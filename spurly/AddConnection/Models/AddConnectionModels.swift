//
//  File name: AddConnectionModels.swift (Updated)
//
// Product / Project: spurly / spurly
//
// Organization: phaeton order llc
// Bundle ID: com.phaeton-order.spurly
//
//

import SwiftUI
import UIKit
import PhotosUI

struct AddConnectionPayload: Codable {
var connectionName: String?
var connectionAge: Int?
var connectionContextBlock: String?
var connectionOcrImages: [UIImage]?
var connectionProfileImages: [UIImage]?
var connectionFacePhotoURL: String? // New field for the processed face photo URL

// CodingKeys remain the same, but we will handle encoding/decoding manually for images
enum CodingKeys: String, CodingKey {
    case connectionName = "connection_name"
    case connectionAge = "connection_age"
    case connectionContextBlock = "connection_context_block"
    case connectionOcrImages = "connection_ocr_images"
    case connectionProfileImages = "connection_profile_images"
    case connectionFacePhotoURL = "connection_face_photo_url" // New coding key
}

// Custom initializer
init(connectionName: String?, connectionAge: Int?, connectionContextBlock: String?, connectionOcrImages: [UIImage]?, connectionProfileImages: [UIImage]?, connectionFacePhotoURL: String? = nil) {
    self.connectionName = connectionName?.isEmpty ?? true ? nil : connectionName
    self.connectionAge = connectionAge
    self.connectionContextBlock = connectionContextBlock?.isEmpty ?? true ? nil : connectionContextBlock
    self.connectionOcrImages = connectionOcrImages?.isEmpty ?? true ? nil : connectionOcrImages
    self.connectionProfileImages = connectionProfileImages?.isEmpty ?? true ? nil : connectionProfileImages
    self.connectionFacePhotoURL = connectionFacePhotoURL?.isEmpty ?? true ? nil : connectionFacePhotoURL
}

// Custom Decodable initializer
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    connectionName = try container.decodeIfPresent(String.self, forKey: .connectionName)
    connectionAge = try container.decodeIfPresent(Int.self, forKey: .connectionAge)
    connectionContextBlock = try container.decodeIfPresent(String.self, forKey: .connectionContextBlock)
    connectionFacePhotoURL = try container.decodeIfPresent(String.self, forKey: .connectionFacePhotoURL)

    // Decode OCR images
    if let ocrImageDataArray = try container.decodeIfPresent([Data].self, forKey: .connectionOcrImages) {
        connectionOcrImages = ocrImageDataArray.compactMap { UIImage(data: $0) }
    } else {
        connectionOcrImages = nil
    }

    // Decode Profile images
    if let profileImageDataArray = try container.decodeIfPresent([Data].self, forKey: .connectionProfileImages) {
        connectionProfileImages = profileImageDataArray.compactMap { UIImage(data: $0) }
    } else {
        connectionProfileImages = nil
    }
}

// Custom Encodable function
func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(connectionName, forKey: .connectionName)
    try container.encodeIfPresent(connectionAge, forKey: .connectionAge)
    try container.encodeIfPresent(connectionContextBlock, forKey: .connectionContextBlock)
    try container.encodeIfPresent(connectionFacePhotoURL, forKey: .connectionFacePhotoURL)

    // Encode OCR images with compression
    if let ocrImages = connectionOcrImages {
        let ocrImageDataArray = ocrImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
        try container.encode(ocrImageDataArray, forKey: .connectionOcrImages)
    }

    // Encode Profile images with compression
    if let profileImages = connectionProfileImages {
        let profileImageDataArray = profileImages.compactMap { $0.jpegData(compressionQuality: 0.8) }
        try container.encode(profileImageDataArray, forKey: .connectionProfileImages)
    }
}
}

struct AddConnectionResponse: Codable {
var connectionId: String
var message: String?

enum CodingKeys: String, CodingKey {
    case connectionId = "connection_id"
    case message
}
}

// MARK: - Photo Picker View (Updated)


struct PhotoPickerView: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var isProcessingFaces = false
    @State private var faceProcessingError: String?
    @State private var showFaceErrorAlert = false
    @State private var processedFacePhoto: UIImage?
    @State private var facePhotoURL: String?

    // Add AuthManager access
    @EnvironmentObject var authManager: AuthManager

    private let maxPhotos = 4
    let label: String
    let photoPickerToolHelp: String

    // Callback to parent with processed face photo URL
    let onFacePhotoProcessed: ((String?) -> Void)?

    init(selectedImages: Binding<[UIImage]>, label: String, photoPickerToolHelp: String, onFacePhotoProcessed: ((String?) -> Void)? = nil) {
        self._selectedImages = selectedImages
        self.label = label
        self.photoPickerToolHelp = photoPickerToolHelp
        self.onFacePhotoProcessed = onFacePhotoProcessed
    }

    var body: some View {
        VStack(spacing: 8) {
            // Processing indicator
            if isProcessingFaces {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("processing faces...")
                        .font(.caption)
                        .foregroundColor(.secondaryText)
                }
                .padding(.vertical, 4)
            }

            // Processed face photo preview
            if let facePhoto = processedFacePhoto {
                VStack(spacing: 4) {
                    Text("detected connection face:")
                        .font(.caption)
                        .foregroundColor(.primaryText)

                    Image(uiImage: facePhoto)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.highlight, lineWidth: 2))
                        .shadow(radius: 3)
                }
                .padding(.vertical, 8)
            }

            // Thumbnails grid
            if !selectedImages.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 10) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ThumbnailView(image: image) {
                                removeImage(at: index)
                            }
                        }
                    }
                }
            }

            if (selectedImages.count < maxPhotos) {
                VStack {
                    PhotosPicker(
                        selection: $selectedItems,
                        maxSelectionCount: maxPhotos,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("\(label) ", systemImage: "photo.on.rectangle.angled")
                            .font(.custom("SF Pro Text", size: 14).weight(.regular))
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color.primaryButton)
                            .foregroundColor(Color.tertiaryBg)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        Color.highlight.opacity(0.4),
                                        lineWidth: 2
                                    )
                            )
                            .shadow(
                                color: Color.primaryText.opacity(0.55),
                                radius: 4,
                                x: 2,
                                y: 5
                            )
                    }
                    .padding(.top, 8)
                    .onChange(of: selectedItems) { newItems in
                        loadImages(from: newItems)
                    }
                    .disabled(isProcessingFaces)

                    if selectedImages.isEmpty {
                        Text(photoPickerToolHelp)
                            .font(.footnote)
                            .foregroundColor(.secondaryText)
                            .padding(.top, 5)
                            .shadow(color: .brandColor.opacity(0.42), radius: 4, x: 2, y: 4)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, 8)
            }

            Spacer()
        }
        .navigationTitle(label)
        .alert("Face Detection Error", isPresented: $showFaceErrorAlert, presenting: faceProcessingError) { errorDetail in
            Button("OK") {
                faceProcessingError = nil
                processedFacePhoto = nil
                facePhotoURL = nil
                onFacePhotoProcessed?(nil)
            }
        } message: { errorDetail in
            Text(errorDetail)
        }
    }

    // Load images from PhotosPickerItem
    private func loadImages(from items: [PhotosPickerItem]) {
        selectedImages.removeAll()
        processedFacePhoto = nil
        facePhotoURL = nil

        for item in items {
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        selectedImages.append(image)
                    }
                }
            }
        }

        // Process faces when images are loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !selectedImages.isEmpty && label.lowercased().contains("pics") {
                processFacesInSelectedImages()
            }
        }
    }

    // Remove image at index
    private func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)

        if index < selectedItems.count {
            selectedItems.remove(at: index)
        }

        if selectedImages.isEmpty {
            processedFacePhoto = nil
            facePhotoURL = nil
            onFacePhotoProcessed?(nil)
        } else {
            processFacesInSelectedImages()
        }
    }

    // MARK: - Face Processing

    private func processFacesInSelectedImages() {
        guard !selectedImages.isEmpty else { return }

        isProcessingFaces = true
        faceProcessingError = nil

        FaceDetectionService.shared.processFacesInImages(selectedImages) { result in
            DispatchQueue.main.async {
                self.isProcessingFaces = false

                switch result {
                case .success(let croppedFaceImage):
                    self.processedFacePhoto = croppedFaceImage
                    self.uploadFacePhoto(croppedFaceImage)

                case .failure(let error):
                    self.handleFaceDetectionError(error)
                }
            }
        }
    }

    // MARK: - Upload Methods (Choose One Based on Your Architecture)

    private func uploadFacePhoto(_ image: UIImage) {
        // Option 1: Authenticate with Firebase first, then upload
        // authenticateAndUploadToFirebase(image)

        // Option 2: Upload without Firebase Auth (public bucket)
        // uploadToPublicFirebase(image)

        // Option 3: Upload through your backend
        uploadThroughBackend(image)
    }

    // Option 1: Authenticate with Firebase, then upload
//    private func authenticateAndUploadToFirebase(_ image: UIImage) {
//        authManager.authenticateWithFirebase { success in
//            if success {
//                // Now upload with Firebase Auth
//                let tempConnectionId = UUID().uuidString
//                FirebaseStorageService.shared.uploadConnectionFacePhoto(image, connectionId: tempConnectionId) { result in
//                    DispatchQueue.main.async {
//                        self.handleUploadResult(result)
//                    }
//                }
//            } else {
//                DispatchQueue.main.async {
//                    self.faceProcessingError = "Failed to authenticate with storage service. Please try again."
//                    self.showFaceErrorAlert = true
//                }
//            }
//        }
//    }
//
//    // Option 2: Upload to public Firebase bucket without auth
//    private func uploadToPublicFirebase(_ image: UIImage) {
//        guard let userId = authManager.userId else {
//            faceProcessingError = "User not authenticated. Please log in again."
//            showFaceErrorAlert = true
//            return
//        }
//
//        let tempConnectionId = UUID().uuidString
//        FirebaseStorageServiceNoAuth.shared.uploadConnectionFacePhoto(
//            image,
//            userId: userId,
//            connectionId: tempConnectionId
//        ) { result in
//            DispatchQueue.main.async {
//                self.handleUploadResult(result)
//            }
//        }
//    }

    // Option 3: Upload through your backend (Recommended)
    private func uploadThroughBackend(_ image: UIImage) {
        guard let token = authManager.token else {
            faceProcessingError = "Authentication required. Please log in again."
            showFaceErrorAlert = true
            return
        }

        let tempConnectionId = UUID().uuidString
        BackendProxyStorageService.shared.uploadConnectionFacePhoto(
            image,
            connectionId: tempConnectionId,
            authToken: token
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    self.facePhotoURL = url
                    self.onFacePhotoProcessed?(url)
                    print("Successfully uploaded face photo via backend: \(url)")

                case .failure(let error):
                    print("Failed to upload face photo via backend: \(error.localizedDescription)")
                    self.faceProcessingError = "Failed to save face photo: \(error.localizedDescription)"
                    self.showFaceErrorAlert = true
                }
            }
        }
    }

    private func handleUploadResult(_ result: Result<String, FirebaseStorageError>) {
        switch result {
        case .success(let downloadURL):
            self.facePhotoURL = downloadURL
            self.onFacePhotoProcessed?(downloadURL)
            print("Successfully uploaded face photo: \(downloadURL)")

        case .failure(let error):
            print("Failed to upload face photo: \(error.localizedDescription)")
            self.faceProcessingError = "Failed to save face photo: \(error.localizedDescription)"
            self.showFaceErrorAlert = true
        }
    }

    private func handleFaceDetectionError(_ error: FaceDetectionError) {
        switch error {
        case .noFacesDetected:
            faceProcessingError = "No faces were detected in the uploaded photos. Please upload photos that clearly show the person's face."

        case .multipleFacesInSingleImage:
            faceProcessingError = "Multiple faces were detected in a single photo. Please upload photos with only one person visible."

        case .multipleMostFrequentFaces:
            faceProcessingError = "Multiple different faces appear equally often in the photos. Please upload photos of the same person."

        case .imageProcessingFailed:
            faceProcessingError = "Failed to process the uploaded images. Please try uploading different photos."

        case .visionFrameworkError(let error):
            faceProcessingError = "Face detection failed: \(error.localizedDescription)"

        case .noImagesProvided:
            faceProcessingError = "No images were provided for face detection."
        }

        showFaceErrorAlert = true
    }
}

// MARK: - Thumbnail View

struct ThumbnailView: View {
let image: UIImage
let onDelete: () -> Void

var body: some View {
    ZStack(alignment: .topTrailing) {
            // Thumbnail image
        Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .frame(width: 50, height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )

            // Delete button
        Button(action: onDelete) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(Color.accent2)
                .background(Color.primaryBg)
                .clipShape(Circle())
                .opacity(0.7)
        }
        .offset(x: 8, y: -8)
    }
    .padding(.top, 10)
}
}
