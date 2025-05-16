// SpurDisplayCardView.swift

import SwiftUI
import UIKit

struct SpurDisplayCardView: View {
    let title: String
    let cardIconName: String
    @Binding var spurText: String

    let onCopy: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void

    @FocusState private var isTextEditorFocused: Bool

    private let cardBackgroundColor = Color.cardBg
    private let cardOpacity: Double = 0.92
    private let cardCornerRadius: CGFloat = 12.0
    private let cardTitleFont = Font.custom("SF Pro Text", size: 18).weight(.bold)

    private let buttonIconScale: Image.Scale = .medium
    private let buttonVerticalPadding: CGFloat = 1
    private let buttonHorizontalPadding: CGFloat = 8

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 2) {
                Spacer(minLength: 2)

                HStack(alignment: .center, spacing: 8) {
                    Image(cardIconName)
                        .resizable().scaledToFit().frame(width: 30, height: 30)
                        .foregroundColor(.primaryText)
                    Text(title.lowercased())
                        .font(cardTitleFont)
                        .foregroundColor(.primaryText)
                }
                .padding(.bottom, 5)

                TextEditor(text: $spurText)
                    .focused($isTextEditorFocused)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100, idealHeight: 170, maxHeight: .infinity)
                    .padding(2)
                    .background(Color.tertiaryBg.opacity(0.6))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                Color.bordersSeparators.opacity(0.5),
                                lineWidth: 1
                            )
                    )


                Spacer(minLength: 10)

                HStack {
                    // Copy Button
                    Button(action: { onCopy(); isTextEditorFocused = false; }) {
                        Label { Text("copy") } icon: { Image(systemName: "doc.on.doc.fill").imageScale(buttonIconScale) }
                            .padding(.vertical, buttonVerticalPadding)
                            .padding(.horizontal, buttonHorizontalPadding)
                            .frame(minWidth: 30)
                            .labelStyle(.iconOnly)
                            .foregroundStyle(Color.brandColor)
                            .shadow(color: .black.opacity(0.55), radius: 4, x: 4, y: 4)
                    }
                    //.buttonStyle(.bordered) // Apply style directly
                    //.tint(.accent1)

                    Spacer()

                    HStack(spacing: 2) {
                        // Save Button
                        Button(action: { onSave(); isTextEditorFocused = false; }) {
                            Label { Text("save") } icon: { Image(systemName: "hand.thumbsup.fill").imageScale(buttonIconScale) }
                                .padding(.vertical, buttonVerticalPadding)
                                .padding(.horizontal, buttonHorizontalPadding)
                                .frame(minWidth: 30)
                                .labelStyle(.iconOnly)
                                .foregroundStyle(Color.brandColor)
                                .shadow(color: .black.opacity(0.55), radius: 4, x: 4, y: 4)
                        }
                        //.buttonStyle(.borderedProminent) // Apply style directly
                        //.tint(.accent3)

                        // Discard Button
                        Button(action: { onDelete(); isTextEditorFocused = false; }) {
                            Label { Text("discard") } icon: { Image(systemName: "hand.thumbsdown.fill").imageScale(buttonIconScale) }
                                .padding(.vertical, buttonVerticalPadding)
                                .padding(.horizontal, buttonHorizontalPadding)
                                .frame(minWidth: 30)
                                .labelStyle(.iconOnly)
                                .foregroundStyle(Color.brandColor)
                                .shadow(color: .black.opacity(0.55), radius: 4, x: 4, y: 4)
                        }
                        //.buttonStyle(.bordered) // Apply style directly
                        //.tint(.accent2)
                    }
                }
                .padding(.horizontal)
                Spacer(minLength: 2)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(cardBackgroundColor)
        .opacity(cardOpacity)
        .cornerRadius(cardCornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: cardCornerRadius)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color.cardBg.opacity(0.4),
                                Color.highlight.opacity(0.8)
                            ]
                        ),
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 12
                )
                .cornerRadius(cardCornerRadius)
        )
        .onTapGesture { isTextEditorFocused = false }
    }
}
