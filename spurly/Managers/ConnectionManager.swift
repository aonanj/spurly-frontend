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
    @Published var currentConnectionId: String? = nil
    @Published var currentConnectionName: String? = nil

    /// Opens the New Connection UI (can wrap in animation)
    func addNewConnection() {
        print("Add New Connection tapped")
//        withAnimation {
            isNewConnectionOpen = true
//        }
    }

    /// Closes the New Connection UI
    func closeNewConnection() {
        print("Close New Connection tapped")
//        withAnimation {
            isNewConnectionOpen = false
//        }
    }

    /// Toggles the New Connection UI
    func toggleNewConnection() {
        print("Toggle New Connection tapped")
//        withAnimation {
            isNewConnectionOpen.toggle()
//        }
    }

    func setActiveConnection(connectionId: String, connectionName: String) {
        DispatchQueue.main.async {
            self.currentConnectionId = connectionId
            self.currentConnectionName = connectionName
            print(
                "ConnectionManager: Active connection ID set to: \(connectionId)."
            )
        }
    }

    func clearActiveConnection()  {
        DispatchQueue.main.async {
            self.currentConnectionId = nil
            self.currentConnectionName = nil
            print("ConnectionManager: Active connection ID cleared.")
        }
    }
}
