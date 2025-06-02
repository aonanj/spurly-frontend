//
//
// File name: AddConnectionView.swift
//
// Product / Project: spurly / spurly
//
// Organization: phaeton order llc
// Bundle ID: com.phaeton-order.spurly
//
//

import SwiftUI
import UIKit

struct AddConnectionView: View {
    // MARK: - Environment Objects
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var connectionManager: ConnectionManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var sideMenuManager: SideMenuManager

    @State var connectionOcrImages: [UIImage]? = []
    @State var connectionProfileImages: [UIImage]? = []
    @State var connectionFacePhotoURL: String? = nil // New state for face photo URL

    // MARK: - View State
    @State private var currentCardIndex = 0
    let totalCards = 2

    // MARK: - Connection Data State
    @State private var connectionName = "their name"
    @State private var connectionAge: Int? = nil
    @State private var connectionContextBlock: String = "... spurly can keep things relevant to your connection. here you can add your connection's interests, job, hometown, relationship type, and anything else that could help spurly help you find your own words quicker ..."

    let nameDefault = "their name"
    let textEditorDefault = "... spurly can keep things relevant to your connection. here you can add your connection's interests, job, hometown, relationship type, and anything else that could help spurly help you find your own words quicker ..."

    // Submission State
    @State private var connectionIsSaving = false
    @State private var connectionSaveError: String? = nil
    @State private var connectionShowErrorOverlay = false
    @State private var connectionShowAgeError = false
    @State private var errorMessageTitle = ""

    // MARK: - Computed Properties
    var progress: Double {
        guard totalCards > 0 else { return 0.0 }
        return Double(currentCardIndex + 1) / Double(totalCards)
    }

    var isAgeValidForSubmission: Bool {
        guard let currentAge = connectionAge else { return false }
        return currentAge >= 18
    }

    var canProceedToNextCard: Bool {
        if currentCardIndex == 0 {
            return canSaveChanges
        }
        return true
    }

    var canSaveChanges: Bool {
        let nameIsValid = !connectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                         connectionName != nameDefault
        return nameIsValid && isAgeValidForSubmission
    }

    var isNextOrSaveActionBlocked: Bool {
        if currentCardIndex < totalCards - 1 {
            return !canProceedToNextCard
        } else {
            return !canSaveChanges
        }
    }

    // MARK: - Layout Constants
    let cardWidthMultiplier: CGFloat = 0.85
    let cardHeightMultiplier: CGFloat = 0.6
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width

    private var menuWidthValue: CGFloat {
        UIScreen.main.bounds.width * 0.82
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Color.tappablePrimaryBg
                    .onTapGesture {
                        hideKeyboard()
                    }
                    .zIndex(0)

                Image.tappableBgIcon
                    .frame(width: screenWidth * 1.8, height: screenHeight * 1.8)
                    .position(x: screenWidth / 2, y: screenHeight * 0.52)
                    .zIndex(1)

                // Main Content VStack
                VStack(spacing: 0) {
                    // Header with buttons
                    headerView

                    // Logo and tagline
                    VStack(spacing: 5) {
                        Image.bannerLogo
                            .padding(.horizontal)
                            .frame(height: screenHeight * 0.1)

                        Text.bannerTag
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 15)

                    // Progress Indicator
                    VStack(alignment: .center, spacing: 5) {
                        ZStack {
                            Capsule()
                                .fill(Color.tertiaryBg.opacity(0.6))
                                .frame(width: geometry.size.width * cardWidthMultiplier * 0.8, height: 6)
                                .shadow(color: .black.opacity(0.5), radius: 3, x: 3, y: 3)

                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle(tint: .secondaryText.opacity(0.8)))
                                .frame(width: geometry.size.width * cardWidthMultiplier * 0.8)
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                                .opacity(0.8)
                        }

                        HStack(spacing: 4) {
                            Text("(\(currentCardIndex + 1)/\(totalCards))")
                                .font(Font.custom("SF Pro Text", size: 12).weight(.regular))
                                .foregroundColor(.secondaryText)
                                .opacity(0.8)
                                .shadow(color: .black.opacity(0.4), radius: 3, x: 3, y: 3)

                            Spacer()

                            Button(action: {
                                if currentCardIndex < totalCards - 1 {
                                    if canProceedToNextCard {
                                        connectionShowAgeError = false
                                        withAnimation { currentCardIndex += 1 }
                                    } else if currentCardIndex == 0 {
                                        errorMessageTitle = "minimum age requirement"
                                        connectionSaveError = "connection must be at least 18 years old"
                                        connectionShowErrorOverlay = true
                                    }
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text("skip to next")
                                    Image(systemName: "arrow.right")
                                }
                            }
                            .font(Font.custom("SF Pro Text", size: 12).weight(.regular))
                            .foregroundColor(.secondaryText)
                            .opacity(currentCardIndex < totalCards - 1 ? 0.8 : 0.0)
                            .shadow(color: .black.opacity(0.4), radius: 3, x: 3, y: 3)
                        }
                        .frame(width: geometry.size.width * cardWidthMultiplier * 0.8)
                    }
                    .padding(.bottom, 20)

                    // Card Content Area - CENTERED
                    Spacer()

                    Group {
                        switch currentCardIndex {
                            case 0:
                                AddConnectionCardView(
                                    title: "connection info",
                                    icon: Image(.addConnectionBasicsIcon)
                                ) {
                                    AddConnectionBasicsCardContent(
                                        connectionName: $connectionName,
                                        connectionAge: $connectionAge,
                                        connectionContextBlock: $connectionContextBlock,
                                        connectionShowAgeError: $connectionShowAgeError,
                                        textEditorDefault: textEditorDefault,
                                        textFieldDefault: nameDefault
                                    )
                                }
                            case 1:
                                AddConnectionCardView(
                                    title: "connection profile",
                                    icon: Image(.addConnectionBackgroundIcon)
                                ) {
                                    AddConnectionImagesCardContent(
                                        connectionOcrImages: $connectionOcrImages,
                                        connectionProfileImages: $connectionProfileImages,
                                        connectionFacePhotoURL: $connectionFacePhotoURL
                                    )
                                }
                            default:
                                EmptyView()
                        }
                    }
                    .frame(
                        width: geometry.size.width * cardWidthMultiplier,
                        height: geometry.size.height * cardHeightMultiplier
                    )

                    Spacer()

                    // Navigation Buttons
                    HStack {
                        // Back Button
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

                        // Next / Save Button
                        Button {
                            hideKeyboard()

                            if isNextOrSaveActionBlocked {
                                if currentCardIndex == 0 {
                                    let trimmedName = connectionName.trimmingCharacters(in: .whitespacesAndNewlines)
                                    if trimmedName.isEmpty || trimmedName == nameDefault || trimmedName == "" {
                                        errorMessageTitle = "missing information"
                                        connectionSaveError = "please enter a name for your connection"
                                        print("TrimmedName: \(trimmedName)")
                                    } else if !isAgeValidForSubmission {
                                        errorMessageTitle = "minimum age requirement"
                                        connectionSaveError = "connection must be at least 18 years old"
                                    }
                                    connectionShowErrorOverlay = true
                                } else if currentCardIndex == totalCards - 1 {
                                    errorMessageTitle = "validation error"
                                    connectionSaveError = "please ensure all required fields are valid and try again"
                                    connectionShowErrorOverlay = true
                                }
                            } else {
                                connectionShowAgeError = false
                                connectionSaveError = nil
                                connectionShowErrorOverlay = false

                                if currentCardIndex < totalCards - 1 {
                                    withAnimation { currentCardIndex += 1 }
                                } else {
                                    saveConnection()
                                }
                            }
                        } label: {
                            Image(systemName: currentCardIndex < totalCards - 1 ? "arrow.right" : "checkmark")
                                .padding()
                                .background(
                                    Circle()
                                        .fill(
                                            isNextOrSaveActionBlocked ?
                                            Color.secondaryText.opacity(0.2) : Color.secondaryButton.opacity(0.7)
                                        )
                                        .shadow(color: .black.opacity(0.4), radius: 4, x: 4, y: 4)
                                )
                                .foregroundColor(Color.primaryBg)
                        }
                    }
                    .padding(.horizontal, geometry.size.width * ((1.0 - cardWidthMultiplier) / 2.0))
                    .padding(.bottom, 8)

                    // Footer
                    VStack(spacing: 2) {
                        Text("we care about protecting your data")
                            .font(.footnote)
                            .foregroundColor(.secondaryText)
                            .opacity(0.6)
                        Link(destination: URL(string: "https://example.com/privacy")!) {
                            Text("learn more here")
                                .underline()
                                .font(.footnote)
                                .foregroundStyle(Color.secondaryText)
                                .opacity(0.6)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 20)

                }
                .background(Color.clear)
                .offset(x: sideMenuManager.isMenuOpen ? self.menuWidthValue : CGFloat(0))
                .animation(.easeInOut, value: sideMenuManager.isMenuOpen)
                .disabled(sideMenuManager.isMenuOpen || connectionIsSaving)
                .zIndex(2)

                dimmingOverlayWhenMenuIsOpen
                sideMenuPresentation

                // Saving Progress Overlay
                if connectionIsSaving {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("saving...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .zIndex(5)
                }

                // Error Overlay
                if connectionShowErrorOverlay {
                    errorOverlay
                }
            }
        }
        .ignoresSafeArea(.keyboard)
        .navigationBarHidden(true)
        .onTapGesture { hideKeyboard() }
    }

    private var headerView: some View {
        HStack {
            Button(action: { sideMenuManager.toggleSideMenu() }) {
                Image.menuIcon
            }.frame(width: 45, height: 45)
            Spacer()
            Button(action: { clearAllConnectionDataAndDismiss() }) {
                Image.cancelAddConnectionIcon
            }
            .frame(width: 45, height: 45)
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            .shadow(color: .black.opacity(0.5), radius: 5, x: 3, y: 3)
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: connectionManager.currentConnectionId)
    }

    // MARK: - Error Overlay View
    private var errorOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    connectionShowErrorOverlay = false
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

                    Text(connectionSaveError ?? "an unknown error occurred")
                        .font(.footnote)
                        .foregroundColor(.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button("dismiss") {
                        connectionShowErrorOverlay = false
                        connectionShowAgeError = false
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

    @ViewBuilder
    private var dimmingOverlayWhenMenuIsOpen: some View {
        if sideMenuManager.isMenuOpen {
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .zIndex(4)
                .onTapGesture { sideMenuManager.closeSideMenu() }
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var sideMenuPresentation: some View {
        if sideMenuManager.isMenuOpen {
            SideMenuView()
                .transition(.move(edge: .leading))
                .zIndex(5)
        }
    }

    // MARK: - Actions

    func clearAllConnectionDataAndDismiss() {
        connectionName = nameDefault
        connectionAge = nil
        connectionContextBlock = textEditorDefault
        connectionOcrImages = []
        connectionProfileImages = []
        connectionFacePhotoURL = nil // Clear face photo URL

        currentCardIndex = 0
        connectionShowAgeError = false
        connectionSaveError = nil
        connectionShowErrorOverlay = false
        connectionIsSaving = false

        dismiss()
    }

    func saveConnection() {
        guard let token = authManager.token, let _ = authManager.userId else {
            errorMessageTitle = "authentication error"
            connectionSaveError = "you must be logged in to save a connection"
            connectionShowErrorOverlay = true
            return
        }

        print("Attempting to save connection...")
        connectionIsSaving = true
        connectionSaveError = nil
        connectionShowErrorOverlay = false

        let nameForConnection = self.connectionName

        let connectionPayload = AddConnectionPayload(
            connectionName: nameForConnection,
            connectionAge: connectionAge,
            connectionContextBlock: connectionContextBlock,
            connectionOcrImages: connectionOcrImages,
            connectionProfileImages: connectionProfileImages,
            connectionFacePhotoURL: connectionFacePhotoURL // Include face photo URL
        )

        guard let encodedPayload = try? JSONEncoder().encode(connectionPayload) else {
            handleSaveResult(.failure(NSError(domain: "Encoding", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to prepare connection data."])))
            return
        }

        if let jsonString = String(data: encodedPayload, encoding: .utf8) {
            print("Sending Connection JSON payload: \(jsonString)")
        }

        #if DEBUG
        let baseURL = "https://staging-api.yourbackend.com/api"
        #else
        let baseURL = "https://api.yourbackend.com/api"
        #endif

        guard let url = URL(string: "\(baseURL)/connections/create") else {
            handleSaveResult(.failure(NSError(domain: "URL", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid API endpoint for saving connection."])))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = encodedPayload

        URLSession.shared.dataTask(with: request) { data, response, error in
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
                    if httpResponse.statusCode == 401 {
                        self.authManager.refreshAccessToken { success in
                            if success {
                                self.saveConnection()
                            } else {
                                self.handleSaveResult(.failure(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Session expired. Please log in again."])))
                            }
                        }
                        return
                    }

                    var serverMsg = "Server error (\(httpResponse.statusCode))."
                    if let responseData = data,
                       let errorString = String(data: responseData, encoding: .utf8),
                       !errorString.isEmpty {
                        serverMsg += " Details: \(errorString)"
                    }
                    self.handleSaveResult(.failure(NSError(domain: "Server", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: serverMsg])))
                    return
                }

                // SUCCESS
                if let responseData = data {
                    struct SaveConnectionResponse: Decodable {
                        let connection_id: String?
                    }
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
                            print("Connection saved successfully. Received Connection ID: \(newConnectionId)")
                        } else {
                            print("Connection saved successfully (no data in response).")
                            self.handleSaveResult(.success(
                                (id: nil, name: nameForConnection)
                                )
                            )
                        }

                    } catch {
                         print("Warning: Could not decode save connection response: \(error.localizedDescription)")
                         self.handleSaveResult(.success(
                            (id: nil, name: nameForConnection))
                         )
                    }
                } else {
                    print("Connection saved successfully (no data in response).")
                    self.handleSaveResult(.success(
                        (id: nil, name: nameForConnection))
                    )
                }
            }
        }.resume()
    }

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
            dismiss()
        case .failure(let error):
            print("Save Error: \(error.localizedDescription)")
            errorMessageTitle = "save failed"
            connectionSaveError = error.localizedDescription
            connectionShowErrorOverlay = true
        }
    }
}

// MARK: - Preview
#if DEBUG
extension UIImage {
    static func solidColor(color: UIColor, size: CGSize = CGSize(width: 100, height: 100)) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return image
    }
}

struct AddConnectionView_Previews: PreviewProvider {
    @State static var dummyOcrImages: [UIImage]? = [UIImage.solidColor(color: .red)]
    @State static var dummyProfileImages: [UIImage]? = [UIImage.solidColor(color: .blue)]

    static var previews: some View {
        AddConnectionView()
        .environmentObject(ConnectionManager())
        .environmentObject(AuthManager())
        .environmentObject(SideMenuManager())
    }
}
#endif
