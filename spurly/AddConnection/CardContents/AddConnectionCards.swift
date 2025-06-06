//
//
// File name: AddConnectionCards.swift
//
// Product / Project: spurly / spurly
//
// Organization: phaeton order llc
// Bundle ID: com.phaeton-order.spurly
//
//

import SwiftUI

struct AddConnectionCardView<Content: View>: View {
    let addConnectionCardTitle: String
    let addConnectionCardIcon: Image
    let addConnectionCardContent: Content
    private let cardBackgroundColor = Color.spurlyCardBackground
    private let cardOpacity: Double = 0.88
    private let cardCornerRadius: CGFloat = 12.0
    private let cardTitleFont = Font.custom("SF Pro Text", size: 18).weight(.bold)

    init(
        title: String,
        icon: Image,
        @ViewBuilder addConnectionCardContent: () -> Content
    ) {
        self.addConnectionCardTitle = title
        self.addConnectionCardIcon = icon
        self.addConnectionCardContent = addConnectionCardContent()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 5) {
                Spacer()
                HStack(alignment: .center, spacing: 12) {
                    addConnectionCardIcon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.primaryText)
                    Text(addConnectionCardTitle)
                        .font(cardTitleFont)
                        .foregroundColor(.primaryText)
                }
                .padding(.top, 15)
                .padding(.bottom, 8)

                addConnectionCardContent
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)

                Spacer()
            }
            .background(cardBackgroundColor)
            .opacity(cardOpacity)
            .cornerRadius(cardCornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cardCornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(
                                colors: [
                                    Color.spurlyCardBackground.opacity(0.4),
                                    Color.spurlyHighlight.opacity(0.85)
                                ]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 12
                    )
                    .cornerRadius(cardCornerRadius)
            )
        }
        .scrollDismissesKeyboard(.interactively)
        .ignoresSafeArea(.keyboard)
    }
}

@available(iOS 17.0, *)
struct AddConnectionBasicsCardContent: View {
    @Binding var connectionName: String
    @Binding var connectionAge: Int?
    @Binding var connectionContextBlock: String
    @Binding var connectionShowAgeError: Bool
    @FocusState private var connectionFieldIsFocused: Bool
    @FocusState private var connectionEditorIsFocused: Bool

    let ageOptions: [Int?] = [nil] + Array(18..<100).map { Optional($0) }
    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    let textEditorDefault: String
    let textFieldDefault: String
    let paddingHorizontal: CGFloat = 12
    let paddingVertical: CGFloat = 10
    let fontLineHeight = UIFont.systemFont(ofSize: 14).lineHeight * 1.2

    var minHeight: CGFloat {
        fontLineHeight + (paddingVertical * 1.8)
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    connectionFieldIsFocused = false
                    connectionEditorIsFocused = false
                }

            VStack(alignment: .center, spacing: 8) {
                HStack(alignment: .center, spacing: 5) {
                    TextField("", text: $connectionName)
                        .focused($connectionFieldIsFocused)
                        .font(.custom("SF Pro Text", size: 14).weight(.regular))
                        .foregroundColor(
                            connectionName == textFieldDefault ? .spurlySecondaryText : .spurlyPrimaryText
                        )
                        .padding(.horizontal, paddingHorizontal)
                        .padding(.vertical, paddingVertical)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.spurlyTertiaryBackground.opacity(1))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.spurlyHighlight.opacity(0.4), lineWidth: 2)
                        )
                        .shadow(
                            color: .spurlyPrimaryText.opacity(0.44),
                            radius: 4,
                            x: 2,
                            y: 5
                        )
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: minHeight)
                        .onChange(of: connectionFieldIsFocused) {
                            if connectionFieldIsFocused && connectionName == textFieldDefault {
                                connectionName = ""
                            } else if !connectionFieldIsFocused && connectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                connectionName = textFieldDefault
                            }
                        }

                    AgePickerMenu(selectedAge: $connectionAge)
                        .padding(.leading, 6)
                        .frame(maxWidth: 105)
                        // Removed the red border since we're using overlay for errors
                }
                .frame(minHeight: minHeight)

                Spacer()

                TextEditor(text: $connectionContextBlock)
                    .focused($connectionEditorIsFocused)
                    .font(.custom("SF Pro Text", size: 16).weight(.heavy))
                    .foregroundColor(
                        connectionContextBlock == textEditorDefault ? .spurlySecondaryText : .spurlyPrimaryText
                    )
                    .padding(3)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.spurlyTertiaryBackground.opacity(0.6))
                    )
                    .opacity(0.78)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(.spurlyAccent1.opacity(0.45), lineWidth: 2)
                    )
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                    .onChange(of: connectionEditorIsFocused) {
                        if connectionEditorIsFocused && connectionContextBlock == textEditorDefault {
                            connectionContextBlock = ""
                        } else if !connectionEditorIsFocused && connectionContextBlock.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            connectionContextBlock = textEditorDefault
                        }
                    }
            }
            .padding(.horizontal, 5)
        }
    }
}

struct AddConnectionImagesCardContent: View {
    @FocusState private var connectionIsOcrImagesFocused: Bool
    @FocusState private var connectionIsProfileImagesFocused: Bool

    @Binding var connectionOcrImages: [UIImage]?
    @Binding var connectionProfileImages: [UIImage]?
    @Binding var connectionFacePhotoURL: String? // New binding for face photo URL

    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            if(connectionOcrImages?.count == 4) {
                Spacer(minLength: 30)
            }

            PhotoPickerView(
                selectedImages: Binding(
                    get: { connectionOcrImages ?? [] },
                    set: { connectionOcrImages = $0.isEmpty ? nil : $0 }
                ),
                label: "add pics",
                photoPickerToolHelp: "add up to four screenshots of your connection's bio, prompts, or other profile info here. spurly can use text from those when suggesting spurs."
            )
            .padding(.bottom, 1)
            .focused($connectionIsOcrImagesFocused)

            if(connectionOcrImages?.count == 4) {
                Spacer(minLength: 30)
            }

            Divider()
                .frame(maxWidth: .infinity)
                .frame(height: 2)
                .background(Color.accent1)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .opacity(0.4)
                .shadow(
                    color: Color.bordersSeparators.opacity(0.55),
                    radius: 5,
                    x: 2,
                    y: 3
                )
            if(connectionProfileImages?.count == 4) {
                Spacer(minLength: 30)
            }

            // Updated PhotoPickerView with face processing callback
            PhotoPickerView(
                selectedImages: Binding(
                    get: { connectionProfileImages ?? [] },
                    set: { connectionProfileImages = $0.isEmpty ? nil : $0 }
                ),
                label: "add pics",
                photoPickerToolHelp: "add up to four pics of your connection here. spurly will automatically detect and crop their face for the connection profile.",
                onFacePhotoProcessed: { facePhotoURL in
                    connectionFacePhotoURL = facePhotoURL
                }
            )
            .padding(.top, 15)
            .focused($connectionIsProfileImagesFocused)

            if(connectionProfileImages?.count == 4) {
                Spacer(minLength: 30)
            }
        }
        .padding(.horizontal, 5)
    }
}
