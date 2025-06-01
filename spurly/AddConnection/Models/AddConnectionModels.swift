//
//  AddConnectionModels.swift
//
//  Author: phaeton order llc
//  Target: spurly
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

    // CodingKeys remain the same, but we will handle encoding/decoding manually for images
    enum CodingKeys: String, CodingKey {
        case connectionName = "connection_name"
        case connectionAge = "connection_age"
        case connectionContextBlock = "connection_context_block"
        case connectionOcrImages = "connection_ocr_images"
        case connectionProfileImages = "connection_profile_images"
    }

    // Custom initializer
    init(connectionName: String?, connectionAge: Int?, connectionContextBlock: String?, connectionOcrImages: [UIImage]?, connectionProfileImages: [UIImage]?) {
        self.connectionName = connectionName?.isEmpty ?? true ? nil : connectionName
        self.connectionAge = connectionAge
        self.connectionContextBlock = connectionContextBlock?.isEmpty ?? true ? nil : connectionContextBlock
        self.connectionOcrImages = connectionOcrImages?.isEmpty ?? true ? nil : connectionOcrImages
        self.connectionProfileImages = connectionProfileImages?.isEmpty ?? true ? nil : connectionProfileImages
    }

    // Custom Decodable initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        connectionName = try container.decodeIfPresent(String.self, forKey: .connectionName)
        connectionAge = try container.decodeIfPresent(Int.self, forKey: .connectionAge)
        connectionContextBlock = try container.decodeIfPresent(String.self, forKey: .connectionContextBlock)

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

// MARK: - Photo Picker View

struct PhotoPickerView: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var newSelectedItems: [PhotosPickerItem] = []
    private let maxPhotos = 4
    let label: String
    let photoPickerToolHelp: String

    var body: some View {
        VStack(spacing: 8) {


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
                    if selectedImages.isEmpty   {
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
    }

    // Load images from PhotosPickerItem
    private func loadImages(from items: [PhotosPickerItem]) {
        selectedImages.removeAll()

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
    }


    // Remove image at index
    private func removeImage(at index: Int) {
        guard index < selectedImages.count else { return }
        selectedImages.remove(at: index)

        // Also remove from selectedItems to keep in sync
        if index < selectedItems.count {
            selectedItems.remove(at: index)
        }
    }

    private func addPreviousToNewItems(previousItems: [PhotosPickerItem]) {

        for item in previousItems {
            newSelectedItems.append(item)
        }
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
