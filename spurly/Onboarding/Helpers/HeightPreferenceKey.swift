//
//  HeightPreferenceKey.swift
//  spurly
//
//  Created by Alex Osterlind on 4/29/25.
//

import SwiftUI

struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
