//
//  SignInView.swift
//  spurly
//
//  Created by [Your Name/App Name] on 5/16/25.
//

import SwiftUI
import AuthenticationServices

struct SignInView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel: AuthViewModel

    init(authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authManager: authManager))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Logo
                    Image("SpurlyBannerLoginLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 120)
                        .padding(.top)
                        .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5)

                    Spacer()

                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    // Email and Password Fields
                    VStack(spacing: 15) {
                        TextField("email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .frame(width: 250, height: 48)
                            .autocapitalization(.none)
                            .padding(.horizontal, 12)
                            .background(Color.secondaryBg)
                            .opacity(0.95)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.45), radius: 5, x: 5, y: 5)

                        SecureField("password", text: $viewModel.password)
                            .textContentType(.password)
                            .frame(width: 250, height: 48)
                            .padding(.horizontal, 12)
                            .background(Color.secondaryBg)
                            .opacity(0.95)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.45), radius: 5, x: 5, y: 5)
                    }

                    Spacer()

                    // Sign In Button
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.loginUser()
                        }) {
                            HStack {
                                Spacer()
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image("SpurlyLogoWhite")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .rotationEffect(.degrees(180))

                                    Text("sign in")
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                        }
                        .modifier(SignInButtonModifier())
                        .disabled(!viewModel.isLoginFormValid || viewModel.isLoading)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5)
                        Spacer()
                    }

                    // Forgot Password
                    Button("forgot password") {
                        // Navigate to forgot password screen
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .shadow(color: Color.black.opacity(0.45), radius: 3, x: 2, y: 2)
                    .padding(.vertical, 5)

                    // Divider
                    HStack {
                        Spacer()
                        Divider()
                            .frame(maxWidth: 100)
                            .frame(height: 2)
                            .background(Color.accent1)
                            .padding(.horizontal, 5)
                            .opacity(0.4)
                            .shadow(color: Color.black.opacity(0.45), radius: 3, x: 2, y: 2)
                        Text("or sign in with")
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                            .shadow(color: Color.black.opacity(0.45), radius: 3, x: 2, y: 2)
                        Divider()
                            .frame(maxWidth: 100)
                            .frame(height: 2)
                            .background(Color.accent1)
                            .padding(.horizontal, 5)
                            .opacity(0.4)
                            .shadow(color: Color.black.opacity(0.45), radius: 3, x: 2, y: 2)
                        Spacer()
                    }

                    Spacer()

                    // Social Sign In Buttons
                    VStack(spacing: 10) {
                        // Apple Sign In
                        HStack {
                            Spacer()
                            SocialSignInButton(
                                title: "sign in with apple",
                                image: Image(systemName: "applelogo"),
                                background: .black,
                                foreground: .white,
                                action: viewModel.signInWithApple,
                                isLoading: viewModel.isLoading
                            )
                            Spacer()
                        }

                        // Google Sign In
                        HStack {
                            Spacer()
                            SocialSignInButton(
                                title: "sign in with google",
                                image: Image("GoogleSignInIcon"),
                                background: .white,
                                foreground: .blue,
                                action: viewModel.signInWithGoogle,
                                isLoading: viewModel.isLoading
                            )
                            Spacer()
                        }

                        // Facebook Sign In
                        HStack {
                            Spacer()
                            SocialSignInButton(
                                title: "sign in with facebook",
                                image: Image("FacebookSignInIcon"),
                                background: Color(red: 0.25, green: 0.4, blue: 0.7),
                                foreground: .white,
                                action: viewModel.signInWithFacebook,
                                isLoading: viewModel.isLoading
                            )
                            Spacer()
                        }
                    }

                    Spacer()

                } // End Main VStack
                .padding(.bottom, 10)
            } // End ScrollView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(10)
            .background(Color.primaryBg)
            .edgesIgnoringSafeArea(.all)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.clearInputs()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "x.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.highlight, .primaryText, .highlight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.black.opacity(0.5), radius: 5, x: 5, y: 5)
                    }
                }
            }
            .onReceive(authManager.$token) { token in
                if token != nil && presentationMode.wrappedValue.isPresented {
                    print("SignInView: User authenticated, dismissing view")
                    viewModel.clearInputs()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

// Updated Social Sign In Button with loading state
struct SocialSignInButton: View {
    let title: String
    let image: Image
    let background: Color
    let foreground: Color
    let action: () -> Void
    let isLoading: Bool

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foreground))
                        .scaleEffect(0.8)
                } else {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                }
                Text(title)
                    .font(.system(size: 17))
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 2)
            .frame(width: 225, height: 50)
            .background(background)
            .foregroundStyle(foreground)
        }
        .disabled(isLoading)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5)
    }
}

// Sign In Button Modifier
//struct SignInButtonModifier: ViewModifier {
//    func body(content: Content) -> some View {
//        content
//            .font(.body)
//            .foregroundColor(.white)
//            .padding(.vertical, 12)
//            .padding(.horizontal, 24)
//            .background(Color.accent1)
//            .cornerRadius(8)
//    }
//}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthManager()
        SignInView(authManager: authManager)
            .environmentObject(authManager)
    }
}
