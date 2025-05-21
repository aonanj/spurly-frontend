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

        let request = CreateAccountRequest(email: email, password: password)
        NetworkService.shared.createAccount(requestData: request) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let authResponse):
                print("Account created successfully: UserID \(authResponse.userId)")
                self.authManager.login(userId: authResponse.userId, token: authResponse.token)
                // self.showLoginSuccessAlert = true // Or trigger navigation
            case .failure(let error):
                self.handleAuthError(error)
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

        let request = LoginRequest(email: email, password: password)
        NetworkService.shared.login(requestData: request) { [weak self] result in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let authResponse):
                print("Login successful: UserID \(authResponse.userId)")
                self.authManager.login(userId: authResponse.userId, token: authResponse.token)
                // self.showLoginSuccessAlert = true // Or trigger navigation
            case .failure(let error):
                self.handleAuthError(error)
            }
        }
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

    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        isLoading = true
        errorMessage = nil
        switch result {
        case .success(let auth):
            if let appleIDCredential = auth.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = appleSignInNonce else {
                    fatalError("Invalid state: A login callback was received, but no login nonce was stored.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token.")
                    errorMessage = "Unable to fetch Apple ID token."
                    isLoading = false
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    errorMessage = "Unable to process Apple ID token."
                    isLoading = false
                    return
                }

                let userId = appleIDCredential.user // This is a stable user identifier.
                let email = appleIDCredential.email
                let fullName = appleIDCredential.fullName

                print("Apple Sign In Success: UserID - \(userId)")
                print("Apple Sign In Token: \(idTokenString)") // This token needs to be sent to your backend for validation

                // TODO: Send this idTokenString (and nonce, user identifier) to your backend
                // Your backend will verify the token with Apple's servers and then
                // create an account or log in the user, returning your app's own auth token.
                // Example:
                // let socialRequest = SocialLoginRequest(provider: "apple", idToken: idTokenString, /* other details */)
                // NetworkService.shared.socialLogin(requestData: socialRequest) { ... }

                // For now, let's simulate a successful login with a placeholder token
                // In a real app, you'd get the token from your backend response.
                // self.authManager.login(userId: userId, token: "fakeAppleBackendToken-\(idTokenString.prefix(10))")

                // This is where you would call your backend. For now, we'll set an error message.
                self.errorMessage = "Apple Sign-In successful! Backend integration needed to complete login with token: \(idTokenString.prefix(20))..."
                self.isLoading = false


            } else if let passwordCredential = auth.credential as? ASPasswordCredential {
                // Sign in with Password (for existing iCloud Keychain users)
                let username = passwordCredential.user
                let password = passwordCredential.password
                print("Apple Sign In with Keychain: User - \(username)")
                // You can use this to pre-fill your app's own login form or directly attempt login
                // self.email = username
                // self.password = password
                // loginUser()
                self.errorMessage = "Apple Keychain credential received. Integrate with your login flow."
                isLoading = false
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
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        // Get the top view controller to present the sign-in flow.
        guard let presentingViewController = Utilities.shared.getTopViewController() else {
            errorMessage = "Could not find a view controller to present Google Sign-In."
            isLoading = false
            print("AuthViewModel: No top view controller found for Google Sign-In.")
            return
        }

        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] signInResult, error in
            guard let self = self else { return }

            if let error = error {
                self.errorMessage = "Google Sign-In failed: \(error.localizedDescription)"
                self.isLoading = false
                print("AuthViewModel: Google Sign-In error: \(error.localizedDescription)")
                return
            }

            guard let result = signInResult else {
                self.errorMessage = "Google Sign-In failed: No result."
                self.isLoading = false
                print("AuthViewModel: Google Sign-In error: No result.")
                return
            }

            guard let idToken = result.user.idToken?.tokenString else {
                self.errorMessage = "Google Sign-In failed: Could not retrieve ID token."
                self.isLoading = false
                print("AuthViewModel: Google Sign-In error: Missing ID token.")
                return
            }

            let serverAuthCode = result.serverAuthCode // Optional: if your backend needs it for offline access

            print("Google Sign-In successful. ID Token retrieved. User: \(result.user.profile?.email ?? "N/A")")

            // Now, send this idToken (and serverAuthCode if needed) to your backend
            // to exchange it for your app's own authentication token.
            NetworkService.shared.signInWithGoogleToken(idToken: idToken, serverAuthCode: serverAuthCode) { backendResult in
                self.isLoading = false
                switch backendResult {
                case .success(let authResponse):
                    print("AuthViewModel: Successfully exchanged Google token with backend.")
                    // AuthManager's login will trigger profile fetch
                    self.authManager.login(userId: authResponse.userId, token: authResponse.token)
                case .failure(let backendError):
                    self.handleAuthError(backendError) // Use existing error handler
                    print("AuthViewModel: Backend token exchange failed: \(backendError.localizedDescription)")
                }
            }
        }
    }

    // Placeholder for Facebook Sign In
    func signInWithFacebook() {
        isLoading = true
        errorMessage = nil
        // TODO: Implement Facebook SDK logic
        // 1. Initialize Facebook SDK (usually in AppDelegate)
        // 2. Create a LoginManager instance
        // 3. Call loginManager.logIn(...)
        // 4. In the completion, get the accessToken and send to your backend
        print("Attempting Facebook Sign In (Not Implemented)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // Simulate delay
            self.isLoading = false
            self.errorMessage = "Facebook Sign-In is not yet implemented. SDK integration required."
        }
    }

    func clearInputs() {
        email = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
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
