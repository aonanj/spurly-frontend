//  AddConnectionView.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

struct AddConnectionView: View {
    // MARK: - Environment Objects
    @Environment(\.dismiss) var dismiss // To close the view
    @EnvironmentObject var connectionManager: ConnectionManager
    @EnvironmentObject var authManager: AuthManager

    // MARK: - View State
    @State private var currentCardIndex = 0
    let totalCards = 4 // Same number of cards as onboarding

    // MARK: - Connection Data State
    @State private var connectionName = ""
    @State private var connectionAge: Int? = nil
    @State private var connectionGender = ""
    @State private var connectionPronouns = ""
    @State private var connectionEthnicity = ""
    @State private var connectionShowAgeError = false

    @State private var connectionCurrentCity = ""
    @State private var connectionHometown = ""
    @State private var connectionSchool = ""
    @State private var connectionJob = ""

    @State private var connectionGreenlights: [String] = []
    @State private var connectionRedlights: [String] = []
    @State private var allTopics: [String] = presetTopics

    @State private var connectionDrinking = ""
    @State private var connectionDatingPlatform = ""
    @State private var connectionLookingFor = ""
    @State private var connectionKids = ""



    // Submission State
    @State private var connectionIsSaving = false // Used for ProgressView during save
    @State private var connectionSaveError: String? = nil // Holds the error message string
    @State private var connectionShowErrorOverlay = false // Controls visibility of the error overlay

    // MARK: - Computed Properties
    var progress: Double {
        guard totalCards > 0 else { return 0.0 }
        return Double(currentCardIndex + 1) / Double(totalCards)
    }

    // REVISED: Validation for proceeding to the next card
    var canProceedToNextCard: Bool {
        if currentCardIndex == 0 { // Basics Card
            // Age must be selected (not nil) AND be >= 18 to proceed from the first card
            return (connectionAge != nil && connectionAge ?? 0 >= 18)
        }
        return true // Allow proceeding from other cards freely
    }

    // REVISED: Validation for final save action
    var canSaveChanges: Bool {
        // Age must be selected (not nil) AND be >= 18 for saving, plus name must be present.
        let connectionAgeIsValid = (connectionAge != nil && connectionAge ?? 0 >= 18)
        return !connectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && connectionAgeIsValid
    }

    // Computed property to determine if the Next/Save button should *appear* disabled and act accordingly
    var isNextOrSaveActionBlocked: Bool {
        if currentCardIndex < totalCards - 1 { // If it's the "Next" button
            return !canProceedToNextCard // Blocked if we can't proceed
        } else { // If it's the "Save" button
            return !canSaveChanges // Blocked if we can't save
        }
    }

    // MARK: - Layout Constants (Mirrored from OnboardingView)
    let cardWidthMultiplier: CGFloat = 0.8
    let cardHeightMultiplier: CGFloat = 0.52
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background (Consistent with OnboardingView)
                Color.tappablePrimaryBg
                    .ignoresSafeArea() // Ensure it covers the whole screen

                Image.tappableBgIcon
                    .frame(width: screenWidth * 1.5, height: screenHeight * 1.5)
                    .position(x: screenWidth / 2, y: screenHeight * 0.52) // Mirrored position
                    .allowsHitTesting(false)

                // Main Content VStack
                VStack(spacing: 0) {
                    // Header (Mirrored from OnboardingView - Logo and Tagline)
                    VStack(alignment: .center, spacing: 0) {
                        // Optional: Menu button if still needed, but OnboardingView doesn't have it here.
                        // If keeping, consider placement that doesn't interfere with the mirrored layout.
                        // For strict mirroring, this HStack would be removed or rethought.
                        HStack {
                            Button(action: {
                                // Assuming sideMenuManager.openSideMenu() is the intended action
                                // For now, using a dummy to avoid needing SideMenuManager in this direct context
                                // if it's not available or not the focus of this refactor.
                                print("Menu button tapped (AddConnectionView)")
                            }) {
                                Image.menuIcon // Ensure this is defined as in other views
                                    .frame(width: 44, height: 44)
                            }
                            Spacer()

                            Button(action: {
                                clearAllConnectionDataAndDismiss()
                            }) {
                                Image.cancelAddConnectionIcon
                                    .frame(width: 35, height: 35) // Adjust size as
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, geometry.safeAreaInsets.top > 0 ? 50 : 55) // Adjust top padding

                        Image.bannerLogo // Centered logo
                            .frame(height: screenHeight * 0.1)

                        Text.bannerTag // Centered tagline
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)
                    }
                    .frame(height: geometry.size.height * 0.14) // Matches OnboardingView
                     // Adjusted top padding to be similar to OnboardingView, considering safe area
                    .padding(.top, geometry.safeAreaInsets.top > 0 ? geometry.safeAreaInsets.top / 4 : 2)


                    Spacer(minLength: 100) // Matches OnboardingView

                    // Progress Indicator (Mirrored from OnboardingView)
                    VStack(alignment: .center, spacing: 5) { // Changed spacing to 5 to match Onboarding
                        ZStack {
                            Capsule()
                                .fill(Color.tertiaryBg.opacity(0.6)) // Matches Onboarding
                                .frame(width: geometry.size.width * cardWidthMultiplier * 0.8, height: 6)
                                .shadow(color: .black.opacity(0.5), radius: 3, x: 3, y: 3) // Added shadow

                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .secondaryText.opacity(0.8))) // Matches Onboarding
                                .frame(width: geometry.size.width * cardWidthMultiplier * 0.8)
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                                .opacity(0.8) // Added opacity to match
                        }
                        // .padding(.bottom, 5) // Matches OnboardingView
                        // .padding(.horizontal) // Matches OnboardingView

                        // Text label for progress (X/Y) and skip button
                        HStack(spacing: 4) {
                             Text("(\(currentCardIndex + 1)/\(totalCards))") // Matches OnboardingView format
                                 .font(Font.custom("SF Pro Text", size: 12).weight(.regular))
                                 .foregroundColor(.secondaryText)
                                 .opacity(0.8)
                                 .shadow(color: .black.opacity(0.4), radius: 3, x: 3, y: 3) // Added shadow

                             Spacer()

                             // "Skip ahead" button - optional for AddConnectionView,
                             // but included for closer mirroring.
                             // You can remove this if "skip ahead" is not applicable here.
                            Button(action: {
                                // Logic for skip ahead:
                                // Should probably check `canProceedToNextCard` for the current card
                                // or a more specific skip validation if needed.
                                if currentCardIndex < totalCards - 1 {
                                    if canProceedToNextCard {
                                        connectionShowAgeError = false
                                        withAnimation { currentCardIndex += 1 }
                                    } else if currentCardIndex == 0 { // Special case for age error on first card
                                        connectionShowAgeError = true
                                    }
                                }
                                // If on the last card, "skip ahead" might not make sense,
                                // or it could mean "skip filling this card and try to save"
                                // which would need to align with `handleNextOrSave` logic.
                                // For now, it primarily advances if not on the last card.
                            }) {
                                 HStack(spacing: 4) {
                                     Text("skip to next") // Text can be "skip ahead" or "skip to next"
                                     Image(systemName: "arrow.right")
                                 }
                             }
                             .font(Font.custom("SF Pro Text", size: 12).weight(.regular))
                             .foregroundColor(.secondaryText)
                             .opacity(currentCardIndex < totalCards - 1 ? 0.8 : 0.0) // Hide on last card
                             .shadow(color: .black.opacity(0.4), radius: 3, x: 3, y: 3)
                         }
                         .frame(width: geometry.size.width * cardWidthMultiplier * 0.8)
                    }
                    // .padding(.bottom, 20) // Original padding, Onboarding has this Spacer(minLength: 20) after progress
                    Spacer(minLength: 20) // Matches OnboardingView

                    // Card Content Area
                    Group {
                        switch currentCardIndex {
                            case 0:
                                AddConnectionCardView(
                                    title: "connection basics",
                                    icon: Image(.addConnectionBasicsIcon)
                                ) {
                                    AddConnectionBasicsCardContent(
                                        connectionName: $connectionName,
                                        connectionAge: $connectionAge,
                                        connectionGender: $connectionGender,
                                        connectionPronouns: $connectionPronouns,
                                        connectionEthnicity: $connectionEthnicity,
                                        connectionShowAgeError: $connectionShowAgeError
                                    )
                                }
                            case 1:
                                AddConnectionCardView(title: "connection background", icon: Image(.addConnectionBackgroundIcon)) {
                                    AddConnectionBackgroundCardContent(
                                        connectionCurrentCity: $connectionCurrentCity,
                                        connectionJob: $connectionJob,
                                        connectionSchool: $connectionSchool,
                                        connectionHometown: $connectionHometown
                                    )
                                }
                            case 2:
                                AddConnectionCardView(
                                    title: "about connection",
                                    icon: Image(.addConnectionAboutIcon)
                                ) {
                                    AddConnectionAboutCardContent(
                                        connectionGreenlights: $connectionGreenlights,
                                        connectionRedlights: $connectionRedlights,
                                        allTopics: $allTopics
                                    )
                                }
                            case 3:
                                AddConnectionCardView(title: "connection lifestyle", icon: Image(.addConnectionLifestyleIcon)) {
                                    AddConnectionLifestyleCardContent(
                                        connectionDrinking: $connectionDrinking,
                                        connectionDatingPlatform: $connectionDatingPlatform, // Consider if needed
                                        connectionLookingFor: $connectionLookingFor,       // Consider if needed
                                        connectionKids: $connectionKids
                                    )
                                }
                            default:
                                EmptyView()
                        }
                    }
                    .frame(width: geometry.size.width * cardWidthMultiplier, height: geometry.size.height * cardHeightMultiplier)

                    Spacer(minLength: 1) // Matches OnboardingView

                    // Navigation Buttons (Mirrored style from OnboardingView)
                    HStack {
                        // Back Button
                        if currentCardIndex > 0 {
                            Button {
                                withAnimation { currentCardIndex -= 1 }
                            } label: {
                                Image(systemName: "arrow.left") // Consistent icon
                                    .padding()
                                    .background(Circle().fill(Color.secondaryButton.opacity(0.6)).shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4)) // Mirrored style
                                    .foregroundColor(.primaryBg)
                            }
                        } else {
                            // Hidden button to maintain layout, matches OnboardingView
                            Button {} label: { Image(systemName: "arrow.left").padding().background(Circle().fill(Color.clear)) }.hidden()
                        }

                        Spacer()

                        // Next / Save Button
                        Button {
                            hideKeyboard()

                            if isNextOrSaveActionBlocked {
                                // --- ACTION IS BLOCKED BY VALIDATION ---
                                if currentCardIndex == 0 {
                                    // If on Basics Card and "Next" action is blocked, it's due to age being nil
                                    // (since the picker prevents selecting < 18, and canProceedToNextCard requires non-nil valid age).
                                    connectionShowAgeError = true // This will make BasicsCardContent show the error text
                                } else if currentCardIndex == totalCards - 1 {
                                    // If on the last card and "Save" action is blocked:
                                    // Determine specific save error for the overlay.
                                    if connectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        connectionSaveError = "Connection name cannot be empty."
                                        // If age is ALSO an issue (e.g., nil), ensure BasicsCardContent can show its error.
                                        if !(connectionAge != nil && connectionAge ?? 0 >= 18) { // Checks if age is nil or <18
                                            connectionShowAgeError = true
                                        }
                                    } else if !(connectionAge != nil && connectionAge ?? 0 >= 18) { // Name is fine, but age is nil (or <18 if somehow set).
                                        connectionShowAgeError = true // Essential for BasicsCardContent's inline error
                                        connectionSaveError = "Age must be selected and be 18 or older."
                                        // Optionally, navigate back to the card with the age error:
                                        // if currentCardIndex != 0 { // Only if not already on the basics card
                                        //     withAnimation { currentCardIndex = 0 }
                                        // }
                                    } else {
                                        connectionSaveError = "Please ensure all required fields are valid and try again."
                                    }
                                    connectionShowErrorOverlay = true // Show the general error overlay
                                }
                                // Add more conditions here if other cards have blocking validation
                            } else {
                                // --- ACTION IS PERMITTED ---
                                connectionShowAgeError = false // Clear age field error as we are proceeding/saving
                                connectionSaveError = nil      // Clear general save error message
                                connectionShowErrorOverlay = false // Hide general error overlay

                                if currentCardIndex < totalCards - 1 { // Proceed to next card
                                    withAnimation { currentCardIndex += 1 }
                                } else { // All checks passed for saving
                                    saveConnection()
                                }
                            }
                        } label: {
                            Image(systemName: currentCardIndex < totalCards - 1 ? "arrow.right" : "checkmark")
                                .padding()
                                .background(
                                    Circle()
                                        // The visual appearance of being "disabled" is controlled here:
                                        .fill(
                                            isNextOrSaveActionBlocked ? // Use the computed property
                                            Color.secondaryText.opacity(0.2) : Color.secondaryButton.opacity(0.7)
                                        )
                                        .shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4)
                                )
                                .foregroundColor(Color.primaryBg)
                        }
                    }
                    .padding(.horizontal, geometry.size.width * ((1.0 - cardWidthMultiplier) / 2.0)) // Mirrored padding

                    Spacer(minLength: 35) // Matches OnboardingView

                    // Footer (Mirrored from OnboardingView)
                    VStack(spacing: 2) {
                        Text("we care about protecting your data")
                            .font(.footnote)
                            .foregroundColor(.secondaryText)
                            .opacity(0.6)
                        Link(destination: URL(string: "https://example.com/privacy")!) { // Use a relevant URL
                            Text("learn more here")
                                .underline()
                                .font(.footnote)
                                .foregroundStyle(Color.secondaryText)
                                .opacity(0.6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, (geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 0) + 10) // Mirrored padding


                } // End Main VStack
                .disabled(connectionIsSaving) // Disable interaction while saving (same as before)

                // Saving Progress Overlay (same as before, generally fine)
                if connectionIsSaving {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("saving...") // Changed text slightly
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                // Error Overlay (Mirrored style from OnboardingView's error overlay)
                if connectionShowErrorOverlay {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .onTapGesture { connectionShowErrorOverlay = false }

                    VStack {
                        Spacer()
                        VStack(spacing: 15) {
                             Image(systemName: "exclamationmark.triangle.fill")
                                 .font(.system(size: 40)) // Matched size
                                 .foregroundColor(.red)
                             Text("Error Saving Connection") // Title
                                 .font(.headline).foregroundColor(.primaryText)
                             Text(connectionSaveError ?? "An unknown error occurred. Please try again.") // Message
                                 .font(.footnote).foregroundColor(.secondaryText)
                                 .multilineTextAlignment(.center).padding(.horizontal)
                             Button("Dismiss") {
                                 connectionShowErrorOverlay = false
                             }
                                 .padding(.vertical, 10)
                                 .padding(.horizontal, 20)
                                 .background(Color.red.opacity(0.8)) // Matched style
                                 .foregroundColor(.white)
                                 .clipShape(Capsule())
                                 .padding(.top)
                        }
                        .padding(EdgeInsets(top: 30, leading: 20, bottom: 20, trailing: 20))
                        .background(RoundedRectangle(cornerRadius: 15).fill(Color.cardBg))
                        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 5) // Matched shadow
                        .padding(.horizontal, 40)
                        Spacer()
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
                }
            } // End ZStack
            .ignoresSafeArea(.keyboard)
            .navigationBarHidden(true)
            .onTapGesture { hideKeyboard() }
        } // End GeometryReader
    }

    // MARK: - Actions

    func attemptProceedOrSave() {
        hideKeyboard()

        if currentCardIndex < totalCards - 1 { // --- Trying to go "Next" ---
            if canProceedToNextCard {
                connectionShowAgeError = false // Clear error if proceeding
                withAnimation { currentCardIndex += 1 }
            } else {
                // Cannot proceed. If on card 0, it's because age is nil (picker prevents <18).
                if currentCardIndex == 0 {
                    connectionShowAgeError = true // This will trigger the "you must be at least 18" if age is nil
                                        // because BasicsCardContent checks: (showAgeError && !(age ?? 0 >= 18))
                                        // If age is nil, !(nil ?? 0 >= 18) becomes !(false) which is true.
                }
                // Add other handling here if there are other reasons to not proceed on other cards.
            }
        } else { // --- Trying to "Save" (on the last card) ---
            if canSaveChanges {
                connectionShowAgeError = false // Clear age error if saving
                connectionSaveError = nil      // Clear general save error
                connectionShowErrorOverlay = false // Hide overlay
                saveConnection()
            } else {
                // Cannot save. Determine reason and set appropriate error messages.
                if connectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    connectionSaveError = "Connection name cannot be empty."
                    // If age is ALSO an issue (e.g., nil), ensure BasicsCardContent can show it.
                    if !(connectionAge != nil && connectionAge ?? 0 >= 18) { // Checks if age is nil or < 18
                        connectionShowAgeError = true
                    }
                } else if !(connectionAge != nil && connectionAge ?? 0 >= 18) { // Name is fine, but age is nil or < 18.
                    connectionShowAgeError = true // This is key for BasicsCardContent to show its error
                    connectionSaveError = "Age must be selected and be 18 or older." // Overlay message
                    // Optionally, navigate back to the card with the age error:
                    // if currentCardIndex != 0 { // Only if not already on the basics card
                    //     withAnimation { currentCardIndex = 0 }
                    // }
                } else {
                    // Some other validation for canSaveChanges failed.
                    connectionSaveError = "Please ensure all required fields are valid and try again."
                }
                connectionShowErrorOverlay = true // Show the general error overlay
            }
        }
    }

    func clearAllConnectionDataAndDismiss() {
        // Reset all @State variables to their initial values
        connectionName = ""
        connectionAge = nil
        connectionGender = ""
        connectionPronouns = ""
        connectionSchool = ""
        connectionJob = ""
        connectionDrinking = ""
        connectionEthnicity = ""
        connectionCurrentCity = ""
        connectionHometown = ""
        connectionGreenlights = []
        connectionRedlights = []
        connectionDatingPlatform = ""
        connectionLookingFor = ""
        connectionKids = ""

        currentCardIndex = 0 // Reset card index
        connectionShowAgeError = false
        connectionSaveError = nil
        connectionShowErrorOverlay = false
        connectionIsSaving = false // Just in case

        dismiss() // Dismiss the view
    }


    func saveConnection() {
        print("Attempting to save connection...")
        connectionIsSaving = true
        connectionSaveError = nil // Clear previous errors
        connectionShowErrorOverlay = false // Hide error overlay

        resolveTopicConflicts()

        let nameForConnection = self.connectionName

        let connectionPayload = AddConnectionPayload(
            connectionName: nameForConnection,
            connectionAge: connectionAge,
            connectionGender: connectionGender,
            connectionPronouns: connectionPronouns,
            connectionSchool: connectionSchool,
            connectionJob: connectionJob,
            connectionDrinking: connectionDrinking,
            connectionEthnicity: connectionEthnicity,
            connectionCurrentCity: connectionCurrentCity,
            connectionHometown: connectionHometown,
            connectionGreenlights: connectionGreenlights,
            connectionRedlights: connectionRedlights,
            connectionDatingPlatform: connectionDatingPlatform,
            connectionLookingFor: connectionLookingFor,
            connectionKids: connectionKids)

        guard let encodedPayload = try? JSONEncoder().encode(connectionPayload) else {
            handleSaveResult(.failure(NSError(domain: "Encoding", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare connection data."])))
            return
        }

        if let jsonString = String(data: encodedPayload, encoding: .utf8) {
            print("Sending Connection JSON payload: \(jsonString)")
        }

        // --- Replace with your actual backend URL for saving connections ---
        guard let url = URL(string: "YOUR_SAVE_CONNECTION_ENDPOINT_HERE") else { // <<-- IMPORTANT
            handleSaveResult(.failure(NSError(domain: "URL", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid API endpoint for saving connection."])))
            return
        }
        // --- ---

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = authManager.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = encodedPayload

        URLSession.shared.dataTask(with: request) {
 data,
 response,
 error in
            DispatchQueue.main.async {
                if let networkError = error {
                    self.handleSaveResult(.failure(networkError))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.handleSaveResult(.failure(NSError(domain: "Network", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server."])))
                    return
                }

                print("Save Connection Received HTTP Status: \(httpResponse.statusCode)")

                guard (200...299).contains(httpResponse.statusCode) else {
                    var serverMsg = "Server error (\(httpResponse.statusCode))."
                    if let responseData = data,
 let errorString = String(data: responseData, encoding: .utf8),
 !errorString.isEmpty {
                        serverMsg += " Details: \(errorString)"
                    }
                    self.handleSaveResult(.failure(NSError(domain: "Server", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: serverMsg])))
                    return
                }

                // --- SUCCESS ---
                // Optionally decode response if needed
                if let responseData = data {
                    struct SaveConnectionResponse: Decodable {
                        let connection_id: String?
                    } // Make id optional
                    do {
                        let decodedResponse = try JSONDecoder().decode(
                            SaveConnectionResponse.self,
                            from: responseData
                        )
                        if let newConnectionId = decodedResponse.connection_id {
                            self.handleSaveResult(
                                .success((
                                    id: newConnectionId,
                                    name: nameForConnection)
                                )
                            )
                            print("Connection saved successfully. Received Connection ID: \(decodedResponse.connection_id ?? "N/A")")
                        } else {
                            print("Connection saved successfully (no data in response).")
                            self.handleSaveResult(.success(
                                (id: nil, name: nameForConnection)
                                )
                            )
                        }

                    } catch {
                         print("Warning: Could not decode save connection response: \(error.localizedDescription)")
                         // Proceed with success even if decoding response fails, as 2xx means server accepted it
                    }
                } else {
                    print("Connection saved successfully (no data in response).")
                }
                self.handleSaveResult(.success(
                    (id: nil, name: nameForConnection))
                ) // Pass a void success
            }
        }.resume()
    }

    // Unified way to handle save results and update UI
    func handleSaveResult(_ result: Result<(id: String?, name: String), Error>) {
        connectionIsSaving = false
        switch result {
        case .success(let connectionDetails):
            print("Connection saved successfully! Dismissing view.")
                if let id = connectionDetails.id, !connectionDetails.name.isEmpty {
                    connectionManager
                        .setActiveConnection(
                            connectionId: id,
                            connectionName: connectionDetails.name
                        )
                } else {
                    print("Connection saved, but no connection ID provided")
                }
            // connectionManager.connectionAddedSuccessfully() // If you have such a method
            dismiss() // Dismiss the view on successful save
            // No success overlay needed as the view dismisses. If one were desired, it would be set here.
        case .failure(let error):
            print("Save Error: \(error.localizedDescription)")
                connectionSaveError = error.localizedDescription
            connectionShowErrorOverlay = true // Show the mirrored error overlay
        }
    }

    private func resolveTopicConflicts() {
        let greenSet = Set(connectionGreenlights)
        let redSet = Set(connectionRedlights)
        let conflictingTopics = greenSet.intersection(redSet)
        if !conflictingTopics.isEmpty {
            print("Resolving topic conflicts for: \(conflictingTopics)")
            connectionGreenlights.removeAll { conflictingTopics.contains($0) }
            connectionRedlights.removeAll { conflictingTopics.contains($0) }
        }
    }
}

// NavigationButtonStyle from AddConnectionView.swift (ensure it's defined or accessible)
// If it's identical to OnboardingView's implied style, we might not need a separate one,
// but if it was defined in AddConnectionView, make sure it's either moved to a shared location
// or its logic is incorporated directly.
// For this refactor, I've directly applied styles similar to OnboardingView's buttons.
// If `NavigationButtonStyle` was a distinct, desired style, you'd ensure it's used consistently.

// MARK: - Preview
#if DEBUG
struct AddConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        AddConnectionView()
            .environmentObject(ConnectionManager())
            .environmentObject(AuthManager())
    }
}
#endif
