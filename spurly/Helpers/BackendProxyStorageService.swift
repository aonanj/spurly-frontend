//
//
// File name: FirebaseAuthManagerExtension.swift
//
// Product / Project: spurly / spurly
//
// Organization: phaeton order llc
// Bundle ID: com.phaeton-order.spurly
//
//

import FirebaseAuth
import FirebaseStorage
import UIKit

// MARK: - Option 1: Integrate Firebase Auth with your existing auth system

//extension AuthManager {
//
//    // Call this after successful login with your backend
//    func authenticateWithFirebase(completion: @escaping (Bool) -> Void) {
//        guard let token = self.token else {
//            print("No backend token available for Firebase authentication")
//            completion(false)
//            return
//        }
//
//        // Option 1A: Use Custom Token from your backend
//        // Your backend would need to generate Firebase custom tokens
//        authenticateWithCustomToken(completion: completion)
//
//        // Option 1B: Use Anonymous Authentication (simpler but less secure)
//        // authenticateAnonymously(completion: completion)
//    }
//
//    // Option 1A: Custom Token Authentication (Recommended)
//    private func authenticateWithCustomToken(completion: @escaping (Bool) -> Void) {
//        // First, get a custom Firebase token from your backend
//        getFirebaseCustomToken { [weak self] result in
//            switch result {
//            case .success(let customToken):
//                Auth.auth().signIn(withCustomToken: customToken) { authResult, error in
//                    if let error = error {
//                        print("Firebase custom auth failed: \(error.localizedDescription)")
//                        completion(false)
//                    } else {
//                        print("Firebase custom auth successful")
//                        completion(true)
//                    }
//                }
//            case .failure(let error):
//                print("Failed to get Firebase custom token: \(error.localizedDescription)")
//                completion(false)
//            }
//        }
//    }
//
//    // Option 1B: Anonymous Authentication (Less secure but simpler)
//    private func authenticateAnonymously(completion: @escaping (Bool) -> Void) {
//        Auth.auth().signInAnonymously { authResult, error in
//            if let error = error {
//                print("Firebase anonymous auth failed: \(error.localizedDescription)")
//                completion(false)
//            } else {
//                print("Firebase anonymous auth successful")
//                completion(true)
//            }
//        }
//    }
//
//    // Get Firebase custom token from your backend
//    private func getFirebaseCustomToken(completion: @escaping (Result<String, Error>) -> Void) {
//        guard let token = self.token, let userId = self.userId else {
//            completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No auth token available"])))
//            return
//        }
//
//        #if DEBUG
//        let baseURL = "https://staging-api.yourbackend.com/api"
//        #else
//        let baseURL = "https://api.yourbackend.com/api"
//        #endif
//
//        guard let url = URL(string: "\(baseURL)/firebase/custom-token") else {
//            completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//
//        let payload = ["user_id": userId]
//        request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
//
//        URLSession.shared.dataTask(with: request) { data, response, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//
//            guard let data = data,
//                  let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
//                  let customToken = response["custom_token"] as? String else {
//                completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
//                return
//            }
//
//            completion(.success(customToken))
//        }.resume()
//    }
//}
//
//// MARK: - Option 2: Use Firebase Storage without Authentication (Public bucket)
//
//class FirebaseStorageServiceNoAuth {
//
//    static let shared = FirebaseStorageServiceNoAuth()
//    private let storage = Storage.storage()
//
//    private init() {}
//
//    // Upload to a public bucket or use your backend user ID for organization
//    func uploadConnectionFacePhoto(_ image: UIImage, userId: String, connectionId: String, completion: @escaping (Result<String, FirebaseStorageError>) -> Void) {
//
//        // Compress image for upload
//        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
//            completion(.failure(.imageCompressionFailed))
//            return
//        }
//
//        // Create storage reference using your backend user ID
//        let fileName = "connection_face_\(connectionId)_\(Date().timeIntervalSince1970).jpg"
//        let storageRef = storage.reference()
//            .child("public_uploads") // Or use a public bucket
//            .child("users")
//            .child(userId) // Use your backend user ID
//            .child("connections")
//            .child(connectionId)
//            .child("face_photos")
//            .child(fileName)
//
//        // Upload metadata
//        let metadata = StorageMetadata()
//        metadata.contentType = "image/jpeg"
//        metadata.customMetadata = [
//            "connection_id": connectionId,
//            "user_id": userId,
//            "upload_date": ISO8601DateFormatter().string(from: Date()),
//            "image_type": "connection_face"
//        ]
//
//        // Upload the image
//        let uploadTask = storageRef.putData(imageData, metadata: metadata) { metadata, error in
//            if let error = error {
//                print("Firebase upload error: \(error.localizedDescription)")
//                completion(.failure(.uploadFailed(error)))
//                return
//            }
//
//            // Get download URL
//            storageRef.downloadURL { url, error in
//                if let error = error {
//                    print("Firebase download URL error: \(error.localizedDescription)")
//                    completion(.failure(.downloadUrlFailed(error)))
//                    return
//                }
//
//                guard let downloadURL = url else {
//                    completion(.failure(.downloadUrlFailed(NSError(domain: "FirebaseStorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No download URL returned"]))))
//                    return
//                }
//
//                print("Successfully uploaded connection face photo: \(downloadURL.absoluteString)")
//                completion(.success(downloadURL.absoluteString))
//            }
//        }
//
//        // Monitor upload progress
//        uploadTask.observe(.progress) { snapshot in
//            let progress = Double(snapshot.progress?.completedUnitCount ?? 0) / Double(snapshot.progress?.totalUnitCount ?? 1)
//            print("Upload progress: \(progress * 100)%")
//        }
//    }
//}

// MARK: - Option 3: Use your backend as a proxy for Firebase uploads

class BackendProxyStorageService {

    static let shared = BackendProxyStorageService()
    private init() {}

    func uploadConnectionFacePhoto(_ image: UIImage, connectionId: String, authToken: String, completion: @escaping (Result<String, Error>) -> Void) {

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            completion(.failure(NSError(domain: "BackendProxyStorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }

        #if DEBUG
        let baseURL = "https://spurly-middleware-280376325694.us-west2.run.app"
        #else
        let baseURL = "https://spurly-middleware-280376325694.us-west2.run.app"
        #endif

        // Updated URL to match the new endpoint
        guard let url = URL(string: "\(baseURL)/connections/upload-face-photo") else {
            completion(.failure(NSError(domain: "BackendProxyStorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")

        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // Add connection ID
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"connection_id\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(connectionId)\r\n".data(using: .utf8)!)

        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"face_photo\"; filename=\"face.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    completion(.failure(NSError(domain: "BackendProxyStorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Server error"])))
                    return
                }

                guard let data = data,
                      let response = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let photoURL = response["photo_url"] as? String else {
                    completion(.failure(NSError(domain: "BackendProxyStorageService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                    return
                }

                completion(.success(photoURL))
            }
        }.resume()
    }
}
