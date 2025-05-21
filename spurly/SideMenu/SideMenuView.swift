//
//  SideMenuView.swift
//  spurly
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI

// Enum for navigation destinations - Icons and labels updated
enum SideMenuNavigation: String, Identifiable {
    case updateProfile
    case loadConnection
    case editConnection
    case removeConnection
    case savedSpurs
    case settings

    var id: String { self.rawValue }

    @ViewBuilder
    var destinationView: some View {
        // Placeholder views - to be implemented later
        switch self {
        case .updateProfile:
            Text("update profile (placeholder)")
        case .loadConnection:
            Text("load connection (placeholder)")
        case .editConnection:
            Text("edit connection (placeholder)")
        case .removeConnection:
            Text("remove connection (placeholder)")
        case .savedSpurs:
            Text("saved spurs (placeholder)")
        case .settings:
            Text("settings (placeholder)")
        }
    }

    // Labels are now lowercase
    var label: String {
        switch self {
        case .updateProfile: return "update profile"
        case .loadConnection: return "load connection"
        case .editConnection: return "edit connection"
        case .removeConnection: return "remove connection"
        case .savedSpurs: return "saved spurs"
        case .settings: return "settings & preferences"
        }
    }

    // Updated icon names as per your request
    var iconName: String {
        switch self {
        case .updateProfile: return "rectangle.and.pencil.and.ellipsis"
        case .loadConnection: return "person.crop.square.filled.and.at.rectangle"
        case .editConnection: return "pencil.line"
        case .removeConnection: return "person.fill.xmark"
        case .savedSpurs: return "staroflife.fill"
        case .settings: return "gearshape"
        }
    }
}

struct SideMenuView: View {
    @EnvironmentObject var sideMenuManager: SideMenuManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var connectionManager: ConnectionManager

    @State private var selectedDestination: SideMenuNavigation?

    // Define a new button style for menu items
    struct MenuButtonStyle: ButtonStyle {
        let iconName: String
        let text: String
        let isDisabled: Bool

        func makeBody(configuration: Configuration) -> some View {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(
                        isDisabled ? .secondaryText.opacity(
                            0.4
                        ) : .primaryText
                    ) //
                    .font(.system(size: 22))
                    .frame(width: 25, alignment: .center)
                    .shadow(color: Color.black.opacity(0.55), radius: 3, x: 2, y: 2)
                Text(text) // Already lowercase from enum
                    .font(.system(size: 17, weight: .medium)) // Smaller text
                    .foregroundColor(
                        isDisabled ? .secondaryText
                            .opacity(0.4) : .primaryText
                    )
                    .shadow(color: Color.black.opacity(0.55), radius: 3, x: 2, y: 2)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                configuration.isPressed ? Color.tertiaryBg
                    .opacity(0.8) : Color.clear
            ) //
            .cornerRadius(8)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
    }

    // Dynamic width for the menu
    private var menuWidth: CGFloat {
        UIScreen.main.bounds.width * 0.82 // Increased width
    }

    // Max height for the menu
    private var menuMaxHeight: CGFloat {
        UIScreen.main.bounds.height * 0.8 // Reduced height, e.g., 80% of screen
    }


    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Spacer()
                    Image("SpurlySideMenuLogo") // Placeholder for your logo
                        .resizable()
                        .scaledToFit()
                        .frame(height: 65) // Adjust size as needed
                        .padding(.bottom, 10)
                    Spacer()
                }


            }
            .padding(.horizontal, 20)
            .padding(.top, 30) // Adjusted top padding
            .padding(.bottom, 5)
            Spacer()
            HStack {


                Divider()
                    .frame(maxWidth: .infinity)
                    .frame(height: 2)
                    .background(Color.accent1)
                    .padding(.horizontal, 8)
                    .opacity(0.4)
                    .shadow(color: Color.black.opacity(0.55), radius: 3, x: 2, y: 2)
                Text(authManager.userId ?? "guest") // Using userId, should be email/name
                    .font(.system(size: 14, weight: .medium))
                    .italic() // Reduced size
                    .foregroundColor(.secondaryText) //
                    .lineLimit(1)
                    .shadow(color: Color.black.opacity(0.55), radius: 3, x: 2, y: 2)
                Divider()
                    .frame(maxWidth: 30)
                    .frame(height: 2)
                    .background(Color.accent1)
                    .padding(.horizontal, 8)
                    .opacity(0.4)
                    .shadow(color: Color.black.opacity(0.55), radius: 3, x: 2, y: 2)
            }
            .padding(.top, 10)
            Spacer()

            // Menu Items using ScrollView and VStack for custom buttons
            ScrollView {
                VStack(alignment: .leading, spacing: 12) { // Spacing between buttons
                    Spacer()
                    menuButton(for: .updateProfile)
                    menuButton(for: .loadConnection)

                    let isEditConnectionDisabled = connectionManager.currentConnectionId == nil
                    menuButton(for: .editConnection, disabled: isEditConnectionDisabled)

                    menuButton(for: .removeConnection)
                    menuButton(for: .savedSpurs)
                    Spacer()
                    Divider()
                        .frame(maxWidth: .infinity)
                        .frame(height: 2)
                        .background(Color.accent1)
                        .padding(.horizontal, 15)
                        .opacity(0.4)
                        .shadow(color: Color.black.opacity(0.55), radius: 3, x: 2, y: 2)
                    Spacer()
                    menuButton(for: .settings)
                }
                .padding(.horizontal, 15) // Padding for the button group
            }

            Spacer() // Pushes footer to the bottom

            // Footer
            VStack(spacing: 0) {
                Divider().background(Color.bordersSeparators.opacity(0.5)) //

                HStack {

                    Button(action: {
                        print("Help tapped")
                        // TODO: Implement help action
                        sideMenuManager.closeSideMenu()
                    }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 25)) // Adjusted icon size
                            .foregroundColor(.primaryButton)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.highlight, .primaryText, .highlight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.5), radius: 5, x: 5, y: 5)
                    }
                    .padding(15)

                    Spacer()

                    Button(action: {
                        authManager.logout()
                        sideMenuManager.closeSideMenu()
                    }) {
                        Image(systemName: "figure.walk.departure")
                            .font(.system(size: 25)) // Adjusted icon size
                            .foregroundColor(.primaryButton)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.highlight, .primaryText, .highlight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.5), radius: 5, x: 5, y: 5)
                    }
                    .padding(15)

                }
                .frame(height: 55) // Fixed height for footer
            }
        }
        .frame(width: menuWidth, height: menuMaxHeight)
        .background(Color.cardBg) //
        .cornerRadius(20, corners: [.topRight, .bottomRight]) // Rounded corners on the right
        .shadow(color: .black.opacity(0.3), radius: 10, x: 5, y: 0)
        .edgesIgnoringSafeArea(.bottom) // Allow content like footer to go to bottom if menuMaxHeight is large
        .sheet(item: $selectedDestination) { destination in
            NavigationView {
                destination.destinationView
                    .navigationTitle(destination.label) // Title is already lowercase
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("done") { // Lowercase
                                selectedDestination = nil
                            }
                        }
                    }
                    .onDisappear {
                        if selectedDestination != nil {
                             sideMenuManager.closeSideMenu()
                         }
                    }
            }
        }
    }

    // Helper function to create menu buttons
    @ViewBuilder
    private func menuButton(for destination: SideMenuNavigation, disabled: Bool = false) -> some View {
        Button(action: {
            if disabled { return }
            selectedDestination = destination
        }) {
            EmptyView()
        }
        .buttonStyle(MenuButtonStyle(iconName: destination.iconName, text: destination.label, isDisabled: disabled))
        .disabled(disabled)
    }
}

// Custom extension for rounding specific corners (if not already defined elsewhere)
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}


struct SideMenuView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a mock SideMenuManager that starts with the menu open for easy previewing
        let openMenuManager = SideMenuManager()
       // openMenuManager.isMenuOpen = true // So we can see it in the preview

        // Simulate an active connection for previewing the "Edit Connection" state
        let connectionManagerWithActive = ConnectionManager()
        connectionManagerWithActive.setActiveConnection(connectionId: "123", connectionName: "Preview Conn")

        let connectionManagerNoActive = ConnectionManager()

        return Group {
            SideMenuView()
                .environmentObject(openMenuManager)
                .environmentObject(AuthManager())
                .environmentObject(connectionManagerWithActive)
                .previewDisplayName("With Active Connection")

            SideMenuView()
                .environmentObject(openMenuManager)
                .environmentObject(AuthManager())
                .environmentObject(connectionManagerNoActive)
                .previewDisplayName("No Active Connection")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.3)) // Simulate a dimmed background for preview
    }
}
