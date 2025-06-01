import SwiftUI
import UIKit

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel: OnboardingViewModel

    

    @State private var showAgeError = false
    @State private var showNameError = false
    @State private var age: Int? = nil
    @State private var showSuccessOverlay = false
    @State private var successMessage = ""
    @State private var errorMessageTitle = ""
    @State private var showErrorOverlay: Bool = false
    @State private var errorMessage = ""
    @State private var name: String = "what do you go by"
    @State private var textEditorText: String = "... spurly can keep things relevant to you. here you can add your interests, job, hometown, relationship type, and anything else that could help spurly help you find your own words quicker ..."

    let nameDefault = "what do you go by"
    let textEditorDefault = "... spurly can keep things relevant to you. here you can add your interests, job, hometown, relationship type, and anything else that could help spurly help you find your own words quicker ..."

    var isAgeValidForSubmission: Bool {
        guard let currentAge = age else { return false }
        return currentAge >= 18
    }

    var isNameValid: Bool {
        // Age must be selected (not nil) AND be >= 18 for saving, plus name must be present.
        let nameIsValid = (!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                         (name != nameDefault) && (name != ""))
        return nameIsValid
    }

    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width
    let cardWidthMultiplier: CGFloat = 0.85
    let cardHeightMultiplier: CGFloat = 0.62

    init(authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: OnboardingViewModel(authManager: authManager))
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.tappablePrimaryBg
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .zIndex(0)

                Image.tappableBgIcon
                    .frame(width: screenWidth * 1.8, height: screenHeight * 1.8)
                    .position(x: screenWidth / 2, y: screenHeight * 0.49)
                    .zIndex(1)

                VStack(spacing: 0) {
                    // Header
                    VStack(alignment: .center, spacing: 0) {
                        Image.bannerLogo
                            .frame(height: screenHeight * 0.1)

                        Text.bannerTag
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)
                    }
                    .frame(height: geometry.size.height * 0.14)
                    .padding(.top, geometry.safeAreaInsets.top > 30 ? 25 : geometry.safeAreaInsets.top)
                    .padding(.bottom, 20)

                    Spacer()

                    // Main Card
                    OnboardingCardView {
                        UserCardContent(
                            name: $name,
                            age: $age,
                            showAgeError: $showAgeError,
                            textEditorText: $textEditorText,
                            textEditorDefault: textEditorDefault,
                            textFieldDefault: nameDefault
                        )
                    }
                    .frame(
                        width: geometry.size.width * cardWidthMultiplier,
                        height: geometry.size.height * cardHeightMultiplier
                    )
                    .padding(.top, 30)

                    // Submit Button
                    HStack {
                        Spacer()
                        Button(action: submit) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryButton))
                                    .scaleEffect(1.2)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 45))
                                    .if(isAgeValidForSubmission && isNameValid) { view in
                                        view.foregroundStyle(
                                            LinearGradient(
                                                colors: [.highlight, .primaryButton, .highlight],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .shadow(
                                            color: .spurlyPrimaryText.opacity(0.44),
                                            radius: 4,
                                            x: 2,
                                            y: 5
                                        )
                                    }
                                    .if(!isAgeValidForSubmission || !isNameValid) { view in
                                        view
                                            .foregroundColor(.spurlySecondaryText.opacity(0.2))
                                            .shadow(
                                                color: .spurlyPrimaryText.opacity(0.44),
                                                radius: 4,
                                                x: 2,
                                                y: 5
                                            )
                                    }
                            }
                        }
                        .disabled(viewModel.isLoading)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, geometry.size.width * ((1.0 - cardWidthMultiplier) / 2.0))
                    .padding(.bottom, 5)

                    Spacer()

                    // Privacy Notice
                    VStack(spacing: 2) {
                        Text("we care about protecting your data")
                            .font(.footnote)
                            .foregroundStyle(Color.secondaryText)
                            .opacity(0.75)
                            .shadow(
                                color: .spurlyPrimaryText.opacity(0.44),
                                radius: 4,
                                x: 2,
                                y: 5
                            )
                        Link(destination: URL(string: "https://dataprotectionpolicy")!) {
                            Text("learn more here")
                                .underline()
                                .font(.footnote)
                                .foregroundStyle(Color.secondaryText)
                                .opacity(0.75)
                                .shadow(
                                    color: .spurlyPrimaryText.opacity(0.44),
                                    radius: 4,
                                    x: 2,
                                    y: 5
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, (geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 0) + 10)

                } // End main VStack
                .navigationBarHidden(true)
                .ignoresSafeArea(.keyboard)
                .zIndex(2)

                // Success Overlay
                if showSuccessOverlay {
                    SuccessOverlayView(
                        isPresented: $showSuccessOverlay,
                        message: successMessage
                    )
                }

                // Error Overlay
                if showAgeError {
                    ErrorOverlayView(
                        isPresented: $showAgeError,
                        errorTitle: "minimum age requirement",
                        errorMessage: "spurly is only for use by those 18 years and up",
                        onDismiss: {
                            if viewModel.isAgeError {
                                viewModel.isAgeError = false
                            }
                            showErrorOverlay = false
                        }
                    )
                }
                if showNameError {
                    ErrorOverlayView(
                        isPresented: $showNameError,
                        errorTitle: "name requirement",
                        errorMessage: "please enter a name to use spurly",
                        onDismiss: {
                            if viewModel.isNameError {
                                viewModel.isNameError = false
                            }
                            showErrorOverlay = false
                        }
                    )
                }

                if showErrorOverlay {
                    ErrorOverlayView(
                        isPresented: $showErrorOverlay,
                        errorTitle: errorMessageTitle,
                        errorMessage: errorMessage,
                        onDismiss: {
                            if viewModel.isError {
                                viewModel.isError = false
                            }
                        }
                    )
                }

            } // End main ZStack
        } // End Geometry Reader
        .onReceive(viewModel.$errorMessage) { error in
            if let error = error {
                self.errorMessageTitle = "Error"
                self.errorMessage = error
                self.showErrorOverlay = true
            }
        }
        .onReceive(authManager.$userProfileExists) { profileExists in
            if profileExists == true {
                // Profile successfully created, navigation will be handled by parent view
                print("OnboardingView: Profile created successfully")
            }
        }
    }

    // MARK: - Methods

    private func submit() {
        hideKeyboard()

        guard isAgeValidForSubmission else {
            showAgeError = true
            errorMessageTitle = "minimum age requirement"
            errorMessage = "you must be at least 18 to use spurly"
            showErrorOverlay = true
            viewModel.isError = true
            viewModel.isAgeError = true
            return
        }

        guard isNameValid else {
            showNameError = true
            errorMessageTitle = "please enter a name name cannot be blank"
            errorMessage = "name cannot be blank. please enter a name to use with spurly"
            showErrorOverlay = true
            viewModel.isError = true
            viewModel.isNameError = true
            return
        }

        showAgeError = false
        showNameError = false
        showErrorOverlay = false
        viewModel.isError = false

        // Validate inputs
        let finalName = name.isEmpty ? nameDefault : name
        let userContextBlock = textEditorText.isEmpty ? textEditorDefault : textEditorText

        let payload = OnboardingPayload(
            name: finalName,
            age: age,
            user_context_block: userContextBlock
        )

        // Submit through viewModel
        viewModel.submitOnboarding(data: payload) { success, error in
            if success {
                let displayName = finalName == nameDefault ? "User" : finalName
                self.successMessage = "welcome to spurly, \(displayName)"
                self.showSuccessOverlay = true
            } else if let error = error {
                self.errorMessageTitle = "Error"
                self.errorMessage = error
                self.showErrorOverlay = true
            }
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - View Model

class OnboardingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String? = nil


    @Published var isError: Bool = false
    @Published var isAgeError: Bool = false
    @Published var isNameError: Bool = false

    private let authManager: AuthManager

    init(authManager: AuthManager) {
        self.authManager = authManager
    }

    func submitOnboarding(data: OnboardingPayload, completion: @escaping (Bool, String?) -> Void) {


        guard let token = authManager.token, let userId = authManager.userId else {
            completion(false, "User is not authenticated. Cannot complete onboarding.")
            return
        }

        isLoading = true
        errorMessage = nil

        let requestData = OnboardingRequest(
            name: data.name ?? "",
            age: data.age ?? 0,
            userContextBlock: data.user_context_block ?? ""
        )


        NetworkService.shared.submitOnboardingProfile(requestData: requestData, authToken: token) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false

                switch result {
                case .success(_):
                    // Re-fetch profile to update userProfileExists
                    self.authManager.fetchUserProfile(userId: userId, token: token)
                    completion(true, nil)

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
                        errorMessage = "Failed to save your profile. Please try again."
                    }

                    self.errorMessage = errorMessage
                    completion(false, errorMessage)
                }
            }
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func triggerError() {
        isError = true
    }

    func clearAllErrors() {
        isError = false
        isAgeError = false
        isNameError = false
    }
}

// MARK: - Supporting Types

struct OnboardingPayload: Codable {
    let name: String?
    let age: Int?
    let user_context_block: String?
}

// MARK: - View Extension

extension View {

    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            return AnyView(transform(self))
        } else {
            return AnyView(self)
        }
    }
}

// MARK: - Preview

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthManager()
        OnboardingView(authManager: authManager)
            .environmentObject(authManager)
    }
}
