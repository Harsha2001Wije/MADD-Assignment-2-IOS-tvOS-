import SwiftUI

enum AppTheme: String, Codable {
    case system
    case light
    case dark
}

final class ThemeManager: ObservableObject {
    @Published var theme: AppTheme {
        didSet { persist() }
    }

    init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey), let val = AppTheme(rawValue: raw) {
            self.theme = val
        } else {
            self.theme = .dark
        }
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var isDark: Bool { theme == .dark }

    func setDark(_ on: Bool) {
        theme = on ? .dark : .light
    }

    func setTheme(_ t: AppTheme) {
        theme = t
    }

    private func persist() {
        UserDefaults.standard.set(theme.rawValue, forKey: Self.storageKey)
    }

    private static let storageKey = "ThemeManager.theme"
}
