import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("darkModeEnabled") private var darkModeEnabled: Bool = true

    // General
    @State private var defaultFromLang: String = "English"
    @State private var defaultToLang: String = "Sinhala"
    @State private var showLanguagePicker: Bool = false

    // Accessibility
    @State private var largeText: Bool = false

    private let languages = ["English", "Sinhala", "Tamil"]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    header

                    sectionLabel("Appearance")
                    appearanceCard

                    sectionLabel("General")
                    generalCard

                    sectionLabel("Accessibility")
                    accessibilityCard

                    Spacer(minLength: 12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(darkModeEnabled ? .dark : .light)
        .confirmationDialog("Default Translation", isPresented: $showLanguagePicker, titleVisibility: .visible) {
            ForEach(languages, id: \.self) { from in
                ForEach(languages.filter { $0 != from }, id: \.self) { to in
                    Button("\(from) → \(to)") {
                        defaultFromLang = from
                        defaultToLang = to
                    }
                }
            }
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
                Text("Settings")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                Color.clear.frame(width: 24, height: 24)
            }
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        VStack(spacing: 8) {
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
            Text(text.uppercased())
                .foregroundColor(.white.opacity(0.7))
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var appearanceCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "moon.fill")
                    .foregroundColor(.white)
                    .frame(width: 22)
                Text("Dark Mode")
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $darkModeEnabled).labelsHidden()
            }
            .padding(14)
        }
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var generalCard: some View {
        VStack(spacing: 0) {
            Button(action: { showLanguagePicker = true }) {
                HStack(spacing: 12) {
                    Image(systemName: "globe.asia.australia.fill")
                        .foregroundColor(.white)
                        .frame(width: 22)
                    Text("Default Translation")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(defaultFromLang) → \(defaultToLang)")
                        .foregroundColor(.white.opacity(0.9))
                    Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.9))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)

            Button(action: { /* future: manage saved trips screen */ }) {
                HStack(spacing: 12) {
                    Image(systemName: "archivebox.fill")
                        .foregroundColor(.white)
                        .frame(width: 22)
                    Text("Manage Saved Trips")
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.9))
                }
                .padding(14)
            }
            .buttonStyle(.plain)
        }
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var accessibilityCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: "textformat.size.larger")
                    .foregroundColor(.white)
                    .frame(width: 22)
                Text("Large Text")
                    .foregroundColor(.white)
                Spacer()
                Toggle("", isOn: $largeText).labelsHidden()
            }
            .padding(14)
        }
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

#if DEBUG
#Preview("Settings") {
    SettingsView()
        .environmentObject(ThemeManager())
}
#endif
