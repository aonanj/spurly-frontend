//
//  ColorPalette.swift
//  spurly
//
//  Created by Alex Osterlind on 4/29/25.
//

import SwiftUI

extension Color {
    static let spurlyPrimaryBrand = Color(hex: "#3A506B") //Slate blue
    static let spurlyPrimaryBackground = Color(hex: "#F0F4F8") //Soft Ice Gray
    static let spurlySecondaryBackground = Color(hex: "#D9E2EC") //Pale Cloud Blue
    static let spurlyTertiaryBackground = Color(hex: "#BCCCDC") //Steel Mist
    static let spurlyPrimaryText = Color(hex: "#102A43") //Deep Navy
    static let spurlySecondaryText = Color(hex: "#627D98") //Cool Slate
    static let spurlyAccent1 = Color(hex: "#5FA8D3") //Sky Blue
    static let spurlyAccent2 = Color(hex: "#F25F5C") //Muted Coral Red
    static let spurlyAccent3 = Color(hex: "#D27D2D") //Burnt Amber
    static let spurlyAccent4 = Color(hex: "#FFA500") //Orange
    static let spurlyBordersSeparators = Color(hex: "#CBD2D9") //Pale Stone Gray
    static let spurlyPrimaryButton = Color(hex: "#3A506B") //Slate blue (Primary brand color)
    static let spurlySecondaryButton = Color(hex: "#5FA8D3") //Picton Blue
    static let spurlyTertiaryButton = Color(hex: "#C80815") //Venetian Red
    static let spurlyCardBackground = Color(hex: "#EAF6FF") //Alice Blue
    static let spurlyHighlight = Color(hex: "#9BC8FF") //Sky Blue

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:(a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
