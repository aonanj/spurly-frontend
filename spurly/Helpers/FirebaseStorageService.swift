//
//
// File name: FirebaseStorageService.swift
//
// Product / Project: spurly / spurly
//
// Organization: phaeton order llc
// Bundle ID: com.phaeton-order.spurly
//
//

import UIKit
import FirebaseStorage
import FirebaseAuth

class FirebaseStorageService {

    static let shared = FirebaseStorageService()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - Upload Connection Face Photo

    func uploadConnectionFacePhoto(_ image: UIImage, connectionId: String, completion: @escaping (Result<String, FirebaseStorageError>) -> Void) {

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(.notAuthenticated))
            return
        }

        // Compress image for upload
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(.imageCompressionFailed))
            return
        }

        // Create storage reference
        let fileName = "connection_face_\(connectionId)_\(Date().timeIntervalSince1970).jpg"
        let storageRef = storage.reference()
            .child("users")
            .child(userId)
            .child("connections")
            .child(connectionId)
            .child("face_photos")
            .child(fileName)

        // Upload metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "connection_id": connectionId,
            "upload_date": ISO8601DateFormatter().string(from: Date()),
            "image_type": "connection_face"
        ]

        // Upload the image
        let uploadTask = storageRef.putData(imageData, metadata: metadata) { metadata, error in
            if let error = error {
                print("Firebase upload error: \(error.localizedDescription)")
                completion(.failure(.uploadFailed(error)))
                return
            }

            // Get download URL
            storageRef.downloadURL { url, error in
                if let error = error {
                    print("Firebase download URL error: \(error.localizedDescription)")
                    completion(.failure(.downloadUrlFailed(error)))
                    return
                }

                guard let downloadURL = url else {
                    completion(.failure(.downloadUrlFailed(NSError(domain: "FirebaseStorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No download URL returned"]))))
                    return
                }

                print("Successfully uploaded connection face photo: \(downloadURL.absoluteString)")
                completion(.success(downloadURL.absoluteString))
            }
        }

        // Monitor upload progress (optional)
        uploadTask.observe(.progress) { snapshot in
            let progress = Double(snapshot.progress?.completedUnitCount ?? 0) / Double(snapshot.progress?.totalUnitCount ?? 1)
            print("Upload progress: \(progress * 100)%")
        }
    }

    // MARK: - Delete Connection Face Photo

    func deleteConnectionFacePhoto(connectionId: String, completion: @escaping (Result<Void, FirebaseStorageError>) -> Void) {

        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(.notAuthenticated))
            return
        }

        let folderRef = storage.reference()
            .child("users")
            .child(userId)
            .child("connections")
            .child(connectionId)
            .child("face_photos")

        // List all files in the face_photos folder
        folderRef.listAll { result, error in
            if let error = error {
                print("Error listing face photos: \(error.localizedDescription)")
                completion(.failure(.deleteFailed(error)))
                return
            }

            guard let result = result else {
                completion(.success(()))
                return
            }

            // Delete all files in the folder
            let deleteGroup = DispatchGroup()
            var deleteError: Error?

            for item in result.items {
                deleteGroup.enter()
                item.delete { error in
                    if let error = error {
                        deleteError = error
                        print("Error deleting file \(item.name): \(error.localizedDescription)")
                    }
                    deleteGroup.leave()
                }
            }

            deleteGroup.notify(queue: .main) {
                if let error = deleteError {
                    completion(.failure(.deleteFailed(error)))
                } else {
                    print("Successfully deleted all face photos for connection \(connectionId)")
                    completion(.success(()))
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func generateFileName(for connectionId: String) -> String {
        let timestamp = Date().timeIntervalSince1970
        return "connection_face_\(connectionId)_\(timestamp).jpg"
    }
}

// MARK: - Error Types

enum FirebaseStorageError: LocalizedError {
    case notAuthenticated
    case imageCompressionFailed
    case uploadFailed(Error)
    case downloadUrlFailed(Error)
    case deleteFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .imageCompressionFailed:
            return "Failed to compress image for upload"
        case .uploadFailed(let error):
            return "Upload failed: \(error.localizedDescription)"
        case .downloadUrlFailed(let error):
            return "Failed to get download URL: \(error.localizedDescription)"
        case .deleteFailed(let error):
            return "Failed to delete file: \(error.localizedDescription)"
        }
    }
}
