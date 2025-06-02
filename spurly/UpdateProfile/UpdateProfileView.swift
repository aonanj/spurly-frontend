//
//
// File name: UpdateProfileView.swift
//
// Product / Project: spurly / spurly
//
// Organization: phaeton order llc
// Bundle ID: com.phaeton-order.spurly
//
//

import SwiftUI

struct UpdateProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel: UpdateProfileViewModel

    @State private var name: String = ""
    @State private var age: Int? = nil
    @State private var email: String = ""
    @State private var textEditorText: String = ""
    @State private var showAgeError = false
    @State private var showNameError = false
    @State private var showEmailError = false
    @State private var showSuccessOverlay = false
    @State private var successMessage = ""
    @State private var errorMessageTitle = ""
    @State private var showErrorOverlay: Bool = false
    @State private var errorMessage = ""

    let nameDefault = "what do you go by"
    let textEditorDefault = "... spurly can keep things relevant to you. here you can add your interests, job, hometown, relationship type, and anything else that could help spurly help you find your own words quicker ..."

    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width
    let cardWidthMultiplier: CGFloat = 0.85
    let cardHeightMultiplier: CGFloat = 0.62

    init(authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: UpdateProfileViewModel(authManager: authManager))
    }

    var isAgeValidForSubmission: Bool {
        guard let currentAge = age else { return false }
        return currentAge >= 18
    }

    var isNameValid: Bool {
        let nameIsValid = (!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                          (name != nameDefault) && (name != ""))
        return nameIsValid
    }

    var isEmailValid: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    var isFormValid: Bool {
        return isNameValid && isAgeValidForSubmission && isEmailValid
    }

    var currentEmail: String {
        return authManager.userEmail ?? ""
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
                    .position(x: screenWidth / 2, y: screenHeight * 0.5)
                    .zIndex(1)

                VStack(spacing: 0) {
                    // Header
                    Spacer()

                    VStack(alignment: .center, spacing: 0) {
                        Image.bannerLogo
                            .frame(height: screenHeight * 0.1)

                        Text.bannerTag
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)
                    }
                    .frame(height: geometry.size.height * 0.11)
                    .padding(.top, geometry.safeAreaInsets.top + 25)
                    .padding(.bottom, 40)

                    Spacer()

                    // Main Card
                    UpdateProfileCardView {
                        UpdateProfileCardContent(
                            name: $name,
                            age: $age,
                            email: $email,
                            showAgeError: $showAgeError,
                            textEditorText: $textEditorText,
                            textEditorDefault: textEditorDefault,
                            textFieldDefault: nameDefault,
                            currentEmail: currentEmail
                        )
                    }
                    .frame(
                        width: geometry.size.width * cardWidthMultiplier,
                        height: geometry.size.height * cardHeightMultiplier
                    )
                    .padding(.top, 20)

                    // Buttons
                    HStack {
                        // Cancel Button
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 45))
                                .foregroundColor(.secondaryButton.opacity(0.92))
                                .shadow(
                                    color: .spurlyPrimaryText.opacity(0.5),
                                    radius: 4,
                                    x: 2,
                                    y: 5
                                )
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Submit Button
                        Button(action: submit) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryButton))
                                    .scaleEffect(1.2)
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 45))
                                    .if(isFormValid) { view in
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
                                    .if(!isFormValid) { view in
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

                // Error Overlays
                if showAgeError {
                    ErrorOverlayView(
                        isPresented: $showAgeError,
                        errorTitle: "minimum age requirement",
                        errorMessage: "spurly is only for use by those 18 years and up",
                        onDismiss: {
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
                            showErrorOverlay = false
                        }
                    )
                }

                if showEmailError {
                    ErrorOverlayView(
                        isPresented: $showEmailError,
                        errorTitle: "email requirement",
                        errorMessage: "please enter a valid email address",
                        onDismiss: {
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
        .onAppear {
            loadUserData()
        }
        .onReceive(viewModel.$errorMessage) { error in
            if let error = error {
                self.errorMessageTitle = "Error"
                self.errorMessage = error
                self.showErrorOverlay = true
            }
        }
        .onReceive(viewModel.$updateSuccess) { success in
            if success {
                self.successMessage = "profile updated successfully"
                self.showSuccessOverlay = true

                // Dismiss after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Methods

    private func loadUserData() {
        // Load existing user data
        if let userName = authManager.userName, !userName.isEmpty {
            name = userName
        } else {
            name = nameDefault
        }

        if let userEmail = authManager.userEmail {
            email = userEmail
        }

        // Load profile data if available
        viewModel.loadUserProfile { profileData in
            if let profileData = profileData {
                if let profileAge = profileData.age {
                    self.age = profileAge
                }
                if let contextBlock = profileData.userContextBlock, !contextBlock.isEmpty {
                    self.textEditorText = contextBlock
                } else {
                    self.textEditorText = textEditorDefault
                }
            } else {
                self.textEditorText = textEditorDefault
            }
        }
    }

    private func submit() {
        hideKeyboard()


        // Validate age
        guard isAgeValidForSubmission else {
            showAgeError = true
            errorMessageTitle = "minimum age requirement"
            errorMessage = "you must be at least 18 to use spurly"
            viewModel.isError = true
            return
        }

        // Validate name
        guard isNameValid else {
            showNameError = true
            errorMessageTitle = "please enter a name"
            errorMessage = "name cannot be blank. please enter a name to use with spurly"
            viewModel.isError = true
            return
        }

        // Validate email
        guard isEmailValid else {
            showEmailError = true
            errorMessageTitle = "invalid email"
            errorMessage = "please enter a valid email address"
            viewModel.isError = true
            return
        }

        // Reset all error states
        showAgeError = false
        showNameError = false
        showEmailError = false
        showErrorOverlay = false
        viewModel.isError = false

        // Prepare data
        let finalName = name.isEmpty ? nameDefault : name
        let userContextBlock = textEditorText == textEditorDefault ? "" : textEditorText

        let payload = UpdateProfilePayload(
            name: finalName,
            age: age,
            email: email,
            userContextBlock: userContextBlock
        )

        // Submit through viewModel
        viewModel.updateProfile(data: payload)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// MARK: - Preview

struct UpdateProfileView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthManager()

        UpdateProfileView(authManager: authManager)
            .environmentObject(authManager)
    }
}
