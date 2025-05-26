import SwiftUI

// This function will now create a single card view model for the updated OnboardingView
struct UserCardContent: View {
    @Binding var name: String
    @Binding var age: Int?
    @Binding var showAgeError: Bool
    @Binding var textEditorText: String

    @FocusState private var fieldIsFocused: Bool
    @FocusState private var editorIsFocused: Bool


    let labelFont = Font.custom("SF Pro Text", size: 14).weight(.regular)
    let ageOptions: [Int?] = [nil] + Array(18..<100).map { Optional($0) }
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
                    fieldIsFocused = false
                    editorIsFocused = false
                }
            VStack(alignment: .center, spacing: 8) {
                HStack(alignment: .center, spacing: 5) {

                    TextField("", text: $name)
                        .focused($fieldIsFocused)
                        .font(.custom("SF Pro Text", size: 14).weight(.regular))
                        .foregroundColor(
                            name == textFieldDefault ? .spurlySecondaryText : .spurlyPrimaryText)
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
                        .border(Color.red, width: (showAgeError && !(age ?? 0 >= 18)) ? 3 : 0)
                }
                .frame(minHeight: minHeight)

                Spacer()

                TextEditor(text: $textEditorText)
                    .focused($editorIsFocused)
                    .font(.custom("SF Pro Text", size: 16).weight(.heavy))
                    .foregroundColor(
                        textEditorText == textEditorDefault ? .spurlySecondaryText : .spurlyPrimaryText)
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
                    .onChange(of: editorIsFocused) {
                        if editorIsFocused && textEditorText == textEditorDefault {
                            textEditorText = ""
                        } else if !editorIsFocused && textEditorText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            textEditorText = textEditorDefault
                        }
                    }
            }
            .padding(.horizontal, 5)// End VStack
        } // End ZStack
    }
}
