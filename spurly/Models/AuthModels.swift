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
    let firebaseIdToken: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case firebaseIdToken = "access_token"
        case email
    }
}

struct LoginRequest: Codable {
    let firebaseIdToken: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case firebaseIdToken = "access_token"
        case email
    }
}

// If using social logins, you might have specific request structures
// e.g., struct SocialLoginRequest: Codable {
//     let provider: String // "apple", "google", "facebook"
//     let idToken: String  // The token received from the social provider
// }


// MARK: - Error Response Structure (Optional but Recommended)

//struct APIErrorResponse: Codable, Error {
//    let message: String
//    let errorCode: String? // Optional: a specific error code from your backend
//
//    enum CodingKeys: String, CodingKey {
//        case message
//        case errorCode = "error_code"
//    }
//}

enum UserState {
    case unknown
    case unauthenticated
    case authenticated // User is logged in, but not yet onboarded
    case onboarded     // User is logged in AND has completed onboarding
    case error(String)
}

struct AuthResponse: Decodable {
    let accessToken: String
    let user_id: String
    let refreshToken: String?
    let name: String?
    let email: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user_id
        case name
        case email
    }
}

struct UserInfo: Decodable {
    let user_id: String
    let userEmail: String?
    let name: String?
//    let emailVerified: Bool

    enum CodingKeys: String, CodingKey {
        case user_id = "user_id"
        case userEmail = "email"
        case name
//        case emailVerified = "email_verified"
    }
}

struct UserProfileResponse: Decodable {
    let userId: String?
    let name: String?
    let email: String?
    let age: Int?
    let userContextBlock: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case email
        case age
        case userContextBlock = "user_context_block"
    }

    // Regular initializer
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        userId = try container.decodeIfPresent(String.self, forKey: .userId)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        userContextBlock = try container.decodeIfPresent(String.self, forKey: .userContextBlock)

        // Attempt 1: Try to decode 'age' as an Int
        if let intValue = try? container.decode(Int.self, forKey: .age) {
            self.age = intValue // e.g., JSON is "age": 31
        }
        // Attempt 2: If Int decoding failed (e.g., it was a string), try to decode as String
        else if let stringValue = try? container.decode(String.self, forKey: .age) {
            self.age = Int(stringValue) // e.g., JSON is "age": "31". Converts "31" to 31. If "abc", results in nil.
        }

        else {

            self.age = nil
        }
    }

    // Added memberwise initializer for manual instantiation
    init(userId: String?, name: String?, age: Int?, email: String?, userContextBlock: String?) {
        self.userId = userId
        self.name = name
        self.age = age
        self.email = email
        self.userContextBlock = userContextBlock
    }


}



// MARK: - Request Models

// Firebase Auth Request Models




struct GoogleTokenPayload: Codable {
    let idToken: String
    let serverAuthCode: String?

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
        case serverAuthCode = "server_auth_code"
    }
}

struct AppleTokenPayload: Codable {
    let identityToken: String
    let authorizationCode: String
    let email: String?
    let fullName: PersonNameComponents?

    enum CodingKeys: String, CodingKey {
        case identityToken = "identity_token"
        case authorizationCode = "authorization_code"
        case email
        case fullName = "name"
    }
}

struct FacebookTokenPayload: Codable {
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

struct OnboardingRequest: Codable {
    let name: String
    let age: Int
    let userContextBlock: String

    enum CodingKeys: String, CodingKey {
        case name, age
        case userContextBlock = "user_context_block"
    }
}

struct OnboardingResponse: Decodable {
    let success: Bool
    let message: String?
}

struct TokenRefreshResponse: Decodable {
    let accessToken: String
    let tokenType: String?
    let expiresIn: Int?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

struct APIErrorResponse: Decodable {
    let message: String
    let error: String?
    let statusCode: Int?

    enum CodingKeys: String, CodingKey {
        case message
        case error
        case statusCode = "status_code"
    }
}

// MARK: - Supporting Types

struct Empty: Codable {}

// Facebook Graph API Response
struct FacebookUser: Decodable {
    let id: String
    let name: String
    let email: String?

}

