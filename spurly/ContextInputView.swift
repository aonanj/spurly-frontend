// ContextInputView.swift
// Spurly
//
// Created by Alex Osterlind on 4/27/25.
//

import SwiftUI
import PhotosUI

struct ContextInputView: View {
    // MARK: – Context State
    @State private var conversationText: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var conversationImages: [UIImage] = []
    @State private var selectedSituation: String = ""
    @State private var quickTopic: String = ""
    @State private var showTopicError: Bool = false
    @FocusState private var isConversationFocused: Bool
    @FocusState private var isTopicFocused: Bool

    // MARK: – Configuration
    private let situationOptions = [
        "", "Cold Open", "CTA Setup", "CTA Response",
        "Follow-Up After No Response", "Re-Engagement",
        "Recovery", "Topic Pivot", "Message Refinement"
    ]
    private let prohibitedTopics: Set<String> = [
        "violence", "self harm", "suicide", "narcotics",
        "drugs", "sexually suggestive", "explicit"
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.spurlyPrimaryBackground
                    .ignoresSafeArea()
                    .onTapGesture { hideKeyboard() }

                VStack(spacing: 16) {
                    // Top bar with Menu & POI buttons
                    HStack {
                        Button(action: openSideMenu) {
                            Image(systemName: "line.horizontal.3")
                                .font(.title2)
                                .foregroundColor(.spurlyPrimaryText)
                        }
                        Spacer()
                        Text("Conversation")
                            .font(.headline)
                            .foregroundColor(.spurlyPrimaryText)
                        Spacer()
                        Button(action: showPOISketch) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.spurlyPrimaryText)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, geo.safeAreaInsets.top + 8)

                    // Conversation card
                    VStack(spacing: 0) {
                        TextEditor(text: $conversationText)
                            .focused($isConversationFocused)
                            .padding(12)
                            .frame(minHeight: geo.size.height * 0.3)
                            .background(Color.spurlyCardBackground)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)

                        HStack {
                            // Clear button
                            Button(action: clearConversation) {
                                Image(systemName: "xmark")
                                    .padding(10)
                                    .background(Circle().fill(Color.spurlyAccent2.opacity(0.7)))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            // Upload button
                            PhotosPicker(
                                selection: $selectedPhotos,
                                maxSelectionCount: 5,
                                matching: .images
                            ) {
                                Image(systemName: "arrow.up.doc")
                                    .padding(10)
                                    .background(Circle().fill(Color.spurlyAccent1.opacity(0.7)))
                                    .foregroundColor(.white)
                            }
                            .onChange(of: selectedPhotos) { _ in loadSelectedImages() }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                    }
                    .padding(.horizontal)

                    // Thumbnails of uploaded screenshots
                    if !conversationImages.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(conversationImages, id: \.self) { img in
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .cornerRadius(8)
                                        .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Situation picker & topic field
                    VStack(alignment: .leading, spacing: 8) {
                        // Situation
                        Text("situation (optional)")
                            .font(.subheadline)
                            .foregroundColor(.spurlySecondaryText)
                        CustomPickerStyle(
                            title: "Select situation",
                            selection: $selectedSituation,
                            options: situationOptions,
                            textMapping: { $0 }
                        )
                        // Topic
                        Text("topic (optional)")
                            .font(.subheadline)
                            .foregroundColor(.spurlySecondaryText)
                        TextField(
                            "add a quick topic…",
                            text: $quickTopic
                        )
                        .focused($isTopicFocused)
                        .textFieldStyle(CustomTextFieldStyle())
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(showTopicError ? Color.red : Color.clear, lineWidth: 1)
                        )
                        .onChange(of: quickTopic) { _ in showTopicError = false }

                        if showTopicError {
                            Text("topic cannot be used")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Submit button
                    Button(action: submitContext) {
                        HStack {
                            Text("Generate Spurs")
                                .fontWeight(.bold)
                            Image(systemName: "arrow.right")
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.spurlySecondaryButton)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 2, y: 2)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, geo.safeAreaInsets.bottom + 8)
                } // VStack
            } // ZStack
        } // GeometryReader
        .navigationBarHidden(true)
    }

    // MARK: – Actions

    private func clearConversation() {
        conversationText = ""
        conversationImages.removeAll()
    }

    private func loadSelectedImages() {
        conversationImages = []
        for item in selectedPhotos {
            item.loadTransferable(type: Data.self) { result in
                if case .success(let data) = result,
                   let data = data,
                   let uiImage = UIImage(data: data)
                {
                    DispatchQueue.main.async {
                        conversationImages.append(uiImage)
                    }
                }
            }
        }
    }

    private func submitContext() {
        hideKeyboard()

        // Validate topic against prohibited list
        let lower = quickTopic.lowercased()
        if !quickTopic.isEmpty && prohibitedTopics.contains(where: lower.contains) {
            showTopicError = true
            quickTopic = ""
            return
        }

        // Build payload
        struct ContextPayload: Codable {
            let conversation: String?
            let situation: String?
            let topic: String?
        }
        let payload = ContextPayload(
            conversation: conversationText.isEmpty ? nil : conversationText,
            situation: selectedSituation.isEmpty ? nil : selectedSituation,
            topic: quickTopic.isEmpty ? nil : quickTopic
        )

        guard let url = URL(string: "https://your.backend/api/generate") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(payload)

        URLSession.shared.dataTask(with: request) { data, resp, err in
            // TODO: handle response, parse spurs and navigate to suggestions screen
        }.resume()
    }

    private func openSideMenu() {
        // TODO: integrate your side‐menu presentation
    }

    private func showPOISketch() {
        // TODO: present the POI sketch overlay
    }
}

#if DEBUG
struct ContextInputView_Previews: PreviewProvider {
    static var previews: some View {
        ContextInputView()
            .previewDevice("iPhone 14 Pro")
    }
}
#endif
