//
//  AuthViewModel.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI
import Combine
import AuthenticationServices // For Sign in with Apple
import CryptoKit
import GoogleSignIn
import GoogleSignInSwift
import Foundation
import FacebookLogin
import FirebaseAuth

class AuthViewModel: NSObject, ObservableObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    // Input fields for Login & Create Account
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = "" // For account creation

    // State management
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var showLoginSuccessAlert = false // Or navigate directly

    // For Sign in with Apple
    @Published var appleSignInNonce: String?

    private var authManager: AuthManager
    private var cancellables = Set<AnyCancellable>()

    init(authManager: AuthManager) {
        self.authManager = authManager
        super.init()
    }

    // MARK: - Computed Properties for Validation (Basic examples)
    var isLoginFormValid: Bool {
        !email.isEmpty && NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: email) && !password.isEmpty && password.count >= 8
    }

    var isCreateAccountFormValid: Bool {
        !email.isEmpty && NSPredicate(format:"SELF MATCHES %@", "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}").evaluate(with: email) &&
        !password.isEmpty && password.count >= 8 &&
        password == confirmPassword
    }

    // MARK: - API Calls
    func createAccount() {
        guard isCreateAccountFormValid else {
            errorMessage = "Please fill all fields correctly. Password must be at least 8 characters and match the confirmation."
            return
        }
        isLoading = true
        errorMessage = nil

        // Create account with Firebase Auth
        // TODO: Need to execute check to see if email is in use already
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.handleFirebaseAuthError(error)
                }
                return
            }

            guard let user = authResult?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to create account. Please try again."
                }
                return
            }

            // Get the Firebase ID token
            user.getIDToken { [weak self] idToken, error in
                guard let self = self else { return }

                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Failed to get authentication token: \(error.localizedDescription)"
                    }
                    return
                }

                guard let idToken = idToken else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Failed to get authentication token."
                    }
                    return
                }

                // Send the Firebase ID token to your backend
                let request = CreateAccountRequest(firebaseIdToken: idToken, email: self.email)
                NetworkService.shared.createAccountWithFirebase(requestData: request) { [weak self] result in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        self.isLoading = false

                        switch result {
                        case .success(let authResponse):
                            print("Account created successfully: UserID \(authResponse.user_id)")
                                self.authManager
                                    .login(authResponse: authResponse)

                        case .failure(let error):
                            // If backend fails, we might want to delete the Firebase user
                            user.delete { _ in
                                print("Deleted Firebase user after backend failure")
                            }
                            self.handleAuthError(error)
                        }
                    }
                }
            }
        }
    }

    func loginUser() {
        guard isLoginFormValid else {
            errorMessage = "Please enter a valid email and password (min. 8 characters)."
            return
        }
        isLoading = true
        errorMessage = nil


        // Sign in with Firebase Auth
        Auth.auth().signIn(withEmail: email, password: password) {
 [weak self] authResult,
 error in
            guard let self = self else { return }

            if let error = error {

                DispatchQueue.main.async {
                    self.isLoading = false
                    self.handleFirebaseAuthError(error)
                }
                return
            }

            guard let user = authResult?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to sign in. Please try again."
                }
                return
            }

            // Get the Firebase ID token
            user.getIDToken {
 [weak self] idToken,
 error in
                guard let self = self else { return }
            user

                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Failed to get authentication token: \(error.localizedDescription)"
                    }
                    return
                }

                guard let idToken = idToken else {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Failed to get authentication token."
                    }
                    return
                }

                if user.email != nil && user.email != "" {
                    self.email = user.email ?? ""
                }

                    // Send the Firebase ID token to your backend
                let request = LoginRequest(firebaseIdToken: idToken, email: self.email)
                NetworkService.shared.loginWithFirebase(requestData: request) { [weak self] result in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        self.isLoading = false

                        switch result {
                            case .success(let authResponse):
                                print(
                                    "Login successful: UserID \(authResponse.user_id)"
                                )
                                self.authManager
                                    .login(
                                        userId: authResponse.user_id,
                                        token: authResponse.accessToken,
                                        email: user.email
                                    )

                        case .failure(let error):
                            self.handleAuthError(error)
                        }
                    }
                }
            }
        }
    }

    private func handleFirebaseAuthError(_ error: Error) {
        let nsError = error as NSError

        if let errorCode = AuthErrorCode(rawValue: nsError.code) {
            switch errorCode {
            case .emailAlreadyInUse:
                self.errorMessage = "This email is already registered. Please sign in instead."
            case .invalidEmail:
                self.errorMessage = "Please enter a valid email address."
            case .weakPassword:
                self.errorMessage = "Password is too weak. Please use at least 8 characters."
            case .wrongPassword:
                self.errorMessage = "Incorrect password. Please try again."
            case .userNotFound:
                self.errorMessage = "No account found with this email. Please create an account."
            case .networkError:
                self.errorMessage = "Network error. Please check your connection and try again."
            case .tooManyRequests:
                self.errorMessage = "Too many failed attempts. Please try again later."
            case .userDisabled:
                self.errorMessage = "This account has been disabled. Please contact support."
            default:
                self.errorMessage = "Authentication failed: \(error.localizedDescription)"
            }
        } else {
            self.errorMessage = "Authentication failed: \(error.localizedDescription)"
        }

        print("Firebase Auth Error: \(self.errorMessage ?? "Unknown error")")
    }

    private func handleAuthError(_ error: NetworkError) {
        switch error {
            case .serverError(let message, let statusCode):
                self.errorMessage = "Server Error (\(statusCode)): \(message)"
            case .decodingError:
                self.errorMessage = "Could not understand server response. Please try again."
            case .requestFailed:
                self.errorMessage = "Network request failed. Please check your connection."
            default:
                self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        print("AuthViewModel Error: \(self.errorMessage ?? "Unknown error")")
    }

    // MARK: - Social Logins (Placeholders - Requires SDK Integration)

    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        handleSignInWithAppleRequest(request)

        let controller = ASAuthorizationController(
            authorizationRequests: [request]
        )
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    func handleSignInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        // Generate a new nonce for this sign-in attempt.
        // A nonce is a random string that helps prevent replay attacks.
        let nonce = randomNonceString()
        appleSignInNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce) // The SHA256 hash of the nonce
    }

        // Update the Apple Sign-In completion handler in AuthViewModel.swift

    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil

        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = appleSignInNonce else {
                    errorMessage = "Invalid state: A login callback was received, but no login nonce was stored."
                    isLoading = false
                    return
                }

                guard let identityToken = appleIDCredential.identityToken,
                      let identityTokenString = String(data: identityToken, encoding: .utf8) else {
                    errorMessage = "Unable to fetch Apple ID token."
                    isLoading = false
                    return
                }

                guard let authorizationCode = appleIDCredential.authorizationCode,
                      let authCodeString = String(data: authorizationCode, encoding: .utf8) else {
                    errorMessage = "Unable to fetch authorization code."
                    isLoading = false
                    return
                }

                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName

                print("Apple Sign In Success - Sending to backend for validation")

                // Send to backend for validation
                NetworkService.shared.signInWithApple(
                    identityToken: identityTokenString,
                    authorizationCode: authCodeString,
                    email: email,
                    fullName: fullName
                ) { [weak self] result in
                    guard let self = self else { return }

                    DispatchQueue.main.async {
                        self.isLoading = false

                        switch result {
                        case .success(let authResponse):
                            print("AuthViewModel: Successfully validated Apple Sign-In with backend.")
                            self.authManager.login(authResponse: authResponse)

                        case .failure(let error):
                            self.handleAuthError(error)
                            print("AuthViewModel: Apple Sign-In backend validation failed: \(error.localizedDescription)")
                        }
                    }
                }

            } else if let passwordCredential = auth.credential as? ASPasswordCredential {
                // Sign in with Password (for existing iCloud Keychain users)
                let username = passwordCredential.user
                let password = passwordCredential.password
                print("Apple Sign In with Keychain: User - \(username)")

                // Auto-fill and attempt login
                self.email = username
                self.password = password
                self.loginUser()
            }

        case .failure(let error):
            print("Apple Sign In Error: \(error.localizedDescription)")
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                errorMessage = "Sign in with Apple was canceled."
            } else {
                errorMessage = "Apple Sign In failed: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }

    // Update the Google Sign-In method to handle the new response structure
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        guard let presentingViewController = Utilities.shared.getTopViewController() else {
            errorMessage = "Could not find a view controller to present Google Sign-In."
            isLoading = false
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] signInResult, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                self.isLoading = false
                return
            }

            guard let result = signInResult,
                  let idToken = result.user.idToken?.tokenString else {
                self.errorMessage = "Google Sign-In failed: Could not retrieve ID token."
                self.isLoading = false
                return
            }

            let serverAuthCode = result.serverAuthCode

            print("Google Sign-In successful - Sending to backend for validation")

            // Send to backend for validation
            NetworkService.shared.signInWithGoogle(idToken: idToken, serverAuthCode: serverAuthCode) { [weak self] backendResult in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    self.isLoading = false

                    switch backendResult {
                    case .success(let authResponse):
                        print("AuthViewModel: Successfully validated Google Sign-In with backend.")
                        self.authManager.login(authResponse: authResponse)

                    case .failure(let backendError):
                        self.handleAuthError(backendError)
                    }
                }
            }
        }
    }

    // Implement Facebook Sign-In
    func signInWithFacebook() {
        isLoading = true
        errorMessage = nil

        // Import FacebookLogin framework
        // import FacebookLogin

        let loginManager = LoginManager()

        guard let presentingViewController = Utilities.shared.getTopViewController() else {
            errorMessage = "Could not find a view controller to present Facebook Sign-In."
            isLoading = false
            return
        }

        loginManager.logIn(permissions: ["public_profile", "email"], from: presentingViewController) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = "Facebook Sign-In failed: \(error.localizedDescription)"
                self.isLoading = false
                return
            }

            guard let result = result, !result.isCancelled,
                  let accessToken = AccessToken.current?.tokenString else {
                self.errorMessage = result?.isCancelled == true ? "Facebook Sign-In was canceled." : "Failed to get Facebook access token."
                self.isLoading = false
                return
            }

            print("Facebook Sign-In successful - Sending to backend for validation")

            NetworkService.shared.signInWithFacebook(accessToken: accessToken) { [weak self] backendResult in
                guard let self = self else { return }

                DispatchQueue.main.async {
                    self.isLoading = false

                    switch backendResult {
                    case .success(let authResponse):
                        print("AuthViewModel: Successfully validated Facebook Sign-In with backend.")
                        self.authManager.login(authResponse: authResponse)

                    case .failure(let backendError):
                        self.handleAuthError(backendError)
                    }
                }
            }
        }
    }


    // MARK: - ASAuthorizationControllerDelegate Methods
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        handleSignInWithAppleCompletion(.success(authorization))
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        handleSignInWithAppleCompletion(.failure(error))
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding Method
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Return the main window of the application.
        // This helper function might need to be adjusted based on your app's scene setup.
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            // Fallback or error handling if window is not found
            // This could happen if called very early or in unusual contexts.
            // For most typical app flows, it should be available.
#if DEBUG
            print("Warning: Could not get presentation anchor window. Using a new UIWindow as a fallback for debug.")
            return UIWindow() // Fallback for DEBUG, not ideal for production
#else
            // In a release build, you might prefer to fail more gracefully or log an error.
            // Depending on the context, returning a newly created window might still work or might cause issues.
            // For safety, ensure this part is robust in your app.
            // A common approach is to have a utility to get the key window.
            fatalError("Could not get presentation anchor window for ASAuthorizationController.")
#endif
        }
        return window
    }

    // Generates a random nonce string.
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate random byte. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    // Hashes the input string using SHA256.
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }

    // MARK: - Google Sign In


    // Placeholder for Facebook Sign In


    func clearInputs() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
    }

    func checkAuthentication() {
        isLoading = true // Start loading
        if authManager.isAuthenticated, let userId = authManager.userId, let token = authManager.token {
            // If authenticated, immediately check for profile existence
            NetworkService.shared.getUserProfile(userId: userId, token: token) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let profileResponse):
                            self.authManager.userId
                    case .failure(let error):
                        // If getUserProfile fails (e.g., 404 or other errors),
                        // we assume the profile doesn't exist for UI purposes.
                        // AuthManager's checkAuthentication might have already handled this
                        // by setting userProfileExists to false for 404.
                        // This ensures it's false if any other error occurs during profile check.
                        print("AuthViewModel: Error checking user profile - \(error.localizedDescription)")
                        if case .serverError(let message, let statusCode) = error {
                            print("AuthViewModel: Server error (\(statusCode)) checking profile: \(message)")
                        }
                    }
                    self.isLoading = false // Stop loading after profile check
                }
            }
        } else {
            // Not authenticated or missing details
            isLoading = false // Stop loading if not authenticated
        }
    }

    func completeOnboarding(data: OnboardingPayload, completion: @escaping (Bool, String?) -> Void) {
        // 1. Get the auth token from AuthManager
        guard let token = authManager.token, let userId = authManager.userId else {
            completion(false, "User is not authenticated. Cannot complete onboarding.")
            return
        }


        let requestData = OnboardingRequest(
            name: data.name ?? "",
            age: data.age ?? 0,
            userContextBlock: data.user_context_block ?? ""
        )

        // 3. Use the NetworkService to submit the profile
        NetworkService.shared.submitOnboardingProfile(requestData: requestData, authToken: token) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):

                    // *** THE KEY CHANGE IS HERE ***
                    // Instead of setting a state, we re-check the profile.
                    // This will update the `userProfileExists` property to true,
                    // which will trigger the navigation in the main app view.
                    self?.authManager.fetchUserProfile(userId: userId, token: token)

                    completion(true, nil)

                case .failure(let error):
                    let errorMessage = "Failed to save your profile. Please try again."
                    print("Onboarding failed: \(error.localizedDescription)")
                    if case .serverError(let message, let statusCode) = error {
                        print("Server error (\(statusCode)): \(message)")
                    }
                    completion(false, errorMessage)
                }
            }
        }
    }
}


// MARK: - Utilities to get the Top View Controller (for presenting Google Sign-In)
// You can place this in a separate Utilities.swift file if you prefer
class Utilities {
    static let shared = Utilities()
    private init() {}

    func getTopViewController(base: UIViewController? = UIApplication.shared.connectedScenes
                                .filter({$0.activationState == .foregroundActive})
                                .map({$0 as? UIWindowScene})
                                .compactMap({$0})
                                .first?.windows
                                .filter({$0.isKeyWindow}).first?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return getTopViewController(base: nav.visibleViewController)
        } else if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return getTopViewController(base: selected)
        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}
