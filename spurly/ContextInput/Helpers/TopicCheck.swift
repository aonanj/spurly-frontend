//
//  TopicCheck.swift
//
//  Author: phaeton order llc
//  Target: spurly
//


import SwiftUI

// Using the set directly for efficient lookup
private let prohibitedTopics: Set<String> = [
    "violence", "self harm", "suicide", "narcotics",
    "drugs", "sexually suggestive", "explicit"
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
