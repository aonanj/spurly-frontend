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

    func loadUserProfile(completion: @escaping (UserProfileData?) -> Void) {
        guard let token = authManager.token, let userId = authManager.userId else {
            completion(nil)
            return
        }

        // Call to get existing profile data
        NetworkService.shared.getUserProfile(userId: userId, token: token) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let profileResponse):
                    // Convert to UserProfileData (you may need to adjust based on your actual response structure)
                    let profileData = UserProfileData(
                        name: profileResponse.name,
                        age: nil, // Age might need to come from a different endpoint
                        email: nil,
                        userContextBlock: nil // This might need to come from a different endpoint
                    )
                    completion(profileData)
                case .failure:
                    completion(nil)
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
}

struct UpdateProfileRequest: Codable {
    let name: String
    let age: Int
    let email: String
    let userContextBlock: String

    enum CodingKeys: String, CodingKey {
        case name, age, email
        case userContextBlock = "profile_text"
    }
}

struct UserProfileData {
    let name: String?
    let age: Int?
    let email: String?
    let userContextBlock: String?
}

