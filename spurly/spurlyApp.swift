//
//  spurlyApp.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI
import GoogleSignIn // <-- Import GoogleSignIn

@main
struct spurlyApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var sideMenuManager = SideMenuManager()
    @StateObject private var spurManager = SpurManager()
    @StateObject private var connectionManager = ConnectionManager()

    init() { // <-- Add an init method
        setupGoogleSignIn()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .environmentObject(sideMenuManager)
                .environmentObject(spurManager)
                .environmentObject(connectionManager)
                .onOpenURL { url in // <-- Handle the URL callback
                    GIDSignIn.sharedInstance.handle(url)
                }
        }
    }

    private func setupGoogleSignIn() {
        guard let clientID = getGoogleClientID() else {
            print("Error: Google Client ID not found in GoogleService-Info.plist. Google Sign-In will not work.")
            // You might want to handle this more gracefully, perhaps disable Google Sign-In
            return
        }
        // No direct GIDConfiguration init with clientID in latest SDKs for basic setup.
        // The clientID is typically read from the GoogleService-Info.plist automatically by the SDK.
        // If you need to set it programmatically (less common for standard setup):
        // let config = GIDConfiguration(clientID: clientID)
        // GIDSignIn.sharedInstance.configuration = config
        // However, usually, just having GoogleService-Info.plist is enough.
        // The critical part is ensuring GoogleService-Info.plist is correctly added and configured.
        print("Google Sign-In configured (relies on GoogleService-Info.plist).")
    }

    private func getGoogleClientID() -> String? {
        // Attempt to read CLIENT_ID from the GoogleService-Info.plist
        // This is just for verification or if you needed to pass it manually somewhere.
        // The GIDSignIn SDK usually picks this up automatically.
        var dictionary: NSDictionary?
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") {
            dictionary = NSDictionary(contentsOfFile: path)
        }
        return dictionary?["CLIENT_ID"] as? String
    }
}

// RootView and MainAppView remain as previously defined
struct RootView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var spurManager: SpurManager
    @EnvironmentObject var connectionManager: ConnectionManager
    @EnvironmentObject var sideMenuManager: SideMenuManager

    var body: some View {

        NavigationView {
            ContextInputView()
                .environmentObject(authManager)
                .environmentObject(spurManager)
                .environmentObject(connectionManager)
                .environmentObject(sideMenuManager)
        }


//        if authManager.isAuthenticated {
//            if authManager.isLoadingProfile {
//                ProgressView("loading profile...")
//            } else if authManager.userProfileExists == true {
//                NavigationView {
//                    ContextInputView()
//                        .environmentObject(authManager)
//                        .environmentObject(spurManager)
//                        .environmentObject(connectionManager)
//                        .environmentObject(sideMenuManager)
//                }
//            } else if authManager.userProfileExists == false {
//                OnboardingView(authManager: authManager)
//                    .environmentObject(authManager)
//            } else {
//                ProgressView("checking authentication state...")
//            }
//        } else {
//            LoginLandingView()
//        }
    }
}

struct MainAppView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var spurManager: SpurManager
    @EnvironmentObject var connectionManager: ConnectionManager
    @EnvironmentObject var sideMenuManager: SideMenuManager

    var body: some View {

        NavigationView {
            ContextInputView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
