//
//  SignInView.swift
//  TravelTalk
//
//  Created by Cascade on 2025-11-15.
//

import SwiftUI

struct SignInView: View {
    var onSignIn: () -> Void
    var onSignUp: () -> Void = {}
    var onForgotPassword: () -> Void = {}
    @EnvironmentObject private var userStore: UserStore

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSecure: Bool = true
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack(alignment: .top) {
            AuthBackground()
                .allowsHitTesting(false)

            ScrollView {
                VStack(spacing: 24) {
                    // Brand
                    Text("TravelTalk")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: 0x3B82F6))
                        .padding(.top, 56)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        Text("Sign in to continue your journey.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                    formCard()
                        .padding(.horizontal, 24)

                    Button("Forgot Password?") { onForgotPassword() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: 0x3B82F6))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    signInButton()
                        .padding(.horizontal, 24)
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.8 : 1)

                    if let msg = errorMessage {
                        Text(msg)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                    }

                    HStack(spacing: 6) {
                        Text("Don't have an account?")
                            .foregroundColor(.white.opacity(0.8))
                        Button("Sign Up") { onSignUp() }
                            .foregroundColor(Color(hex: 0x3B82F6))
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .padding(.bottom, 32)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: 360)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func signIn() {
        errorMessage = nil
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }
        isLoading = true
        DispatchQueue.main.async {
            do {
                try userStore.login(email: email, password: password)
                isLoading = false
                onSignIn() // triggers transition; isSignedIn comes from store
            } catch {
                isLoading = false
                errorMessage = (error as NSError).localizedDescription
            }
        }
    }
    
    // MARK: - Small helpers to reduce type-checking load
    @ViewBuilder
    private func formCard() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Email or Username")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            emailRow()

            Text("Password")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)

            passwordRow()
        }
        .padding(16)
        .background(Color.black.opacity(0.40))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func emailRow() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person")
                .foregroundColor(.white.opacity(0.75))
            TextField("", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .foregroundColor(.white.opacity(0.92))
                .font(.system(size: 16))
                .placeholder(when: email.isEmpty) {
                    Text("Enter your email or username")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.38))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func passwordRow() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundColor(.white.opacity(0.75))
            Group {
                if isSecure { SecureField("", text: $password) }
                else { TextField("", text: $password) }
            }
            .foregroundColor(.white.opacity(0.92))
            .font(.system(size: 16))
            .placeholder(when: password.isEmpty) {
                Text("Enter your password")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.38))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Button(action: { isSecure.toggle() }) {
                Image(systemName: isSecure ? "eye" : "eye.slash")
                    .foregroundColor(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
        .background(Color.black.opacity(0.8))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func signInButton() -> some View {
        Button(action: signIn) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x3B82F6), Color(hex: 0x2563EB)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 52)
                    .shadow(color: Color(hex: 0x2563EB).opacity(0.45), radius: 10, x: 0, y: 8)

                if isLoading { ProgressView().tint(.white) }
                else {
                    Text("Sign In")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }
}

private struct AuthBackground: View {
    var body: some View {
        ZStack {
            // If you add an image named "AuthBackground" it'll be used automatically
            if UIImage(named: "AuthBackground") != nil {
                Image("AuthBackground")
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
    SignInView(onSignIn: {})
        .environmentObject(UserStore())
        .preferredColorScheme(.dark)
}
