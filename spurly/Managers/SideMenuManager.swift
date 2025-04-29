//
//  SideMenuManager.swift
//  spurly
//
//  Created by Alex Osterlind on 4/29/25.
//

import SwiftUI

/// Manages presentation of a side‐menu across the app
final class SideMenuManager: ObservableObject {
    /// `true` when the menu is visible
    @Published private(set) var isMenuOpen: Bool = false

    /// Opens the side menu (can wrap in animation)
    func openSideMenu() {
        print("Open side menu not implemented yet")
    //    withAnimation {
    //        isMenuOpen = true
    //    }
    }

    /// Closes the side menu
    func closeSideMenu() {
        print("Close side menu not implemented yet")
    //    withAnimation {
    //        isMenuOpen = false
    //    }
    }

    /// Toggles the menu state
    func toggleSideMenu() {
        print("Toggle side menu not implemented yet")
//        withAnimation {
//            isMenuOpen.toggle()
//        }
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
