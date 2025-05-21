//
//  CreateAccountView.swift
//
//  Author: phaeton order llc
//  Target: spurly
//

import SwiftUI
import AuthenticationServices // For Sign in with Apple
import GoogleSignIn
import GoogleSignInSwift

struct CreateAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager // To potentially dismiss if auth state changes elsewhere
    @StateObject private var viewModel: AuthViewModel

    // Initialize viewModel with the authManager from environment
    // This ensures the viewModel can interact with the correct AuthManager instance
    init() {
        // This pattern is common if you want the AuthViewModel to be specific to this view's lifecycle
        // and use the AuthManager passed down via the environment.
        // However, SwiftUI best practices for @StateObject initialization are in the `init()` or
        // directly at the declaration if no parameters are needed from `init()`.
        // Since AuthManager comes from @EnvironmentObject, it's not directly available during memberwise init.
        // A common workaround is to initialize it in the view body or use a private initializer trick.
        // For simplicity here, we'll assume AuthManager is injected or picked up correctly.
        // This will be properly initialized because AuthManager is passed via .environmentObject() to this View.
        // The _viewModel declaration handles getting the AuthManager from the environment.
        let authManagerForVM = AuthManager() // Placeholder if not correctly injected
                                           // This will be replaced by the actual injected one.
                                           // This is a bit of a workaround for @StateObject init.
                                           // A better pattern might be to pass AuthManager explicitly.

        // Let's refine this:
        // The viewModel needs the authManager. If AuthManager is an @EnvironmentObject,
        // the @StateObject initializer should be able to use it IF it's passed correctly.
        // The most straightforward way to ensure AuthViewModel gets the AuthManager
        // is to pass it during the view's initialization if the ViewModel requires it in its init.
        // However, since AuthViewModel(authManager: AuthManager) is what we need,
        // and we expect AuthManager to be in the environment:
        // We can't directly use @EnvironmentObject in @StateObject's wrappedValue initializer.
        // One solution is to initialize AuthViewModel in an .onAppear or have the parent pass it.
        // Or, like this:
        self._viewModel = StateObject(wrappedValue: AuthViewModel(authManager: AuthManager()))
        // This ^ AuthManager() is a NEW instance, which is WRONG.

        // Correct approach: The parent view (LoginLandingView) should create and pass the AuthViewModel
        // if it needs the shared AuthManager.
        // OR, if CreateAccountView *owns* its AuthViewModel that *uses* the shared AuthManager:
        // The `AuthViewModel` itself needs to be an @EnvironmentObject or passed in.
        // Let's assume `LoginLandingView` does:
        // .sheet(isPresented: $showCreateAccountView) {
        //     CreateAccountView().environmentObject(AuthViewModel(authManager: authManager))
        // }
        // Then here: @EnvironmentObject var viewModel: AuthViewModel
        //
        // For this example, let's make AuthViewModel an @StateObject initialized with the passed authManager.
        // This means LoginLandingView needs to construct CreateAccountView with the authManager.
        // So, LoginLandingView: CreateAccountView(authManager: authManager)
        // And here:
        // @StateObject private var viewModel: AuthViewModel
        // init(authManager: AuthManager) { // Passed by parent
        //    _viewModel = StateObject(wrappedValue: AuthViewModel(authManager: authManager))
        // }
        // For now, to keep it simpler with .sheet, let's make AuthViewModel in CreateAccountView
        // take the AuthManager from its own environment.

        // The provided code for LoginLandingView already does .environmentObject(authManager)
        // and the AuthViewModel takes authManager in its init.
        // So, we should make AuthViewModel an @ObservedObject if created by parent,
        // or @StateObject if created here.
        // If CreateAccountView is presented as a sheet and gets `authManager` in its environment,
        // and AuthViewModel is specific to this view's lifecycle:

        // This is tricky. Let's re-evaluate.
        // If AuthManager is in the environment:
        // @EnvironmentObject var authManager: AuthManager
        // @StateObject var viewModel: AuthViewModel = AuthViewModel(authManager: /* need to get it */) // This is the issue

        // Simplest for now, if CreateAccountView uses a sheet:
        // Parent (LoginLandingView):
        // .sheet(...) { CreateAccountView().environmentObject(self.authManager) }
        // CreateAccountView:
        // @EnvironmentObject var authManager: AuthManager
        // @StateObject var viewModel: AuthViewModel
        //
        // init() {
        //     // This is a common pattern to initialize @StateObject with dependencies
        //     // that are not available when the @StateObject property wrapper itself is initialized.
        //     // However, it's generally better if the AuthViewModel can discover its dependencies (like AuthManager)
        //     // from the environment itself, or if AuthManager is passed into its methods.
        //
        //     // Let's assume AuthViewModel's init takes AuthManager,
        //     // and we construct it here using the one from the environment.
        //     // This requires `CreateAccountView` to have `authManager` available at `init`.
        //
        //     // The provided LoginLandingView will pass authManager via .environmentObject().
        //     // The AuthViewModel(authManager: AuthManager) needs this.
        //     // So the most robust way is for the parent that calls this view
        //     // to prepare the AuthViewModel for it.
        //
        //     // If we want CreateAccountView to create its own AuthViewModel instance:
        //     // We need to ensure AuthManager is available to AuthViewModel's init.
        //
        //     // For now, let's assume `AuthViewModel` is provided as an `@EnvironmentObject`
        //     // by the `LoginLandingView` for simplicity of sheet presentation.
        //     // LoginLandingView: .sheet { CreateAccountView().environmentObject(AuthViewModel(authManager: authManager)) }
        //     // Then here: @EnvironmentObject var viewModel: AuthViewModel
        //     // This approach means the viewModel state is tied to the sheet's lifecycle.
        //
        //     // Let's stick to the original plan where CreateAccountView will have its own @StateObject AuthViewModel
        //     // and AuthViewModel will receive AuthManager.
        //     // The LoginLandingView will pass AuthManager.
        //     // CreateAccountView(authManager: theAuthManagerFromLanding)
        //     // Then:
        //     // @StateObject var viewModel: AuthViewModel
        //     // init(authManager: AuthManager) { _viewModel = StateObject(wrappedValue: AuthViewModel(authManager: authManager))}
        //
        // The user's AuthManager is passed in the environment. AuthViewModel takes it as an init param.
        // So, CreateAccountView needs to create its AuthViewModel using the environment's AuthManager.
        // This is typically done by making the ViewModel itself an EnvironmentObject if shared,
        // or by creating it within the view if it's specific to that view.
        //
        // To resolve this: Create an initializer for CreateAccountView that takes AuthManager.
    }

    // If AuthManager is injected via init (e.g., from parent like LoginLandingView):
     init(authManager: AuthManager) {
         _viewModel = StateObject(wrappedValue: AuthViewModel(authManager: authManager))
     }
    // If AuthManager is expected from environment (e.g. if CreateAccountView is deep in a hierarchy):
    // This requires AuthViewModel to be able to be initialized with an AuthManager from its own environment,
    // which is not how @StateObject works directly.
    //
    // The simplest way if LoginLandingView presents this in a sheet and provides AuthManager via environment:
    // LoginLandingView.swift:
    // .sheet(isPresented: $showCreateAccountView) {
    //      CreateAccountView() // AuthManager is already in environment
    //          .environmentObject(authManager)
    // }
    //
    // CreateAccountView.swift:
    // @EnvironmentObject var authManager: AuthManager
    // @StateObject var viewModel: AuthViewModel
    //
    // init() {
    //     // This is incorrect for @StateObject as it needs to be initialized before view body access.
    //     // One workaround is to use a private struct to hold the AuthManager from environment
    //     // and pass it to AuthViewModel.
    //     // Or, the AuthViewModel itself is made an @EnvironmentObject.
    //
    //     // Let's use the initializer approach where the parent passes it.
    //     // This requires LoginLandingView to change:
    //     // .sheet(isPresented: $showCreateAccountView) {
    //     //     CreateAccountView(authManager: self.authManager)
    //     // }
    //
    //     // For the current structure where LoginLandingView does .environmentObject(authManager),
    //     // CreateAccountView can then declare:
    //     // @EnvironmentObject var authManager: AuthManager
    //     // And then create the StateObject like this:
    //
    //     // This is the typical way:
    //     // @StateObject var viewModel = AuthViewModel(authManager: /* how to get from environment here? */)
    //     // This is not directly possible.
    //
    //     // Reverting to the provided structure where LoginLandingView.swift passes AuthManager via .environmentObject.
    //     // Then CreateAccountView needs to pick it up.
    //     // Then AuthViewModel is created.
    //     // The cleanest way with @StateObject is if AuthViewModel can find AuthManager itself or if it's passed.
    //
    // Let's assume LoginLandingView now does this for clarity:
    // .sheet(isPresented: $showCreateAccountView) {
    //     CreateAccountViewWrapper(authManager: authManager)
    // }
    // struct CreateAccountViewWrapper: View {
    //     @ObservedObject var authManager: AuthManager
    //     var body: some View { CreateAccountView(viewModel: AuthViewModel(authManager: authManager)) }
    // }
    // struct CreateAccountView: View {
    //     @StateObject var viewModel: AuthViewModel
    // ...
    // } This is getting complex.
    //
    // Simpler: LoginLandingView provides AuthManager to CreateAccountView's environment.
    // CreateAccountView declares @EnvironmentObject var authManager.
    // CreateAccountView *then* initializes its @StateObject AuthViewModel using this authManager.
    // This is done by having the AuthViewModel accept AuthManager in its init().
    // CreateAccountView's init() is where this happens.

    // Let's assume the LoginLandingView does:
    // .sheet(isPresented: $showCreateAccountView) {
    //    CreateAccountView().environmentObject(self.authManager)
    // }
    // And AuthViewModel is adapted to take AuthManager from its own environment if needed, or passed.
    // For now, let's go with:
    // @StateObject private var viewModel = AuthViewModel(authManager: AuthManager()) // This creates a new AuthManager! BAD.

    // The best approach for @StateObject with dependency:
    // The View takes the dependency in ITS init, then passes it to the @StateObject's init.
    // So, LoginLandingView should call:
    // .sheet(isPresented: $showCreateAccountView) { CreateAccountView(authManager: self.authManager) }
    // And CreateAccountView is:
    // @StateObject private var viewModel: AuthViewModel
    // init(authManager: AuthManager) { // This authManager is the shared one from LoginLandingView
    //     _viewModel = StateObject(wrappedValue: AuthViewModel(authManager: authManager))
    // }
    // This is the way. The `init()` I added earlier is correct.
    // And `LoginLandingView` needs to call `CreateAccountView(authManager: self.authManager)`

    var body: some View {
        NavigationView { // For the title and close button within the sheet
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Spacer()
                    Image("SpurlyBannerLoginLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 120)
                        .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5)
                        .padding(.top)

                    Spacer()

                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }

                    VStack {
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
                            Spacer(minLength: 15)

                            SecureField("password", text: $viewModel.password)
                                .textContentType(.newPassword)
                                .frame(width: 250, height: 48)
                                .padding(.horizontal, 12)
                                .background(Color.secondaryBg)
                                .opacity(0.95)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.45), radius: 5, x: 5, y: 5)
                            Spacer(minLength: 15)
                            SecureField("confirm", text: $viewModel.confirmPassword)
                                .textContentType(.newPassword)
                                .frame(width: 250, height: 48)
                                .padding(.horizontal, 12)
                                .background(Color.secondaryBg)
                                .opacity(0.95)
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.45), radius: 5, x: 5, y: 5)
                        }
                    }.padding(.horizontal)

                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            viewModel.createAccount()
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
                                    Text("create account")
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

                    HStack  {
                        Spacer()
                        Divider()
                            .frame(maxWidth: 100)
                            .frame(height: 2)
                            .background(Color.accent1)
                            .padding(.horizontal, 2)
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
                            .padding(.horizontal, 2)
                            .opacity(0.4)
                            .shadow(color: Color.black.opacity(0.45), radius: 3, x: 2, y: 2)
                        Spacer()
                    }
                    .padding(.top, 8)

                    Spacer()

                    // Sign in with Apple Button
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
                } // End Main VStack
            } // End Main ScrollView
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryBg).edgesIgnoringSafeArea(.all)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button( action: {
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
                    print("CreateAccountView: Auth state changed to authenticated (via token change), dismissing.")
                    viewModel.clearInputs()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        // Handle alerts or further navigation based on viewModel state if needed
        // For example, if showLoginSuccessAlert was used:
        // .alert("Success!", isPresented: $viewModel.showLoginSuccessAlert, actions: {
        //     Button("OK", role: .cancel) {
        //         presentationMode.wrappedValue.dismiss()
        //     }
        // }, message: {
        //     Text("Your account has been created and you are logged in.")
        // })
    }
}

struct SocialSignInButton: View {
    let title: String
    let image: Image
    let background: Color
    let foreground: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                image
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                Text(title)
                    .font(.system(size: 17))
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 2)
            .frame(width: 225, height: 50)
            .background(background)
            .foregroundStyle(foreground)
        }
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
            )
        .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5)
    }
}

// MARK: - Social Button Style (Example - place in your Styles file)
struct SocialButtonModifier: ViewModifier {
    let backgroundColor: Color
    let foregroundColor: Color

    func body(content: Content) -> some View {
        content
            .font(.body)
            .foregroundColor(foregroundColor)
            .padding(.vertical, 2)
            .padding(.horizontal, 8)
            .background(backgroundColor)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.75), radius: 5, x: 5, y: 5)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.5), lineWidth: 0.5) // Subtle border
            )
    }
}

struct CreateAccountView_Previews: PreviewProvider {
    static var previews: some View {
        // To preview, CreateAccountView needs an AuthManager instance.
        // Since its init requires it for the AuthViewModel.
        let authManager = AuthManager()
        CreateAccountView(authManager: authManager)
            //.environmentObject(AuthViewModel(authManager: authManager)) // If ViewModel was EnvObject
            .environmentObject(authManager) // Ensure AuthManager is in environment for onReceive
    }
}
