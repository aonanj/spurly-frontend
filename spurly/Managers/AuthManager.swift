//
//  AuthManager.swift
//  spurly
//
//  Created by Alex Osterlind on 4/29/25.
//

import SwiftUI
import Combine // Needed for ObservableObject

// Class to hold authentication state
class AuthManager: ObservableObject {
    @Published var userId: String? = nil
    @Published var token: String? = nil
    // Add @Published var isAuthenticated: Bool = false if you want explicit control,
    // otherwise, compute it based on the token.

    // Computed property to easily check authentication status
    var isAuthenticated: Bool {
        // Simple check: authenticated if token exists and is not empty.
        // You might add token validation logic here later.
        //token != nil && !(token?.isEmpty ?? true)

        // MARK: always return true for testing only
        true
    }

    // Function to update state upon successful login/onboarding
    func login(userId: String, token: String) {
        // In a real app, securely store the token (e.g., Keychain) here.
        // For now, just update the published properties.
        DispatchQueue.main.async { // Ensure updates happen on the main thread
            self.userId = userId
            self.token = token
            print("AuthManager: User logged in - UserID: \(userId)") // Don't log token
        }
    }

    // Function to clear state upon logout
    func logout() {
        // In a real app, remove the token from Keychain here.
        DispatchQueue.main.async {
            self.userId = nil
            self.token = nil
            print("AuthManager: User logged out.")
        }
    }

    // Optional: Add an initializer for preview purposes
    init(userId: String? = nil, token: String? = nil) {
        self.userId = userId
        self.token = token
    }
}
