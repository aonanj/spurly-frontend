// ContextInputView.swift
// Spurly
//
// Created by Alex Osterlind on 4/27/25.
// Updated: 4/27/25 (Final Version based on requests)

import SwiftUI
import PhotosUI // Ensure PhotosUI is imported

struct ContextInputView: View {
    // MARK: Access shared AuthManager from the environment
    @EnvironmentObject var authManager: AuthManager

    // MARK: – Context State
    @State private var conversationText: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var conversationImages: [UIImage] = [] // Store loaded UIImages
    @State private var selectedSituation: String = ""
    @State private var quickTopic: String = ""
    @FocusState private var isConversationFocused: Bool
    @FocusState private var isTopicFocused: Bool

    // MARK: – View State
    @State private var isSubmitting: Bool = false
    @State private var submissionError: String? = nil // Holds error message
    @State private var showTopicError: Bool = false
    @State private var navigateToSuggestions: Bool = false // Controls navigation
    // @State private var generatedSpurs: [Spur] = [] // Example: To hold fetched spurs

    // MARK: – View State for Photo OCR
    @State private var isSubmittingPhotos: Bool = false
    @State private var photoSubmissionError: String? = nil
    @State private var photosSubmittedSuccessfully: Bool = false // Optional: Track success

    // MARK: – Configuration
    private let situationOptions = [
        "", "cold intro", "cta setup", "cta response",
        "no response", "reengagement",
        "recovery", "switch subject", "refine"
    ]
    // Using the set directly for efficient lookup
    private let prohibitedTopics: Set<String> = [
        "violence", "self harm", "suicide", "narcotics",
        "drugs", "sexually suggestive", "explicit"
    ]
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
                // Background color
                Color.spurlyPrimaryBackground
                    .ignoresSafeArea()
                    .zIndex(0) // Base layer

                // Background Logo (Requirement 2 - Copied from OnboardingView)
                Image("SpurlyBackgroundBrandColor")
                    .resizable()
                    .scaledToFit()
                    .frame(width: screenWidth * 1.5, height: screenHeight * 1.5)
                    .opacity(0.7)
                    .position(x: screenWidth / 2, y: screenHeight * 0.45)
                    .allowsHitTesting(false) // Make sure it doesn't block taps
                    .zIndex(1) // Above background color

                // Main content VStack layer
                VStack(spacing: 2) { // Reduced overall spacing slightly

                    // Header Row (Menu, Banner, Plus Button aligned horizontally)
                    HStack {
                        // Menu Button
                        Button(action: openSideMenu) {
                            Image("MenuIcon").imageScale(.large)
                                .font(.title2)
                                .foregroundColor(.spurlyPrimaryText)
                                .shadow(
                                    color: .spurlyPrimaryText.opacity(0.5),
                                    radius: 5,
                                    x: 3,
                                    y: 3
                                )
                                .frame(width: 44, height: 44) // Ensure tappable area
                        }

                        Spacer() // Pushes banner to center


                        // Plus Button
                        Button(action: openSideMenu) {
                            Image("AddConnectionIcon").imageScale(.large)
                                .font(.title2)
                                .foregroundColor(.spurlyPrimaryText)
                                .shadow(
                                    color: .spurlyPrimaryText.opacity(0.5),
                                    radius: 5,
                                    x: 3,
                                    y: 3
                                )
                                .frame(width: 44, height: 44) // Ensure tappable area
                        }
                    }.padding(.horizontal)

                    // Banner Image (within the HStack now)
                    Image("SpurlyBannerBrandColor")
                        .resizable()
                        .scaledToFit()
                        .frame(height: screenHeight * 0.1) // Adjust height to fit line
                        .padding(.horizontal)
                        // Minimal top padding, just safe area
                        //.padding(.top, geo.safeAreaInsets.top > 0 ? geo.safeAreaInsets.top : 8) // Add small padding if no safe area


                    // Subtitle Text (Moved below header HStack)
                    Text("less guessing. more connecting.")
                        .font(Font.custom("SF Pro Text", size: 16).weight(.bold))
                        .foregroundColor(.spurlyPrimaryBrand)
                        .shadow(color: .black.opacity(0.55), radius: 4, x: 4, y: 4)
                        .padding(.bottom, 15) // Add slight padding below subtitle

                    Spacer() // Pushes content down
                    // Conversation Input Card with Opacity

                    VStack(spacing: 12) {
                        ZStack {
                            TextEditor(text: $conversationText)
                                .font(.caption)
                                .focused($isConversationFocused)
                                .foregroundColor(.spurlyPrimaryText)
                                .padding(12)
                                .padding(.bottom, 40) // Space for buttons
                                .scrollContentBackground(.hidden) // Needed to make background transparent
                                .background(
                                    Color.white
                                        .opacity(inputBackgroundOpacity) // Apply opacity here
                                )
                                .cornerRadius(12)
                                .frame(minHeight: geo.size.height * 0.25, maxHeight: geo.size.height * 0.45)
                            //.shadow(color: .black.opacity(0.45), radius: 5, x: 4, y: 4)


                            // Image Thumbnails Display
                            if !conversationImages.isEmpty {
                               // ScrollView(.horizontal, showsIndicators: false) {
                                VStack() {
                                    Spacer()
                                    HStack(spacing: 8) {
                                        ForEach(conversationImages.indices, id: \.self) { index in
                                            imageThumbnailView(image: conversationImages[index], index: index)
                                        }
                                        Spacer()
                                    }
                                    .padding(.leading) // Use leading padding to align with card edge
                                }
                                .frame(height: geo.size.height * 0.4)
                             }
                        }
                        // Buttons Area (Clear, and Conditional Picker/Submit)
                        HStack {
                            // Clear Button (remains the same)
                            Button(action: clearConversation) { clearButtonStyle }
                                .disabled(conversationText.isEmpty && conversationImages.isEmpty && selectedPhotos.isEmpty) // Also disable if picker selection is empty

                            Spacer() // Pushes buttons apart

                            // --- Conditional Photo Button ---
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
                                        Text(photosSubmittedSuccessfully ? "Photos Sent" : (isSubmittingPhotos ? "Sending..." : "Send Photos"))
                                            .font(.caption) // Smaller text
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 10)
                                    .background(Capsule().fill(photosSubmittedSuccessfully ? Color.green.opacity(0.7) : Color.spurlyAccent1.opacity(0.8))) // Green on success
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                                }
                                .disabled(isSubmittingPhotos || photosSubmittedSuccessfully) // Disable while submitting or if already successful
                            }
                            // --- End Conditional Photo Button ---
                        }
                        .padding(.horizontal, 15)
                        .padding(.bottom, 10)
                        // Optional: Display photo submission errors nearby
                        if let photoError = photoSubmissionError {
                             Text("Photo Error: \(photoError)")
                                 .font(.caption)
                                 .foregroundColor(.red)
                                 .padding(.horizontal, 15)
                                 .padding(.bottom, 5) // Adjust positioning as needed
                         }
                    } // End ZStack for TextEditor overlay
                    .frame(width: geo.size.width * 0.89, height: geo.size.height * 0.5) // Reduced width to fit card
                    .background(Color.spurlyCardBackground) // Use defined color
                    .opacity(0.75).cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(
                                        colors: [
                                            Color.spurlyCardBackground.opacity(0.6),
                                            Color.spurlyHighlight.opacity(0.8)
                                        ]
                                    ),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 12
                            )
                            .cornerRadius(12)
                    );

                    Spacer()


                    // Situation/Topic + Generate Button Row with Opacity
                    HStack(alignment: .top, spacing: 8) {
                        // Situation Picker & Topic Field Container
                        VStack(alignment: .leading, spacing: 12) {
                            situationPicker(geo: geo) // Use helper view
                            topicField(geo: geo)      // Use helper view
                        }
                        .frame(width: geo.size.width * 0.55) // Keep reduced width

                        Spacer() // Pushes button to the right edge

                        // Generate Spurs Image Button
                        spurGenerationButton // Use helper view

                    } // End HStack for Situation/Topic + Button
                    .padding(.horizontal) // Overall padding for the row
                    .padding(.top, 10) // Add top padding for spacing
                    // Display General Submission Error Message
                    submissionErrorView // Use helper view

                    Spacer(minLength: 25) // Pushes footer down

                    // Footer Text and Link
                    footerView // Use helper view
                    .padding(.bottom, geo.safeAreaInsets.bottom > 0 ? 5 : 15) // Adjust padding based on safe area

                } // Main content VStack
                .zIndex(2) // Above background elements

            } // ZStack Container
            .onTapGesture { hideKeyboard() } // Dismiss keyboard on background tap
            .navigationDestination(isPresented: $navigateToSuggestions) {
                 // Replace with your actual Suggestions View
                 // SuggestionsView(spurs: generatedSpurs) // Example
                 Text("Suggestions View Placeholder") // Placeholder
            }
            .navigationBarHidden(true) // Keep navigation bar hidden if desired
            .ignoresSafeArea(.keyboard) // Keep content visible when keyboard appears
        } // GeometryReader
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

                // TODO: Handle OCR results if the backend returns them in the response
                /*
                 if let responseData = data {
                     // Try to decode OCR results (replace with your actual response model)
                     // struct OcrResponse: Decodable { let results: [String]? }
                     // if let decodedResponse = try? JSONDecoder().decode(OcrResponse.self, from: responseData) {
                     //    print("Received OCR results: \(decodedResponse.results ?? [])")
                     //    // Integrate results into conversationText or elsewhere?
                     // }
                 }
                 */

            }
        }.resume()
    }


    // Helper function to correct image orientation (Important for uploads)
    // Add this function within the ContextInputView struct
     private func imageWithCorrectOrientation(_ image: UIImage) -> UIImage? {
         // Check if orientation is already correct
         guard image.imageOrientation != .up else { return image }

         // Recalculate transform based on orientation
         var transform = CGAffineTransform.identity
         switch image.imageOrientation {
             case .down, .downMirrored:
                 transform = transform.translatedBy(x: image.size.width, y: image.size.height)
                 transform = transform.rotated(by: .pi)
             case .left, .leftMirrored:
                 transform = transform.translatedBy(x: image.size.width, y: 0)
                 transform = transform.rotated(by: .pi / 2)
             case .right, .rightMirrored:
                 transform = transform.translatedBy(x: 0, y: image.size.height)
                 transform = transform.rotated(by: -.pi / 2)
             case .up, .upMirrored:
                 break
             @unknown default:
                 break
         }

         // Apply mirroring if needed
         switch image.imageOrientation {
             case .upMirrored, .downMirrored:
                 transform = transform.translatedBy(x: image.size.width, y: 0)
                 transform = transform.scaledBy(x: -1, y: 1)
             case .leftMirrored, .rightMirrored:
                 transform = transform.translatedBy(x: image.size.height, y: 0)
                 transform = transform.scaledBy(x: -1, y: 1)
             default:
                 break
         }

         // Create context and draw the new image
         guard let cgImage = image.cgImage, let colorSpace = cgImage.colorSpace else { return nil }
         guard let ctx = CGContext(data: nil, width: Int(image.size.width), height: Int(image.size.height),
                                   bitsPerComponent: cgImage.bitsPerComponent, bytesPerRow: 0,
                                   space: colorSpace, bitmapInfo: cgImage.bitmapInfo.rawValue) else { return nil }

         ctx.concatenate(transform)

         switch image.imageOrientation {
             case .left, .leftMirrored, .right, .rightMirrored:
                 ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: image.size.height, height: image.size.width))
             default:
                 ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
         }

         // Get the new image
         guard let cgImg = ctx.makeImage() else { return nil }
         return UIImage(cgImage: cgImg)
     }


    // MARK: – Actions

    private func clearConversation() {
        hideKeyboard()
        conversationText = ""
        selectedPhotos = [] // Clear picker selection
        conversationImages.removeAll() // Clear loaded images
        quickTopic = ""
        selectedSituation = ""
        showTopicError = false
        submissionError = nil
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

        hideKeyboard()
        submissionError = nil // Clear previous errors
        showTopicError = false // Clear topic error

        // 1. Validate Topic
        let lowercasedTopic = quickTopic.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !lowercasedTopic.isEmpty {
             // Check if any part of the input topic contains a prohibited word
             var isProhibited = false
             for prohibited in prohibitedTopics {
                 if lowercasedTopic.contains(prohibited) {
                     isProhibited = true
                     break
                 }
             }
             if isProhibited {
                 showTopicError = true
                 quickTopic = "" // Clear the invalid topic
                 print("Validation Error: Prohibited topic detected.")
                 return // Stop submission
             }
         }


        // 2. Prepare Payload (Add images later if needed)
        struct ContextPayload: Codable {
            let conversation: String?
            let situation: String?
            let topic: String?
            let userId: String?
             // Add image data if your backend expects it
            // let images: [String]? // e.g., base64 encoded strings
        }

        let payload = ContextPayload(
            conversation: conversationText.isEmpty ? nil : conversationText,
            situation: selectedSituation.isEmpty ? nil : selectedSituation,
            topic: lowercasedTopic.isEmpty ? nil : lowercasedTopic, // Send validated topic
            userId: userId,
            // images: encodeImagesIfNeeded(conversationImages) // Example function call
        )

        // --- Replace with your actual backend URL ---
        guard let url = URL(string: "https://your.backend/api/generate") else { // (placeholder URL used)
            submissionError = "Invalid backend URL."
            print("Error: Invalid backend URL configured.")
            return
        }
        // --- ---

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


                // 4. Decode Response (Placeholder)
                // Replace 'BackendResponse' and 'Spur' with your actual data models
                /*
                 do {
                     let decodedResponse = try JSONDecoder().decode(BackendResponse.self, from: responseData)
                     print("Successfully decoded response. Spurs received: \(decodedResponse.spurs.count)")
                     self.generatedSpurs = decodedResponse.spurs // Store the spurs
                     self.navigateToSuggestions = true // Trigger navigation
                     // Optionally clear fields after successful submission
                     // clearConversation()
                 } catch {
                     submissionError = "Failed to understand server response."
                     print("Error: Failed to decode response: \(error)")
                 }
                 */

                // --- Placeholder Success ---
                print("Successfully submitted context (Placeholder Response).")
                // self.generatedSpurs = [] // Set empty spurs for placeholder navigation
                 // TODO: Remove this placeholder navigation once backend response handling is implemented
                 DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Short delay for effect
                     self.navigateToSuggestions = true // Trigger navigation to placeholder
                 }
                 // clearConversation() // Optionally clear fields
                 // --- End Placeholder ---
            }
        }.resume()
    }

    // MARK: – Placeholder Actions (Implement these based on your app structure)

    private func openSideMenu() {
        hideKeyboard()
        print("Action: Open Side Menu (Not Implemented)")
        // TODO: Implement side menu presentation logic
    }

    private func showPOISketch() {
        hideKeyboard()
        print("Action: Show POI Sketch (Not Implemented)")
        // TODO: Implement POI sketch presentation logic
    }

    // Helper to dismiss keyboard (using extension from OnboardingView)
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Helper Button Styles (for cleaner overlay code)

    private var clearButtonStyle: some View {
         Image(systemName: "xmark")
             .padding(10)
             .background(Circle().fill(Color.spurlyAccent1.opacity(0.8)))
             .foregroundColor(.white)
             .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
     }

     private var photosPickerStyle: some View {
          Image(systemName: "photo.on.rectangle.angled")
              .padding(10)
              .background(Circle().fill(Color.spurlyAccent1.opacity(0.8)))
              .foregroundColor(.white)
              .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
      }

    // MARK: - Helper Image Thumbnail View

    private func imageThumbnailView(image: UIImage, index: Int) -> some View {
         Image(uiImage: image)
             .resizable().scaledToFill().frame(width: 60, height: 60)
             .clipped().cornerRadius(8)
             .shadow(color: .black.opacity(0.1), radius: 2, x: 1, y: 1)
             .overlay(alignment: .topTrailing) {
                 Button { removeImage(at: index) } label: {
                     Image(systemName: "xmark.circle.fill")
                         .foregroundColor(.spurlyAccent2.opacity(0.9))
                         .background(Circle().fill(.white.opacity(0.7)))
                         .font(.callout)
                 }.padding(4)
             }
     }

     // MARK: - Helper Footer View

     private var footerView: some View {
          VStack(spacing: 2) {
               Text("we care about protecting your data")
                   .font(.footnote).foregroundColor(.spurlySecondaryText).opacity(0.6)
               // Ensure you have a valid URL here
               Link(destination: URL(string: "https://example.com/privacy")!) {
                   Text("learn more here")
                       .underline().font(.footnote)
                       .foregroundStyle(Color.spurlySecondaryText).opacity(0.6)
               }
           }
           .frame(maxWidth: .infinity)
     }

     // MARK: - Helper Submission Error View

     @ViewBuilder
      private var submissionErrorView: some View {
           if let errorMsg = submissionError {
                Text("Error: \(errorMsg)")
                    .font(.caption).foregroundColor(.red).padding(.horizontal).multilineTextAlignment(.center)
            } else {
                EmptyView()
            }
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

      // MARK: - Helper Picker/Topic Input Fields

      // Extracted Situation Picker into a helper function
      @ViewBuilder
      private func situationPicker(geo: GeometryProxy) -> some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("situation")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.spurlySecondaryText)
                CustomPickerStyle(
                    title: "Select situation", selection: $selectedSituation,
                    options: situationOptions, textMapping: { $0.isEmpty ? "Select..." : $0 }
                )
                .opacity(inputBackgroundOpacity + 0.05) // Apply opacity
            }
      }

      // Extracted Topic Field into a helper function
      @ViewBuilder
      private func topicField(geo: GeometryProxy) -> some View {
            VStack(alignment: .leading, spacing: 4) {
                Text("topic").font(.subheadline).bold().foregroundColor(.spurlySecondaryText)
                TextField("add topic...", text: $quickTopic)
                    .focused($isTopicFocused)
                    .textFieldStyle(CustomTextFieldStyle()) // Assumes this style exists
                    .limitInputLength(for: $quickTopic, limit: 50) // Assumes this modifier exists
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(showTopicError ? Color.red : Color.clear, lineWidth: 1.5))
                    .onChange(of: quickTopic) { _, _ in showTopicError = false }
                    .opacity(inputBackgroundOpacity + 0.05) // Apply opacity

                // Display Topic Error Message inline
                if showTopicError {
                    Text("Topic not allowed.")
                        .font(.caption).foregroundColor(.red).padding(.leading, 4)
                }
            }
      }


} // End Struct ContextInputView



// MARK: - Preview

// MARK: - Preview Provider Update
#if DEBUG
struct ContextInputView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            // Remove initializer arguments and inject a dummy AuthManager environment object
            ContextInputView()
                .environmentObject(AuthManager(userId: "previewUser123", token: "previewTokenAbc")) // Add this
        }
    }
}
#endif
