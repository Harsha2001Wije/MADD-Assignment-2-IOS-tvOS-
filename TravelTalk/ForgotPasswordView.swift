//
//  ForgotPasswordView.swift
//  TravelTalk
//
//  Created by Cascade on 2025-11-16.
//

import SwiftUI

struct ForgotPasswordView: View {
    var onBack: () -> Void = {}
    var onSent: () -> Void = {}

    @State private var email: String = ""
    @State private var isLoading: Bool = false
    @State private var message: String?

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header()

                    VStack(alignment: .center, spacing: 10) {
                        Text("Reset Password")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("Enter the email associated with your account and we'll send an email with instructions to reset your password.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)

                    emailField()

                    sendButton()
                        .disabled(isLoading)
                        .opacity(isLoading ? 0.85 : 1)

                    if let msg = message {
                        Text(msg)
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func header() -> some View {
        ZStack {
            HStack(spacing: 12) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            Text("Forgot Password")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.top, 14)
    }

    @ViewBuilder
    private func emailField() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope")
                .foregroundColor(.white.opacity(0.8))
            TextField("", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .foregroundColor(.white)
                .placeholder(when: email.isEmpty) {
                    Text("Enter your email").foregroundColor(.white.opacity(0.6))
                }
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
        .background(Color.white.opacity(0.10))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func sendButton() -> some View {
        Button(action: send) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(LinearGradient(colors: [Color(hex: 0x3B82F6), Color(hex: 0x2563EB)], startPoint: .leading, endPoint: .trailing))
                    .frame(height: 54)
                    .shadow(color: Color(hex: 0x2563EB).opacity(0.45), radius: 12, x: 0, y: 9)

                if isLoading { ProgressView().tint(.white) }
                else {
                    Text("Send Instructions")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
        }
    }

    private func send() {
        message = nil
        guard !email.isEmpty else { return }
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            message = "If an account exists for \(email), you'll receive an email with instructions."
            onSent()
        }
    }
}

#if DEBUG
#Preview("Forgot Password") {
    ForgotPasswordView()
}
#endif
