//
//
// File name: SuccessOverlayView.swift
//
// Product / Project: spurly / spurly
//
// Organization: phaeton order llc
// Bundle ID: com.phaeton-order.spurly
//
//


import SwiftUI

struct SuccessOverlayView: View {
    @Binding var isPresented: Bool
    let message: String
    let iconName: String       // Default was "staroflife.fill"
    let iconColor: Color       // Default was .spurlyBrand
    let autoDismissDelay: Double? // Default was 2.0
    let onDismiss: (() -> Void)?  // Default was nil

    // Swift's memberwise initializer for this would expect labels
    // if you provide values for properties that have defaults.
    // We can make this more explicit by defining our own init.

    // Explicit Initializer to clarify usage:
    init(
        isPresented: Binding<Bool>,
        message: String,
        iconName: String = "staroflife.fill", // Default icon
        iconColor: Color = .spurlyBrand,      // Default icon color
        autoDismissDelay: Double? = 5.0,      // Default 2-second auto-dismiss
        onDismiss: (() -> Void)? = nil        // Optional dismiss action
    ) {
        _isPresented = isPresented // Note the underscore for @Binding
        self.message = message
        self.iconName = iconName
        self.iconColor = iconColor
        self.autoDismissDelay = autoDismissDelay
        self.onDismiss = onDismiss
    }

    var body: some View {
        // ... (rest of the body is the same as before) ...
        ZStack {
            Color.primaryText.opacity(0.5)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture { dismissOverlay() }
                .zIndex(3)

            VStack {
                Spacer()
                Image(systemName: iconName)
                    .font(.system(size: 35))
                    .foregroundColor(iconColor)
                    .shadow(color: Color.accent1.opacity(0.7), radius: 8, x: 0, y: 4)
                Spacer()
                Divider()
                    .frame(maxWidth: .infinity)
                    .frame(height: 2)
                    .background(Color.accent1)
                    .padding(.horizontal, 15)
                    .opacity(0.4)
                    .shadow(color: Color.black.opacity(0.55), radius: 3, x: 2, y: 2)
                Text(message)
                    .font(.headline)
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cardBg)
                            .shadow(color: Color.accent1.opacity(0.7), radius: 8, x: 2, y: 4)
                    )
                    .padding(.horizontal, 40)
                Spacer()
            }
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
            .zIndex(4)
        }
        .zIndex(4)
    }

    private func dismissOverlay() {
        isPresented = false
        onDismiss?()
    }
}
