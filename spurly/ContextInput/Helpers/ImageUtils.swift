//
//  ImageUtils.swift
//  spurly
//
//  Created by Alex Osterlind on 4/29/25.
//

import SwiftUI
import PhotosUI

// Helper function to correct image orientation (Important for uploads)

func imageWithCorrectOrientation(_ image: UIImage) -> UIImage? {
     // Check if orientation is already correct
     guard image.imageOrientation != .up else { return image }

     // Recalculate transform based on orientation
     var transform = CGAffineTransform.identity
     switch image.imageOrientation {
         case .down, .downMirrored:
             transform = transform.translatedBy(x: image.size.width, y: image.size.height)
             transform = transform.rotated(by: .pi)
         case .left, .leftMirrored:
             transform = transform.translatedBy(x: image.size.width, y: 0)
             transform = transform.rotated(by: .pi / 2)
         case .right, .rightMirrored:
             transform = transform.translatedBy(x: 0, y: image.size.height)
             transform = transform.rotated(by: -.pi / 2)
         case .up, .upMirrored:
             break
         @unknown default:
             break
     }

     // Apply mirroring if needed
     switch image.imageOrientation {
         case .upMirrored, .downMirrored:
             transform = transform.translatedBy(x: image.size.width, y: 0)
             transform = transform.scaledBy(x: -1, y: 1)
         case .leftMirrored, .rightMirrored:
             transform = transform.translatedBy(x: image.size.height, y: 0)
             transform = transform.scaledBy(x: -1, y: 1)
         default:
             break
     }

     // Create context and draw the new image
     guard let cgImage = image.cgImage, let colorSpace = cgImage.colorSpace else { return nil }
     guard let ctx = CGContext(data: nil, width: Int(image.size.width), height: Int(image.size.height),
                               bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0,
                               space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue) else { return nil }

     ctx.concatenate(transform)

     switch image.imageOrientation {
         case .left, .leftMirrored, .right, .rightMirrored:
             ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width))
         default:
             ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
     }

     // Get the new image
     guard let cgImg = ctx.makeImage() else { return nil }
     return UIImage(cgImage: cgImg)
 }

struct ImageThumbnailView: View {
    let image: UIImage
    let removeAction: () -> Void // Action to perform when remove button is tapped

    var body: some View {
        Image(uiImage: image)
            .resizable().scaledToFill().frame(width: 60, height: 60)
            .clipped().cornerRadius(8)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 1)
            .overlay(alignment: .topTrailing) {
                Button(action: removeAction) { // Use the passed-in action
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.accent2.opacity(0.9))
                        .background(Circle().fill(.white.opacity(0.7)))
                        .font(.callout)
            }.padding(4)
        }
    }
}

