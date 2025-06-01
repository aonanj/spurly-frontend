//
//
// File name: ErrorOverlayView.swift
//
// Product / Project: spurly / spurly
//
// Organization: phaeton order llc
// Bundle ID: com.phaeton-order.spurly
//
//

import SwiftUI

struct ErrorOverlayView: View {
    // MARK: - Properties

    /// Binding to control the visibility of the overlay.
    /// When set to false, the overlay will dismiss.
    @Binding var isPresented: Bool

    /// The title of the error message.
    let errorTitle: String

    /// The detailed error message.
    let errorMessage: String

    let autoDismissDelay: Double?

    /// An optional action to perform when the overlay is dismissed.
    /// This can be used for cleanup tasks like resetting state variables or calling ViewModel methods.
    let onDismiss: (() -> Void)?

    init(
        isPresented: Binding<Bool>,
        errorTitle: String,
        errorMessage: String,
        autoDismissDelay: Double? = 5.0,
        onDismiss: (() -> Void)? = nil
    ) {
        _isPresented = isPresented
        self.errorTitle = errorTitle
        self.errorMessage = errorMessage
        self.autoDismissDelay = autoDismissDelay
        self.onDismiss = onDismiss
    }


    // MARK: - Body

    var body: some View {
        // The main ZStack that holds the semi-transparent background and the error content.
        ZStack {
            // Semi-transparent background that covers the entire screen.
            Color.black.opacity(0.5)
                .ignoresSafeArea() // Ensures the background extends to the screen edges.
                .transition(.opacity) // Animate the appearance/disappearance of the background.
                .onTapGesture {
                    // Allows dismissing the overlay by tapping on the background.
                    isPresented = false
                    onDismiss?() // Execute the dismiss action if provided.
                }
                .zIndex(3) // Ensures the background is behind the error message content but above other views if used in a complex ZStack.

            // VStack to center the error message card on the screen.
            VStack {
                Spacer() // Pushes the error card to the vertical center.

                // VStack for the content of the error message card.
                VStack(spacing: 12) {
                    // Error Icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                        .shadow(color: Color.accent1.opacity(0.7), // Assuming Color.accent1 is defined in your project
                                radius: 8,
                                x: 0,
                                y: 4)

                    // Error Title
                    Text(errorTitle)
                        .font(.headline)
                        .foregroundColor(.primaryText) // Assuming Color.primaryText is defined

                    // Divider
                    Divider()
                        .frame(maxWidth: .infinity)
                        .frame(height: 2)
                        .background(Color.accent1) // Assuming Color.accent1 is defined
                        .padding(.horizontal, 15)
                        .opacity(0.4)
                        .shadow(color: Color.black.opacity(0.55), radius: 3, x: 2, y: 2)

                    // Error Message
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.secondaryText) // Assuming Color.secondaryText is defined
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Dismiss Button
                    Button("dismiss") {
                        isPresented = false
                        onDismiss?() // Execute the dismiss action if provided.
                    }
                    .font(.body)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.red.opacity(0.6))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(.top)
                }
                .padding(EdgeInsets(top: 30, leading: 20, bottom: 20, trailing: 20)) // Padding inside the card
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.cardBg) // Assuming Color.cardBg is defined
                        .shadow(color: .black.opacity(0.8), radius: 10, x: 2, y: 5)
                )
                .padding(.horizontal, 30) // Padding around the card

                Spacer() // Pushes the error card to the vertical center.
            }
            // Animation for the appearance/disappearance of the error content.
            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            .onAppear {
                if let delay = autoDismissDelay {
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        if isPresented {
                           dismissOverlay()
                        }
                    }
                }
            }
            .zIndex(4) // Ensures the error message content is above the semi-transparent background.
        }
        .zIndex(4) // Ensures the entire overlay is above other content in the calling view.
                   // You might adjust this zIndex based on your view hierarchy.
    }

    private func dismissOverlay() {
        isPresented = false
        onDismiss?()
    }
}

// MARK: - Preview

struct ErrorOverlayView_Previews: PreviewProvider {
    // Example state for the preview
    @State static var showPreviewError = true

    static var previews: some View {
        // Example usage for the preview
        ZStack {
            // Sample background content for context
            Color.blue.ignoresSafeArea()
            Text("Some background content")
                .foregroundColor(.white)

            // The ErrorOverlayView
            if showPreviewError {
                ErrorOverlayView(
                    isPresented: $showPreviewError,
                    errorTitle: "Sample Error",
                    errorMessage: "This is a detailed description of what went wrong. Please try again later.",
                    onDismiss: {
                        print("Preview Overlay Dismissed!")
                    }
                )
            }
        }
    }
}
