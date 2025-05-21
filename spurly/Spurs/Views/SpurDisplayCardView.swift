//
// SpurDisplayCardView.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI
import UIKit

struct SpurDisplayCardView: View {
    let title: String
    let cardIconName: String
    @Binding var spurText: String

    let onCopy: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void

    @EnvironmentObject var connectionManager: ConnectionManager
    @FocusState private var isTextEditorFocused: Bool

    private let cardBackgroundColor = Color.cardBg
    private let cardOpacity: Double = 0.92
    private let cardCornerRadius: CGFloat = 12.0
    private let cardTitleFont = Font.custom("SF Pro Text", size: 18).weight(.bold)

    private let buttonIconScale: Image.Scale = .medium
    private let buttonVerticalPadding: CGFloat = 5
    private let buttonHorizontalPadding: CGFloat = 8

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center) { // Using .top for better alignment if capsule and title have different heights
                    // Left-aligned Icon and Title
                    HStack(spacing: 8) {
                        Image(cardIconName)
                            .resizable().scaledToFit().frame(width: 35, height: 35)
                            .foregroundColor(Color.primaryText) // Use defined color palette
                            .shadow(
                                color: Color.black.opacity(0.5), // Shadow for the capsule
                                radius: 5, x: 3, y: 3
                            )
                        Text(title.lowercased())
                            .font(cardTitleFont)
                            .foregroundColor(Color.primaryText) // Use defined color palette
                            .shadow(
                                color: Color.black.opacity(0.6), // Shadow for the capsule
                                radius: 5, x: 3, y: 3
                            )
                    }
                    .padding(.bottom, 10)

                    Spacer() // Pushes connection capsule to the right

                    // Conditional Connection Name Capsule
                    if let connectionName = connectionManager.currentConnectionName, connectionManager.currentConnectionId != nil {
                        HStack(
                            alignment: .top
                        ) { // Inner HStack for capsule content
                            Text(connectionName)
                                .font(.caption)
                                .foregroundColor(Color.primaryBg) // Text color (e.g., light text on dark capsule)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Capsule().fill(Color.primaryText.opacity(0.7))) // Capsule background
                        .transition(.opacity.combined(with: .scale(scale: 0.85))) // Animation for appearance
                        .shadow(
                            color: Color.black.opacity(0.4), // Shadow for the capsule
                            radius: 5, x: 3, y: 3
                        )
                        .padding(.bottom, 10)
                    }
                }

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


                HStack {
                    // Copy Button
                    Button(action: { onCopy(); isTextEditorFocused = false; }) {
                        Label { Text("copy") } icon: { Image(systemName: "doc.on.doc.fill").imageScale(buttonIconScale) }
                            .padding(.vertical, buttonVerticalPadding)
                            .padding(.horizontal, 2)
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
                //.padding(.horizontal)
                .padding(.bottom, 10)
                Spacer(minLength: 12)
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
