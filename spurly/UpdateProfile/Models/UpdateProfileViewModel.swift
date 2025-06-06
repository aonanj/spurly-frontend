//
//
// File name: UpdateProfileViewModel.swift
//
// Product / Project: spurly / spurly
//
// Organization: phaeton order llc
// Bundle ID: com.phaeton-order.spurly
//
//

import SwiftUI

class UpdateProfileViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var isError: Bool = false
    @Published var updateSuccess: Bool = false

    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    // In UpdateProfileViewModel.swift
        func loadUserProfile(_ completion: @escaping (Result<UserProfileData, Error>) -> Void) { // No userId, token parameters
            guard let authToken = authManager.token, let authUserId = authManager.userId else {
                //completion(.failure()) // Or your specific error type
                return
            }

            // Now directly uses authManager's properties without any confusion from parameters
            NetworkService.shared.getUserProfile(userId: authUserId, token: authToken) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profileResponse):
                        let userProfile = UserProfileData(
                            name: profileResponse.name,
                            age: profileResponse.age,
                            email: profileResponse.email,
                            userContextBlock: profileResponse.userContextBlock
                        )
                        completion(.success(userProfile))
                    case .failure(let networkError):
                        completion(.failure(networkError))
                    }
                }
            }
        }

    func updateProfile(data: UpdateProfilePayload) {
        guard let token = authManager.token, let _ = authManager.userId else {
            errorMessage = "User is not authenticated. Cannot update profile."
            return
        }

        isLoading = true
        errorMessage = nil
        updateSuccess = false

        let requestData = UpdateProfileRequest(
            name: data.name,
            age: data.age ?? 0,
            email: data.email,
            userContextBlock: data.userContextBlock
        )

        // Call to update profile endpoint
        // Note: You'll need to add updateUserProfile method to NetworkService
        // For now, using submitOnboardingProfile as a placeholder
        let onboardingRequest = OnboardingRequest(
            name: requestData.name,
            age: requestData.age,
            userContextBlock: requestData.userContextBlock
        )

        NetworkService.shared.submitOnboardingProfile(requestData: onboardingRequest, authToken: token) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success:
                    // Update local auth manager with new values
                    self.authManager.userName = data.name
                    self.authManager.userEmail = data.email

                    // Save to keychain
                    KeychainHelper.standard.save(data.name, service: "com.spurly.name", account: "user")
                    KeychainHelper.standard.save(data.email, service: "com.spurly.email", account: "user")

                    self.updateSuccess = true

                case .failure(let error):
                    let errorMessage: String
                    switch error {
                    case .serverError(let message, _):
                        errorMessage = message
                    case .unauthorized:
                        errorMessage = "Session expired. Please log in again."
                    case .requestFailed:
                        errorMessage = "Network error. Please check your connection."
                    default:
                        errorMessage = "Failed to update your profile. Please try again."
                    }

                    self.errorMessage = errorMessage
                }
            }
        }
    }
}


// MARK: - Supporting Types

struct UpdateProfilePayload {
    let name: String
    let age: Int?
    let email: String
    let userContextBlock: String

    enum CodingKeys: String, CodingKey {
        case name, age, email
        case userContextBlock = "user_context_block"
    }
}

struct UpdateProfileRequest: Codable {
    let name: String
    let age: Int
    let email: String
    let userContextBlock: String

    enum CodingKeys: String, CodingKey {
        case name, age, email
        case userContextBlock = "user_context_block"
    }
}

struct UserProfileData: Decodable {
    let name: String?
    let age: Int?
    let email: String?
    let userContextBlock: String?

    enum CodingKeys: String, CodingKey {
        case name, age, email
        case userContextBlock = "user_context_block"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

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
    init(name: String?, age: Int?, email: String?, userContextBlock: String?) {
        self.name = name
        self.age = age
        self.email = email
        self.userContextBlock = userContextBlock
    }
}

