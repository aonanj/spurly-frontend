//
//  CreateAccountView.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI
import AuthenticationServices
import GoogleSignIn
import GoogleSignInSwift

struct CreateAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel: AuthViewModel

    init(authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authManager: authManager))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Spacer()

                    // Logo
                    Image("SpurlyBannerLoginLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 120)
                        .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5)
                        .padding(.top)

                    Spacer()

                    // Error Message
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    // Input Fields
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
                            .textContentType(.newPassword)
                            .frame(width: 250, height: 48)
                            .padding(.horizontal, 12)
                            .background(Color.secondaryBg)
                            .opacity(0.95)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.45), radius: 5, x: 5, y: 5)

                        SecureField("confirm password", text: $viewModel.confirmPassword)
                            .textContentType(.newPassword)
                            .frame(width: 250, height: 48)
                            .padding(.horizontal, 12)
                            .background(Color.secondaryBg)
                            .opacity(0.95)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.45), radius: 5, x: 5, y: 5)
                    }
                    .padding(.horizontal)

                    Spacer()

                    // Create Account Button
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.createAccount()
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
                                    Text("create account")
                                        .foregroundColor(.white)
                                }
                                Spacer()
                            }
                        }
                        .modifier(SignInButtonModifier())
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5)
                        .disabled(!viewModel.isCreateAccountFormValid || viewModel.isLoading)
                        .padding(.vertical, 5)
                        Spacer()
                    }

                    // Divider
                    HStack {
                        Spacer()
                        Divider()
                            .frame(maxWidth: 100)
                            .frame(height: 2)
                            .background(Color.accent1)
                            .padding(.horizontal, 2)
                            .opacity(0.4)
                            .shadow(color: Color.black.opacity(0.45), radius: 3, x: 2, y: 2)
                        Text("or sign up with")
                            .font(.subheadline)
                            .foregroundColor(.secondaryText)
                            .shadow(color: Color.black.opacity(0.45), radius: 3, x: 2, y: 2)
                        Divider()
                            .frame(maxWidth: 100)
                            .frame(height: 2)
                            .background(Color.accent1)
                            .padding(.horizontal, 2)
                            .opacity(0.4)
                            .shadow(color: Color.black.opacity(0.45), radius: 3, x: 2, y: 2)
                        Spacer()
                    }
                    .padding(.top, 8)

                    Spacer()

                    // Social Sign In Buttons
                    VStack(spacing: 10) {
                        // Apple Sign In
                        HStack {
                            Spacer()
                            SocialSignInButton(
                                title: "sign up with apple",
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
                                title: "sign up with google",
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
                                title: "sign up with facebook",
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
            } // End Main ScrollView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                    print("CreateAccountView: User authenticated, dismissing view")
                    viewModel.clearInputs()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthManager()
        CreateAccountView(authManager: authManager)
            .environmentObject(authManager)
    }
}
