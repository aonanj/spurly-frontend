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
        case firebaseIdToken = "firebase_id_token"
        case email
    }
}

struct LoginRequest: Codable {
    let firebaseIdToken: String
    let email: String

    enum CodingKeys: String, CodingKey {
        case firebaseIdToken = "firebase_id_token"
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
    let refreshToken: String?
    let user: UserInfo

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

struct UserInfo: Decodable {
    let id: String
    let email: String
    let name: String?
//    let emailVerified: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
//        case emailVerified = "email_verified"
    }
}

struct UserProfileResponse: Decodable {
    let exists: Bool
    let userId: String?
    let name: String?
    let profileCompleted: Bool?

    // Regular initializer
    init(exists: Bool, userId: String? = nil, name: String? = nil, profileCompleted: Bool? = nil) {
        self.exists = exists
        self.userId = userId
        self.name = name
        self.profileCompleted = profileCompleted
    }

    // Handle flexible response structure
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // If the response just has a status, default exists to true
        self.exists = try container.decodeIfPresent(Bool.self, forKey: .exists) ?? true
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.profileCompleted = try container.decodeIfPresent(Bool.self, forKey: .profileCompleted)
    }

    enum CodingKeys: String, CodingKey {
        case exists
        case userId = "user_id"
        case name
        case profileCompleted = "profile_completed"
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
        case fullName = "full_name"
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
        case userContextBlock = "profile_text"
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

