//
//  TopicCheck.swift
//
//  Author: phaeton order llc
//  Target: spurly
//


import SwiftUI

private let prohibitedTopics: Set<String> = [
    // Original items
    "violence", "self harm", "suicide", "narcotics",
    "drugs", "sexually suggestive", "explicit",

    // Profanity & Vulgar Language
    "fuck", "shit", "bitch", "cunt", "asshole",
    "motherfucker", "cocksucker", "piss", "damn", "bastard",

    // Explicit Sexual Content & Exploitation
    "porn", "orgy", "rape", "incest", "pedophile",
    "pedophilia", "bestiality", "nude photos", "sex tape", "child porn",
    "lolicon", "shota", // Forms of child exploitation content

    // Hate Speech, Racism, Discrimination
    "nazi", "swastika", "white supremacy", "kkk", "heil hitler", // Nazism/White Supremacy & related symbols/phrases
    "nigger", "chink", "kike", "gook", "wetback", // Racial/Ethnic Slurs
    "faggot", "dyke", "homo", // Anti-LGBTQ+ Slurs (note: "tranny" is widely considered a slur)
    "ethnic cleansing", "genocide", // Extreme forms of hate/violence against groups
    "hate speech",

    // Extreme Violence & Gore
    "murder", "torture", "behead", "massacre", "gore", "slaughter",

    // Other Harmful Activities
    "bomb", "terrorist", "terrorism", "doxxing", "stalking",

    //Drugs
    "coke", "blow", "molly", "rolling", "tripping", "getting high", "getting stoned", "throwed"
]

func IsTopicProhibited (topic: String) -> Bool {
    let lowercasedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    var isProhibited = false
    if !lowercasedTopic.isEmpty {
        for prohibited in prohibitedTopics {
            if lowercasedTopic.contains(prohibited) {
                isProhibited = true
                break
            }
        }
    }
    return isProhibited
}
