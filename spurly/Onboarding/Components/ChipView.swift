//
//  ChipView.swift
//  spurly
//
//  Created by Alex Osterlind on 4/29/25.
//

import SwiftUI

enum TopicFlowItem: Identifiable, Hashable {
    case chip(String); case inputField
    var id: String { switch self { case .chip(let t): return "chip-\(t)"; case .inputField: return "inputField" } }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: TopicFlowItem, rhs: TopicFlowItem) -> Bool { lhs.id == rhs.id }
}


struct ChipView: View {
    let topic: String; let isGreen: Bool; let deleteAction: () -> Void
    let topicChipGreen = Color(hex: "#D0FFBC")
    let topicChipRed = Color(hex: "#FF8488")
    var body: some View {
        HStack(spacing: 4) {
            Text(topic).lineLimit(1).font(.system(size: 14)).foregroundColor(Color.spurlyPrimaryText.opacity(0.9))
            Button(action: deleteAction) { Image(systemName: "xmark.circle.fill").foregroundColor(Color.spurlySecondaryText) }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .fixedSize()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isGreen
                      ? topicChipGreen.opacity(0.7)
                      : topicChipRed.opacity(0.7))
                .shadow(color: .black.opacity(0.5), radius: 4, x: 4, y: 4)
        )
    }
}



struct TopicInputField: View {
    var label: String; @Binding var topics: [String]; var exclude: [String]; var allTopics: [String]; var isGreen: Bool
    @State private var newTopic = ""; @FocusState private var isTextFieldFocused: Bool; @State private var flowLayoutHeight: CGFloat = 30
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular); let inputFont = Font.custom("SF Pro Text", size: 16).weight(.regular); let placeholderText = "add..."
    private var flowItems: [TopicFlowItem] {
        let chipItems = topics.map { TopicFlowItem.chip($0) }

        if topics.count < 5 {
            return chipItems + [TopicFlowItem.inputField]
        }
        else {
            return chipItems
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(labelFont).foregroundColor(.spurlySecondaryText)
            FlowLayout(flowItems, id: \.id, spacing: 8) { item in
                switch item {
                case .chip(let topic): ChipView(topic: topic, isGreen: isGreen) { if let index = topics.firstIndex(of: topic) { topics.remove(at: index) } }
                case .inputField:
                    TextField(placeholderText, text: $newTopic)
                            .font(inputFont).foregroundColor(.spurlyPrimaryText).textFieldStyle(.plain).autocorrectionDisabled(true)
                        .padding(.horizontal, 10).padding(.vertical, 5).background(Color.spurlyTertiaryBackground)
                        .cornerRadius(16).frame(minWidth: 120, idealHeight: 30).fixedSize()
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4)
                        .focused($isTextFieldFocused).onSubmit { addCurrentTopic() }
                }
            }
            .frame(minHeight: flowLayoutHeight)
            .onPreferenceChange(HeightPreferenceKey.self) { calculatedHeight in
                let newHeight = max(30, calculatedHeight + 5)
                if calculatedHeight.isFinite, calculatedHeight >= 0, abs(flowLayoutHeight - newHeight) > 1 { flowLayoutHeight = newHeight }
            }
            .animation(.default, value: flowLayoutHeight)

            if isTextFieldFocused && !newTopic.isEmpty {
                let filteredTopics = allTopics.filter { $0.lowercased().hasPrefix(newTopic.lowercased()) && !topics.contains($0) && !exclude.contains($0) }.prefix(2)
                if !filteredTopics.isEmpty {



                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(filteredTopics), id: \.self) { suggestion in
                            Button(action: { addTopic(suggestion) }) {
                                Text(suggestion).font(inputFont).foregroundColor(.spurlyPrimaryText)
                                    .padding(.vertical, 10).padding(.horizontal, 12).frame(maxWidth: .infinity, alignment: .leading)

                            }.buttonStyle(.plain)
                            if(suggestion != filteredTopics.last) {
                                Divider().background(Color.spurlyBordersSeparators).padding(.horizontal, 10)
                            }
                        }
                    }
                        .cornerRadius(8).padding(.top, 4)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.spurlyBordersSeparators, lineWidth: 1))
                        .frame(maxHeight: min(CGFloat(filteredTopics.count), 2.0) * 44)
                        .clipped()
                        .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                }
            }
        }
    }

    private func addTopic(_ topic: String) {

        guard !exclude.contains(topic) else {
            print("cannot add topic '\(topic)' to \(label) because it exists in the other list.")

             newTopic = ""
             DispatchQueue.main.async { isTextFieldFocused = false }
            return
        }
        if topics.count < 5 {
            topics.append(topic); newTopic = ""
            DispatchQueue.main.async { isTextFieldFocused = false }
        } else { print("topic limit reached for \(label). Cannot add '\(topic)'.") }
    }

    private func addCurrentTopic() {
        let trimmedTopic = newTopic.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTopic.isEmpty && !topics.contains(trimmedTopic) {
            addTopic(trimmedTopic)
        } else {
            newTopic = ""
            DispatchQueue.main.async { isTextFieldFocused = false }
        }
    }
}
