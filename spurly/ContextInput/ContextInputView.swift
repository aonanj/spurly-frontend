// ContextInputView.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI
import PhotosUI
import Combine // <<< Add Combine for keyboard notifications

enum ContextInputMode: String, CaseIterable, Identifiable {
    case photos = "pics"
    case text = "text"
    var id: String { self.rawValue }
}

struct ContextInputView: View {
    // MARK: Access shared AuthManager from the environment
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var sideMenuManager: SideMenuManager
    @EnvironmentObject var connectionManager: ConnectionManager
    @EnvironmentObject var spurManager: SpurManager

    // MARK: – Context State
    @State private var conversationText: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var conversationImages: [UIImage] = []
    @State private var scale: CGFloat = 1.0
    @State var selectedSituation: String = ""
    @State var topic: String = ""
    @FocusState var isTextEditorFocused: Bool
    @FocusState var isTopicFocused: Bool

    // MARK: – View State
    @State private var isSubmitting: Bool = false
    @State var submissionError: String? = nil
    @State var showTopicError: Bool = false
    @State private var navigateToSuggestions: Bool = false

    // MARK: - State for Input Mode
    @State private var inputMode: ContextInputMode = .photos

    // MARK: - State for Text Input
    @State private var newMessageText: String = ""
    @State private var selectedSender: MessageSender = .user

    // MARK: – View State for Photo OCR
    @State private var isSubmittingPhotos: Bool = false
    @State private var photoSubmissionError: String? = nil {
        didSet {
            if photoSubmissionError != nil {
                showingPhotoErrorAlert = true
            }
        }
    }
    @State private var photosSubmittedSuccessfully: Bool = false
    @State private var showingPhotoErrorAlert: Bool = false
    @State private var conversationMessages: [ConversationMessage] = []

    // For EditMessageView sheet
    @State private var editingMessageId: UUID? = nil
    @State private var showEditMessageSheet: Bool = false
    @State private var messageTextBeingEdited: String = ""

    // Token refresh state
    @State private var isRefreshingToken: Bool = false

    // MARK: - Keyboard Handling State <<< NEW
    @State private var keyboardHeight: CGFloat = 0
    @State private var isKeyboardVisible: Bool = false


    private var editingMessageBinding: Binding<ConversationMessage>? {
        guard let id = editingMessageId,
              let index = conversationMessages.firstIndex(where: { $0.id == id })
        else { return nil }
        return $conversationMessages[index]
    }

    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width
    private let inputBackgroundOpacity: Double = 0.9

    private var menuWidthValue: CGFloat {
        UIScreen.main.bounds.width * 0.82
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                NavigationLink(
                    destination: AddConnectionView()
                        .environmentObject(authManager)
                        .environmentObject(connectionManager)
                        .environmentObject(sideMenuManager),
                    isActive: $connectionManager.isNewConnectionOpen
                ) {
                    EmptyView()
                }
                .isDetailLink(false)

                Color.tappablePrimaryBg.zIndex(0)

                Image.tappableBgIcon
                    .frame(width: screenWidth * 1.5, height: screenHeight * 1.5)
                    .position(x: screenWidth / 2, y: screenHeight * 0.46)
                    .zIndex(0)

                ScrollViewReader { scrollViewProxy in // <<< Wrap with ScrollViewReader
                    ScrollView {
                        VStack(spacing: 10) {
                            headerView


                            Image.bannerLogo
                                .frame(height: screenHeight * 0.1)
                                .padding(.horizontal)
                            Text.bannerTag
                                .padding(.bottom, 25)

                            inputCardView(geometry: geo)
                                .id("inputCard")

                            situationAndTopicView(geometry: geo)
                                .padding(.top, 10)
                                .padding(.bottom, 2)
                                .id("topicSection") // <<< Add an ID for scrolling
                            getSpursButton


                            footerView
                                .frame(maxWidth: .infinity)
                                .padding(.bottom, geo.safeAreaInsets.bottom > 10 ? 10 : geo.safeAreaInsets.bottom
                                ) // Initial padding
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, keyboardHeight) // <<< APPLY KEYBOARD HEIGHT AS PADDING
                        .onReceive(Publishers.keyboardHeight) { newKeyboardHeight in // <<< OBSERVE KEYBOARD HEIGHT
                            withAnimation(.spring()) { // Use an animation for smoother transition
                                self.keyboardHeight = newKeyboardHeight
                                self.isKeyboardVisible = newKeyboardHeight > 0
                            }
                        }
                        .onChange(of: isTopicFocused) { focused in // <<< SCROLL TO TOPIC FIELD WHEN FOCUSED
                            if focused && isKeyboardVisible { // Only scroll if keyboard is also visible
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Delay to allow keyboard to animate
                                    withAnimation {
                                        scrollViewProxy.scrollTo("topicSection", anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .onChange(of: isTextEditorFocused) { editorFocused in // <<< SCROLL TO TOPIC FIELD WHEN FOCUSED
                            if editorFocused && isKeyboardVisible { // Only scroll if keyboard is also visible
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { // Delay to allow keyboard to animate
                                    withAnimation {
                                        scrollViewProxy.scrollTo("inputCard", anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .offset(x: sideMenuManager.isMenuOpen ? self.menuWidthValue : CGFloat(0))
                    .animation(.easeInOut, value: sideMenuManager.isMenuOpen)
                    .disabled(sideMenuManager.isMenuOpen || isSubmitting || isSubmittingPhotos || isRefreshingToken)
                    .zIndex(2)
                } // End ScrollViewReader

                dimmingOverlayWhenMenuIsOpen
                sideMenuPresentation
            }
            .alert("Photo Error", isPresented: $showingPhotoErrorAlert, presenting: photoSubmissionError) { errorDetail in
                Button("OK") { photoSubmissionError = nil }
            } message: { errorDetail in Text(errorDetail) }
            .sheet(isPresented: $spurManager.showSpursView) {
                SpursView()
                    .environmentObject(spurManager)
                    .environmentObject(authManager)
                    .environmentObject(connectionManager)
            }
            .sheet(isPresented: $showEditMessageSheet) {
                if let messageBinding = editingMessageBinding {
                    EditMessageView(
                        message: messageBinding,
                        onSave: { updatedText in
                            if let idToEdit = editingMessageId,
                               let index = conversationMessages.firstIndex(where: { $0.id == idToEdit }) {
                                conversationMessages[index].text = updatedText
                            }
                            editingMessageId = nil
                            showEditMessageSheet = false
                        },
                        onCancel: {
                            editingMessageId = nil
                            showEditMessageSheet = false
                        }
                    )
                } else {
                     Text("Error loading message for editing.")
                }
            }
        }
        .navigationBarHidden(true)
        // .ignoresSafeArea(.keyboard) // REMOVE from here if applying padding directly
        // OR Keep it if you want the ScrollView to extend fully and padding handles content overlap
        // For this direct padding approach, let's try keeping it to see how ScrollView behaves.
        // If issues persist, removing it and ensuring ScrollView respects the safe area might be better.
        // However, typically for text fields, you want the view to shrink, not just have content go under.
        // Let's manage the safe area via padding.
        .onTapGesture { hideKeyboard() }
    }

    // ... (rest of your functions: headerView, inputCardView, etc. remain the same) ...
    // MARK: - Refactored View Components

    private var headerView: some View {
        HStack {
            Button(action: { sideMenuManager.toggleSideMenu() }) {
                Image.menuIcon
            }.frame(width: 45, height: 45)
            Spacer()
            if connectionManager.currentConnectionId != nil {
                Button(action: { connectionManager.clearActiveConnection() }) {
                    Image.cancelAddConnectionIcon
                }
                .frame(width: 45, height: 45)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .shadow(color: .black.opacity(0.5), radius: 5, x: 3, y: 3)
            } else {
                Button(action: { connectionManager.addNewConnection() }) {
                    Image.connectionIcon
                }
                .frame(width: 45, height: 45)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: connectionManager.currentConnectionId)
    }

    private func inputCardView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            inputModePickerAndConnectionNameView
            messageDisplayAreaView(geometry: geometry)
            conditionalInputAreaView
            actionButtonsAreaView
        }
        .frame(width: geometry.size.width * 0.89, height: geometry.size.height * 0.5)
        .background(Color.cardBg)
        .opacity(0.88)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.cardBg.opacity(0.4), Color.highlight.opacity(0.85)]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ), lineWidth: 12
                )
                .cornerRadius(12)
        )
        .zIndex(3)
        .animation(.easeInOut, value: inputMode)
        .animation(.easeInOut, value: conversationMessages.isEmpty)
    }

    private var inputModePickerAndConnectionNameView: some View {
        HStack {
            Picker("Input Mode", selection: $inputMode) {
                ForEach(ContextInputMode.allCases) { mode in Text(mode.rawValue).tag(mode) }
            }
            .frame(maxWidth: 200, maxHeight: 60)
            .pickerStyle(.segmented)
            .scaleEffect(0.85)
            .shadow(color: .black.opacity(0.4),radius: 5,x: 3,y: 3)
            .onChange(of: inputMode) { _, _ in
                conversationMessages.removeAll(); conversationImages.removeAll(); selectedPhotos.removeAll()
                newMessageText = ""; photoSubmissionError = nil; photosSubmittedSuccessfully = false; conversationText = ""
            }
            Spacer()
            if let connectionName = connectionManager.currentConnectionName, connectionManager.currentConnectionId != nil {
                HStack(spacing: 4) { Text(connectionName).font(.caption).fontWeight(.semibold).foregroundColor(.primaryBg).lineLimit(1) }
                .padding(.vertical, 6).padding(.horizontal, 10)
                .background(Capsule().fill(Color.primaryText.opacity(0.9)).shadow(color: .black.opacity(0.4),radius: 5,x: 3,y: 3))
                .padding(.horizontal).transition(.opacity.combined(with: .scale(scale: 0.85)))
            }
        }
        .padding(.top, 1)
        .animation(.easeInOut, value: connectionManager.currentConnectionId)
    }

    private func messageDisplayAreaView(geometry: GeometryProxy) -> some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach($conversationMessages) { $message in
                            MessageRow(message: $message)
                                .padding(.horizontal, 10)
                                .background((editingMessageId == message.id) ? Color.yellow.opacity(0.3) : Color.clear)
                                .cornerRadius(6)
                                .onTapGesture {
                                    editingMessageId = message.id;
                                    messageTextBeingEdited = message.text;
                                    showEditMessageSheet = true
                                }
                                .id(message.id)
                        }
                    }
                }
                .onChange(of: conversationMessages.count) { _, _ in
                    if let lastMessageId = conversationMessages.last?.id { withAnimation { proxy.scrollTo(lastMessageId, anchor: .bottom) } }
                }
            }
            .background(Color.white.opacity(inputBackgroundOpacity))
            .cornerRadius(12)
            .frame(minHeight: geometry.size.height * (inputMode == .text ? 0.15 : 0.25), maxHeight: geometry.size.height * (inputMode == .text ? 0.28 : 0.45))
        }
    }

    @ViewBuilder
    private var conditionalInputAreaView: some View {
        Group {
             if inputMode == .text {
                 ManualTextInputView(
                    newMessageText: $newMessageText,
                    selectedSender: $selectedSender,
                    addMessageAction: addManualMessage,
                    isTextEditorFocused: $isTextEditorFocused
                 )
                 .padding(.horizontal, 10).transition(.opacity.combined(with: .move(edge: .bottom)))
             } else if !conversationImages.isEmpty {
                 ScrollView(.horizontal, showsIndicators: false) {
                     HStack(spacing: 8) {
                         ForEach(conversationImages.indices, id: \.self) { index in
                             ImageThumbnailView(image: conversationImages[index]) { removeImage(at: index) }
                         }
                         Spacer()
                     }.padding(.horizontal, 8)
                 }
                 .frame(height: 60).transition(.opacity.combined(with: .move(edge: .bottom)))
             }
         }
         .padding(.bottom, (inputMode == .photos && conversationImages.isEmpty) ? 0 : 5)
         .padding(.horizontal, 8)
    }

    private var actionButtonsAreaView: some View {
        HStack {
            Button(action: clearConversation) { clearButtonStyle }
                .disabled(conversationMessages.isEmpty && conversationImages.isEmpty && selectedPhotos.isEmpty && newMessageText.isEmpty)
            Spacer()
            if inputMode == .photos {
                if conversationImages.isEmpty {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        photosPickerStyle
                    }
                        .onChange(of: selectedPhotos) {
                            _,
                            newItems in photoSubmissionError = nil; photosSubmittedSuccessfully = false; loadSelectedImages(
                                from: newItems
                            )
                        }
                    .disabled(isSubmittingPhotos).transition(.opacity)
                } else {
                    Button(action: submitPhotosForOCR) {
                        HStack {
                            if isSubmittingPhotos { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8) }
                            Image(systemName: photosSubmittedSuccessfully ? "checkmark.circle.fill" : "arrow.up.doc.on.clipboard")
                            Text(photosSubmittedSuccessfully ? "pics sent" : (isSubmittingPhotos ? "..." : "send pics")).font(.caption).lineLimit(1)
                        }
                        .padding(.horizontal, 5).padding(.vertical, 10)
                        .background(Capsule().fill(photosSubmittedSuccessfully ? Color.green.opacity(0.7) : Color.accent1.opacity(0.8))).foregroundColor(.white)
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                    }
                    .padding(.bottom, 10)
                    .disabled(isSubmittingPhotos || photosSubmittedSuccessfully).transition(.opacity)
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 10)
    }

    private func situationAndTopicView(geometry: GeometryProxy) -> some View {
        HStack(alignment: .center, spacing: 5) { //
            SituationPicker(selectedSituation: $selectedSituation)
                .padding(.leading, 8)//
            TopicFieldView(topic: $topic,showTopicError: $showTopicError,isTopicFocused: $isTopicFocused)
                .padding(.trailing, 8)//
        }
        .frame(width: geometry.size.width * 0.89) //
        .padding(.horizontal, 5) //
        .padding(.top, 10)
        .padding(.bottom, 8)//
    }

    @ViewBuilder
    private var dimmingOverlayWhenMenuIsOpen: some View {
        if sideMenuManager.isMenuOpen {
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .zIndex(3)
                .onTapGesture { sideMenuManager.closeSideMenu() }
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var sideMenuPresentation: some View {
        if sideMenuManager.isMenuOpen {
            SideMenuView()
                .transition(.move(edge: .leading))
                .zIndex(4)
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func addManualMessage() {
        let trimmedText = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        let newMessage = ConversationMessage(sender: selectedSender, text: trimmedText)
        conversationMessages.append(newMessage)
        newMessageText = ""
        selectedSender = .user
        print("Added manual message: \(newMessage.text) from \(newMessage.sender.rawValue)")
    }

    private func submitPhotosForOCR() {
        guard !conversationImages.isEmpty else { return }

        hideKeyboard()
        photoSubmissionError = nil
        isSubmittingPhotos = true
        photosSubmittedSuccessfully = false

        guard let token = authManager.token else {
            photoSubmissionError = "You must be logged in to submit photos."
            isSubmittingPhotos = false
            return
        }

        let imageDatas: [String] = conversationImages.compactMap { image in
            guard let orientedImage = imageWithCorrectOrientation(image),
                  let imageData = orientedImage.jpegData(compressionQuality: 0.7) else { return nil }
            return imageData.base64EncodedString()
        }

        guard !imageDatas.isEmpty else {
            photoSubmissionError = "Could not process images for upload."
            isSubmittingPhotos = false
            return
        }

        performOCRRequest(with: imageDatas, token: token)
    }

    private func performOCRRequest(with imageDatas: [String], token: String, isRetry: Bool = false) {
        struct OcrPayload: Codable {
            let images: [String]
            let userId: String?
        }

        let payload = OcrPayload(images: imageDatas, userId: authManager.userId)

        guard let url = URL(string: "https://your.backend/api/ocr") else {
            photoSubmissionError = "Invalid OCR backend URL."
            isSubmittingPhotos = false
            return
        }

        guard let encodedPayload = try? JSONEncoder().encode(payload) else {
            photoSubmissionError = "Failed to prepare photo data."
            isSubmittingPhotos = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = encodedPayload

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { [self] in
                if let error = error {
                    self.isSubmittingPhotos = false
                    self.photoSubmissionError = "Network error: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.isSubmittingPhotos = false
                    self.photoSubmissionError = "Invalid response from server."
                    return
                }

                if httpResponse.statusCode == 401 && !isRetry {
                    self.handleTokenRefreshAndRetry {
                        self.performOCRRequest(with: imageDatas, token: self.authManager.token ?? "", isRetry: true)
                    }
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    self.isSubmittingPhotos = false
                    var serverMsg = "Photo upload failed (\(httpResponse.statusCode))."
                    if let d = data, let s = String(data: d, encoding: .utf8), !s.isEmpty {
                        serverMsg += " Details: \(s)"
                    }
                    self.photoSubmissionError = serverMsg
                    return
                }

                self.isSubmittingPhotos = false
                self.photosSubmittedSuccessfully = true

                if let responseData = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode(OcrConversationResponse.self, from: responseData)
                        self.conversationMessages.append(contentsOf: decodedResponse.messages)
                    } catch {
                        self.photoSubmissionError = "Failed to process server response."
                    }
                } else {
                    print("OCR Warning: No data received.")
                }
            }
        }.resume()
    }

    private func clearConversation() {
        hideKeyboard()
        conversationMessages.removeAll()
        topic = ""; selectedSituation = ""; showTopicError = false; submissionError = nil
        selectedPhotos = []; conversationImages.removeAll()
        photoSubmissionError = nil; photosSubmittedSuccessfully = false; isSubmittingPhotos = false
        newMessageText = ""; selectedSender = .user
        print("Context cleared.")
    }

    private func removeImage(at index: Int) {
         guard index >= 0 && index < conversationImages.count else { return }
         conversationImages.remove(at: index)
         print("Removed image at index \(index)")
     }

    private func loadSelectedImages(from items: [PhotosPickerItem]) {
        self.conversationImages = []
        Task {
            var loadedImages: [UIImage] = []
            await withTaskGroup(of: UIImage?.self) { group in
                for item in items {
                    group.addTask {
                        do {
                            guard let data = try await item.loadTransferable(type: Data.self) else { return nil }
                            guard let uiImage = UIImage(data: data) else { return nil }
                            return uiImage
                        } catch { print("Error loading image: \(error.localizedDescription)"); return nil }
                    }
                }
                for await resultImage in group {
                    if let image = resultImage, loadedImages.count < 5 { loadedImages.append(image) }
                }
            }
            await MainActor.run { self.conversationImages = loadedImages }
        }
    }

    private func submitContext() {
        hideKeyboard()
        submissionError = nil
        showTopicError = false
        isSubmitting = true

        guard let token = authManager.token else {
            submissionError = "You must be logged in to generate spurs."
            isSubmitting = false
            return
        }

        let currentConnectionId = connectionManager.currentConnectionId

        let payload = SubmitContextPayload(
            messages: conversationMessages.isEmpty ? nil : conversationMessages.map { SimplifiedMessage(sender: $0.sender.rawValue, text: $0.text) },
            situation: selectedSituation.isEmpty ? nil : selectedSituation,
            topic: topic.isEmpty ? nil : topic,
            userId: authManager.userId,
            connectionId: currentConnectionId
        )

        performContextSubmission(with: payload, token: token)
    }

    private func performContextSubmission(with payload: SubmitContextPayload, token: String, isRetry: Bool = false) {
        guard let url = URL(string: "https://your.backend/api/generate") else {
            submissionError = "Invalid backend URL."
            isSubmitting = false
            return
        }

        guard let encodedPayload = try? JSONEncoder().encode(payload) else {
            submissionError = "Failed to prepare data."
            isSubmitting = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = encodedPayload

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async { [self] in
                if let error = error {
                    self.isSubmitting = false
                    self.submissionError = "Network request failed: \(error.localizedDescription)"
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    self.isSubmitting = false
                    self.submissionError = "Invalid response from server."
                    return
                }

                if httpResponse.statusCode == 401 && !isRetry {
                    self.handleTokenRefreshAndRetry {
                        self.performContextSubmission(with: payload, token: self.authManager.token ?? "", isRetry: true)
                    }
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    self.isSubmitting = false
                    var serverMsg = "Server error (\(httpResponse.statusCode))."
                    if let d = data, let s = String(data: d, encoding: .utf8), !s.isEmpty {
                        serverMsg += " Details: \(s)"
                    }
                    self.submissionError = serverMsg
                    return
                }

                self.isSubmitting = false

                guard let responseData = data else {
                    self.submissionError = "No data received from server."
                    return
                }

                struct BackendSpursResponse: Decodable { let spurs: [BackendSpurData]? }

                do {
                    let decodedResponse = try JSONDecoder().decode(BackendSpursResponse.self, from: responseData)
                    if let receivedSpurData = decodedResponse.spurs, !receivedSpurData.isEmpty {
                        self.spurManager.loadSpurs(backendSpurData: receivedSpurData)
                    } else {
                        self.submissionError = "No spurs were generated."
                    }
                } catch {
                    self.submissionError = "Failed to understand server response for spurs: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    private func handleTokenRefreshAndRetry(onSuccess: @escaping () -> Void) {
        isRefreshingToken = true

        authManager.refreshAccessToken { success in
            DispatchQueue.main.async { [self] in
                self.isRefreshingToken = false

                if success {
                    onSuccess()
                } else {
                    self.submissionError = "Session expired. Please log in again."
                    self.isSubmitting = false
                    self.isSubmittingPhotos = false
                }
            }
        }
    }

    private var getSpursButton: some View { //
        HStack {
            Spacer()
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    scale = 0.8
                }

                // Return to normal size after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        scale = 1.0
                    }
                }

                submitContext()
            }) {
                Image("GetSpursButton").resizable().scaledToFit() //
                if isSubmitting || isRefreshingToken {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5).background(Circle().fill(Color.black.opacity(0.3)))
                }
            }
            .scaleEffect(scale)
            .shadow(color: .black.opacity(0.45), radius: 5, x: 4, y: 4) //
            .frame(width: 120) //
            .disabled(isSubmitting || isRefreshingToken) //
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 5)

    }

    struct SubmitContextPayload: Codable {
        let messages: [SimplifiedMessage]?
        let situation: String?
        let topic: String?
        let userId: String?
        let connectionId: String?
    }

    struct SimplifiedMessage: Codable {
        let sender: String
        let text: String
    }

    var clearButtonStyle: some View { Image(systemName: "xmark").padding(10).background(Circle().fill(Color.accent1.opacity(0.8))).foregroundColor(.white).shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1) }
    var photosPickerStyle: some View { Image(systemName: "photo.on.rectangle.angled").padding(10).background(Circle().fill(Color.accent1.opacity(0.8))).foregroundColor(.white).shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1) }
    var footerView: some View { VStack(spacing: 2) { Text("we care about protecting your data").font(.footnote).foregroundColor(.secondaryText).opacity(0.6); Link(destination: URL(string: "https://example.com/privacy")!) { Text("learn more here").underline().font(.footnote).foregroundStyle(Color.secondaryText).opacity(0.6) } } }
}

// Helper Publisher to get keyboard height
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { $0.keyboardHeight }

        let willHide = NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .map { _ in CGFloat(0) }

        // Merge the two publishers. `eraseToAnyPublisher()` is important for type erasure.
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}

extension Notification {
    var keyboardHeight: CGFloat {
        return (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
    }
}


#if DEBUG
struct ContextInputView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthManager = AuthManager()
        let mockConnectionManager = ConnectionManager()
        let mockSideMenuManager = SideMenuManager()
        let mockSpurManager = SpurManager()

        NavigationView {
            ContextInputView()
                .environmentObject(mockAuthManager)
                .environmentObject(mockConnectionManager)
                .environmentObject(mockSideMenuManager)
                .environmentObject(mockSpurManager)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            mockConnectionManager.setActiveConnection(connectionId: "connPreview", connectionName: "Sara")
        }
    }
}
#endif
