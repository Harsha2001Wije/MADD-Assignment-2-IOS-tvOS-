import Foundation
import Combine

struct SavedPhrase: Identifiable, Codable, Equatable {
    let id: UUID
    let sourceLang: String
    let targetLang: String
    let input: String
    let output: String
    let date: Date
}

final class SavedPhrasesStore: ObservableObject {
    @Published private(set) var phrases: [SavedPhrase] = [] {
        didSet { persist() }
    }

    private let storageKey = "SavedPhrasesStore.phrases"

    init() {
        load()
    }

    func add(sourceLang: String, targetLang: String, input: String, output: String) {
        let trimmedIn = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOut = output.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedIn.isEmpty, !trimmedOut.isEmpty else { return }
        let item = SavedPhrase(id: UUID(), sourceLang: sourceLang, targetLang: targetLang, input: trimmedIn, output: trimmedOut, date: Date())
        phrases.insert(item, at: 0)
    }

    func remove(at offsets: IndexSet) {
        phrases.remove(atOffsets: offsets)
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(phrases)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            // ignore
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        if let arr = try? JSONDecoder().decode([SavedPhrase].self, from: data) {
            phrases = arr
        }
    }
}
