//
//  AuthManager.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI
import Combine

// Class to hold authentication state
class AuthManager: ObservableObject {
    @Published var userId: String?
    @Published var token: String?
    @Published var refreshToken: String?
    @Published var userEmail: String?
    @Published var userName: String?

    // User Profile Status
    @Published var userProfileExists: Bool? = nil
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
        self.refreshToken = KeychainHelper.standard.read(service: "com.spurly.refreshtoken", account: "user")
        self.userEmail = "testEmail@email.com"//KeychainHelper.standard.read(service: "com.spurly.email", account: "user")
        self.userName = KeychainHelper.standard.read(service: "com.spurly.name", account: "user")

        print("AuthManager: Initialized. UserID loaded: \(userId != nil), Token loaded: \(token != nil)")

        if isAuthenticated, let currentUserId = self.userId, let currentToken = self.token {
            fetchUserProfile(userId: currentUserId, token: currentToken)
        }
    }

    // Updated login function to handle new AuthResponse structure
    func login(authResponse: AuthResponse) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Update state from AuthResponse
            self.userId = authResponse.user.id
            self.token = authResponse.accessToken
            self.refreshToken = authResponse.refreshToken
            self.userEmail = authResponse.user.email
            self.userName = authResponse.user.name


            // Securely store in Keychain
            KeychainHelper.standard.save(authResponse.user.id, service: "com.spurly.userid", account: "user")
            KeychainHelper.standard.save(authResponse.accessToken, service: "com.spurly.token", account: "user")

            if let refreshToken = authResponse.refreshToken {
                KeychainHelper.standard.save(refreshToken, service: "com.spurly.refreshtoken", account: "user")
            }

            KeychainHelper.standard.save(authResponse.user.email, service: "com.spurly.email", account: "user")

            if let name = authResponse.user.name {
                KeychainHelper.standard.save(name, service: "com.spurly.name", account: "user")
            }


            print("AuthManager: User logged in - UserID: \(authResponse.user.id), Email: \(authResponse.user.email)")

            // Fetch profile status after login
            self.fetchUserProfile(userId: authResponse.user.id, token: authResponse.accessToken)
        }
    }

    // Legacy login function for compatibility
    func login(userId: String, token: String) {
        // Create a minimal AuthResponse for backward compatibility
        let user = UserInfo(
            id: userId,
            email: userEmail ?? "",
            name: userName,
        )
        let authResponse = AuthResponse(
            accessToken: token,
            refreshToken: refreshToken,
            user: user
        )
        login(authResponse: authResponse)
    }

    // Function to clear state upon logout
    func logout() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.userId = nil
            self.token = nil
            self.refreshToken = nil
            self.userEmail = nil
            self.userName = nil
            self.userProfileExists = nil
            self.isLoadingProfile = false

            // Remove all from Keychain
            KeychainHelper.standard.delete(service: "com.spurly.userid", account: "user")
            KeychainHelper.standard.delete(service: "com.spurly.token", account: "user")
            KeychainHelper.standard.delete(service: "com.spurly.refreshtoken", account: "user")
            KeychainHelper.standard.delete(service: "com.spurly.email", account: "user")
            KeychainHelper.standard.delete(service: "com.spurly.name", account: "user")
            
            print("AuthManager: User logged out.")
        }
    }

    // Function to refresh access token
    func refreshAccessToken(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = refreshToken else {
            print("AuthManager: No refresh token available")
            completion(false)
            return
        }

        NetworkService.shared.refreshToken(refreshToken: refreshToken) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                switch result {
                case .success(let tokenResponse):
                    self.token = tokenResponse.accessToken
                    KeychainHelper.standard.save(tokenResponse.accessToken, service: "com.spurly.token", account: "user")
                    print("AuthManager: Access token refreshed successfully")
                    completion(true)

                case .failure(let error):
                    print("AuthManager: Failed to refresh token: \(error.localizedDescription)")
                    // If refresh fails, logout user
                    self.logout()
                    completion(false)
                }
            }
        }
    }

    // Function to fetch user profile status
    func fetchUserProfile(userId: String, token: String) {
        guard !userId.isEmpty, !token.isEmpty else {
            print("AuthManager: Cannot fetch profile, userId or token is missing.")
            DispatchQueue.main.async { [weak self] in
                self?.userProfileExists = false
                self?.isLoadingProfile = false
            }
            return
        }

        DispatchQueue.main.async { [weak self] in
            self?.isLoadingProfile = true
            self?.userProfileExists = nil
        }

        print("AuthManager: Fetching profile for UserID: \(userId)...")

        NetworkService.shared.getUserProfile(userId: userId, token: token) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoadingProfile = false

                switch result {
                case .success(let profileResponse):
                    self.userProfileExists = profileResponse.exists
                    print("AuthManager: Profile fetch success. Profile exists: \(profileResponse.exists)")

                    // Update user info if provided in profile response
                    if let name = profileResponse.name {
                        self.userName = name
                        KeychainHelper.standard.save(name, service: "com.spurly.name", account: "user")
                    }

                case .failure(let error):
                    // Handle different error cases
                    switch error {
                    case .profileNotFound:
                        self.userProfileExists = false
                        print("AuthManager: Profile not found.")

                    case .unauthorized:
                        // Token might be expired, try to refresh
                        self.refreshAccessToken { success in
                            if success {
                                // Retry profile fetch with new token
                                self.fetchUserProfile(userId: userId, token: self.token ?? "")
                            }
                        }

                    default:
                        self.userProfileExists = false
                        print("AuthManager: Profile fetch failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    // Call this after onboarding is successfully completed
    func userDidCompleteOnboarding() {
        DispatchQueue.main.async { [weak self] in
            self?.userProfileExists = true
            print("AuthManager: User marked as having completed onboarding.")
        }
    }
}
