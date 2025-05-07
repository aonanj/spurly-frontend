//
//  ConnectionManager.swift
//  spurly
//
//  Created by Alex Osterlind on 4/29/25.
//

import SwiftUI

/// Manages presentation of New Connection across the app
final class ConnectionManager: ObservableObject {
    /// `true` when the menu is visible
    @Published var isNewConnectionOpen: Bool = false

    /// Opens the New Connection UI (can wrap in animation)
    func addNewConnection() {
        print("Add New Connection not implemented yet")
//        withAnimation {
            isNewConnectionOpen = true
//        }
    }

    /// Closes the New Connection UI
    func closeNewConnection() {
        print("Close New Connection not implemented yet")
//        withAnimation {
            isNewConnectionOpen = false
//        }
    }

    /// Toggles the New Connection UI
    func toggleNewConnection() {
        print("Toggle New Connection not implemented yet")
//        withAnimation {
//            isNewConnectionOpen.toggle()
//        }
    }
}
