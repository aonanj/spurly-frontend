//
//  spurlyApp.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI
import UIKit
import GoogleSignIn
import FirebaseCore
import FirebaseAuth
import FirebaseStorage
import FirebaseAppCheck


class AppDelegate: NSObject, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {


        FirebaseApp.configure()
//        #if targetEnvironment(simulator)
//
//        print("App Check initialized with DEBUG provider for simulator.") // You are seeing this
//
//        // ---- ADD THIS SECTION ----
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            let providerFactory = AppCheckDebugProviderFactory()
//            AppCheck.setAppCheckProviderFactory(providerFactory)
//
//            AppCheck.appCheck().token(forcingRefresh: true) { token, error in // <--- Change false to true
//                if let error = error {
//                    print("App Check (forcing refresh): Error explicitly fetching token: \(error.localizedDescription)")
//                    if let nsError = error as NSError? {
//                        print("App Check (forcing refresh): Explicit fetch error - Domain: \(nsError.domain), Code: \(nsError.code), UserInfo: \(nsError.userInfo)")
//                    }
//                } else if let token = token {
//                    print("App Check (forcing refresh): Explicitly fetched an App Check token. Token value: \(token.token)")
//                } else {
//                    print("App Check (forcing refresh): Explicitly fetching token returned no token and no error.")
//                }
//            }
//        }
        // ---- END OF ADDED SECTION ----

       // #else
        // For real devices, use DeviceCheckProvider.
        // ... (your existing real device code) ...
 //       #endif


        return true
    }
}

@main
struct spurlyApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var sideMenuManager = SideMenuManager()
    @StateObject private var spurManager = SpurManager()
    @StateObject private var connectionManager = ConnectionManager()
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    init() {
        setupGoogleSignIn()
        let providerFactory = AppCheckDebugProviderFactory()
        AppCheck.setAppCheckProviderFactory(providerFactory)

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
        if authManager.isAuthenticated {
            if authManager.isLoadingProfile {
                ProgressView("loading profile...")
            } else if authManager.userName != nil && authManager.userName != "" {
                NavigationView {
                    ContextInputView()
                        .environmentObject(authManager)
                        .environmentObject(spurManager)
                        .environmentObject(connectionManager)
                        .environmentObject(sideMenuManager)
                }
            } else if authManager.userName == nil || authManager.userName == "" {
                OnboardingView(authManager: authManager)
                    .environmentObject(authManager)
            } else {
                ProgressView("checking authentication state...")
            }
        } else {
            LoginLandingView()
        }
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
