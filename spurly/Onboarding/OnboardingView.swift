






import SwiftUI
import UIKit

struct OnboardingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var currentCardIndex = 0; let totalCards = 4
    @State private var name = ""
    @State private var age: Int? = nil
    @State private var gender = ""
    @State private var pronouns = ""
    @State private var ethnicity = ""
    @State private var currentCity = ""
    @State private var hometown = ""
    @State private var school = ""
    @State private var job = ""
    @State private var drinking = ""
    @State private var datingPlatform = ""
    @State private var lookingFor = ""
    @State private var kids = ""
    @State private var greenlights: [String] = []
    @State private var redlights: [String] = []
    @State private var allTopics: [String] = presetTopics
    @State private var showAgeError = false
    @State private var showSuccessOverlay = false
    @State private var successMessage = ""
    @State private var showErrorOverlay = false
    @State private var errorMessage = ""
    @State private var isSubmitting = false

    var progress: Double { guard totalCards > 0 else { return 0.0 }; return Double(currentCardIndex + 1) / Double(totalCards) }
    var isAgeValidForSubmission: Bool { guard let currentAge = age else { return false }; return currentAge >= 18 }
    let cardWidthMultiplier: CGFloat = 0.8; let cardHeightMultiplier: CGFloat = 0.52
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width


    var body: some View {

        GeometryReader { geometry in
            ZStack {
                Color.tappablePrimaryBg

                Image.tappableBgIcon
                    .frame(width: screenWidth * 1.5, height: screenHeight * 1.5)
                    .position(x: screenWidth / 2, y: screenHeight * 0.59)
                VStack(spacing: 0) {
                    VStack(alignment: .center, spacing: 0) {
                        Image.bannerLogo
                            .frame(height: screenHeight * 0.1)

                        Text.bannerTag
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)
                    }
                    .frame(height: geometry.size.height * 0.14)
                    .padding(.top, geometry.safeAreaInsets.top + 15)

                    Spacer(minLength: 100)
                    VStack(alignment: .center, spacing: 0) {
                        ZStack {
                            Capsule()
                                .fill(Color.tertiaryBg)
                                .frame(width: geometry.size.width * cardWidthMultiplier * 0.8, height: 6)
                                .opacity(0.6)
                                .shadow(color: .black.opacity(0.5), radius: 3, x: 3, y: 3)
                            ProgressView(value: progress)
                                .progressViewStyle(
                                    LinearProgressViewStyle(
                                        tint: .secondaryText
                                    )
                                )
                                .frame(width: geometry.size.width * cardWidthMultiplier * 0.8)
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                                .opacity(0.8)
                        }
                        .padding(.bottom, 5)
                        .padding(.horizontal)

                        HStack(spacing: 4) {
                            Text("(\(currentCardIndex + 1)/4)")
                                .font(Font.custom("SF Pro Text", size: 12).weight(.regular))
                                .foregroundColor(.secondaryText)
                                .opacity(0.8)
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 3, y: 3)
                            Spacer()
                            Button(action: {
                                if isAgeValidForSubmission {
                                    currentCardIndex += 1
                                } else {
                                    showAgeError = true
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("skip ahead")
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .font(Font.custom("SF Pro Text", size: 12).weight(.regular))
                            .foregroundColor(.secondaryText)
                            .opacity(0.8)
                            .shadow(color: .black.opacity(0.4), radius: 3, x: 3, y: 3)
                        }
                        .frame(width: geometry.size.width * cardWidthMultiplier * 0.8)

                    }
                    Spacer(minLength: 20)
                    Group {
                        switch currentCardIndex {
                            case 0:
                                OnboardingCardView(title: "basics", icon: Image(systemName: "person.crop.circle.fill")) {
                                    BasicsCardContent(name: $name, age: $age, gender: $gender, pronouns: $pronouns, ethnicity: $ethnicity, showAgeError: $showAgeError)
                                }
                            case 1:
                                OnboardingCardView(title: "background", icon: Image(systemName: "globe.americas.fill")) {
                                    BackgroundCardContent(currentCity: $currentCity, job: $job, school: $school, hometown: $hometown)
                                }
                            case 2:
                                OnboardingCardView(title: "about me", icon: Image(systemName: "person.text.rectangle.fill")) {
                                    AboutMeCardContent(greenlights: $greenlights, redlights: $redlights, allTopics: $allTopics)
                                }
                            case 3:
                                OnboardingCardView(title: "lifestyle", icon: Image(systemName: "heart.text.clipboard.fill")) {
                                    LifestyleCardContent(drinking: $drinking, datingPlatform: $datingPlatform, lookingFor: $lookingFor, kids: $kids)
                                }
                            default: EmptyView()
                        }
                    }
                    .frame(width: geometry.size.width * cardWidthMultiplier, height: geometry.size.height * cardHeightMultiplier)
                    Spacer(minLength: 1)
                    HStack {
                        if currentCardIndex > 0 {
                            Button {
                                withAnimation { currentCardIndex -= 1 }
                            } label: {
                                Image(systemName: "arrow.left")
                                    .padding()
                                    .background(Circle().fill(Color.secondaryButton.opacity(0.6)).shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4))
                                    .foregroundColor(.primaryBg)
                            }
                        } else {
                            Button {} label: {
                                Image(systemName: "arrow.left")
                                    .padding()
                                    .background(Circle().fill(Color.clear))
                            }.hidden()
                        }
                        Spacer()
                        let isNextButtonDisabled: Bool = {
                            if currentCardIndex == 0 {
                                return !(age ?? 0 >= 18)
                            } else if currentCardIndex == totalCards - 1 {
                                return !isAgeValidForSubmission
                            } else {
                                return false
                            }
                        }()
                        Button {
                            if isNextButtonDisabled {
                                // Show error if age is invalid
                                showAgeError = true
                            } else {
                                // Clear error and proceed
                                showAgeError = false
                                if currentCardIndex < totalCards - 1 {
                                    withAnimation { currentCardIndex += 1 }
                                } else {
                                    submit()
                                }
                            }
                        } label: {
                            Image(systemName: currentCardIndex < totalCards - 1 ? "arrow.right" : "checkmark")
                                .padding()
                                .background(
                                    Circle()
                                        .fill(
                                            isNextButtonDisabled ? Color.secondaryText
                                                .opacity(
                                                    0.2
                                                ) : Color.secondaryButton
                                                .opacity(0.7)
                                        ).shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4)
                                )
                                .foregroundColor(Color.primaryBg)
                        }
                    }
                    .padding(.horizontal, geometry.size.width * (1.0 - cardWidthMultiplier) / 2.0)

                    Spacer(minLength: 5)
                    VStack(spacing: 2) {
                        Text("we care about protecting your data")
                            .font(.footnote)
                            .foregroundColor(.secondaryText)
                            .opacity(0.6)
                        Link(destination: URL(string: "https://example.com")!) {
                            Text("learn more here")
                                .underline()
                                .font(.footnote)
                                .foregroundStyle(Color.secondaryText)
                                .opacity(0.6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 10)
                }
                .navigationBarHidden(true)

                if showSuccessOverlay {
                    // Dimmed background
                    Color.primaryText.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            showSuccessOverlay = false
                        }

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
                }

                if showErrorOverlay {
                    // Dimmed background - Tappable to dismiss
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture {
                            showErrorOverlay = false // Dismiss on tap
                        }

                    // Error Message Box
                    VStack { // Use a new VStack for the error message
                        Spacer() // Push to center vertically
                        VStack(spacing: 15) { // Inner VStack for content spacing
                            Image(systemName: "exclamationmark.triangle.fill") // Error Icon
                                .font(.system(size: 40)) // Make icon larger
                                .foregroundColor(.red)

                            Text("Error Creating Account") // Clear Title
                                .font(.headline)
                                .foregroundColor(.primaryText)

                            Text(errorMessage) // The specific error message from state
                                .font(.footnote) // Use footnote size for potentially longer messages
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal) // Add padding if message is long

                            // Explicit Dismiss Button
                            Button("Dismiss") {
                                showErrorOverlay = false
                            }
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(Color.red.opacity(0.8)) // Match icon color
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
                        .padding(.horizontal, 40) // Padding for the whole box horizontally
                        Spacer() // Push to center vertically
                    }
                    .onTapGesture {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showSuccessOverlay = false // Dismiss on tap
                        }
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.3))) // Fade transition
                }
            }
            .ignoresSafeArea(.container, edges: .all)
        }
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

        let payload = OnboardingPayload(name: name, age: age, gender: gender, pronouns: pronouns, ethnicity: ethnicity, currentCity: currentCity, hometown: hometown, school: school, job: job, drinking: drinking, datingPlatform: datingPlatform, lookingFor: lookingFor, kids: kids, greenlights: greenlights, redlights: redlights)

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
            if currentCardIndex == 0 { showAgeError = true }
            return
        }
        showAgeError = false
        resolveTopicConflicts()

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
                self.successMessage = "Welcome \(displayName)! Your Spurly account was successfully created."
                self.showSuccessOverlay = true // Show success message overlay NOW

            case .failure(let error):
                print("Onboarding data submission failed: \(error.localizedDescription)")
                self.errorMessage = "Account creation failed. Please check connection and try again.\n(\(error.localizedDescription))"
                self.showErrorOverlay = true

            }
        }
    }

    private func resolveTopicConflicts() {
        let greenSet = Set(greenlights); let redSet = Set(redlights)
        let conflictingTopics = greenSet.intersection(redSet)
        if !conflictingTopics.isEmpty {
            print("conflict detected for topics: \(conflictingTopics). Removing from both lists.")
            greenlights.removeAll { conflictingTopics.contains($0) }
            redlights.removeAll { conflictingTopics.contains($0) }
        }
    }
}


// MARK: - Preview Provider Update
#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        // Inject a dummy AuthManager for the preview
        OnboardingView()
            .environmentObject(AuthManager()) // Add this line
    }
}
#endif

