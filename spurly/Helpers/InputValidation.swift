//
//  InputValidation.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

// Original CharacterLimiter for non-optional String
@available(iOS 17.0, *)
struct CharacterLimiter: ViewModifier {
    @Binding var text: String // Non-optional
    let limit: Int

    func body(content: Content) -> some View {
        content
            .onChange(of: text) { oldValue, newValue in
                if newValue.count > limit {
                    DispatchQueue.main.async {
                        // Check current value before truncating
                        if text.count > limit {
                            text = String(newValue.prefix(limit))
                        }
                    }
                }
            }
    }
}

// OptionalCharacterLimiter for optional String (keep this as is)
@available(iOS 17.0, *)
struct OptionalCharacterLimiter: ViewModifier {
    @Binding var text: String? // Optional
    let limit: Int

    func body(content: Content) -> some View {
        content
            .onChange(of: text) { oldValue, newValue in
                guard let newString = newValue, newString.count > limit else {
                    return
                }
                DispatchQueue.main.async {
                    // Check current value before truncating
                    if let currentText = text, currentText.count > limit {
                        text = String(newString.prefix(limit))
                    }
                }
            }
    }
}

// Extension for View
@available(iOS 17.0, *)
extension View {
    // Overload for Binding<String?> (keep this as is)
    func limitInputLength(for text: Binding<String?>, limit: Int = 29) -> some View {
        self.modifier(OptionalCharacterLimiter(text: text, limit: limit))
    }

    // Add this overload for Binding<String>
    func limitInputLength(for text: Binding<String>, limit: Int = 29) -> some View {
        self.modifier(CharacterLimiter(text: text, limit: limit))
    }
}

// --- Example Usage (within Card Content views) ---
/*
 struct BasicsCardContent: View {
     @Binding var name: String? // Already optional
     // ... other bindings

     let nameLimit = 50 // Example limit for name

     var body: some View {
         VStack {
             TextField("Name", text: $name.bound) // Use a helper to bind TextField to String?
                 .textFieldStyle(CustomTextFieldStyle()) // Your existing style
                 .limitInputLength(for: $name, limit: nameLimit) // Apply the modifier directly to Binding<String?>

             // ... other fields
         }
     }
 }

 // Helper extension for binding TextField to String?
 extension Binding where Value == String? {
     var bound: Binding<String> {
         Binding<String>(
             get: { self.wrappedValue ?? "" },
             set: { self.wrappedValue = $0.isEmpty ? nil : $0 }
         )
     }
 }
 */
