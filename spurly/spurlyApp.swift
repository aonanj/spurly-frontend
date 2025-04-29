//
//  spurlyApp.swift
//  spurly
//
//  Created by Alex Osterlind on 4/24/25.
//

import SwiftUI

@main
struct spurlyApp: App {

    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                if authManager.isAuthenticated {
                    ContextInputView()
                    //Other views for authenticated users
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(authManager) // Pass AuthManager to the environment
        }
    }
}
