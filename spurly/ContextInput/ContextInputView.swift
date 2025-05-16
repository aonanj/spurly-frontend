// ContextInputView.swift
// Spurly
//
// Created by Alex Osterlind on 4/27/25.
// Updated: 4/27/25 (Final Version based on requests)

import SwiftUI
import PhotosUI // Ensure PhotosUI is imported

enum ContextInputMode: String, CaseIterable, Identifiable {
    case photos = "Photos"
    case text = "Text"
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
    @State private var conversationImages: [UIImage] = [] // Store loaded UIImages
    @State var selectedSituation: String = ""
    @State var topic: String = ""
    @FocusState private var isConversationFocused: Bool
    @FocusState var isTopicFocused: Bool

    // MARK: – View State
    @State private var isSubmitting: Bool = false
    @State var submissionError: String? = nil // Holds error message
    @State var showTopicError: Bool = false
    @State private var navigateToSuggestions: Bool = false // Controls navigation
    // @State private var generatedSpurs: [Spur] = [] // Example: To hold fetched spurs

    // MARK: - State for Input Mode
    @State private var inputMode: ContextInputMode = .photos // Default to photos

    // MARK: - State for Text Input
    @State private var newMessageText: String = ""
    @State private var selectedSender: MessageSender = .user // Default sender

    // MARK: – View State for Photo OCR
    @State private var isSubmittingPhotos: Bool = false
    @State private var photoSubmissionError: String? = nil {
        didSet {
            if photoSubmissionError != nil {
                showingPhotoErrorAlert = true
            }
        }
    }
    @State private var photosSubmittedSuccessfully: Bool = false // Optional: Track success
    @State private var showingPhotoErrorAlert: Bool = false
    @State private var conversationMessages: [ConversationMessage] = []
    @State private var editingMessageId: UUID? = nil
    @State private var messageTextBeingEdited: String = ""

    private var editingMessageBinding: Binding<ConversationMessage>? {
        guard let id = editingMessageId,
              let index = conversationMessages.firstIndex(where: { $0.id == id })
        else { return nil }
        return $conversationMessages[index]
    }
    // Assume a structure for the spurs received from the backend
    // struct Spur: Decodable, Identifiable { /* ... properties ... */ let id = UUID() }
    // struct BackendResponse: Decodable { let spurs: [Spur] }

    // Access screen dimensions for layout
    let screenHeight = UIScreen.main.bounds.height
    let screenWidth = UIScreen.main.bounds.width

    // Define opacity level for input backgrounds
    private let inputBackgroundOpacity: Double = 0.9 // Adjust as needed (0.0 to 1.0)


    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.tappablePrimaryBg
                    .zIndex(0) // Background color layer

                Image.tappableBgIcon
                    .frame(width: screenWidth * 1.5, height: screenHeight * 1.5)
                    .position(x: screenWidth / 2, y: screenHeight * 0.43)
                    .allowsHitTesting(false) // Make sure it doesn't block taps
                    .zIndex(1) // Above background color

                // Main content VStack layer
                VStack(spacing: 2) { // Reduced overall spacing slightly

                    // Header Row (Menu, Banner, Plus Button aligned horizontally)
                    HStack {
                        // Menu Button
                        Button(
                            action: dummyFunction // MARK: Replace with sideMenuManager.openSideMenu
                        ) {
                            Image.menuIcon
                                .frame(width: 44, height: 44) // Ensure tappable area
                        }

                        Spacer() // Pushes banner to center


                        // --- Dynamic Connection Display ---
                        if let connectionName = connectionManager.currentConnectionName, connectionManager.currentConnectionId != nil {
                            Spacer()
                            HStack(spacing: 6) {
                                Text(connectionName)
                                    .font(.caption) // Or your desired font
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primaryBg)
                                    .lineLimit(1)
                                    .padding(.trailing, 2)


                                Button(action: {
                                    connectionManager.clearActiveConnection()
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(
                                            .primaryBg.opacity(0.7)
                                        ) // Or your desired color
                                        .imageScale(.medium)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(
                                Capsule().fill(Color.primaryText.opacity(0.9))
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.9))) // Animation
                            .frame(width: 100, height: 44) // Constrain width
                            .shadow(
                                color: .primaryText.opacity(0.5),
                                radius: 5,
                                x: 3,
                                y: 3
                            )

                        } else {
                            Button(action: {
                                connectionManager.addNewConnection()
                            }) {
                                Image.connectionIcon // Your existing add connection icon
                                    .frame(width: 44, height: 44)
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.9))) // Animation
                        }
                        // --- End Dynamic Connection Display ---
                    }
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.2), value: connectionManager.currentConnectionId) // Animate changes
                    // --- END MODIFIED HEADER ---

                    // Banner Image (within the HStack now)
                    Image.bannerLogo
                        .frame(height: screenHeight * 0.1) // Adjust height to fit line
                        .padding(.horizontal)
                    // Minimal top padding, just safe area
                    //.padding(.top, geo.safeAreaInsets.top > 0 ? geo.safeAreaInsets.top : 8) // Add small padding if no safe area


                    // Subtitle Text (Moved below header HStack)
                    Text.bannerTag
                        .padding(.bottom, 15) // Add slight padding below subtitle

                    Spacer() // Pushes content down
                             // Conversation Input Card with Opacity

                    VStack(spacing: 8) {
                        // --- NEW: Input Mode Picker ---
                        Picker("Input Mode", selection: $inputMode) {
                            ForEach(ContextInputMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                                //.font(.caption)
                            }
                        }
                        .pickerStyle(.segmented)
                        .scaleEffect(0.85) // Slightly smaller picker
                        .padding(.horizontal, geo.size.width * 0.1) // Adjust padding to match card width
                        .padding(.top, 8) // Add top padding for spacing
                        .onChange(of: inputMode) { _, _ in
                            conversationMessages.removeAll()
                            conversationImages.removeAll()
                            selectedPhotos.removeAll() // Clear picker selection
                            newMessageText = ""         // Clear manual input field
                            photoSubmissionError = nil  // Clear photo errors
                            photosSubmittedSuccessfully = false // Reset photo success state
                            conversationText = ""
                        }

                        ZStack {
                            ScrollViewReader { proxy in // Optional: Allows scrolling to specific messages
                                ScrollView {
                                    VStack(alignment: .leading, spacing: 8) { // Use VStack for messages
                                        ForEach($conversationMessages) { $message in // Use binding ($)
                                            MessageRow(message: $message) // Pass binding to row
                                                .padding(.horizontal, 10)
                                                .background( // Subtle background highlight for selection
                                                    (editingMessageId == message.id) ? Color.yellow.opacity(0.3) : Color.clear
                                                )
                                                .cornerRadius(6)
                                                .onTapGesture {
                                                    // When tapped, set the ID and load text for editing
                                                    editingMessageId = message.id
                                                    messageTextBeingEdited = message.text // Load current text
                                                }
                                                .id(message.id) // Assign ID for ScrollViewReader
                                        }
                                    }
                                    //.padding(.vertical) // Add some padding inside ScrollView
                                } // End ScrollView
                                .onChange(of: conversationMessages.count) {
                                    _,
                                    _ in
                                    if let lastMessageId = conversationMessages.last?.id {
                                        withAnimation {
                                            proxy.scrollTo(lastMessageId, anchor: .bottom) // Scroll to the last message

                                        }
                                    }
                                }
                            } // End ScrollViewReader
                            .background(Color.white.opacity(inputBackgroundOpacity)) // Background for the list area
                            .cornerRadius(12)
                            .frame(minHeight: geo.size.height * (inputMode == .text ? 0.15 : 0.25), maxHeight: geo.size.height * (inputMode == .text ? 0.28 : 0.45))
                            .sheet(isPresented: Binding<Bool>(
                                get: { editingMessageId != nil },
                                set: { if !$0 { editingMessageId = nil } }
                            )) {
                                // Pass necessary data/bindings to the EditMessageView
                                if let messageBinding = editingMessageBinding {
                                    EditMessageView(
                                        message: messageBinding, // Pass the binding to the message
                                        onSave: { updatedText in
                                            // Find the message and update its text
                                            if let index = conversationMessages.firstIndex(where: { $0.id == editingMessageId }) {
                                                conversationMessages[index].text = updatedText
                                            }
                                            editingMessageId = nil // Dismiss sheet
                                        },
                                        onCancel: {
                                            editingMessageId = nil // Dismiss sheet
                                        }
                                    )
                                } else {
                                    // Fallback view or handle error if binding is unexpectedly nil
                                    Text("Error loading message for editing.")
                                }
                            }
                            //.shadow(color: .black.opacity(0.45), radius: 5, x: 4, y: 4)

                        }
                        Group {
                             if inputMode == .text {
                                 ManualTextInputView(newMessageText: $newMessageText, selectedSender: $selectedSender, addMessageAction: addManualMessage)
                                 .padding(.horizontal, 10).transition(.opacity.combined(with: .move(edge: .bottom)))
                             } else if !conversationImages.isEmpty {
                                 ScrollView(.horizontal, showsIndicators: false) {
                                     HStack(spacing: 8) {
                                         ForEach(conversationImages.indices, id: \.self) { index in
                                             ImageThumbnailView(image: conversationImages[index]) {
                                                 removeImage(at: index)
                                             }
                                         }
                                         Spacer()
                                     }
                                 }
                                 .frame(height: 60).transition(.opacity.combined(with: .move(edge: .bottom)))
                             }
                         }
                         .padding(.bottom, (inputMode == .photos && conversationImages.isEmpty) ? 0 : 5)


                        // Buttons Area (Clear, and Conditional Picker/Submit)
                        HStack {
                            // Clear Button (remains the same)
                            Button(action: clearConversation) { clearButtonStyle }
                                .disabled(
                                    conversationMessages.isEmpty &&    // Check the message array
                                    conversationImages.isEmpty &&    // Check loaded images (for photo mode)
                                    selectedPhotos.isEmpty &&        // Check photo picker items (for photo mode)
                                    newMessageText.isEmpty          // Check text input field (for text mode)
                                )

                            Spacer() // Pushes buttons apart

                            // --- Conditional Photo Button ---
                            if inputMode == .photos {
                                if conversationImages.isEmpty {
                                    // Show PhotosPicker if no images are loaded yet
                                    PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 5, matching: .images) {
                                        photosPickerStyle // Use your existing helper
                                    }
                                    .onChange(of: selectedPhotos) { _, newItems in
                                        // Clear previous errors/success when new photos are chosen
                                        photoSubmissionError = nil
                                        photosSubmittedSuccessfully = false
                                        loadSelectedImages(from: newItems)
                                    }
                                    .disabled(isSubmittingPhotos) // Disable while submitting photos
                                    .transition(.opacity)

                                } else {
                                    // Show Submit Photos Button if images are loaded
                                    Button(action: submitPhotosForOCR) {
                                        HStack {
                                            // Optionally show ProgressView when submitting photos
                                            if isSubmittingPhotos {
                                                ProgressView()
                                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                    .scaleEffect(0.8) // Smaller progress view
                                            }
                                            // Change icon/text based on state
                                            Image(systemName: photosSubmittedSuccessfully ? "checkmark.circle.fill" : "arrow.up.doc.on.clipboard")
                                            Text(photosSubmittedSuccessfully ? "pics sent" : (isSubmittingPhotos ? "..." : "send pics"))
                                                .font(.caption) // Smaller text
                                                .lineLimit(1)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                        .background(Capsule().fill(photosSubmittedSuccessfully ? Color.green.opacity(0.7) : Color.accent1.opacity(0.8))) // Green on success
                                        .foregroundColor(.white)
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                                    }
                                    .disabled(isSubmittingPhotos || photosSubmittedSuccessfully) // Disable while submitting or if already successful
                                    .transition(.opacity)

                                }
                            }
                            // --- End Conditional Photo Button ---
                        }
                        .padding(.horizontal, 15)
                        .padding(.bottom, 10)

                    } // End ZStack for TextEditor overlay
                    .frame(width: geo.size.width * 0.89, height: geo.size.height * 0.5) // Reduced width to fit card
                    .background(Color.cardBg) // Use defined color
                    .opacity(0.75).cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(
                                        colors: [
                                            Color.cardBg.opacity(0.6),
                                            Color.highlight.opacity(0.8)
                                        ]
                                    ),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 12
                            )
                            .cornerRadius(12)
                    )
                    .animation(.easeInOut, value: inputMode) // Smooth transition for background opacity
                    .animation(
                        .easeInOut,
                        value: conversationMessages.isEmpty
                    ) // Smooth transition for message updates
                    Spacer()


                    // Situation/Topic + Generate Button Row with Opacity
                    HStack(alignment: .top, spacing: 8) {
                        // Situation Picker & Topic Field Container
                        VStack(alignment: .leading, spacing: 12) {
                            SituationPicker(
                                selectedSituation: $selectedSituation
                            ) // Use helper view
                            TopicFieldView(
                                topic: $topic,
                                showTopicError: $showTopicError,
                                isTopicFocused: $isTopicFocused,
                            )      // Use helper view
                        }
                        .frame(width: geo.size.width * 0.55) // Keep reduced width

                        Spacer() // Pushes button to the right edge

                        // Generate Spurs Image Button
                        spurGenerationButton // Use helper view

                    } // End HStack for Situation/Topic + Button
                    .padding(.horizontal) // Overall padding for the row
                    .padding(.top, 10) // Add top padding for spacing
                                       // Display General Submission Error Message
                    SubmissionErrorView (
                        submissionError: $submissionError
                    ) // Use helper view

                    Spacer(minLength: 25) // Pushes footer down

                    // Footer Text and Link
                    footerView // Use helper view
                        .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? 5 : 15) // Adjust padding based on safe area
                        .frame(maxWidth: .infinity)

                } // Main content VStack
                .zIndex(2) // Above background elements

            } // ZStack Container
              //.onTapGesture { hideKeyboard() } // Dismiss keyboard on background tap
            .alert("Photo Error", isPresented: $showingPhotoErrorAlert, presenting: photoSubmissionError) { errorDetail in
                Button("OK") {
                    photoSubmissionError = nil
                }
            } message: { errorDetail in
                Text(errorDetail) // The photoSubmissionError string will be the message
            }
            .sheet(isPresented: $connectionManager.isNewConnectionOpen) { // Binding to the manager's state
                AddConnectionView()
                    .environmentObject(authManager)
                    .environmentObject(connectionManager)

            }
            .sheet(isPresented: $spurManager.showSpursView) {
                SpursView()
                    .environmentObject(spurManager)
                    .environmentObject(authManager)
                    .environmentObject(connectionManager)
            }

        } // GeometryReader
        .navigationBarHidden(true) // Keep navigation bar hidden if desired
        .ignoresSafeArea(.keyboard) // Keep content visible when keyboard appears
    }

    // MARK: – DUMMY FUNCTION
    // Environment Objects are not available in previews, so we need to provide dummy values
    private func dummyFunction() {
        // This function is just a placeholder to avoid errors in previews
    }

    // MARK: - NEW: Action for Manual Text Input
    private func addManualMessage() {
        let trimmedText = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }

        let newMessage = ConversationMessage(sender: selectedSender, text: trimmedText)
        conversationMessages.append(newMessage)
        newMessageText = "" // Clear input field
        selectedSender = .user // Reset sender potentially
        print("Added manual message: \(newMessage.text) from \(newMessage.sender.rawValue)")
    }

    // MARK: - Action for Photo OCR Submission
    private func submitPhotosForOCR() {
        guard let token = authManager.token else {
            print("Error: No token available for photo submission.")
            photoSubmissionError = "No token available for photo submission."
            return
        }

        let userId = authManager.userId // Get userId from AuthManager

        guard !conversationImages.isEmpty else {
            print("No images to submit for OCR.")
            return
        }

        hideKeyboard()
        photoSubmissionError = nil // Clear previous errors
        isSubmittingPhotos = true // Show loading state
        photosSubmittedSuccessfully = false // Reset success state

        print("Preparing \(conversationImages.count) images for OCR submission...")

        // 1. Prepare Image Data (Example: JPEG base64 encoding)
        // Adjust compression quality as needed. Consider file size limits.
        let imageDatas: [String] = conversationImages.compactMap { image in
            // Ensure orientation is correct before getting data
            guard let orientedImage = imageWithCorrectOrientation(image),
                  let imageData = orientedImage.jpegData(compressionQuality: 0.7) else {
                print("Warning: Could not process one of the images.")
                return nil
            }
            return imageData.base64EncodedString()
        }

        guard !imageDatas.isEmpty else {
            photoSubmissionError = "Could not process images for upload."
            isSubmittingPhotos = false
            return
        }

        // 2. Prepare Payload
        struct OcrPayload: Codable {
            let images: [String] // Array of base64 encoded image strings
            let userId: String?
        }
        let payload = OcrPayload(images: imageDatas, userId: userId)

        // 3. Network Request
        // --- Replace with your actual OCR backend URL ---
        guard let url = URL(string: "https://your.backend/api/ocr") else { // (placeholder URL)
            photoSubmissionError = "Invalid OCR backend URL."
            isSubmittingPhotos = false
            print("Error: Invalid OCR backend URL configured.")
            return
        }
        // --- ---

        guard let encodedPayload = try? JSONEncoder().encode(payload) else {
            photoSubmissionError = "Failed to prepare photo data."
            isSubmittingPhotos = false
            print("Error: Failed to encode OCR payload.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = encodedPayload

        print("Submitting photos to OCR backend...")

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Ensure UI updates happen on the main thread
            DispatchQueue.main.async {
                isSubmittingPhotos = false // Stop loading indicator

                // Handle Network Error
                if let error = error {
                    photoSubmissionError = "Network error: \(error.localizedDescription)"
                    print("OCR Network Error: \(error.localizedDescription)")
                    return
                }

                // Check HTTP Response Status
                guard let httpResponse = response as? HTTPURLResponse else {
                     photoSubmissionError = "Invalid response from server."
                     print("OCR Error: No valid HTTPURLResponse received.")
                     return
                 }

                 print("OCR Received HTTP Status: \(httpResponse.statusCode)")

                 guard (200...299).contains(httpResponse.statusCode) else {
                    var serverMsg = "Photo upload failed (\(httpResponse.statusCode))."
                     if let responseData = data, let errorString = String(data: responseData, encoding: .utf8), !errorString.isEmpty {
                         serverMsg += " Details: \(errorString)"
                     }
                    photoSubmissionError = serverMsg
                    print("OCR Error: \(serverMsg)")
                    return
                }

                // --- SUCCESS ---
                print("Photos submitted successfully for OCR.")
                photosSubmittedSuccessfully = true // Set success state
                // Optionally clear photos after successful submission?
                // self.conversationImages = []
                // self.selectedPhotos = []

                if let responseData = data {
                    do {
                        // Decode the JSON response using the new structure
                        let decodedResponse = try JSONDecoder().decode(OcrConversationResponse.self, from: responseData)

                        // Update the conversationMessages state variable on the main thread
                        // You might want to append or replace based on your logic
                        self.conversationMessages.append(contentsOf: decodedResponse.messages)
                        print("Successfully decoded OCR response with \(decodedResponse.messages.count) messages.")

                        // **IMPORTANT**: Clear the old plain text editor content if needed
                        self.conversationText = "" // Clear the old state variable

                    } catch {
                        // Handle potential JSON decoding errors
                        print("OCR Error: Failed to decode conversation response: \(error)")
                        self.photoSubmissionError = "Failed to process server response."
                    }
                } else {
                    print("OCR Warning: No data received in the response, cannot extract messages.")
                    // self.photoSubmissionError = "No message data received from server."
                }

            }
        }.resume()
    }


     // MARK: – Actions

    private func clearConversation() {
        hideKeyboard()
        // Clear common states
        conversationMessages.removeAll() // *** Clear the messages array ***
        topic = ""
        selectedSituation = ""
        showTopicError = false
        submissionError = nil

        // Clear photo-specific states
        selectedPhotos = []
        conversationImages.removeAll()
        photoSubmissionError = nil
        photosSubmittedSuccessfully = false
        isSubmittingPhotos = false

        // Clear text-specific states
        newMessageText = ""
        selectedSender = .user

        // Reset input mode if desired (optional)
        // inputMode = .photos

        print("Context cleared.")
    }

    private func removeImage(at index: Int) {
         guard index >= 0 && index < conversationImages.count else { return }
         conversationImages.remove(at: index)
         // If you need to sync back to selectedPhotos (PhotosPickerItem), it's more complex.
         // For simplicity, this just removes the displayed UIImage.
         print("Removed image at index \(index)")
     }


    private func loadSelectedImages(from items: [PhotosPickerItem]) {
        // Reset images array before loading new ones
        self.conversationImages = []
        print("Starting to load \(items.count) images...")

        // Use a Task to perform the asynchronous loading off the main thread
        Task {
            var loadedImages: [UIImage] = [] // Temporary array to hold images loaded in this batch

            // Use a TaskGroup to manage concurrent image loading
            await withTaskGroup(of: UIImage?.self) { group in
                for item in items {
                    // Add a child task to the group for each item
                    group.addTask {
                        do {
                            // Attempt to load data
                            guard let data = try await item.loadTransferable(type: Data.self) else {
                                print("No data loaded from PhotosPickerItem.")
                                return nil // Return nil if no data
                            }
                            // Attempt to create UIImage
                            guard let uiImage = UIImage(data: data) else {
                                print("Failed to create UIImage from data.")
                                return nil // Return nil if image creation fails
                            }
                            // Return the loaded image
                            return uiImage
                        } catch {
                            print("Error loading image: \(error.localizedDescription)")
                            return nil // Return nil on error
                        }
                    }
                }

                // Iterate through the results as they complete
                for await resultImage in group {
                    if let image = resultImage {
                        // Append successfully loaded images to the temporary array
                         // Optional: Add limit check here if desired
                         if loadedImages.count < 5 {
                              loadedImages.append(image)
                         } else {
                             print("Image limit reached during loading, skipping further appends.")
                         }
                    }
                }
            } // TaskGroup finishes here, all child tasks are complete

            // Update the main state variable on the main thread *after* the group finishes
            await MainActor.run {
                self.conversationImages = loadedImages // Assign the successfully loaded images
                print("Finished loading images. Total loaded: \(self.conversationImages.count)")
                // Any other UI updates after all images are processed
            }
        }
    }



    private func submitContext() {
        guard let token = authManager.token else {
            print("Error: No token available for submission.")
            submissionError = "No token available for submission."
            return
        }

        let userId = authManager.userId // Get userId from AuthManager
        let currentConnectionId = connectionManager.currentConnectionId

        hideKeyboard()
        submissionError = nil // Clear previous errors
        showTopicError = false // Clear topic error



        // 2. Prepare Payload (Add images later if needed)
        struct ContextPayload: Codable {
//            let conversation: String?
            let messages: [SimplifiedMessage]? // New way
            let situation: String?
            let topic: String?
            let userId: String?
            let connectionId: String?
             // Add image data if your backend expects it
            // let images: [String]? // e.g., base64 encoded strings
        }

        let payload = ContextPayload(
            // messages: conversationMessages.isEmpty ? nil : conversationMessages, // Send the array
            messages: conversationMessages.isEmpty ? nil : conversationMessages.map { SimplifiedMessage(sender: $0.sender.rawValue, text: $0.text) }, // Or simplified if needed
            situation: selectedSituation.isEmpty ? nil : selectedSituation,
            topic: topic.isEmpty ? nil : topic,
            userId: userId,
            connectionId: currentConnectionId
            // images: encodeImagesIfNeeded(conversationImages) // Example function call
        )

        // --- Example using Option 2 (Converting back to string) ---
        /*
        let conversationString = conversationMessages.map { "\($0.sender.rawValue): \($0.text)" }.joined(separator: "\n")
        struct ContextPayload: Codable {
            let conversation: String?
            // ... other fields ...
        }
        let payload = ContextPayload(
            conversation: conversationString.isEmpty ? nil : conversationString,
            // ... other fields ...
        )
         */
        // --- End Example ---

        // --- Replace with your actual backend URL ---
        guard let url = URL(string: "https://your.backend/api/generate") else { // (placeholder URL used)
            submissionError = "Invalid backend URL."
            print("Error: Invalid backend URL configured.")
            return
        }
        // --- ---

        // Encoder needs to handle ConversationMessage or SimplifiedMessage if using Option 1
        guard let encodedPayload = try? JSONEncoder().encode(payload) else {
            submissionError = "Failed to prepare data."
            print("Error: Failed to encode payload.")
            return
        }

        // 3. Network Request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add Authentication headers if needed (e.g., using the token from onboarding)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.httpBody = encodedPayload

        isSubmitting = true // Start loading indicator
        print("Submitting context to backend...")

        URLSession.shared.dataTask(with: request) { data, response, error in
            // Ensure UI updates happen on the main thread
            DispatchQueue.main.async {
                isSubmitting = false // Stop loading indicator regardless of outcome

                // Handle Network Error
                if let error = error {
                    submissionError = "Network request failed: \(error.localizedDescription)"
                    print("Network Error: \(error.localizedDescription)")
                    return
                }

                // Check HTTP Response Status
                guard let httpResponse = response as? HTTPURLResponse else {
                     submissionError = "Invalid response from server."
                     print("Error: No valid HTTPURLResponse received.")
                     return
                 }

                 print("Received HTTP Status: \(httpResponse.statusCode)")

                 guard (200...299).contains(httpResponse.statusCode) else {
                    var serverMsg = "Server error (\(httpResponse.statusCode))."
                     if let responseData = data, let errorString = String(data: responseData, encoding: .utf8), !errorString.isEmpty {
                         serverMsg += " Details: \(errorString)"
                         print("Server Error Response Body: \(errorString)")
                     }
                    submissionError = serverMsg
                    print("Error: \(serverMsg)")
                    return
                }

                // Check for Data
                 guard let responseData = data else {
                     submissionError = "No data received from server."
                     print("Error: No data received in response.")
                     return
                 }

                struct BackendSpursResponse: Decodable {
                    let spurs: [BackendSpurData]? // Array of spur objects
                }

                do {
                    let decodedResponse = try JSONDecoder().decode(BackendSpursResponse.self, from: responseData)
                    print("Successfully decoded response.")

                    if let receivedSpurData = decodedResponse.spurs, !receivedSpurData.isEmpty {
                        // Pass the array of BackendSpurData to the manager
                        spurManager.loadSpurs(backendSpurData: receivedSpurData)
                    } else {
                        print("No spurs found in the response or response format incorrect.")
                        submissionError = "No spurs were generated."
                    }
                } catch {
                    submissionError = "Failed to understand server response for spurs: \(error.localizedDescription)"
                    print("Error: Failed to decode spurs response: \(error)")
                }
            }
        }.resume()
    }

      // MARK: - Helper Spur Generation Button

      private var spurGenerationButton: some View {
          Button(action: submitContext) {
               ZStack {
                   Image("SpurGenerationButton")
                       .resizable().scaledToFit()
                   if isSubmitting {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5).background(Circle().fill(Color.black.opacity(0.3)))
                    }
               }
          }.shadow(color: .black.opacity(0.45), radius: 5, x: 4, y: 4)
          .frame(width: 80, height: 80)
          .padding(.top, 20)
          .disabled(isSubmitting)// || (conversationText.isEmpty && conversationImages.isEmpty))
      }

    // MARK: - NEW Helper Struct for Simplified Submission (Optional)
    // Use this if your backend expects simpler sender strings instead of the enum
    struct SimplifiedMessage: Codable {
        let sender: String // "User" or "Connection"
        let text: String
    }


} // End Struct ContextInputView

// MARK: - Preview
#if DEBUG
struct ContextInputView_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock managers for the preview
        let mockAuthManager = AuthManager(userId: "previewUser", token: "previewToken")
        let mockConnectionManager = ConnectionManager()
        // Example: Simulate an active connection for one of the previews
        mockConnectionManager
            .setActiveConnection(
                connectionId: "conn123",
                connectionName: "Sarah"
            )

        let mockSideMenuManager = SideMenuManager()
        let mockSpurManager = SpurManager()

        return NavigationView {
            ContextInputView()
                .environmentObject(mockAuthManager)
                .environmentObject(mockConnectionManager)
                .environmentObject(mockSideMenuManager)
                .environmentObject(mockSpurManager)
        }
        .onAppear {
            // You can set an active connection here if you want to test that state specifically
            mockConnectionManager.setActiveConnection(connectionId: "connPreview", connectionName: "Sara")
        }
    }
}
#endif
