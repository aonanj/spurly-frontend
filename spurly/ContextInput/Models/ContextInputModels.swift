//
//  ContextInputModels.swift
//  spurly
//
//  Created by Alex Osterlind on 5/3/25.
//

import SwiftUI
import UIKit

struct OcrResponse: Decodable {
    let conversation_text: String // Or whatever key your backend uses
}

// Represents who sent the message
enum MessageSender: String, Codable {
    case user = "user"
    case connection = "connection"
    // Add other potential senders if needed
    case unknown = "unknown"

    var id: String { self.rawValue }
}

struct MessageRow: View {
    @Binding var message: ConversationMessage

    var body: some View {
        HStack { // Main container HStack
            if message.sender == .user {
                Spacer() // Push user messages to the right
            }

            // Message bubble content
            Text(message.text)
                .font(.caption) // Use callout font for slightly smaller text
                .foregroundColor(message.displayColor)
                .lineLimit(nil)
                .padding(EdgeInsets(top: 5, leading: 8, bottom: 5, trailing: 8)) // Adjust padding for bubble look
                .background(
                    Color.accent1.opacity(0.15)
                ) // Slightly stronger background tint
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous)) // Use clipShape for better corner rounding
                // Limit bubble width to prevent overly wide bubbles
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: message.sender == .user ? .trailing : .leading)
                .padding(.top, 5)
                .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1) // Subtle shadow

            if message.sender == .connection || message.sender == .unknown {
                Spacer() // Push connection/unknown messages to the left
            }
        }
        // No need for extra padding here unless desired for spacing between rows
        // .padding(.horizontal, 10) // Moved padding inside bubble or handled by list
        // .padding(.vertical, 2) // Reduced vertical padding between rows
    }
}

struct EditMessageView: View {
    // Binding to the original message (optional, if you need sender info etc.)
    // We mainly need the original ID to save back.
    // Instead of binding the whole message, let's use the text directly.
    @State var currentText: String // Start with the original text
    let originalMessageId: UUID
    let sender: MessageSender // To maybe style the editor or header

    // Callbacks for saving or cancelling
    let onSave: (String) -> Void
    let onCancel: () -> Void

    // Environment variable to dismiss the sheet
    @Environment(\.dismiss) var dismiss

    init(message: Binding<ConversationMessage>, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self._currentText = State(initialValue: message.wrappedValue.text) // Initialize @State from binding
        self.originalMessageId = message.wrappedValue.id
        self.sender = message.wrappedValue.sender
        self.onSave = onSave
        self.onCancel = onCancel
    }


    var body: some View {
        NavigationView { // Embed in NavigationView for title and buttons
            VStack {
                TextEditor(text: $currentText)
                    .frame(minHeight: 100, maxHeight: 300) // Adjust size
                    .border(Color.gray.opacity(0.5), width: 1)
                    .padding()

                Spacer()
            }
            .navigationTitle("edit message (\(sender.rawValue))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("cancel") {
                        onCancel() // Call the cancel callback
                        // dismiss() // Environment dismiss also works
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("save") {
                        onSave(currentText) // Call the save callback with edited text
                        // dismiss() // Environment dismiss also works
                    }
                    .disabled(currentText.isEmpty) // Disable save if text is empty
                }
            }
        }
    }
}

// Update the EditMessageView initializer call in ContextInputView's .sheet modifier
// to match the new init signature if needed. (The provided .sheet code already uses this init).

// Represents a single message in the conversation
struct ConversationMessage: Identifiable, Codable, Equatable {
    let id = UUID() // For Identifiable conformance
    var sender: MessageSender
    var text: String

    // Define colors (adjust as needed using your ColorPalette)
    var displayColor: Color {
        switch sender {
            case .user:
                return .primaryText // Example: User messages in blue
            case .connection:
                return .accent3 // Example: Connection messages in green
            case .unknown:
                return .secondaryText // Example: Unknown sender in gray
        }
    }

    // Helper to get UIColor for NSAttributedString
    var uiColor: UIColor {
        switch sender {
            case .user:
                return UIColor(Color.primaryText) // Convert SwiftUI Color
            case .connection:
                return UIColor(Color.accent3) // Convert SwiftUI Color
            case .unknown:
                return UIColor(Color.secondaryText)
        }
    }

    // CodingKeys if your JSON uses different names
    enum CodingKeys: String, CodingKey {
        case sender
        case text
    }

    // Required for Equatable (used by .onChange on the ScrollView)
    static func == (lhs: ConversationMessage, rhs: ConversationMessage) -> Bool {
        lhs.id == rhs.id && lhs.text == rhs.text && lhs.sender == rhs.sender // Compare relevant fields
    }
}

// Represents the expected structure of the JSON array from OCR
struct OcrConversationResponse: Decodable {
    let messages: [ConversationMessage]
    // Add other fields if your response includes more data
}

// MARK: - NEW Helper View for Manual Text Input
struct ManualTextInputView: View {
    @Binding var newMessageText: String
    @Binding var selectedSender: MessageSender
    let addMessageAction: () -> Void

    @FocusState var isTextEditorFocused: Bool

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("sender", selection: $selectedSender) {
                    Text("me").tag(MessageSender.user)
                    Text("them").tag(MessageSender.connection)
                }
                .pickerStyle(SegmentedPickerStyle())
                .scaleEffect(0.85) // Slightly smaller picker
                .frame(maxWidth: 150) // Limit picker width

                Spacer()
            }

            HStack {
                // Use TextEditor for multi-line input
                TextEditor(text: $newMessageText)
                    .frame(height: 40) // Adjust height as needed
                    .border(Color.gray.opacity(0.3))
                    .cornerRadius(6)
                    .font(.caption)
                    .focused($isTextEditorFocused)

                Button(action: {
                    addMessageAction()
                    isTextEditorFocused = false // Dismiss keyboard
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accent1)
                }
                .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}

struct BackendSpursResponse: Decodable {
    let spurs: [String]? //adjust to match backend key
}
