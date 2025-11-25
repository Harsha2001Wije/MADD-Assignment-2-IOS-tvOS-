//
//  TravelTalkApp.swift
//  TravelTalk
//
//  Created by STUDENT on 2025-11-15.
//

import SwiftUI
import GoogleSignIn

@main
struct TravelTalkApp: App {
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = true
    @State private var showSplash: Bool = true
    @State private var isSignedIn: Bool = false
    @State private var showSignUp: Bool = false
    @State private var showForgotPassword: Bool = false
    @StateObject private var userStore = UserStore()
    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashView {
                        showSplash = false
                    }
                    .transition(.opacity)
                } else if !isSignedIn && showForgotPassword {
                    ForgotPasswordView(
                        onBack: { withAnimation { showForgotPassword = false } },
                        onSent: { withAnimation { showForgotPassword = false } }
                    )
                    .transition(.opacity)
                } else if !isSignedIn && !showSignUp {
                    SignInView(
                        onSignIn: { withAnimation { isSignedIn = true } },
                        onSignUp: { withAnimation { showSignUp = true } },
                        onForgotPassword: { withAnimation { showForgotPassword = true } }
                    )
                    .transition(.opacity)
                } else if !isSignedIn && showSignUp {
                    SignUpView(
                        onCreateAccount: { withAnimation { showSignUp = false } },
                        onSignInLink: { withAnimation { showSignUp = false } }
                    )
                    .transition(.opacity)
                } else {
                    MainTabView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                isSignedIn = userStore.isSignedIn
                configureGoogleIfNeeded()
            }
            .onReceive(userStore.$currentUserId) { id in
                isSignedIn = (id != nil)
            }
            .onOpenURL { url in
                _ = GIDSignIn.sharedInstance.handle(url)
            }
            .preferredColorScheme(darkModeEnabled ? .dark : .light)
            .environmentObject(userStore)
        }
    }
}

private func configureGoogleIfNeeded() {
    if GIDSignIn.sharedInstance.configuration == nil {
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GIDClientID") as? String, !clientID.isEmpty {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        } else if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
                  let dict = NSDictionary(contentsOfFile: path) as? [String: Any],
                  let clientID = dict["CLIENT_ID"] as? String {
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        }
    }
}


