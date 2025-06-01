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

        VStack(spacing: 1) {

            ZStack(alignment: .leading) {

                if topic.isEmpty {
                    Text("topic")
                        .font(Font.custom("SF Pro Text", size: 14).weight(.regular))
                        .foregroundStyle(Color.secondaryText.opacity(0.9))
                        .padding(.horizontal, 15)
                        .zIndex(1)
                }

                TextField("", text: $topic)
                    .focused(isTopicFocused)
                    .textFieldStyle(CustomTextFieldStyle())
                    .foregroundStyle(Color.primaryText)
                    .padding(4)
                    .limitInputLength(for: $topic, limit: 50) // Assumes this modifier exists
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(showTopicError ? Color.red : Color.clear, lineWidth: 1.5))
                    .onChange(of: topic) {
                        if IsTopicProhibited(topic: self.topic) { showTopicError = true; topic = "" } else {
                            showTopicError = false; //hideKeyboard()
                        }
                    }
                    .opacity(inputBackgroundOpacity)
                    .zIndex(0)
            }
        }
    }
}

// Extracted Situation Picker into a helper function
//@ViewBuilder
struct SituationPicker: View {
    @Binding var selectedSituation: String

    var body: some View {
        CustomPickerStyle(
            title: "situation", selection: $selectedSituation,
            options: situationOptions, textMapping: { $0.isEmpty ? "..." : $0 }
        )
        .opacity(inputBackgroundOpacity) // Apply opacity
    }
}
