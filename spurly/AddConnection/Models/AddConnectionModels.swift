import SwiftUI
import UIKit
import PhotosUI

struct AddConnectionPayload: Codable {
    var connectionName: String?
    var connectionAge: Int?
    var connectionContextBlock: String?
    var connectionOcrImages: [UIImage]?
    var connectionProfileImages: [UIImage]?

    // CodingKeys remain the same, but we will handle encoding/decoding manually for images.
    enum CodingKeys: String, CodingKey {
        case connectionName
        case connectionAge
        case connectionContextBlock
        case connectionOcrImages
        case connectionProfileImages
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

        // Encode OCR images
        if let ocrImages = connectionOcrImages {
            // You can choose .pngData() or .jpegData(compressionQuality:)
            let ocrImageDataArray = ocrImages.compactMap { $0.pngData() }
            try container.encode(ocrImageDataArray, forKey: .connectionOcrImages)
        }

        // Encode Profile images
        if let profileImages = connectionProfileImages {
            // You can choose .pngData() or .jpegData(compressionQuality:)
            let profileImageDataArray = profileImages.compactMap { $0.pngData() }
            try container.encode(profileImageDataArray, forKey: .connectionProfileImages)
        }
    }
}

struct AddConnectionResponse: Codable {
    var user_id: String
    var token: String
}

import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @Binding var selectedImages: [UIImage]
    @State private var selectedItems: [PhotosPickerItem] = []
    private let maxPhotos = 4
    let label: String

    var body: some View {
        VStack(spacing: 20) {
            // Photo picker button
            PhotosPicker(
                selection: $selectedItems,
                maxSelectionCount: maxPhotos,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label("\(label) (\(selectedImages.count)/\(maxPhotos))",
                      systemImage: "photo.on.rectangle.angled")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .onChange(of: selectedItems) { newItems in
                loadImages(from: newItems)
            }

            // Thumbnails grid
            if !selectedImages.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 10) {
                        ForEach(Array(selectedImages.enumerated()), id: \.offset) { index, image in
                            ThumbnailView(image: image) {
                                removeImage(at: index)
                            }
                        }
                    }
                    .padding()
                }
            } else {
                Text("No photos selected")
                    .foregroundColor(.gray)
                    .padding()
            }

            Spacer()
        }
        .navigationTitle(label)
        .padding()
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
}

// Thumbnail view with delete button
struct ThumbnailView: View {
    let image: UIImage
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Thumbnail image
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.red)
                    .clipShape(Circle())
            }
            .offset(x: 8, y: -8)
        }
    }
}

//// Example usage in a ContentView
//struct ContentView: View {
//    var body: some View {
//        NavigationView {
//            PhotoPickerView()
//        }
//    }
//}
//
//// For UIKit integration, here's a UIViewController wrapper
//class PhotoPickerViewController: UIHostingController<PhotoPickerView> {
//    init() {
//        super.init(rootView: PhotoPickerView(selectedImages: <#Binding<[UIImage]>#>, label: <#String#>))
//    }
//
//    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
