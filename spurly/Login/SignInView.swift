//
//  SignInView.swift
//  spurly
//
//  Created by [Your Name/App Name] on 5/16/25.
//

import SwiftUI
import AuthenticationServices // For Sign in with Apple

struct SignInView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager // To observe auth changes
    @StateObject private var viewModel: AuthViewModel

    // Initialize with the shared AuthManager
    init(authManager: AuthManager) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(authManager: authManager))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image("SpurlyBannerLoginLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 120)
                        .padding(.top)
                        .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5)

                    Spacer()

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    Group {
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
                            .textContentType(.password) // Use .password for existing passwords
                            .frame(width: 250, height: 48)
                            .padding(.horizontal, 12)
                            .background(Color.secondaryBg)
                            .opacity(0.95)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.45), radius: 5, x: 5, y: 5)
                    }

                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.loginUser()
                        }) {
                            HStack {
                                Spacer()
                                if viewModel.isLoading {
                                    ProgressView()
                                } else {

                                    Image("SpurlyLogoWhite")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 40, height: 40)
                                        .rotationEffect(.degrees(180))

                                    Text("sign in")

                                }
                                Spacer()
                            }
                        }
                        .modifier(SignInButtonModifier())
                        .disabled(!viewModel.isLoginFormValid || viewModel.isLoading)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5)
                        //.opacity((!viewModel.isLoginFormValid || viewModel.isLoading) ? 0.6 : 1.0)
                        Spacer()
                    }
                    // Optionally, add a "Forgot Password?" link here
                    Button("forgot password") { /* Navigate to forgot password screen */ }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .shadow(color: Color.black.opacity(0.45), radius: 3, x: 2, y: 2)
                        .padding(.vertical, 5)


                    HStack  {
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

                    HStack {
                        Spacer()
                        SocialSignInButton(
                            title: "sign in with apple",
                            image: Image(systemName: "applelogo"),
                            background: .black,
                            foreground: .white,
                            action: viewModel.signInWithApple
                        )
                        Spacer()
                    }.padding(.bottom, 5)

                    HStack {
                        Spacer()
                        SocialSignInButton(
                            title: "sign in with google",
                            image: Image("GoogleSignInIcon"),
                            background: .white,
                            foreground: .blue,
                            action: viewModel.signInWithGoogle
                        )
                        Spacer()
                    }.padding(.vertical, 5)

                    HStack {
                        Spacer()
                        SocialSignInButton(
                            title: "sign in with facebook",
                            image: Image("FacebookSignInIcon"),
                            background: Color(red: 0.25, green: 0.4, blue: 0.7),
                            foreground: .white,
                            action: viewModel.signInWithFacebook
                        )
                        Spacer()
                    }.padding(.vertical, 5)

                    Spacer()

                } //End Main VStack
                .padding(.bottom, 10)
            } // End ScrollView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(10)
            .background(Color.primaryBg).edgesIgnoringSafeArea(.all)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.clearInputs()
                        presentationMode.wrappedValue.dismiss()
                        }
                    )
                    { Image(systemName: "x.circle.fill")
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
            .onReceive(authManager.$token) { newToken in // Observe the actual @Published property
                let isAuthenticatedValue = (newToken != nil && !(newToken?.isEmpty ?? true))
                // Rest of your logic:
                if isAuthenticatedValue && presentationMode.wrappedValue.isPresented {
                    print("SignInView: Auth state changed to authenticated (via token change), dismissing.")
                    viewModel.clearInputs()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        // .alert("Login Successful", isPresented: $viewModel.showLoginSuccessAlert, actions: {
        //     Button("OK", role: .cancel) {
        //         presentationMode.wrappedValue.dismiss()
        //     }
        // }, message: {
        //     Text("You are now logged in.")
        // })
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthManager()
        SignInView(authManager: authManager)
            .environmentObject(authManager) // For onReceive
    }
}
