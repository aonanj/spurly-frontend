import SwiftUI
import UIKit

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel: OnboardingViewModel

    @State private var showAgeError = false
    @State private var age: Int? = nil
    @State private var showSuccessOverlay = false
    @State private var successMessage = ""
    @State private var errorMessageTitle = ""
    @State private var showErrorOverlay = false
    @State private var errorMessage = ""
    @State private var name: String = "what do you go by"
    @State private var textEditorText: String = "... spurly can keep things relevant to you. here you can add your interests, job, hometown, relationship type, and anything else that could help spurly help you find your own words quicker ..."

    let nameDefault = "what do you go by"
    let textEditorDefault = "... spurly can keep things relevant to you. here you can add your interests, job, hometown, relationship type, and anything else that could help spurly help you find your own words quicker ..."

    var isAgeValidForSubmission: Bool {
        guard let currentAge = age else { return false }
        return currentAge >= 18
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
                                    .if(isAgeValidForSubmission) { view in
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
                                    .if(!isAgeValidForSubmission) { view in
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
                    .padding(.horizontal, 30)
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
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 10)

                } // End main VStack
                .navigationBarHidden(true)
                .ignoresSafeArea(.keyboard)
                .zIndex(2)

                // Success Overlay
                if showSuccessOverlay {
                    successOverlay
                }

                // Error Overlay
                if showErrorOverlay {
                    errorOverlay
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

    // MARK: - View Components

    private var successOverlay: some View {
        ZStack {
            Color.primaryText.opacity(0.5)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    showSuccessOverlay = false
                }
                .zIndex(3)

            VStack {
                Spacer()

                Image(systemName: "staroflife.fill")
                    .font(.system(size: 35))
                    .foregroundColor(.spurlyBrand)
                    .shadow(color: Color.accent1.opacity(0.7),
                            radius: 8,
                            x: 0,
                            y: 4)

                Spacer()

                Divider()
                    .frame(maxWidth: .infinity)
                    .frame(height: 2)
                    .background(Color.accent1)
                    .padding(.horizontal, 15)
                    .opacity(0.4)
                    .shadow(color: Color.black.opacity(0.55), radius: 3, x: 2, y: 2)

                Text(successMessage)
                    .font(.headline)
                    .foregroundColor(.primaryText)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.cardBg)
                            .shadow(
                                color: Color.accent1.opacity(0.7),
                                radius: 8,
                                x: 2,
                                y: 4
                            )
                    )
                    .padding(.horizontal, 40)
                Spacer()
            }
            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSuccessOverlay = false
                }
            }
            .zIndex(4)
        }.zIndex(4)
    }

    private var errorOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    showErrorOverlay = false
                }
                .zIndex(3)

            VStack {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                        .shadow(color: Color.accent1.opacity(0.7),
                                radius: 8,
                                x: 0,
                                y: 4)

                    Text(errorMessageTitle)
                        .font(.headline)
                        .foregroundColor(.primaryText)

                    Divider()
                        .frame(maxWidth: .infinity)
                        .frame(height: 2)
                        .background(Color.accent1)
                        .padding(.horizontal, 15)
                        .opacity(0.4)
                        .shadow(color: Color.black.opacity(0.55), radius: 3, x: 2, y: 2)

                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("dismiss") {
                        showErrorOverlay = false
                        showAgeError = false
                        viewModel.clearError()
                    }
                    .font(.body)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.red.opacity(0.6))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .padding(.top)
                }
                .padding(EdgeInsets(top: 30, leading: 20, bottom: 20, trailing: 20))
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.cardBg)
                        .shadow(color: .black.opacity(0.8), radius: 10, x: 2, y: 5)
                )
                .padding(.horizontal, 30)
                Spacer()
            }
            .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            .zIndex(4)
        }.zIndex(4)
    }

    // MARK: - Methods

    private func submit() {
        hideKeyboard()

        guard isAgeValidForSubmission else {
            showAgeError = true
            errorMessageTitle = "minimum age requirement"
            errorMessage = "you must be at least 18 to use spurly"
            showErrorOverlay = true
            return
        }

        showAgeError = false

        // Validate inputs
        let finalName = name.isEmpty ? nameDefault : name
        let finalContext = textEditorText.isEmpty ? textEditorDefault : textEditorText

        let payload = OnboardingPayload(
            name: finalName,
            age: age,
            profile_context: finalContext
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
            profileText: data.profile_context ?? ""
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
}

// MARK: - Supporting Types

struct OnboardingPayload: Codable {
    let name: String?
    let age: Int?
    let profile_context: String?
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
