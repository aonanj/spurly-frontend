//
//  ContextInputStyles.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI


// MARK: – Configuration
private let situationOptions = [
    "", "cold intro", "cta setup", "cta response",
    "no response", "reengagement",
    "recovery", "switch subject", "refine"
]


private let inputBackgroundOpacity: Double = 0.9 // Adjust as needed (0.0 to 1.0)
// Extracted Topic Field into a helper function
//@ViewBuilder
struct TopicFieldView: View {
    @Binding var topic: String
    @Binding var showTopicError: Bool
    var isTopicFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("topic").font(.subheadline).bold().foregroundColor(.secondaryText)
            TextField("...", text: $topic)
                .focused(isTopicFocused)
                .textFieldStyle(CustomTextFieldStyle()) // Assumes this style exists
                .limitInputLength(for: $topic, limit: 50) // Assumes this modifier exists
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(showTopicError ? Color.red : Color.clear, lineWidth: 1.5))
                .onChange(of: topic) {
                    if IsTopicProhibited(topic: self.topic) { showTopicError = true; topic = "" } else { showTopicError = false }
                }
                .opacity(inputBackgroundOpacity + 0.05) // Apply opacity

            // Display Topic Error Message inline
            if showTopicError {
                Text("Topic not allowed.")
                    .font(.caption).foregroundColor(.red).padding(.leading, 4)

            }
        }
    }
}

// Extracted Situation Picker into a helper function
//@ViewBuilder
struct SituationPicker: View {
    @Binding var selectedSituation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("situation")
                .font(.subheadline)
                .bold()
                .foregroundColor(.secondaryText)
            CustomPickerStyle(
                title: "", selection: $selectedSituation,
                options: situationOptions, textMapping: { $0.isEmpty ? "..." : $0 }
            )
            .opacity(inputBackgroundOpacity + 0.05) // Apply opacity
        }
    }
}
