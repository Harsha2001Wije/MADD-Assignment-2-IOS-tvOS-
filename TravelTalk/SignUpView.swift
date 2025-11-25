    private var isRunningInPreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
//
//  SignUpView.swift
//  TravelTalk
//
//  Created by Cascade on 2025-11-15.
//

import SwiftUI
import UIKit
import GoogleSignIn

struct SignUpView: View {
    var onCreateAccount: () -> Void
    var onSignInLink: () -> Void = {}

// Helper to find the top-most view controller for presenting Google Sign-In
private func topViewController(base: UIViewController? = nil) -> UIViewController? {
    var root: UIViewController?
    if let base = base {
        root = base
    } else {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        if let window = scenes
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) {
            root = window.rootViewController
        } else {
            root = scenes.first?.windows.first?.rootViewController
        }
    }
    if let nav = root as? UINavigationController { return topViewController(base: nav.visibleViewController) }
    if let tab = root as? UITabBarController { return tab.selectedViewController.flatMap { topViewController(base: $0) } ?? root }
    if let presented = root?.presentedViewController { return topViewController(base: presented) }
    return root
}
    @EnvironmentObject private var userStore: UserStore

    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var secure1: Bool = true
    @State private var secure2: Bool = true
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .top) {
            AuthBackgroundSU()
                .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 6) {
                        Text("TravelTalk")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 52)
                        Text("Start Your Journey")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    VStack(spacing: 12) {
                        SocialButton(title: "Sign up with Google", systemIcon: nil, assetIcon: "google", color: .white) {
                            socialSignUpGoogle()
                        }
                        SocialButton(title: "Sign up with Apple", systemIcon: "apple.logo", assetIcon: nil, color: .white) {
                            socialSignUpApple()
                        }
                    }
                    .padding(.top, 6)

                    HStack { Rectangle().fill(.white.opacity(0.2)).frame(height: 1) ; Text("OR").foregroundColor(.white.opacity(0.7)).font(.caption) ; Rectangle().fill(.white.opacity(0.2)).frame(height: 1) }
                    .padding(.horizontal, 24)

                    VStack(spacing: 14) {
                        InputField(icon: "person", placeholder: "Full Name", text: $fullName)
                        InputField(icon: "envelope", placeholder: "Email", text: $email, keyboard: .emailAddress, autocap: .never)
                        PasswordField(icon: "lock", placeholder: "Password", text: $password, isSecure: $secure1)
                        PasswordField(icon: "lock", placeholder: "Confirm Password", text: $confirmPassword, isSecure: $secure2)
                    }
                    .padding(20)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(22)
                    .padding(.horizontal, 24)

                    Button(action: createAccount) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(LinearGradient(colors: [Color(hex: 0x3B82F6), Color(hex: 0x2563EB)], startPoint: .leading, endPoint: .trailing))
                                .frame(height: 56)
                                .shadow(color: Color(hex: 0x2563EB).opacity(0.6), radius: 16, x: 0, y: 10)
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Create Account")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .disabled(isLoading)
                    .opacity(isLoading ? 0.8 : 1)

                    if let msg = errorMessage {
                        Text(msg)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }

                    Text("By signing up, you agree to our Terms and Privacy Policy.")
                        .multilineTextAlignment(.center)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 32)

                    HStack(spacing: 6) {
                        Text("Already have an account?")
                            .foregroundColor(.white.opacity(0.85))
                        Button("Sign In") { onSignInLink() }
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.bottom, 32)
                }
                .frame(maxWidth: 420)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func createAccount() {
        errorMessage = nil
        guard !fullName.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        isLoading = true
        DispatchQueue.main.async {
            do {
                try userStore.signUp(fullName: fullName, email: email, password: password)
                isLoading = false
                // After creating an account, navigate back to Sign In screen to log in
                onCreateAccount()
            } catch {
                isLoading = false
                errorMessage = (error as NSError).localizedDescription
            }
        }
    }

    // MARK: - Social sign up (demo)
    private func socialSignUpGoogle() {
        errorMessage = nil
        isLoading = true
        if isRunningInPreviews {
            // In previews, don't invoke Google SDK. Simulate success.
            DispatchQueue.main.async {
                self.isLoading = false
                self.onCreateAccount()
            }
            return
        }
        // Ensure configuration exists in case app-level setup hasn't run yet
        if GIDSignIn.sharedInstance.configuration == nil {
            if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String, !clientID.isEmpty {
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            } else if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                      let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
                      let clientID = dict["CLIENT_ID"] as? String {
                GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            } else {
                self.isLoading = false
                self.errorMessage = "Google ClientID not configured."
                return
            }
        }
        guard let presenter = topViewController() else {
            isLoading = false
            errorMessage = "Unable to present Google Sign-In."
            return
        }
        GIDSignIn.sharedInstance.signIn(withPresenting: presenter, hint: nil, additionalScopes: ["email"]) { result, error in
            if let error = error {
                self.isLoading = false
                self.errorMessage = error.localizedDescription
                return
            }
            guard let user = result?.user else {
                self.isLoading = false
                self.errorMessage = "Google sign-in failed."
                return
            }
            let email = (user.profile?.email ?? "").lowercased()
            let name = [user.profile?.givenName, user.profile?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            guard !email.isEmpty else {
                self.isLoading = false
                self.errorMessage = "Google did not return an email."
                return
            }
            DispatchQueue.main.async {
                do {
                    do { try self.userStore.signUp(fullName: name.isEmpty ? "Google User" : name, email: email, password: "oauth") }
                    catch let e as NSError { if e.code != 2 { throw e } }
                    try self.userStore.login(email: email, password: "oauth")
                    self.isLoading = false
                    self.onCreateAccount()
                } catch {
                    self.isLoading = false
                    self.errorMessage = (error as NSError).localizedDescription
                }
            }
        }
    }

    private func socialSignUpApple() {
        errorMessage = nil
        isLoading = true
        DispatchQueue.main.async {
            do {
                let demoEmail = "apple_user@traveltalk.local"
                do {
                    try userStore.signUp(fullName: "Apple User", email: demoEmail, password: "oauth")
                } catch let e as NSError {
                    if e.code != 2 { throw e }
                }
                try self.userStore.login(email: demoEmail, password: "oauth")
                isLoading = false
                onCreateAccount()
            } catch {
                isLoading = false
                errorMessage = (error as NSError).localizedDescription
            }
        }
    }
}

private struct SocialButton: View {
    let title: String
    let systemIcon: String?
    let assetIcon: String?
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                HStack(spacing: 10) {
                    if let asset = assetIcon {
                        let candidates = [
                            asset,
                            asset.capitalized,
                            "google",
                            "Google",
                            "google_logo",
                            "GoogleLogo",
                            "google-icon",
                            "GoogleIcon",
                            "ic_google",
                            "icGoogle"
                        ]
                        let name = candidates.first(where: { UIImage(named: $0) != nil })
                        if let name {
                            Image(name)
                                .resizable()
                                .renderingMode(.original)
                                .scaledToFit()
                                .frame(width: 20, height: 20)
                        } else if let sys = systemIcon {
                            Image(systemName: sys)
                                .foregroundColor(color)
                        }
                    } else if let sys = systemIcon {
                        Image(systemName: sys)
                            .foregroundColor(color)
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(height: 50)
            .background(Color.white.opacity(0.12))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }
}

private struct InputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboard: UIKeyboardType = .default
    var autocap: TextInputAutocapitalization = .words

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.8))
            TextField(placeholder, text: $text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(autocap)
                .foregroundColor(.white)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder).foregroundColor(.white.opacity(0.6))
                }
        }
        .padding(14)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }
}

private struct PasswordField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var isSecure: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.8))
            Group {
                if isSecure { SecureField(placeholder, text: $text) }
                else { TextField(placeholder, text: $text) }
            }
            .foregroundColor(.white)
            .placeholder(when: text.isEmpty) { Text(placeholder).foregroundColor(.white.opacity(0.6)) }

            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye" : "eye.slash")
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
    }
}

private struct AuthBackgroundSU: View {
    var body: some View {
        ZStack {
            if UIImage(named: "AuthBG_SignUp") != nil {
                Image("AuthBG_SignUp")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
            } else {
                LinearGradient(colors: [Color.black, Color(hex: 0x0F1A1C)], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
            }
            Rectangle()
                .fill(LinearGradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0.85)], startPoint: .top, endPoint: .bottom))
                .ignoresSafeArea()
        }
    }
}

 

#Preview {
    SignUpView(onCreateAccount: {})
        .environmentObject(UserStore())
        .preferredColorScheme(.dark)
}
