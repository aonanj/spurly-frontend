//
//  SideMenuManager.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

/// Manages presentation of a side‐menu across the app
final class SideMenuManager: ObservableObject {
    /// `true` when the menu is visible
    @Published private(set) var isMenuOpen: Bool = false

    /// Opens the side menu (can wrap in animation)
    func openSideMenu() {
        withAnimation {
            isMenuOpen = true
        }
    }

    /// Closes the side menu
    func closeSideMenu() {
        withAnimation {
            isMenuOpen = false
        }
    }

    /// Toggles the menu state
    func toggleSideMenu() {
        withAnimation {
            isMenuOpen.toggle()
        }
    }
}

/**USE:
 struct SomeScreen: View {
   @EnvironmentObject private var sideMenuManager: SideMenuManager

   var body: some View {
     VStack {
       // … your content …
       Button(action: sideMenuManager.openSideMenu) {
         Image.menuIcon                // your reusable Image extension
       }
     }
     // Optionally overlay your menu based on isMenuOpen:
     .overlay(
       SideMenuView(isOpen: sideMenuManager.isMenuOpen),
       alignment: .leading
     )
   }
 }
**/
