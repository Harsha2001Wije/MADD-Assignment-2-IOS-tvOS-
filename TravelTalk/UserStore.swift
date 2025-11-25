import Foundation
import Combine

struct AppUser: Codable, Identifiable, Equatable {
    let id: String
    var fullName: String
    var email: String
    var password: String // For demo only. Do NOT store plain passwords in production.
}

final class UserStore: ObservableObject {
    @Published private(set) var users: [AppUser] = []
    @Published var currentUserId: String? = nil

    var isSignedIn: Bool { currentUserId != nil }
    var currentUser: AppUser? { users.first(where: { $0.id == currentUserId }) }

    private let usersKey = "tt_users_json"
    private let currentKey = "tt_current_user_id"

    init() {
        load()
    }

    // MARK: - Public API
    func signUp(fullName: String, email: String, password: String) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            throw NSError(domain: "UserStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing required fields."])
        }
        guard users.first(where: { $0.email == trimmedEmail }) == nil else {
            throw NSError(domain: "UserStore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Email already exists."])
        }
        let new = AppUser(id: UUID().uuidString, fullName: fullName, email: trimmedEmail, password: password)
        users.append(new)
        save()
    }

    func login(email: String, password: String) throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let user = users.first(where: { $0.email == trimmedEmail && $0.password == password }) else {
            throw NSError(domain: "UserStore", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials."])
        }
        currentUserId = user.id
        save()
    }

    func logout() {
        currentUserId = nil
        save()
    }

    func updateCurrentUser(fullName: String? = nil, email: String? = nil, password: String? = nil) throws {
        guard let id = currentUserId, let idx = users.firstIndex(where: { $0.id == id }) else { return }
        var u = users[idx]
        if let n = fullName { u.fullName = n }
        if let e = email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            if e != u.email, users.contains(where: { $0.email == e }) {
                throw NSError(domain: "UserStore", code: 4, userInfo: [NSLocalizedDescriptionKey: "Email already taken."])
            }
            u.email = e
        }
        if let p = password { u.password = p }
        users[idx] = u
        save()
    }

    func deleteCurrentUser() {
        guard let id = currentUserId else { return }
        users.removeAll { $0.id == id }
        currentUserId = nil
        save()
    }

    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(users) {
            UserDefaults.standard.set(data, forKey: usersKey)
        }
        UserDefaults.standard.set(currentUserId, forKey: currentKey)
        objectWillChange.send()
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: usersKey),
           let decoded = try? JSONDecoder().decode([AppUser].self, from: data) {
            users = decoded
        }
        currentUserId = UserDefaults.standard.string(forKey: currentKey)
    }
}
