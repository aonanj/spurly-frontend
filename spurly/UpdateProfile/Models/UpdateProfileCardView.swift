//
//
// File name: UpdateProfileCardView.swift
//
// Product / Project: spurly / spurly
//
// Organization: phaeton order llc
// Bundle ID: com.phaeton-order.spurly
//
//
import SwiftUI

struct UpdateProfileCardView<Content: View>: View {
    private var title = "update profile"
    let content: Content
    private let cardBackgroundColor = Color.cardBg
    private let cardOpacity: Double = 0.81
    private let cardCornerRadius: CGFloat = 12.0
    private let cardTitleFont = Font.custom("SF Pro Text", size: 20).weight(.bold)

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 5) {
                Spacer()
                HStack(alignment: .center, spacing: 12) {
                    Image(systemName: "rectangle.and.pencil.and.ellipsis")
                        .font(.system(size: 22))
                        .fontWeight(.bold)
                        .foregroundColor(Color.primaryText)
                    Text(title)
                        .font(cardTitleFont)
                        .foregroundColor(Color.primaryText)
                }
                .padding(.top, 15)
                .padding(.bottom, 10)

                content.padding(.horizontal, 10).padding(.vertical, 5)

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
                                    Color.cardBg.opacity(0.4),
                                    Color.highlight.opacity(0.85)
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

struct UpdateProfileCardContent: View {
    @Binding var name: String
    @Binding var age: Int?
    @Binding var email: String
    @Binding var showAgeError: Bool
    @Binding var textEditorText: String

    @FocusState private var fieldIsFocused: Bool
    @FocusState private var emailIsFocused: Bool
    @FocusState private var editorIsFocused: Bool

    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    let textEditorDefault: String
    let textFieldDefault: String
    let currentEmail: String
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
                    fieldIsFocused = false
                    emailIsFocused = false
                    editorIsFocused = false
                }

            VStack(alignment: .center, spacing: 8) {
                // Name and Age Row
                HStack(alignment: .center, spacing: 5) {
                    TextField("", text: $name)
                        .focused($fieldIsFocused)
                        .font(.custom("SF Pro Text", size: 14).weight(.regular))
                        .foregroundColor(
                            name == textFieldDefault ? .spurlySecondaryText : .spurlyPrimaryText
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
                        .onChange(of: fieldIsFocused) {
                            if fieldIsFocused && name == textFieldDefault {
                                name = ""
                            } else if !fieldIsFocused && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                name = textFieldDefault
                            }
                        }

                    AgePickerMenu(selectedAge: $age)
                        .padding(.leading, 6)
                        .frame(maxWidth: 105)
                }
                .frame(minHeight: minHeight)

                Spacer()

                // Text Editor (reduced height)
                TextEditor(text: $textEditorText)
                    .focused($editorIsFocused)
                    .font(.custom("SF Pro Text", size: 16).weight(.heavy))
                    .foregroundColor(
                        textEditorText == textEditorDefault ? .spurlySecondaryText : .spurlyPrimaryText
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
                    .frame(height: 200) // Reduced height
                    .frame(maxWidth: .infinity)
                    .onChange(of: editorIsFocused) {
                        if editorIsFocused && textEditorText == textEditorDefault {
                            textEditorText = ""
                        } else if !editorIsFocused && textEditorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            textEditorText = textEditorDefault
                        }
                    }

                Spacer(minLength: 8)
                HStack {
                        // Email Field
                    TextField("", text: $email)
                        .focused($emailIsFocused)
                        .font(.custom("SF Pro Text", size: 14).weight(.regular))
                        .foregroundColor(
                            email == currentEmail ? .spurlySecondaryText : .spurlyPrimaryText
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
                        .frame(maxWidth: 190)
                        .frame(minHeight: minHeight)
                        .onChange(of: emailIsFocused) {
                            if emailIsFocused && email == currentEmail {
                                email = ""
                            } else if !emailIsFocused && email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                email = currentEmail
                            }
                        }
                    Spacer()
                }
                .padding(.bottom, 5)
            }
            .padding(.horizontal, 5)
        }
    }
}
