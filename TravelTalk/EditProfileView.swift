import SwiftUI
import UIKit
import PhotosUI

struct EditProfileView: View {
    @Binding var name: String
    @Binding var email: String
    @Binding var avatarImage: UIImage?
    @State private var country: String = "United Kingdom"
    @State private var language: String = "English"
    @Environment(\.dismiss) private var dismiss
    // Drafts so edits don't immediately change the profile until saved
    @State private var draftName: String = ""
    @State private var draftEmail: String = ""
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var showLanguagePicker: Bool = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 20) {
                header
                avatar
                formCard
                Spacer()
                primaryButtons
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            // Initialize drafts from current bindings when sheet opens
            draftName = name
            draftEmail = email
        }
        .onChange(of: photoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    await MainActor.run { avatarImage = ui }
                }
            }
        }
        .confirmationDialog("Select Language", isPresented: $showLanguagePicker, titleVisibility: .visible) {
            Button("English") { language = "English" }
            Button("Sinhala") { language = "Sinhala" }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .opacity(0.9)
                    .onTapGesture { dismiss() }
                Spacer()
                Text("Edit Profile")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                Color.clear.frame(width: 24, height: 24)
            }
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
        }
    }

    private var avatar: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let img = avatarImage {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.white)
                        .padding(3)
                }
            }
            .frame(width: 98, height: 98)
            .background(Color.white.opacity(0.08))
            .clipShape(Circle())

            PhotosPicker(selection: $photoItem, matching: .images) {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                    .background(Circle().fill(Color.blue).frame(width: 26, height: 26))
            }
            .offset(x: 6, y: 6)
            .buttonStyle(.plain)
        }
        .padding(.top, 10)
    }

    private var formCard: some View {
        VStack(spacing: 0) {
            formRow(title: "Full Name", value: $draftName, editable: true)
            divider
            formRow(title: "Email", value: $draftEmail, editable: true, keyboard: .emailAddress)
            divider
            formRow(title: "Home Country", value: $country, editable: true)
            divider
            pickerRow(title: "Language", value: $language)
        }
        .padding(10)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var divider: some View { Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1) }

    private func formRow(title: String, value: Binding<String>, editable: Bool, keyboard: UIKeyboardType = .default) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 13))
                .frame(width: 110, alignment: .leading)
            if editable {
                TextField("", text: value)
                    .keyboardType(keyboard)
                    .foregroundColor(.white)
            } else {
                Text(value.wrappedValue)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .frame(height: 44)
    }

    private func pickerRow(title: String, value: Binding<String>) -> some View {
        Button(action: { if title == "Language" { showLanguagePicker = true } }) {
            HStack(spacing: 12) {
                Text(title)
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 13))
                    .frame(width: 110, alignment: .leading)
                Text(value.wrappedValue)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.9))
            }
            .frame(height: 44)
        }
        .buttonStyle(.plain)
    }

    private var primaryButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Apply drafts to bindings and close
                name = draftName
                email = draftEmail
                dismiss()
            }) {
                Text("Save Changes")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.blue, in: Capsule())
            }
            .buttonStyle(.plain)

            Button(action: { dismiss() }) {
                Text("Cancel")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

#if DEBUG
#Preview("EditProfile") {
    EditProfileView(
        name: .constant("Amelia Renshaw"),
        email: .constant("amelia.renshaw@example.com"),
        avatarImage: .constant(nil)
    )
}
#endif
