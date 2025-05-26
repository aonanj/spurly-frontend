import SwiftUI
import UIKit

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var showAgeError = false
    @State private var isLoading = false
    @State private var age: Int? = nil
    @State private var showSuccessOverlay = false
    @State private var successMessage = ""
    @State private var errorMessageTitle = ""
    @State private var showErrorOverlay = false
    @State private var errorMessage = ""
    @State private var isSubmitting = false
    @State private var name: String = "what do you go by"
    @State private var textEditorText: String = "... spurly can keep things relevant to you. here you can add your interests, job, hometown, relationship type, and anything else that could help spurly help you find your own words quicker ..."

    let nameDefault = "what do you go by"
    let textEditorDefault = "... spurly can keep things relevant to you. here you can add your interests, job, hometown, relationship type, and anything else that could help spurly help you find your own words quicker ..."

    var isAgeValidForSubmission: Bool {
        guard let currentAge = age
        else { return false }
        return currentAge >= 18
    }

    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width
    let cardWidthMultiplier: CGFloat = 0.85
    let cardHeightMultiplier: CGFloat = 0.62

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

                    VStack(alignment: .center, spacing: 0) {
                        Image.bannerLogo
                            .frame(height: screenHeight * 0.1)

                        Text.bannerTag
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)
                    }
                    .frame(height: geometry.size.height * 0.14)
                    .padding(
                        .top,
                        geometry.safeAreaInsets.top > 30 ? 25 : geometry.safeAreaInsets.top)
                    .padding(.bottom, 20)


                    Spacer()

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
                        width: geometry
                            .size.width * cardWidthMultiplier, height: geometry.size.height * cardHeightMultiplier)
                    .padding(.top, 30)

                    HStack() {
                        Spacer()
                        Button(action: {
                            if !isAgeValidForSubmission {
                                showAgeError = true
                                self.errorMessageTitle = "minimum age requirement"
                                self.errorMessage = "you must be at least 18 to use spurly"
                                showErrorOverlay = true
                            }
                            else {
                                showAgeError = false
                                self.errorMessageTitle = ""
                                self.errorMessage = ""
                                showErrorOverlay = false
                                submit()
                            }
                        }) { Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 45)) // Adjust size as needed
                                .if(isAgeValidForSubmission) { view in
                                    view.foregroundStyle(
                                        LinearGradient(
                                            colors: [
                                                .highlight,
                                                .primaryButton,
                                                .highlight
                                            ],
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
                                        .foregroundColor(
                                            .spurlySecondaryText.opacity(0.2)
                                        )
                                        .shadow(
                                            color: .spurlyPrimaryText.opacity(0.44),
                                            radius: 4,
                                            x: 2,
                                            y: 5
                                        )

                                }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 5)

                    Spacer()

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

                if showSuccessOverlay {
                    Color.primaryText.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            showSuccessOverlay = false
                        }
                        .zIndex(3)
                    // Message Box
                    VStack {
                        Spacer()
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
                                        x: 0,
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
                }

                if showErrorOverlay {
                    // Dimmed background - Tappable to dismiss
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            showErrorOverlay = false // Dismiss on tap
                        }.zIndex(3)

                    // Error Message Box
                    VStack { // Use a new VStack for the error message
                        Spacer() // Push to center vertically
                        VStack(spacing: 12) { // Inner VStack for content spacing
                            Image(systemName: "exclamationmark.triangle.fill") // Error Icon
                                .font(.system(size: 30)) // Make icon larger
                                .foregroundColor(.red)

                            Text(errorMessageTitle) // Clear Title
                                .font(.headline)
                                .foregroundColor(.primaryText)

                            Divider()
                                .frame(maxWidth: .infinity)
                                .frame(height: 2)
                                .background(Color.accent1)
                                .padding(.horizontal, 15)
                                .opacity(0.4)
                                .shadow(color: Color.black.opacity(0.55), radius: 3, x: 2, y: 2)

                            Text(errorMessage) // The specific error message from state
                                .font(.footnote) // Use footnote size for potentially longer messages
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal) // Add padding if message is long

                            // Explicit Dismiss Button
                            Button("dismiss") {
                                showErrorOverlay = false
                                showAgeError = false
                            }
                            .font(.body)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.red.opacity(0.6)) // Match icon color
                            .foregroundColor(.white)
                            .clipShape(Capsule()) // Use capsule shape
                            .padding(.top) // Add space above button

                        }
                        .padding(EdgeInsets(top: 30, leading: 20, bottom: 20, trailing: 20)) // Adjust padding
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    Color.cardBg
                                ) // Can use same background as success
                                .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5)
                        )
                        .padding(.horizontal, 30) // Padding for the whole box horizontally
                        Spacer() // Push to center vertically
                    }
                    .onTapGesture {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showSuccessOverlay = false
                            showAgeError = false// Dismiss on tap
                        }
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.3))) // Fade transition
                    .zIndex(4)
                }
            } // End main ZStack
            //.ignoresSafeArea(.container, edges: .bottom)
        } // End Geometry Reader
    }

    private func sendOnboardingData(completion: @escaping (Result<OnboardingResponse, Error>) -> Void) {
        print("attempting to submit onboarding data...")
        guard isAgeValidForSubmission else {
            // Create a specific error for this case
            let ageError = NSError(domain: "ValidationDomain", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Age is required and must be 18 or older."])
            print("error: \(ageError.localizedDescription)")
            completion(.failure(ageError)) // Call completion with validation error
            return
        }

        let payload = OnboardingPayload(
            name: name,
            age: age,
            profile_context: textEditorText
        )

        guard let encodedPayload = try? JSONEncoder().encode(payload) else {
            let encodingError = NSError(domain: "EncodingDomain", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Failed to encode payload."])
            print("error: \(encodingError.localizedDescription)")
            completion(.failure(encodingError)) // Call completion with encoding error
            return
        }

        // Print payload for debugging
        if let jsonString = String(data: encodedPayload, encoding: .utf8) { print("Sending JSON payload: \(jsonString)") } else { print("Could not convert encoded payload data to UTF8 string for printing.") }

        // --- Replace with your actual backend URL ---
        guard let url = URL(string: "YOUR_BACKEND_ENDPOINT_HERE") else { // <-- IMPORTANT: Use your real URL
            let urlError = NSError(domain: "URLDomain", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Invalid URL."])
            print("error: \(urlError.localizedDescription)")
            completion(.failure(urlError)) // Call completion with URL error
            return
        }
        // --- ---

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = encodedPayload

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Ensure completion handler is called on the main thread for UI updates
            DispatchQueue.main.async {
                if let networkError = error {
                    print("Network Error: \(networkError.localizedDescription)")
                    completion(.failure(networkError)) // Call completion with network error
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    let responseError = NSError(domain: "HTTPDomain", code: 1004, userInfo: [NSLocalizedDescriptionKey: "Invalid HTTP response."])
                    print("error: \(responseError.localizedDescription)")
                    completion(.failure(responseError)) // Call completion with response error
                    return
                }

                print("Received HTTP Status: \(httpResponse.statusCode)")

                guard (200...299).contains(httpResponse.statusCode) else {
                    var errorUserInfo: [String: Any] = [NSLocalizedDescriptionKey: "Server returned status code \(httpResponse.statusCode)"]
                    if let responseData = data, let errorString = String(data: responseData, encoding: .utf8) {
                        print("Server Error Response: \(errorString)")
                        errorUserInfo[NSLocalizedFailureReasonErrorKey] = errorString // Optionally add server message
                    }
                    let serverError = NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: errorUserInfo)
                    completion(.failure(serverError)) // Call completion with server error
                    return
                }

                guard let responseData = data else {
                    let dataError = NSError(domain: "DataDomain", code: 1005, userInfo: [NSLocalizedDescriptionKey: "No data received."])
                    print("error: \(dataError.localizedDescription)")
                    completion(.failure(dataError)) // Call completion with data error
                    return
                }

                do {
                    let decodedResponse = try JSONDecoder().decode(OnboardingResponse.self, from: responseData)
                    print("Success! User ID: \(decodedResponse.user_id), Token: \(decodedResponse.token)")
                    do {
                        let decodedResponse = try JSONDecoder().decode(OnboardingResponse.self, from: responseData)
                        print("Success! User ID: \(decodedResponse.user_id), Token received.")
                        completion(.success(decodedResponse)) // Call completion with SUCCESS
                    } catch let decodingError {
                        print("error: Failed to decode response: \(decodingError)")
                        completion(.failure(decodingError)) // Call completion with decoding error
                    }
                    completion(.success(decodedResponse)) // Call completion with SUCCESS
                } catch let decodingError {
                    print("error: Failed to decode response: \(decodingError)")
                    completion(.failure(decodingError)) // Call completion with decoding error
                }
            }
        }.resume()
    }

    private func submit() {
        hideKeyboard()
        guard isAgeValidForSubmission else {
            print("Submit cancelled: age validation failed.")
            showAgeError = true
            return
        }
        showAgeError = false

        // Optional: Add a state variable @State private var isSubmitting = false
        // and set isSubmitting = true here to show a loading indicator

        print("Submitting onboarding data...")
        isSubmitting = true // Show loading indicator


        sendOnboardingData { [self] result in // Use [self] to capture self
            isSubmitting = false // Hide loading indicator

            switch result {
            case .success(let onboardingResponse):
                // --- SUCCESS CASE ---
                // Network call succeeded! Show message and schedule navigation.
                print("Onboarding data submission successful.")
                authManager.login(userId: onboardingResponse.user_id, token: onboardingResponse.token)

                let displayName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "User" : name
                    self.successMessage = "hi \(displayName)! your account with spurly has been successfully created."
                self.showSuccessOverlay = true // Show success message overlay NOW

            case .failure(let error):
                print("Onboarding data submission failed: \(error.localizedDescription)")
                self.errorMessageTitle = "Error"
                self.errorMessage = "Account creation failed. Please check connection and try again.\n(\(error.localizedDescription))"
                self.showErrorOverlay = true

            }
        }
    }

    private func hideKeyboard() { //
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView().environmentObject(AuthViewModel(authManager: AuthManager()))
    }
}


// You'll need a way to navigate to ContextInputView when the state changes.
// Your main view (often named ContentView or something similar) would look like this:

/*
 In your main app view (e.g., spurlyApp.swift or a ContentView):

 struct ContentView: View {
     @StateObject private var authViewModel = AuthViewModel(authManager: AuthManager())

     var body: some View {
         Group {
             switch authViewModel.userState {
             case .unauthenticated, .unknown:
                 LoginLandingView()
             case .authenticated:
                 OnboardingView() // Show this if user is logged in but not yet onboarded
             case .onboarded:
                 ContextInputView() // Navigate here after successful onboarding
             case .error(let message):
                 Text("Error: \(message)") // Or an error view
             }
         }
         .environmentObject(authViewModel)
     }
 }
*/
