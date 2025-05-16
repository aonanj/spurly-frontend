// SpurModels.swift

import Foundation

struct Spur: Identifiable, Equatable {
    let id: String
    var variation: String
    var text: String
    let iconCategoryIndex: Int // 0 for Main, 1 for Warm, 2 for Cool, 3 for Playful

    init(id: String, variation: String, text: String, iconCategoryIndex: Int) {
        self.id = id
        self.variation = variation
        self.text = text
        self.iconCategoryIndex = iconCategoryIndex
    }
}

// BackendSpurData remains the same, as we'll assign iconCategoryIndex during mapping
struct BackendSpurData: Decodable, Identifiable {
    let id: String
    let variation: String
    let text: String
}
