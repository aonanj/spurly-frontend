//
//  AuthManager.swift
//
//  Author: phaeton order llc
//  Target: spurly
//


import SwiftUI
import Combine // Needed for ObservableObject

// Class to hold authentication state
class AuthManager: ObservableObject {
    @Published var userId: String?
    @Published var token: String?

    // NEW: For User Profile Status
    @Published var userProfileExists: Bool? = nil // nil: unknown, true: exists, false: not found
    @Published var isLoadingProfile: Bool = false

    // Computed property to easily check authentication status
    var isAuthenticated: Bool {
        guard let token = token, !token.isEmpty else {
            return false
        }
        return true
    }

    init() {
        // Attempt to load existing session from Keychain upon app launch
        self.userId = KeychainHelper.standard.read(service: "com.spurly.userid", account: "user")
        self.token = KeychainHelper.standard.read(service: "com.spurly.token", account: "user")
        print("AuthManager: Initialized. UserID loaded: \(userId != nil), Token loaded: \(token != nil)")

        if isAuthenticated, let currentUserId = self.userId, let currentToken = self.token {
            fetchUserProfile(userId: currentUserId, token: currentToken)
        }
    }

    // Function to update state upon successful login/onboarding
    func login(userId: String, token: String) {
        DispatchQueue.main.async { // Ensure updates happen on the main thread
            self.userId = userId
            self.token = token

            // Securely store the token and userId in Keychain
            KeychainHelper.standard.save(userId, service: "com.spurly.userid", account: "user")
            KeychainHelper.standard.save(token, service: "com.spurly.token", account: "user")

            print("AuthManager: User logged in - UserID: \(userId)")

            // NEW: Fetch profile status after login
            self.fetchUserProfile(userId: userId, token: token)
        }
    }

    // Function to clear state upon logout
    func logout() {
        DispatchQueue.main.async {
            self.userId = nil
            self.token = nil
            self.userProfileExists = nil // Reset profile status
            self.isLoadingProfile = false // Reset loading state

            // Remove the token and userId from Keychain
            KeychainHelper.standard.delete(service: "com.spurly.userid", account: "user")
            KeychainHelper.standard.delete(service: "com.spurly.token", account: "user")

            print("AuthManager: User logged out.")
        }
    }

    // NEW: Function to fetch user profile status
    func fetchUserProfile(userId: String, token: String) {
        guard !userId.isEmpty, !token.isEmpty else {
            print("AuthManager: Cannot fetch profile, userId or token is missing.")
            DispatchQueue.main.async {
                self.userProfileExists = false // Assume no profile if critical info is missing
                self.isLoadingProfile = false
            }
            return
        }

        DispatchQueue.main.async {
            self.isLoadingProfile = true
            self.userProfileExists = nil // Reset while fetching
        }

        print("AuthManager: Fetching profile for UserID: \(userId)...")
        // Use NetworkService to make the call
        // Assuming NetworkService.shared.getUserProfile is added (see step 2)
        NetworkService.shared.getUserProfile(userId: userId, token: token) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoadingProfile = false
                switch result {
                case .success(let profileResponse): // Assuming ProfileExistsResponse indicates existence
                    self.userProfileExists = profileResponse.exists
                    print("AuthManager: Profile fetch success. Profile exists: \(profileResponse.exists)")
                case .failure(let error):
                    // If 404, profile doesn't exist. Other errors are actual failures.
                    if case .serverError(_, let statusCode) = error, statusCode == 404 {
                        self.userProfileExists = false
                        print("AuthManager: Profile not found (404).")
                    } else {
                        self.userProfileExists = false // Or handle error differently, e.g. keep as nil to show error/retry
                        print("AuthManager: Profile fetch failed: \(error.localizedDescription)")
                        // Optionally, you could set an error message here to display to the user
                    }
                }
            }
        }
    }

    // Call this after onboarding is successfully completed
    func userDidCompleteOnboarding() {
        DispatchQueue.main.async {
            self.userProfileExists = true
            print("AuthManager: User marked as having completed onboarding.")
        }
    }
}
