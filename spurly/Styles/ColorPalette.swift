//
//  ColorPalette.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

extension Color {
    static let brandColor = Color("SpurlyBrandColor") //Slate blue
    static let primaryBg = Color("SpurlyPrimaryBackground") //Soft Ice Gray
    static let secondaryBg = Color("SpurlySecondaryBackground") //Pale Cloud Blue
    static let tertiaryBg = Color("SpurlyTertiaryBackground") //Steel Mist
    static let primaryText = Color("SpurlyPrimaryText") //Deep Navy
    static let secondaryText = Color("SpurlySecondaryText") //Cool Slate
    static let accent1 = Color("SpurlyAccent1") //Sky Blue
    static let accent2 = Color("SpurlyAccent2") //Muted Coral Red
    static let accent3 = Color("SpurlyAccent3") //Burnt Amber
    static let accent4 = Color("SpurlyAccent4") //Orange
    static let bordersSeparators = Color("SpurlyBordersSeparators") //Pale Stone Gray
    static let primaryButton = Color("SpurlyPrimaryButton") //Slate blue (Primary brand color)
    static let secondaryButton = Color("SpurlySecondaryButton") //Picton Blue
    static let tertiaryButton = Color("SpurlyTertiaryButton") //Venetian Red
    static let cardBg = Color("SpurlyCardBackground") //Alice Blue
    static let highlight = Color("SpurlyHighlight") //Sky Blue

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


