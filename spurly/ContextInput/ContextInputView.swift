// ContextInputView.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI
import PhotosUI // Ensure PhotosUI is imported

enum ContextInputMode: String, CaseIterable, Identifiable { //
    case photos = "pics" //
    case text = "text" //
    var id: String { self.rawValue } //
}

struct ContextInputView: View {
    // MARK: Access shared AuthManager from the environment
    @EnvironmentObject var authManager: AuthManager //
    @EnvironmentObject var sideMenuManager: SideMenuManager //
    @EnvironmentObject var connectionManager: ConnectionManager //
    @EnvironmentObject var spurManager: SpurManager //

    // MARK: – Context State
    @State private var conversationText: String = "" //
    @State private var selectedPhotos: [PhotosPickerItem] = [] //
    @State private var conversationImages: [UIImage] = [] // Store loaded UIImages //
    @State var selectedSituation: String = "" //
    @State var topic: String = "" //
    @FocusState private var isConversationFocused: Bool //
    @FocusState var isTopicFocused: Bool //

    // MARK: – View State
    @State private var isSubmitting: Bool = false //
    @State var submissionError: String? = nil // Holds error message //
    @State var showTopicError: Bool = false //
    @State private var navigateToSuggestions: Bool = false // Controls navigation //

    // MARK: - State for Input Mode
    @State private var inputMode: ContextInputMode = .photos // Default to photos //

    // MARK: - State for Text Input
    @State private var newMessageText: String = "" //
    @State private var selectedSender: MessageSender = .user // Default sender //

    // MARK: – View State for Photo OCR
    @State private var isSubmittingPhotos: Bool = false //
    @State private var photoSubmissionError: String? = nil { //
        didSet { //
            if photoSubmissionError != nil { //
                showingPhotoErrorAlert = true //
            }
        }
    }
    @State private var photosSubmittedSuccessfully: Bool = false // Optional: Track success //
    @State private var showingPhotoErrorAlert: Bool = false //
    @State private var conversationMessages: [ConversationMessage] = [] //

    // For EditMessageView sheet
    @State private var editingMessageId: UUID? = nil //
    @State private var showEditMessageSheet: Bool = false // NEW state for sheet presentation
    @State private var messageTextBeingEdited: String = "" //


    private var editingMessageBinding: Binding<ConversationMessage>? { //
        guard let id = editingMessageId,
              let index = conversationMessages.firstIndex(where: { $0.id == id })
        else { return nil }
        return $conversationMessages[index]
    }

    let screenHeight = UIScreen.main.bounds.height //
    let screenWidth = UIScreen.main.bounds.width //
    private let inputBackgroundOpacity: Double = 0.9 //

    private var menuWidthValue: CGFloat { //
        UIScreen.main.bounds.width * 0.82
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Color.tappablePrimaryBg.zIndex(0) //

                Image.tappableBgIcon //
                    .frame(width: screenWidth * 1.5, height: screenHeight * 1.5) //
                    .position(x: screenWidth / 2, y: screenHeight * 0.43) //
                    .allowsHitTesting(false)
                    .zIndex(1)

                VStack(spacing: 2) { // Main content VStack //
                    headerView

                    Image.bannerLogo //
                        .frame(height: screenHeight * 0.1) //
                        .padding(.horizontal) //
                    Text.bannerTag //
                        .padding(.bottom, 15) //

                    Spacer() //
                    inputCardView(geometry: geo)
                    Spacer() //
                    situationAndTopicView(geometry: geo)
                    SubmissionErrorView(submissionError: $submissionError) //
                    Spacer(minLength: 25) //
                    footerView //
                        .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? 5 : 15) //
                        .frame(maxWidth: .infinity) //
                }
                .background(Color.clear)
                .offset(x: sideMenuManager.isMenuOpen ? self.menuWidthValue : CGFloat(0)) //
                .animation(.easeInOut, value: sideMenuManager.isMenuOpen)
                .disabled(sideMenuManager.isMenuOpen)
                .opacity(0.89)
                .zIndex(2)

                dimmingOverlayWhenMenuIsOpen
                sideMenuPresentation
            }
            .alert("Photo Error", isPresented: $showingPhotoErrorAlert, presenting: photoSubmissionError) { errorDetail in //
                Button("OK") { photoSubmissionError = nil } //
            } message: { errorDetail in Text(errorDetail) } //
            .sheet(isPresented: $connectionManager.isNewConnectionOpen) { //
                AddConnectionView() //
                    .environmentObject(authManager) //
                    .environmentObject(connectionManager) //
            }
            .sheet(isPresented: $spurManager.showSpursView) { //
                SpursView() //
                    .environmentObject(spurManager) //
                    .environmentObject(authManager) //
                    .environmentObject(connectionManager) //
            }
            // Corrected sheet presentation for editing messages
            .sheet(isPresented: $showEditMessageSheet) { // Use isPresented
                if let messageBinding = editingMessageBinding { // Check if we have a message to edit
                    EditMessageView( //
                        message: messageBinding,
                        onSave: { updatedText in
                            if let idToEdit = editingMessageId, // Ensure editingMessageId is not nil
                               let index = conversationMessages.firstIndex(where: { $0.id == idToEdit }) {
                                conversationMessages[index].text = updatedText
                            }
                            editingMessageId = nil // Clear the ID
                            showEditMessageSheet = false // Dismiss sheet
                        },
                        onCancel: {
                            editingMessageId = nil // Clear the ID
                            showEditMessageSheet = false // Dismiss sheet
                        }
                    )
                } else {
                     Text("Error loading message for editing.") // Fallback content
                }
            }
        }
        .navigationBarHidden(true) //
        .ignoresSafeArea(.keyboard) //
    }

    // MARK: - Refactored View Components

    private var headerView: some View {
        HStack { //
            Button(action: { sideMenuManager.toggleSideMenu() }) { //
                Image.menuIcon//
            }.frame(width: 50, height: 50)
            Spacer() //
            if connectionManager.currentConnectionId != nil { //
                Button(action: { connectionManager.clearActiveConnection() }) { //
                    Image.cancelAddConnectionIcon//
                }
                .frame(width: 50, height: 50)
                .transition(.opacity.combined(with: .scale(scale: 0.9))) //
                .shadow(color: .black.opacity(0.5), radius: 5, x: 3, y: 3) //
            } else {
                Button(action: { connectionManager.addNewConnection() }) { //
                    Image.connectionIcon//
                }
                .frame(width: 50, height: 50)
                .transition(.opacity.combined(with: .scale(scale: 0.9))) //
            }
        }
        .padding(.horizontal) //
        .animation(.easeInOut(duration: 0.2), value: connectionManager.currentConnectionId) //
    }

    private func inputCardView(geometry: GeometryProxy) -> some View {
        VStack(spacing: 8) { //
            inputModePickerAndConnectionNameView
            messageDisplayAreaView(geometry: geometry)
            conditionalInputAreaView
            actionButtonsAreaView
        }
        .frame(width: geometry.size.width * 0.89, height: geometry.size.height * 0.5) //
        .background(Color.cardBg) //
        .cornerRadius(12) //
        .overlay(
            RoundedRectangle(cornerRadius: 12) //
                .stroke(
                    LinearGradient( //
                        gradient: Gradient(colors: [Color.cardBg.opacity(0.6), Color.highlight.opacity(0.8)]), //
                        startPoint: .topLeading, endPoint: .bottomTrailing //
                    ), lineWidth: 12 //
                )
                .cornerRadius(12) //
        )
        .animation(.easeInOut, value: inputMode) //
        .animation(.easeInOut, value: conversationMessages.isEmpty) //
    }

    private var inputModePickerAndConnectionNameView: some View {
        HStack { //
            Picker("Input Mode", selection: $inputMode) { //
                ForEach(ContextInputMode.allCases) { mode in Text(mode.rawValue).tag(mode) } //
            }
            .frame(maxWidth: 200, maxHeight: 60) //
            .pickerStyle(.segmented) //
            .scaleEffect(0.85) //
            .shadow(color: .black.opacity(0.4),radius: 5,x: 3,y: 3) //
            .onChange(of: inputMode) { _, _ in //
                conversationMessages.removeAll(); conversationImages.removeAll(); selectedPhotos.removeAll() //
                newMessageText = ""; photoSubmissionError = nil; photosSubmittedSuccessfully = false; conversationText = "" //
            }
            Spacer() //
            if let connectionName = connectionManager.currentConnectionName, connectionManager.currentConnectionId != nil { //
                HStack(spacing: 4) { Text(connectionName).font(.caption).fontWeight(.semibold).foregroundColor(.primaryBg).lineLimit(1) } //
                .padding(.vertical, 6).padding(.horizontal, 10) //
                .background(Capsule().fill(Color.primaryText.opacity(0.9)).shadow(color: .black.opacity(0.4),radius: 5,x: 3,y: 3)) //
                .padding(.horizontal).transition(.opacity.combined(with: .scale(scale: 0.85))) //
            }
        }
        .padding(.top, 1) //
        .animation(.easeInOut, value: connectionManager.currentConnectionId) //
    }

    private func messageDisplayAreaView(geometry: GeometryProxy) -> some View {
        ZStack { //
            ScrollViewReader { proxy in //
                ScrollView { //
                    VStack(alignment: .leading, spacing: 8) { //
                        ForEach($conversationMessages) { $message in //
                            MessageRow(message: $message) //
                                .padding(.horizontal, 10) //
                                .background((editingMessageId == message.id) ? Color.yellow.opacity(0.3) : Color.clear) //
                                .cornerRadius(6) //
                                .onTapGesture {
                                    editingMessageId = message.id;
                                    messageTextBeingEdited = message.text;
                                    showEditMessageSheet = true // Trigger the sheet
                                }
                                .id(message.id) //
                        }
                    }
                }
                .onChange(of: conversationMessages.count) { _, _ in //
                    if let lastMessageId = conversationMessages.last?.id { withAnimation { proxy.scrollTo(lastMessageId, anchor: .bottom) } } //
                }
            }
            .background(Color.white.opacity(inputBackgroundOpacity)) //
            .cornerRadius(12) //
            .frame(minHeight: geometry.size.height * (inputMode == .text ? 0.15 : 0.25), maxHeight: geometry.size.height * (inputMode == .text ? 0.28 : 0.45)) //
            // Sheet modifier moved to the main ZStack's .body
        }
    }

    @ViewBuilder
    private var conditionalInputAreaView: some View {
        Group { //
             if inputMode == .text { //
                 ManualTextInputView(newMessageText: $newMessageText, selectedSender: $selectedSender, addMessageAction: addManualMessage) //
                 .padding(.horizontal, 10).transition(.opacity.combined(with: .move(edge: .bottom))) //
             } else if !conversationImages.isEmpty { //
                 ScrollView(.horizontal, showsIndicators: false) { //
                     HStack(spacing: 8) { //
                         ForEach(conversationImages.indices, id: \.self) { index in //
                             ImageThumbnailView(image: conversationImages[index]) { removeImage(at: index) } //
                         }
                         Spacer() //
                     }.padding(.horizontal, 8)
                 }
                 .frame(height: 60).transition(.opacity.combined(with: .move(edge: .bottom))) //
             }
         }
         .padding(.bottom, (inputMode == .photos && conversationImages.isEmpty) ? 0 : 5) //
         .padding(.horizontal, 8)
    }

    private var actionButtonsAreaView: some View {
        HStack { //
            Button(action: clearConversation) { clearButtonStyle } //
                .disabled(conversationMessages.isEmpty && conversationImages.isEmpty && selectedPhotos.isEmpty && newMessageText.isEmpty) //
            Spacer() //
            if inputMode == .photos { //
                if conversationImages.isEmpty { //
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        photosPickerStyle
                    }
                    //.padding(.horizontal, 2) //
                        .onChange(of: selectedPhotos) {
                            _,
                            newItems in photoSubmissionError = nil; photosSubmittedSuccessfully = false; loadSelectedImages(
                                from: newItems
                            )
                        }
                        //.padding(.horizontal, 12) //
                    .disabled(isSubmittingPhotos).transition(.opacity) //
                } else {
                    Button(action: submitPhotosForOCR) { //
                        HStack { //
                            if isSubmittingPhotos { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)).scaleEffect(0.8) } //
                            Image(systemName: photosSubmittedSuccessfully ? "checkmark.circle.fill" : "arrow.up.doc.on.clipboard") //
                            Text(photosSubmittedSuccessfully ? "pics sent" : (isSubmittingPhotos ? "..." : "send pics")).font(.caption).lineLimit(1) //
                        }
                        .padding(.horizontal, 5).padding(.vertical, 10) //
                        .background(Capsule().fill(photosSubmittedSuccessfully ? Color.green.opacity(0.7) : Color.accent1.opacity(0.8))).foregroundColor(.white) //
                        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1) //
                    }
                    .padding(.bottom, 10)
                    .disabled(isSubmittingPhotos || photosSubmittedSuccessfully).transition(.opacity) //
                }
            }
        }
        .padding(.horizontal, 15) //
        .padding(.bottom, 10) //
    }

    private func situationAndTopicView(geometry: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 8) { //
            VStack(alignment: .leading, spacing: 12) { //
                SituationPicker(selectedSituation: $selectedSituation) //
                TopicFieldView(topic: $topic,showTopicError: $showTopicError,isTopicFocused: $isTopicFocused) //
            }
            .frame(width: geometry.size.width * 0.55) //
            Spacer() //
            spurGenerationButton //
        }
        .padding(.horizontal) //
        .padding(.top, 10) //
    }

    @ViewBuilder
    private var dimmingOverlayWhenMenuIsOpen: some View {
        if sideMenuManager.isMenuOpen {
            Color.black.opacity(0.6)
                .edgesIgnoringSafeArea(.all)
                .zIndex(3)
                .onTapGesture { sideMenuManager.closeSideMenu() } //
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

    // MARK: - Helper Functions (Copied from your uploaded file)
    private func hideKeyboard() { //
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func addManualMessage() { //
        let trimmedText = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        let newMessage = ConversationMessage(sender: selectedSender, text: trimmedText)
        conversationMessages.append(newMessage)
        newMessageText = ""
        selectedSender = .user
        print("Added manual message: \(newMessage.text) from \(newMessage.sender.rawValue)")
    }

    private func submitPhotosForOCR() { //
        guard let token = authManager.token else {
            photoSubmissionError = "No token available for photo submission."
            return
        }
        let userId = authManager.userId
        guard !conversationImages.isEmpty else { return }

        hideKeyboard()
        photoSubmissionError = nil
        isSubmittingPhotos = true
        photosSubmittedSuccessfully = false

        let imageDatas: [String] = conversationImages.compactMap { image in
            guard let orientedImage = imageWithCorrectOrientation(image), //
                  let imageData = orientedImage.jpegData(compressionQuality: 0.7) else { return nil }
            return imageData.base64EncodedString()
        }

        guard !imageDatas.isEmpty else {
            photoSubmissionError = "Could not process images for upload."
            isSubmittingPhotos = false; return
        }
        struct OcrPayload: Codable { let images: [String]; let userId: String? }
        let payload = OcrPayload(images: imageDatas, userId: userId)

        guard let url = URL(string: "https://your.backend/api/ocr") else { // Replace with actual URL //
            photoSubmissionError = "Invalid OCR backend URL."; isSubmittingPhotos = false; return
        }
        guard let encodedPayload = try? JSONEncoder().encode(payload) else {
            photoSubmissionError = "Failed to prepare photo data."; isSubmittingPhotos = false; return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = encodedPayload

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmittingPhotos = false
                if let error = error { photoSubmissionError = "Network error: \(error.localizedDescription)"; return }
                guard let httpResponse = response as? HTTPURLResponse else { photoSubmissionError = "Invalid response from server."; return }
                guard (200...299).contains(httpResponse.statusCode) else {
                    var serverMsg = "Photo upload failed (\(httpResponse.statusCode))."
                    if let d = data, let s = String(data: d, encoding: .utf8), !s.isEmpty { serverMsg += " Details: \(s)" }
                    photoSubmissionError = serverMsg; return
                }
                photosSubmittedSuccessfully = true
                if let responseData = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode(OcrConversationResponse.self, from: responseData) //
                        self.conversationMessages.append(contentsOf: decodedResponse.messages)
                        self.conversationText = ""
                    } catch { self.photoSubmissionError = "Failed to process server response." }
                } else { print("OCR Warning: No data received.") }
            }
        }.resume()
    }

    private func clearConversation() { //
        hideKeyboard()
        conversationMessages.removeAll()
        topic = ""; selectedSituation = ""; showTopicError = false; submissionError = nil
        selectedPhotos = []; conversationImages.removeAll()
        photoSubmissionError = nil; photosSubmittedSuccessfully = false; isSubmittingPhotos = false
        newMessageText = ""; selectedSender = .user
        print("Context cleared.")
    }

    private func removeImage(at index: Int) { //
         guard index >= 0 && index < conversationImages.count else { return }
         conversationImages.remove(at: index)
         print("Removed image at index \(index)")
     }

    private func loadSelectedImages(from items: [PhotosPickerItem]) { //
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

    // Corrected struct name usage here
    private func submitContext() { //
        guard let token = authManager.token else {
            submissionError = "No token available for submission."; return
        }
        let userId = authManager.userId
        let currentConnectionId = connectionManager.currentConnectionId
        hideKeyboard()
        submissionError = nil; showTopicError = false

        // Use the member-level struct SubmitContextPayload
        let payload = SubmitContextPayload( // <-- CORRECTED
            messages: conversationMessages.isEmpty ? nil : conversationMessages.map { SimplifiedMessage(sender: $0.sender.rawValue, text: $0.text) },
            situation: selectedSituation.isEmpty ? nil : selectedSituation,
            topic: topic.isEmpty ? nil : topic,
            userId: userId,
            connectionId: currentConnectionId
        )

        guard let url = URL(string: "https://your.backend/api/generate") else { // Replace with actual URL //
            submissionError = "Invalid backend URL."; return
        }
        guard let encodedPayload = try? JSONEncoder().encode(payload) else {
            submissionError = "Failed to prepare data."; return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = encodedPayload

        isSubmitting = true
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error = error { submissionError = "Network request failed: \(error.localizedDescription)"; return }
                guard let httpResponse = response as? HTTPURLResponse else { submissionError = "Invalid response from server."; return }
                guard (200...299).contains(httpResponse.statusCode) else {
                    var serverMsg = "Server error (\(httpResponse.statusCode))."
                    if let d = data, let s = String(data: d, encoding: .utf8), !s.isEmpty { serverMsg += " Details: \(s)" }
                    submissionError = serverMsg; return
                }
                guard let responseData = data else { submissionError = "No data received from server."; return }

                struct BackendSpursResponse: Decodable { let spurs: [BackendSpurData]? } //
                do {
                    let decodedResponse = try JSONDecoder().decode(BackendSpursResponse.self, from: responseData)
                    if let receivedSpurData = decodedResponse.spurs, !receivedSpurData.isEmpty {
                        spurManager.loadSpurs(backendSpurData: receivedSpurData) //
                    } else { submissionError = "No spurs were generated." }
                } catch { submissionError = "Failed to understand server response for spurs: \(error.localizedDescription)" }
            }
        }.resume()
    }

    private var spurGenerationButton: some View { //
        Button(action: submitContext) {
            ZStack{
                Image("SpurGenerationButton").resizable().scaledToFit() //
                if isSubmitting {
                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5).background(Circle().fill(Color.black.opacity(0.3)))
                }
            }
        }
        .shadow(color: .black.opacity(0.45), radius: 5, x: 4, y: 4) //
        .frame(width: 80, height: 80) //
        .padding(.top, 20) //
        .disabled(isSubmitting) //
    }

    // This struct should be defined at the member level of ContextInputView
    // if it's used by submitContext() when it creates `payload`.
    struct SubmitContextPayload: Codable {
        let messages: [SimplifiedMessage]?
        let situation: String?
        let topic: String?
        let userId: String?
        let connectionId: String?
    }

    struct SimplifiedMessage: Codable { //
        let sender: String
        let text: String
    }

    var clearButtonStyle: some View { Image(systemName: "xmark").padding(10).background(Circle().fill(Color.accent1.opacity(0.8))).foregroundColor(.white).shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1) } //
    var photosPickerStyle: some View { Image(systemName: "photo.on.rectangle.angled").padding(10).background(Circle().fill(Color.accent1.opacity(0.8))).foregroundColor(.white).shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1) } //
    var footerView: some View { VStack(spacing: 2) { Text("we care about protecting your data").font(.footnote).foregroundColor(.secondaryText).opacity(0.6); Link(destination: URL(string: "https://example.com/privacy")!) { Text("learn more here").underline().font(.footnote).foregroundStyle(Color.secondaryText).opacity(0.6) } } } //
}

#if DEBUG
struct ContextInputView_Previews: PreviewProvider {
    static var previews: some View {
        let mockAuthManager = AuthManager() //
        let mockConnectionManager = ConnectionManager() //
        mockConnectionManager.setActiveConnection(connectionId: "conn123", connectionName: "Sarah") //
        let mockSideMenuManager = SideMenuManager() //
        let mockSpurManager = SpurManager() //

        return NavigationView { //
            ContextInputView()
                .environmentObject(mockAuthManager) //
                .environmentObject(mockConnectionManager) //
                .environmentObject(mockSideMenuManager) //
                .environmentObject(mockSpurManager) //
        }
        .onAppear { //
            mockConnectionManager.setActiveConnection(connectionId: "connPreview", connectionName: "Sara") //
        }
    }
}
#endif
