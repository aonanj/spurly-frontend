//
//  ViewExtensions.swift
//  spurly
//
//  Created by Alex Osterlind on 4/29/25.
//

import SwiftUI

extension View {

    // MARK: - Helper Button Styles (for cleaner overlay code)

    var clearButtonStyle: some View {
         Image(systemName: "xmark")
             .padding(10)
             .background(Circle().fill(Color.accent1.opacity(0.8)))
             .foregroundColor(.white)
             .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
     }

     var photosPickerStyle: some View {
          Image(systemName: "photo.on.rectangle.angled")
              .padding(10)
              .background(Circle().fill(Color.accent1.opacity(0.8)))
              .foregroundColor(.white)
              .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
      }

    // MARK: - Helper Footer View

    var footerView: some View {
         VStack(spacing: 2) {
              Text("we care about protecting your data")
                  .font(.footnote).foregroundColor(.secondaryText).opacity(0.6)
              // Ensure you have a valid URL here
              Link(destination: URL(string: "https://example.com/privacy")!) {
                  Text("learn more here")
                      .underline().font(.footnote)
                      .foregroundStyle(Color.secondaryText).opacity(0.6)
              }
          }
    }
}


// MARK: - Helper Submission Error View
struct SubmissionErrorView: View {
    @Binding var submissionError: String?

    var body: some View {
        if let errorMsg = submissionError {
            Text("Error: \(errorMsg)")
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal)
                .multilineTextAlignment(.center)
        } else {
            EmptyView()
        }
    }
}


