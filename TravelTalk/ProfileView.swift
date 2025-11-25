import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var userStore: UserStore
    @State private var name: String = "Ayesha Perera"
    @State private var email: String = "ayesha.p@email.com"
    @State private var travelStyle: String = "Family"
    @State private var pushEnabled: Bool = true
    @State private var showEdit: Bool = false
    @State private var showTrips: Bool = false
    @State private var showChangePassword: Bool = false
    @State private var showHelp: Bool = false
    @State private var showLogoutAlert: Bool = false
    @State private var avatarImage: UIImage? = nil
    @State private var showSettings: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    header
                    avatar
                    Text(name)
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                    Text(email)
                        .foregroundColor(.white.opacity(0.85))
                        .font(.system(size: 14))
                    Button(action: { showEdit = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "pencil")
                            Text("Edit Profile")
                        }
                        .foregroundColor(.white)
                        .font(.system(size: 15, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)

                    groupLabel("Name")
                    iconField(icon: "person", text: $name)
                    groupLabel("Email")
                    iconField(icon: "envelope", text: $email, keyboard: .emailAddress)
                    groupLabel("Travel Style")
                    iconField(icon: "lanyardcard", text: $travelStyle)

                    settingsCard
                    linkCard(icon: "bookmark.fill", title: "Saved Phrases & Locations") { showTrips = true }
                    linkCard(icon: "lock.fill", title: "Change Password") { showChangePassword = true }
                    linkCard(icon: "questionmark.circle.fill", title: "Help & Support") { showHelp = true }

                    Button(role: .destructive, action: { showLogoutAlert = true }) {
                        Text("Log Out")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color.red.opacity(0.9), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 6)

                    Button(role: .destructive) {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        userStore.deleteCurrentUser()
                    } label: {
                        Text("Delete Account")
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { syncFromCurrentUser() }
        .sheet(isPresented: $showEdit) {
            EditProfileView(name: $name, email: $email, avatarImage: $avatarImage)
                .presentationDetents([.fraction(0.7), .large])
                .presentationDragIndicator(.visible)
                .onDisappear { try? userStore.updateCurrentUser(fullName: name, email: email, password: nil) }
        }
        .sheet(isPresented: $showTrips) {
            TripsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordSheet()
                .presentationDetents([.fraction(0.5), .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showHelp) {
            HelpSupportSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
        .alert("Log Out?", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Log Out", role: .destructive) { userStore.logout() }
        } message: {
            Text("You will need to sign in again to continue.")
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .opacity(0.9)
                Spacer()
                Text("Profile")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                Image(systemName: "gearshape.fill")
                    .foregroundColor(.white)
                    .opacity(0.95)
                    .onTapGesture { showSettings = true }
            }
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
        }
    }

    private var avatar: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.08)).frame(width: 98, height: 98)
            if let img = avatarImage {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 98, height: 98)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable().scaledToFit().frame(width: 92, height: 92)
                    .foregroundColor(.white)
            }
        }
        .padding(.top, 8)
    }

    private func syncFromCurrentUser() {
        if let u = userStore.currentUser {
            name = u.fullName
            email = u.email
        }
    }

    private func groupLabel(_ text: String) -> some View {
        Text(text)
            .foregroundColor(.white.opacity(0.85))
            .font(.system(size: 13))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func iconField(icon: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .frame(width: 18)
            Text(text.wrappedValue)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var settingsCard: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "bell.badge.fill").foregroundColor(.orange)
                Text("Push Notifications").foregroundColor(.white)
            }
            Spacer()
            Toggle("", isOn: $pushEnabled)
                .labelsHidden()
        }
        .padding(14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func linkCard(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .frame(width: 22)
                Text(title)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.9))
            }
            .padding(14)
            .background(Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    struct ChangePasswordSheet: View {
        @Environment(\.dismiss) private var dismiss
        @State private var current: String = ""
        @State private var newPass: String = ""
        @State private var confirm: String = ""
        var body: some View {
            ZStack { Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Change Password").foregroundColor(.white).font(.system(size: 18, weight: .semibold))
                    SecureField("Current Password", text: $current)
                        .textContentType(.password)
                        .padding().background(Color.white.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12))
                    SecureField("New Password", text: $newPass)
                        .textContentType(.newPassword)
                        .padding().background(Color.white.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12))
                    SecureField("Confirm New Password", text: $confirm)
                        .textContentType(.newPassword)
                        .padding().background(Color.white.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12))
                    Button("Done") { dismiss() }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
            }
            .preferredColorScheme(.dark)
        }
    }

    struct HelpSupportSheet: View {
        @Environment(\.dismiss) private var dismiss
        var body: some View {
            ZStack { Color.black.ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Help & Support").foregroundColor(.white).font(.system(size: 18, weight: .semibold))
                    Text("For assistance, visit the Trips tab for guides or contact support@example.com.")
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    Button("Close") { dismiss() }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
            }
            .preferredColorScheme(.dark)
        }
    }
}

#if DEBUG
#Preview("Profile") {
    ProfileView()
        .environmentObject(UserStore())
}
#endif
