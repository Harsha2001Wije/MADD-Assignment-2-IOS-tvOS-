import SwiftUI
import AVFoundation

struct TripsView: View {
    @EnvironmentObject private var saved: SavedPhrasesStore
    @State private var segment: Int = 0
    @State private var searchText: String = ""
    @State private var selectedDetail: PlaceDetail?
    private let tts = AVSpeechSynthesizer()
    @State private var speakingPhraseId: UUID?
    @State private var ttsToast: String? = nil

    private struct Phrase: Identifiable { let id = UUID(); let title: String; let subtitle: String; let lang: String }
    private struct PlaceDetail: Identifiable { let id = UUID(); let title: String; let subtitle: String; let imageURL: URL? }
    private let phrases: [Phrase] = [
        .init(title: "How much is this?", subtitle: "මෙක කීයද?", lang: "Sinhala"),
        .init(title: "Can you help me?", subtitle: "මට උදව් කළහැකිද?", lang: "Sinhala"),
        .init(title: "Where is the train station?", subtitle: "දෙරැලි ස්ථානය කොහෙද?", lang: "Sinhala")
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 14) {
                header
                segments
                searchField
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        if segment == 0 {
                            if filteredSavedPhrases.isEmpty {
                                emptySavedPhrases
                            } else {
                                ForEach(filteredSavedPhrases) { p in savedPhraseRow(p) }
                                .animation(.default, value: filteredSavedPhrases.count)
                            }
                        } else {
                            placeRow(
                                title: "Nine Arch Bridge",
                                subtitle: "Ella, Sri Lanka",
                                imageURL: URL(string: "https://images.unsplash.com/photo-1566296314736-6eaac1ca0cb9?q=80&w=1200&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"),
                                onInfo: {
                                    selectedDetail = PlaceDetail(
                                        title: "Nine Arch Bridge",
                                        subtitle: "Ella, Sri Lanka",
                                        imageURL: URL(string: "https://images.unsplash.com/photo-1566296314736-6eaac1ca0cb9?q=80&w=1200&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")
                                    )
                                }
                            )
                        }
                        ctaCard
                    }
                    .padding(.vertical, 6)
                }
            }
            .padding(.horizontal, 16)
            .sheet(item: $selectedDetail) { d in
                PlaceQuickDetail(title: d.title, subtitle: d.subtitle, imageURL: d.imageURL)
                    .presentationDetents([.fraction(0.4)])
                    .presentationDragIndicator(.visible)
            }
            if let msg = ttsToast {
                VStack { Spacer() 
                    Text(msg)
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.75), in: Capsule())
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        .padding(.bottom, 24)
                }
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { configureAudio() }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "chevron.left")
                    .foregroundColor(.white)
                    .opacity(0.9)
                Spacer()
                Text("My Trips")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .semibold))
                Spacer()
                Color.clear.frame(width: 24, height: 24)
            }
            Rectangle().fill(Color.white.opacity(0.12)).frame(height: 1)
        }
    }

    // MARK: - TTS Helpers
    private func containsSinhala(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            if scalar.value >= 0x0D80 && scalar.value <= 0x0DFF { return true }
        }
        return false
    }

    private func langCode(for language: String, text: String) -> String {
        if containsSinhala(text) { return "si-LK" }
        let lang = language.lowercased()
        if lang.contains("sinh") || lang == "si" || lang == "si-lk" { return "si-LK" }
        if lang.contains("eng") || lang == "en" || lang.hasPrefix("en-") { return "en-US" }
        // default fallback
        return "en-US"
    }

    private func bestVoice(for langCode: String) -> AVSpeechSynthesisVoice? {
        // Exact match first
        if let v = AVSpeechSynthesisVoice(language: langCode) { return v }
        // Fallback: same language family (e.g., "si")
        let family = String(langCode.prefix(2))
        return AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix(family) }
    }

    private func speak(text: String, langCode: String) {
        // If already speaking, stop as a toggle
        if tts.isSpeaking { tts.stopSpeaking(at: .immediate) }
        // Configure audio session right before speaking
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            // ignore and continue
        }
        // Remove punctuation so the engine doesn't read, e.g., "question mark"
        let cleaned = text.unicodeScalars.filter { !CharacterSet.punctuationCharacters.contains($0) }.map(String.init).joined()
        guard !cleaned.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let utterance = AVSpeechUtterance(string: cleaned)
        // Pick the best voice available for the requested language
        let chosen = bestVoice(for: langCode) ?? AVSpeechSynthesisVoice(language: langCode)
        // If Sinhala requested but voice not available, show a helpful toast and bail
        if langCode.hasPrefix("si") && chosen == nil {
            withAnimation(.easeInOut(duration: 0.2)) { ttsToast = "Sinhala voice not available on this device. Try on a real device or install a Sinhala voice in Settings > Accessibility > Spoken Content > Voices." }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.2)) { ttsToast = nil }
            }
            return
        }
        utterance.voice = chosen
        // Slightly slower for Sinhala to improve clarity
        utterance.rate = (langCode.hasPrefix("si")) ? AVSpeechUtteranceDefaultSpeechRate * 0.48 : AVSpeechUtteranceDefaultSpeechRate
        utterance.volume = 1.0
        utterance.pitchMultiplier = 1.0
        utterance.preUtteranceDelay = 0.0
        utterance.postUtteranceDelay = 0.0
        DispatchQueue.main.async { self.tts.speak(utterance) }
    }

    private func configureAudio() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true)
        } catch {
        }
    }

    private var segments: some View {
        HStack(spacing: 8) {
            segmentButton(title: "Saved Phrases", index: 0)
            segmentButton(title: "Saved Places", index: 1)
        }
    }

    private func segmentButton(title: String, index: Int) -> some View {
        Button(action: { withAnimation(.easeInOut(duration: 0.2)) { segment = index } }) {
            Text(title)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(segment == index ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundColor(.white.opacity(0.85))
            TextField("Search your Sri Lanka trip", text: $searchText)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 1))
    }

    private func phraseRow(_ p: Phrase) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(p.title)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                Text(p.subtitle)
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 13))
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(p.lang)
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 13))
                Button(action: {
                    speakingPhraseId = p.id
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    let txt = p.subtitle.isEmpty ? p.title : p.subtitle
                    speak(text: txt, langCode: langCode(for: p.lang, text: txt))
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { withAnimation(.easeOut(duration: 0.2)) { speakingPhraseId = nil } }
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(Color.blue)
                        .padding(10)
                        .background((speakingPhraseId == p.id ? Color.blue.opacity(0.25) : Color.white.opacity(0.15)))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
                .scaleEffect(speakingPhraseId == p.id ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: speakingPhraseId == p.id)
                .accessibilityLabel("Play pronunciation")
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var filteredSavedPhrases: [SavedPhrase] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return saved.phrases }
        return saved.phrases.filter { $0.input.lowercased().contains(q) || $0.output.lowercased().contains(q) || $0.sourceLang.lowercased().contains(q) || $0.targetLang.lowercased().contains(q) }
    }

    private func savedPhraseRow(_ item: SavedPhrase) -> some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.input)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(2)
                Text(item.output)
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 13))
                    .lineLimit(3)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text("\(item.sourceLang) → \(item.targetLang)")
                    .foregroundColor(.white.opacity(0.85))
                    .font(.system(size: 12))
                HStack(spacing: 8) {
                    Button(action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        if speakingPhraseId == item.id && tts.isSpeaking {
                            tts.stopSpeaking(at: .immediate)
                            withAnimation(.easeOut(duration: 0.2)) { speakingPhraseId = nil }
                        } else {
                            speakingPhraseId = item.id
                            let speakLang = item.targetLang
                            let text = item.output.isEmpty ? item.input : item.output
                            speak(text: text, langCode: langCode(for: speakLang, text: text))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { withAnimation(.easeOut(duration: 0.2)) { speakingPhraseId = nil } }
                        }
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(Color.blue)
                            .padding(10)
                            .background((speakingPhraseId == item.id ? Color.blue.opacity(0.25) : Color.white.opacity(0.15)))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .scaleEffect(speakingPhraseId == item.id ? 1.05 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: speakingPhraseId == item.id)
                    .accessibilityLabel("Play pronunciation")

                    Button(role: .destructive, action: {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        deleteSaved(item)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(Color.red)
                            .padding(10)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Delete saved phrase")
                }
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contextMenu {
            Button(role: .destructive) { deleteSaved(item) } label: { Label("Delete", systemImage: "trash") }
            Button { UIPasteboard.general.string = item.output } label: { Label("Copy output", systemImage: "doc.on.doc") }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) { deleteSaved(item) } label: { Label("Delete", systemImage: "trash") }
        }
    }

    private var emptySavedPhrases: some View {
        VStack(spacing: 8) {
            Image(systemName: "bookmark")
                .foregroundColor(.white.opacity(0.8))
            Text("No saved phrases yet")
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .semibold))
            Text("Go to Translator and tap the bookmark after translating.")
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 13))
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func deleteSaved(_ item: SavedPhrase) {
        if let idx = saved.phrases.firstIndex(of: item) {
            saved.remove(at: IndexSet(integer: idx))
        }
    }

    private func placeRow(title: String, subtitle: String, imageURL: URL? = URL(string: "https://images.unsplash.com/photo-1566296314736-6eaac1ca0cb9?q=80&w=640&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"), onInfo: @escaping () -> Void = {}) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 46, height: 46)
                if let url = imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().scaledToFill()
                                .frame(width: 46, height: 46)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        case .empty:
                            ProgressView()
                                .frame(width: 46, height: 46)
                        case .failure:
                            Image(systemName: "photo").foregroundColor(.white)
                        @unknown default:
                            Image(systemName: "photo").foregroundColor(.white)
                        }
                    }
                } else {
                    Image(systemName: "photo").foregroundColor(.white)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).foregroundColor(.white).font(.system(size: 16, weight: .semibold)).lineLimit(1)
                Text(subtitle).foregroundColor(.white.opacity(0.85)).font(.system(size: 13))
            }
            Spacer()
            Button(action: onInfo) {
                Image(systemName: "chevron.right").foregroundColor(.white.opacity(0.9))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private struct PlaceQuickDetail: View {
        let title: String
        let subtitle: String
        let imageURL: URL?
        var body: some View {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)
                if let url = imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img): img.resizable().scaledToFill().frame(height: 140).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        case .empty: ProgressView().frame(height: 140)
                        case .failure: Image(systemName: "photo").foregroundColor(.white).frame(height: 140)
                        @unknown default: Image(systemName: "photo").foregroundColor(.white).frame(height: 140)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text(title).foregroundColor(.white).font(.system(size: 18, weight: .semibold))
                    Text(subtitle).foregroundColor(.white.opacity(0.85)).font(.system(size: 13))
                    Text("A famous colonial-era viaduct bridge in Ella, also known as the Bridge in the Sky.")
                        .foregroundColor(.white.opacity(0.9))
                        .font(.system(size: 13))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .background(Color.black)
            .preferredColorScheme(.dark)
        }
    }

    private var ctaCard: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.north.circle")
                .font(.system(size: 36, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .padding(8)
                .background(Color.white.opacity(0.10))
                .clipShape(Circle())
            Text("Start your Sri Lankan journey")
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .semibold))
            Text("Save useful phrases and amazing places you discover in Sri Lanka to easily find them later.")
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

#if DEBUG
#Preview("Trips") {
    TripsView()
        .environmentObject(SavedPhrasesStore())
}
#endif
