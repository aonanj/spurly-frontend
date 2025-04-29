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
    @StateObject private var sideMenuManager = SideMenuManager()
    @StateObject private var connectionManager = ConnectionManager()

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
            .environmentObject(sideMenuManager) // Pass SideMenuManager to the environment
            .environmentObject(connectionManager) // Pass ConnectionManager to the environment
        }
    }
}
