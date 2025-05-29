//
//  LoginLandingView.swift
//  spurly
//
//  Created by [Your Name/App Name] on 5/16/25.
//

import SwiftUI

struct LoginLandingView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showCreateAccountView = false
    @State private var showSignInView = false

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                     DiagonalColorBlockBackgroundView(
                         colors: [
                            Color.secondaryText,
                            Color.secondaryButton,
                            Color.highlight,
                            Color.secondaryText
                         ],
                         angle: .degrees(25)
                     ).opacity(0.7)
                        .zIndex(0)
                    // For simplicity, using a solid color if the diagonal view isn't set up yet
                   //  Color("SpurlyPrimaryBackground").edgesIgnoringSafeArea(.all) //

                    VStack(spacing: 20) {
                        Spacer()

                        Image("SpurlyBannerLoginLogo") // Assuming this asset exists
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width * 0.97)
                            .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5)

                        Image("SpurlyTagLineImage") // Assuming this asset exists
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width * 0.8)
                            .padding(.top, 10)
                            .shadow(color: Color.black.opacity(0.45), radius: 5, x: 5, y: 5)

                        Spacer()

                        HStack {
                            Button(action: {
                                showSignInView = true
                            }) {
                                Image("SpurlySignInButton") // Assuming this asset exists
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width * 0.25) // Adjusted size for padding
                                    .padding() // Add padding around the image inside the button
                                    .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.15) // Increased frame for the background
                                    .background(Color("SpurlySecondaryButton")) //
                                    .cornerRadius(15) // Rounded corners for the button background
                                    .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5) // Optional shadow
                            }
                            .sheet(isPresented: $showSignInView) {
                                SignInView(authManager: self.authManager)
                            }

                            Image("SpurlySpinningSpur3x") // Assuming this asset exists
                                .resizable()
                                .scaledToFit()
                                .frame(width: geometry.size.width * 0.15)
                                .shadow(color: Color.black.opacity(0.35), radius: 5, x: 0, y: 3)
                                .padding(.vertical, 5) // Adjusted padding
                                .opacity(0.6)

                            Button(action: {
                                showCreateAccountView = true
                            }) {
                                Image("SpurlySignUpButton") // Assuming this asset exists
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width * 0.25) // Adjusted size for padding
                                    .padding() // Add padding around the image inside the button
                                    .frame(width: geometry.size.width * 0.35, height: geometry.size.width * 0.15) // Increased frame for the background
                                    .background(Color("SpurlySecondaryButton")) //
                                    .cornerRadius(15) // Rounded corners for the button background
                                    .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5) // Optional shadow
                            }
                            .sheet(isPresented: $showCreateAccountView) {
                                CreateAccountView(authManager: self.authManager)
                            }
                        }
                        .padding(.horizontal)

                        Spacer()

                        VStack(spacing: 1) {
                            HStack(spacing: 0) {
                                Text("by using spurly, you agree to the ")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .opacity(0.75)
                                    .foregroundColor(Color("SpurlySecondaryText"))
                                Link(
                                    " ::terms of service::",
                                    destination:  URL(string: "https://spurlyTOS.com")!)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(
                                    Color.accent1
                                ) //MARK: add tos link here
                            }

                            HStack(spacing: 0) {
                                Text("spurly respects privacy ")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .opacity(0.75)
                                    .foregroundColor(Color("SpurlySecondaryText"))
                                Link(
                                    " ::privacy policy::",
                                    destination:  URL(string: "https://spurlyPP.com")!)
                                .font(.caption)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(
                                    Color.accent1
                                ) //MARK: add privacy policy link here
                            }
                        }
                        .padding(.bottom, 10)
                        .frame(maxWidth: .infinity, maxHeight: 15)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true)
            // .edgesIgnoringSafeArea(.all) // Apply to NavigationView if your background needs to go under status/home bar
        }
        // Ensure your app has the SpurlySecondaryButton color defined in your Assets.xcassets
        // and the image assets "SpurlySignInButton", "SpurlySignUpButton", etc.
    }
}



struct LoginLandingView_Previews: PreviewProvider {
    static var previews: some View {
        LoginLandingView()
            .environmentObject(AuthManager())
            // You might need to ensure your preview environment has the necessary colors.
            // For example, by creating a temporary ColorPalette in your preview provider or ensuring assets are available.
    }
}
