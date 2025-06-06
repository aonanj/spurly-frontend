//
// SpurModels.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import Foundation

struct Spur: Identifiable, Equatable, Codable {
    let id: String
    var variant: String
    var text: String
    let iconCategoryIndex: Int // 0 for Main, 1 for Warm, 2 for Cool, 3 for Banter
    

    init(id: String, variant: String, text: String, iconCategoryIndex: Int) {
        self.id = id
        self.variant = variant
        self.text = text
        self.iconCategoryIndex = iconCategoryIndex
    }
}

// BackendSpurData remains the same, as we'll assign iconCategoryIndex during mapping
struct BackendSpurData: Decodable, Identifiable {
    let id: String
    let variant: String
    let text: String
    let userId: String
    let conversationId: String?
    let connectionId: String?
    let situation: String?
    let topic: String?
    let tone: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case id = "spur_id"
        case conversationId = "conversation_id"
        case connectionId = "connection_id"
        case situation
        case topic
        case variant
        case tone
        case text
        case createdAt = "created_at"
    }
}
