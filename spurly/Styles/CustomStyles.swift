//
//  CustomStyles.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

struct CustomTextFieldStyle: TextFieldStyle {

    let inputFont = Font.custom("SF Pro Text", size: 16).weight(.regular)
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.font(inputFont).foregroundColor(.spurlyPrimaryText)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.spurlyTertiaryBackground)
            .cornerRadius(12).shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4)
     }
}

struct CustomPickerStyle<SelectionValue: Hashable>: View {
    let title: String; @Binding var selection: SelectionValue; let options: [SelectionValue]; let textMapping: (SelectionValue) -> String
    let inputFont = Font.custom("SF Pro Text", size: 16).weight(.regular); let placeholderColor = Color.spurlySecondaryText; let primaryColor = Color.spurlyPrimaryText
    let backgroundColor = Color.spurlyTertiaryBackground; let cornerRadius: CGFloat = 12; let paddingHorizontal: CGFloat = 12; let paddingVertical: CGFloat = 10; let minHeight: CGFloat
    init(title: String, selection: Binding<SelectionValue>, options: [SelectionValue], textMapping: @escaping (SelectionValue) -> String) {
        self.title = title; self._selection = selection; self.options = options; self.textMapping = textMapping
        let fontLineHeight = Font.system(size: 16).capHeight * 1.2; self.minHeight = fontLineHeight + (paddingVertical * 2.4)

    }
    var body: some View {
        Menu { Picker(title, selection: $selection) { ForEach(options, id: \.self) { option in Text(textMapping(option)).tag(option) } } } label: {
            HStack {
                Text(currentSelectionText).font(inputFont).foregroundColor(isPlaceholder ? placeholderColor : primaryColor)
                    .accessibilityHint(isPlaceholder ? "empty. tap to select \(title)." : "selected: \(currentSelectionText). tap to change.")
                Spacer(); Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundColor(.spurlySecondaryText)
            }
            .padding(.horizontal, paddingHorizontal).padding(.vertical, paddingVertical).frame(maxWidth: .infinity).frame(minHeight: minHeight)
            .background(backgroundColor).cornerRadius(cornerRadius).shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4)
        }
    }
    private var isPlaceholder: Bool { if let o = selection as? Optional<Any>, o == nil { return true }; if let s = selection as? String, s.isEmpty { return true }; return false }
    private var currentSelectionText: String { isPlaceholder ? "" : textMapping(selection) }
}

// Primary Button Style
struct PrimaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.title2)
            .fontDesign(.serif)
            .fontWeight(.semibold)
            .foregroundColor(Color("AccentColorContrast")) // Or your specific color
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("SpurlyPrimaryButton")) // Or your specific color
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2) // Optional shadow
    }
}

// Secondary Button Style
struct SecondaryButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(Color("SpurlyPrimaryButton")) // Text color for secondary
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color("SpurlyPrimaryButton"), lineWidth: 2) // Border
            )
            .cornerRadius(10) // Ensure cornerRadius is applied to the overall shape
    }
}


struct SignInButtonModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 17))
            .fontWeight(.semibold)
            .foregroundColor(Color.primaryText) // Text color for secondary
            .padding()
            .frame(width: 220, height: 50)
            .cornerRadius(10) // Ensure cornerRadius is applied to the overall shape
            .background(
                Color.highlight
                ).cornerRadius(10).opacity(0.7)
            .shadow(color: Color.black.opacity(0.5), radius: 5, x: 5, y: 5)
    }
}



// Extension to make them easier to apply (optional, but good practice)
extension View {
    func primaryButtonStyle() -> some View {
        self.modifier(PrimaryButtonModifier())
    }

    func secondaryButtonStyle() -> some View {
        self.modifier(SecondaryButtonModifier())
    }

    func socialButtonStyle(backgroundColor: Color, foregroundColor: Color) -> some View {
        self.modifier(SocialButtonModifier(backgroundColor: backgroundColor, foregroundColor: foregroundColor))
    }
}
