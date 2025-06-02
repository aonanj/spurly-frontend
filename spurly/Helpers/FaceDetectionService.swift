//
//
// File name: FaceDetectionService.swift
//
// Product / Project: spurly / spurly
//
// Organization: phaeton order llc
// Bundle ID: com.phaeton-order.spurly
//
//

import UIKit
import Vision
import CoreImage

struct DetectedFace {
    let boundingBox: CGRect
    let landmarks: VNFaceLandmarks2D?
    let confidence: Float
    let sourceImageIndex: Int
}

struct FaceMatch {
    let face: DetectedFace
    let matchCount: Int
}

class FaceDetectionService {

    static let shared = FaceDetectionService()
    private init() {}

    // MARK: - Main Processing Function

    func processFacesInImages(_ images: [UIImage], completion: @escaping (Result<UIImage, FaceDetectionError>) -> Void) {
        guard !images.isEmpty else {
            completion(.failure(.noImagesProvided))
            return
        }

        detectFacesInImages(images) { result in
            switch result {
            case .success(let allFaces):
                guard !allFaces.isEmpty else {
                    completion(.failure(.noFacesDetected))
                    return
                }

                // Handle single image case
                if images.count == 1 {
                    self.handleSingleImage(faces: allFaces, image: images[0], completion: completion)
                } else {
                    self.handleMultipleImages(faces: allFaces, images: images, completion: completion)
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // MARK: - Face Detection

    private func detectFacesInImages(_ images: [UIImage], completion: @escaping (Result<[DetectedFace], FaceDetectionError>) -> Void) {
        var allDetectedFaces: [DetectedFace] = []
        let dispatchGroup = DispatchGroup()
        var detectionError: FaceDetectionError?

        for (index, image) in images.enumerated() {
            dispatchGroup.enter()

            detectFacesInImage(image, imageIndex: index) { result in
                defer { dispatchGroup.leave() }

                switch result {
                case .success(let faces):
                    allDetectedFaces.append(contentsOf: faces)
                case .failure(let error):
                    detectionError = error
                }
            }
        }

        dispatchGroup.notify(queue: .main) {
            if let error = detectionError {
                completion(.failure(error))
            } else {
                completion(.success(allDetectedFaces))
            }
        }
    }

    private func detectFacesInImage(_ image: UIImage, imageIndex: Int, completion: @escaping (Result<[DetectedFace], FaceDetectionError>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(.imageProcessingFailed))
            return
        }

        let request = VNDetectFaceLandmarksRequest { request, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Face detection error: \(error.localizedDescription)")
                    completion(.failure(.visionFrameworkError(error)))
                    return
                }

                guard let observations = request.results as? [VNFaceObservation] else {
                    completion(.success([]))
                    return
                }

                let detectedFaces = observations.compactMap { observation -> DetectedFace? in
                    // Only include faces with reasonable confidence
                    guard observation.confidence > 0.5 else { return nil }

                    return DetectedFace(
                        boundingBox: observation.boundingBox,
                        landmarks: observation.landmarks,
                        confidence: observation.confidence,
                        sourceImageIndex: imageIndex
                    )
                }

                completion(.success(detectedFaces))
            }
        }

        // Configure the request for better performance
        request.revision = VNDetectFaceLandmarksRequestRevision3

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.visionFrameworkError(error)))
                }
            }
        }
    }

    // MARK: - Face Matching and Analysis

    private func handleSingleImage(faces: [DetectedFace], image: UIImage, completion: @escaping (Result<UIImage, FaceDetectionError>) -> Void) {
        if faces.count == 0 {
            completion(.failure(.noFacesDetected))
        } else if faces.count == 1 {
            // Single face found, crop it
            cropFaceFromImage(image, face: faces[0], completion: completion)
        } else {
            // Multiple faces in single image
            completion(.failure(.multipleFacesInSingleImage))
        }
    }

    private func handleMultipleImages(faces: [DetectedFace], images: [UIImage], completion: @escaping (Result<UIImage, FaceDetectionError>) -> Void) {
        // Group faces by similarity
        let faceMatches = findMostFrequentFace(faces: faces)

        if faceMatches.isEmpty {
            completion(.failure(.noFacesDetected))
            return
        }

        // Check if we have a clear winner
        let sortedMatches = faceMatches.sorted { $0.matchCount > $1.matchCount }
        let topMatch = sortedMatches[0]

        // Check for ties
        let tiedMatches = sortedMatches.filter { $0.matchCount == topMatch.matchCount }
        if tiedMatches.count > 1 {
            completion(.failure(.multipleMostFrequentFaces))
            return
        }

        // We have a clear winner, crop the best face
        let bestFace = topMatch.face
        let sourceImage = images[bestFace.sourceImageIndex]
        cropFaceFromImage(sourceImage, face: bestFace, completion: completion)
    }

    private func findMostFrequentFace(faces: [DetectedFace]) -> [FaceMatch] {
        var faceGroups: [[DetectedFace]] = []

        // Group similar faces together
        for face in faces {
            var addedToGroup = false

            for i in 0..<faceGroups.count {
                if facesAreSimilar(face, faceGroups[i][0]) {
                    faceGroups[i].append(face)
                    addedToGroup = true
                    break
                }
            }

            if !addedToGroup {
                faceGroups.append([face])
            }
        }

        // Convert groups to matches and find the best face from each group
        let faceMatches: [FaceMatch] = faceGroups.compactMap { group in
            guard !group.isEmpty else { return nil }

            // Find the face with highest confidence in this group
            let bestFace = group.max { $0.confidence < $1.confidence } ?? group[0]

            return FaceMatch(face: bestFace, matchCount: group.count)
        }

        return faceMatches
    }

    private func facesAreSimilar(_ face1: DetectedFace, _ face2: DetectedFace) -> Bool {
        // Simple similarity check based on bounding box size and aspect ratio
        let box1 = face1.boundingBox
        let box2 = face2.boundingBox

        let sizeThreshold: CGFloat = 0.3
        let aspectThreshold: CGFloat = 0.2

        let sizeDiff = abs(box1.width - box2.width) + abs(box1.height - box2.height)
        let aspect1 = box1.width / box1.height
        let aspect2 = box2.width / box2.height
        let aspectDiff = abs(aspect1 - aspect2)

        return sizeDiff < sizeThreshold && aspectDiff < aspectThreshold
    }

    // MARK: - Image Cropping

    private func cropFaceFromImage(_ image: UIImage, face: DetectedFace, completion: @escaping (Result<UIImage, FaceDetectionError>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(.imageProcessingFailed))
            return
        }

        // Convert Vision coordinates to image coordinates
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let faceRect = VNImageRectForNormalizedRect(face.boundingBox, Int(imageSize.width), Int(imageSize.height))

        // Add padding around the face (20% on each side)
        let padding: CGFloat = 0.2
        let paddedRect = CGRect(
            x: max(0, faceRect.origin.x - faceRect.width * padding),
            y: max(0, faceRect.origin.y - faceRect.height * padding),
            width: min(imageSize.width - max(0, faceRect.origin.x - faceRect.width * padding),
                      faceRect.width * (1 + 2 * padding)),
            height: min(imageSize.height - max(0, faceRect.origin.y - faceRect.height * padding),
                       faceRect.height * (1 + 2 * padding))
        )

        // Crop the image
        guard let croppedCGImage = cgImage.cropping(to: paddedRect) else {
            completion(.failure(.imageProcessingFailed))
            return
        }

        let croppedImage = UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
        completion(.success(croppedImage))
    }
}

// MARK: - Error Types

enum FaceDetectionError: LocalizedError {
    case noImagesProvided
    case noFacesDetected
    case multipleFacesInSingleImage
    case multipleMostFrequentFaces
    case imageProcessingFailed
    case visionFrameworkError(Error)

    var errorDescription: String? {
        switch self {
        case .noImagesProvided:
            return "No images provided for face detection"
        case .noFacesDetected:
            return "No faces detected in the provided images"
        case .multipleFacesInSingleImage:
            return "Multiple faces detected in a single image"
        case .multipleMostFrequentFaces:
            return "Multiple faces appear with the same frequency"
        case .imageProcessingFailed:
            return "Failed to process image for face detection"
        case .visionFrameworkError(let error):
            return "Vision framework error: \(error.localizedDescription)"
        }
    }
}
