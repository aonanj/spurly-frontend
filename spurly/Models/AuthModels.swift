//
//  AuthModels.swift
//
//  Author: phaeton order llc
//  Target: spurly
//
//

import Foundation

// MARK: - Request Structures

struct CreateAccountRequest: Codable {
    let email: String
    let password: String
    // Add any other fields your backend expects for account creation
    // e.g., let fullName: String?
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

// If using social logins, you might have specific request structures
// e.g., struct SocialLoginRequest: Codable {
//     let provider: String // "apple", "google", "facebook"
//     let idToken: String  // The token received from the social provider
// }

// MARK: - Response Structures

struct AuthResponse: Codable {
    let userId: String
    let token: String
    // Add any other fields your backend returns upon successful authentication
    // e.g., let email: String
    // e.g., let expiresIn: Int?

    // Example for JSON keys like "user_id", "auth_token"
    enum CodingKeys: String, CodingKey {
        case userId = "user_id" // Map snake_case from backend to camelCase
        case token = "auth_token"
        // case email
        // case expiresIn = "expires_in"
    }
}

// MARK: - Error Response Structure (Optional but Recommended)

struct APIErrorResponse: Codable, Error {
    let message: String
    let errorCode: String? // Optional: a specific error code from your backend

    enum CodingKeys: String, CodingKey {
        case message
        case errorCode = "error_code"
    }
}

enum UserState {
    case unknown
    case unauthenticated
    case authenticated // User is logged in, but not yet onboarded
    case onboarded     // User is logged in AND has completed onboarding
    case error(String)
}
