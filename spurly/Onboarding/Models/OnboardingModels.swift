//
//  OnboardingModels.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

struct OnboardingPayload: Codable {
    var name: String?; var age: Int?; var gender: String?; var pronouns: String?; var school: String?
    var job: String?; var drinking: String?; var ethnicity: String?; var current_city: String?; var hometown: String?
    var greenlights: [String]?; var redlights: [String]?; var dating_platform: String?
    var looking_for: String?; var kids: String?
    enum CodingKeys: String, CodingKey { case name, age, gender, pronouns, school, job, drinking, ethnicity, current_city = "current_city", hometown, greenlights = "greenlights", redlights = "redlights", dating_platform = "dating_platform", looking_for = "looking_for", kids }
    init(name: String?, age: Int?, gender: String?, pronouns: String?, ethnicity: String?, currentCity: String?, hometown: String?, school: String?, job: String?, drinking: String?, datingPlatform: String?, lookingFor: String?, kids: String?, greenlights: [String]?, redlights: [String]?) {
        self.name = name?.isEmpty ?? true ? nil : name; self.age = age; self.gender = gender?.isEmpty ?? true ? nil : gender; self.pronouns = pronouns?.isEmpty ?? true ? nil : pronouns
        self.school = school?.isEmpty ?? true ? nil : school; self.job = job?.isEmpty ?? true ? nil : job; self.drinking = drinking?.isEmpty ?? true ? nil : drinking
        self.ethnicity = ethnicity?.isEmpty ?? true ? nil : ethnicity; self.current_city = currentCity?.isEmpty ?? true ? nil : currentCity; self.hometown = hometown?.isEmpty ?? true ? nil : hometown
        self.dating_platform = datingPlatform?.isEmpty ?? true ? nil : datingPlatform; self.looking_for = lookingFor?.isEmpty ?? true ? nil : lookingFor; self.kids = kids?.isEmpty ?? true ? nil : kids
        self.greenlights = greenlights?.isEmpty ?? true ? nil : greenlights; self.redlights = redlights?.isEmpty ?? true ? nil : redlights
    }
}


struct OnboardingResponse: Codable { var user_id: String; var token: String }
