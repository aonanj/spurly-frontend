//
//  OnboardingModels.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

// MARK: - Onboarding Data Structure
//struct OnboardingPayload: Codable {
//    var name: String?; var age: Int?; var user_context_block: String?;
//    enum CodingKeys: String, CodingKey { case name, age, user_context_block}
//    init(name: String?, age: Int?, user_context_block: String?) {
//        self.name = name?.isEmpty ?? true ? nil : name; self.age = age; self.user_context_block = user_context_block?.isEmpty ?? true ? nil : user_context_block;
//    }
//}


//struct OnboardingResponse: Codable { var user_id: String; var token: String }

// MARK: - Card & Field View Models
// These structs can remain as they are, as we will use them to structure the single card's content.
struct CardViewModel: Identifiable {
    let id = UUID()
    var title: String
    var iconName: String
    var fields: [FieldViewModel]
    var isCompleted: Bool = false
}

struct FieldViewModel: Identifiable {
    let id = UUID()
    var type: FieldType
    var title: String? = nil
    var textInput: Binding<String>? = nil
    var dateSelection: Binding<Date>? = nil
    var isLargeText: Bool = false // We'll use this for the TextEditor
}

enum FieldType {
    case textField
    case datePicker
    case custom // We can use a custom type for the combined name/age row
}
