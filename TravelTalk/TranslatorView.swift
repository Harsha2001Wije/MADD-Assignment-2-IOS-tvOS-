//
//  TranslatorView.swift
//  TravelTalk
//
//  Created by Cascade on 2025-11-16.
//

import SwiftUI
import UIKit
import AVFoundation
#if canImport(AVFAudio)
import AVFAudio
#endif
import Speech
import NaturalLanguage

struct TranslatorView: View {
    @EnvironmentObject private var saved: SavedPhrasesStore
    @State private var sourceLang: String = "English"
    @State private var targetLang: String = "Sinhala"
    @State private var inputText: String = ""
    @State private var outputText: String = ""
    @State private var showBigText: Bool = false
    @State private var copying: Bool = false
    @State private var listening: Bool = false
    @State private var authChecked: Bool = false
    @State private var translating: Bool = false
    @State private var translateError: String? = nil
    @State private var showSavedToast: Bool = false
    // Build recognizer per language when starting listening
    private let audioEngine = AVAudioEngine()
    @State private var request: SFSpeechAudioBufferRecognitionRequest?
    @State private var task: SFSpeechRecognitionTask?
    private var isPreview: Bool { ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header()

                    languageRow()

                    inputArea()

                    suggestions()

                    outputBubble()
                    if translating {
                        HStack { ProgressView().tint(Color.white); Text("Translating...").foregroundColor(.white.opacity(0.85)).font(.system(size: 13)) }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 6)
                    } else if let err = translateError {
                        Text(err).foregroundColor(.red).font(.system(size: 12)).padding(.top, 6)
                    }

                    bottomActions()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { }
        .overlay(alignment: .bottom) {
            if showSavedToast {
                Text("Saved to Trips")
                    .foregroundColor(.white)
                    .font(.system(size: 13, weight: .semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.75), in: Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                    .padding(.bottom, 90)
                    .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private func header() -> some View {
        HStack {
            Text("TravelTalk")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Button(action: saveCurrent) {
                Image(systemName: "bookmark")
                    .foregroundColor(.white)
            }
        }
    }

    @ViewBuilder
    private func languageRow() -> some View {
        HStack(spacing: 12) {
            Text(sourceLang)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
            Button(action: swapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(Color(hex: 0x3B82F6))
            }
            Text(targetLang)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
    }

    @ViewBuilder
    private func inputArea() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                TextEditor(text: $inputText)
                    .scrollContentBackground(.hidden)
                    .foregroundColor(.white)
                    .frame(minHeight: 110)
                    .font(.system(size: 16))
                    .onChange(of: inputText) { oldVal, newVal in
                        if newVal.hasSuffix("\n") {
                            inputText = String(newVal.trimmingCharacters(in: .whitespacesAndNewlines))
                            Task { await performTranslate() }
                        }
                    }
                Button(action: { inputText = "" }) {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            HStack {
                Spacer()
                Button(action: { Task { await performTranslate() } }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Translate")
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(hex: 0x3B82F6), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private func suggestions() -> some View {
        VStack(spacing: 18) {
            suggestionRow("How much for a tuk-tuk?")
            suggestionRow("Is this spicy?")
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private func suggestionRow(_ text: String) -> some View {
        Button(action: {
            inputText = text
            Task { await performTranslate() }
        }) {
            HStack {
                Image(systemName: "sparkle.magnifyingglass")
                    .foregroundColor(.white.opacity(0.9))
                Text(text)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "arrow.up")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func outputBubble() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(outputText)
                .foregroundColor(.white)
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(16)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .padding(.top, 24)
    }

    @ViewBuilder
    private func bottomActions() -> some View {
        HStack(spacing: 32) {
            Button(action: { showBigText = true }) {
                actionChip(title: "Big Text", icon: "arrow.up.left.and.arrow.down.right")
            }
            Spacer()

            Button(action: { listening ? stopListening() : startListening() }) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: 0x3B82F6), Color(hex: 0x2563EB)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 80, height: 80)
                        .shadow(color: Color(hex: 0x2563EB).opacity(0.55), radius: 12, x: 0, y: 8)
                    Image(systemName: listening ? "stop.fill" : "mic.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)

            Spacer()
            Button(action: copyOutput) {
                actionChip(title: "Copy", icon: "doc.on.doc")
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity, alignment: .center)
        .sheet(isPresented: $showBigText) {
            ZStack { Color.black.ignoresSafeArea()
                ScrollView { Text(outputText)
                        .foregroundColor(.white)
                        .font(.system(size: 44, weight: .bold))
                        .padding() }
            }.preferredColorScheme(.dark)
        }
    }

    @ViewBuilder
    private func actionChip(title: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(title)
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 13))
        }
    }
}

#if DEBUG
#Preview("Translator") {
    TranslatorView()
        .environmentObject(SavedPhrasesStore())
}
#endif

extension TranslatorView {
    private func saveCurrent() {
        let input = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let output = outputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty, !output.isEmpty else {
            translateError = "Nothing to save yet. Translate a phrase first."
            return
        }
        saved.add(sourceLang: sourceLang, targetLang: targetLang, input: input, output: output)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)) { showSavedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.2)) { showSavedToast = false }
        }
    }
    private func swapLanguages() {
        // Swap labels
        let s = sourceLang
        sourceLang = targetLang
        targetLang = s
        // Stop mic if running to avoid wrong locale capture
        if listening { stopListening() }
        // Prefer using last translated output as the new input
        let trimmedOut = outputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedOut.isEmpty {
            inputText = trimmedOut
        }
        // Reset output and error state
        outputText = ""
        translateError = nil
        // Trigger fresh translation in new direction if we have input
        let trimmedIn = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedIn.isEmpty {
            Task { await performTranslate() }
        }
    }

    private func langCode(_ name: String) -> String {
        switch name {
        case "English": return "en"
        case "Sinhala": return "si"
        default: return "en"
        }
    }

    private func speechLocaleId() -> String {
        switch sourceLang {
        case "Sinhala": return "si-LK"
        default: return "en-US"
        }
    }

    private func performTranslate() async {
        let q = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        let src = langCode(sourceLang)
        let tgt = langCode(targetLang)
        await MainActor.run { translating = true; translateError = nil }

        // Prefer POST-based LibreTranslate for longer inputs to avoid GET URL length issues.
        let isLong = q.count > 200
        let canUseLibre = libreSupports(tgt)

        if isLong && canUseLibre {
            if let first = try? await translateViaLibreWithFallbacks(q: q, src: src, tgt: tgt), let best = pickValidTranslation(original: q, candidate: first) {
                await MainActor.run { outputText = best; translating = false }
                return
            }
            if let second = try? await translateViaMyMemoryVariants(q: q, src: src, tgt: tgt), let best = pickValidTranslation(original: q, candidate: second) {
                await MainActor.run { outputText = best; translating = false }
                return
            }
        } else {
            if let first = try? await translateViaMyMemoryVariants(q: q, src: src, tgt: tgt), let best = pickValidTranslation(original: q, candidate: first) {
                await MainActor.run { outputText = best; translating = false }
                return
            }
            if canUseLibre, let second = try? await translateViaLibreWithFallbacks(q: q, src: src, tgt: tgt), let best = pickValidTranslation(original: q, candidate: second) {
                await MainActor.run { outputText = best; translating = false }
                return
            }
            // brief retry with MyMemory to handle transient rate limits
            try? await Task.sleep(nanoseconds: 300_000_000)
            if let retry = try? await translateViaMyMemoryVariants(q: q, src: src, tgt: tgt), let best = pickValidTranslation(original: q, candidate: retry) {
                await MainActor.run { outputText = best; translating = false }
                return
            }
            // Last-resort: chunked translation (sentences/words) via MyMemory
            if let chunked = try? await translateByChunks(q: q, src: src, tgt: tgt), let best = pickValidTranslation(original: q, candidate: chunked) {
                await MainActor.run { outputText = best; translating = false }
                return
            }
        }
        if let local = localFallback(q: q, src: src, tgt: tgt) {
            await MainActor.run { outputText = local; translating = false }
            return
        }
        await MainActor.run { translating = false; translateError = "Translation failed. Try again in a moment." }
    }

    private func myMemoryTranslateURL(q: String, src: String, tgt: String) -> URL? {
        let escaped = q.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? q
        let pair = "\(src)|\(tgt)"
        // mt=1 forces machine translation; omit 'de' to avoid provider rejecting identifier
        return URL(string: "https://api.mymemory.translated.net/get?q=\(escaped)&langpair=\(pair)&mt=1")
    }

    private func translateViaMyMemory(q: String, src: String, tgt: String) async throws -> String? {
        guard let url = myMemoryTranslateURL(q: q, src: src, tgt: tgt) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("TravelTalk/1.0 (iOS)", forHTTPHeaderField: "User-Agent")
        req.timeoutInterval = 10
        let (data, _) = try await URLSession.shared.data(for: req)
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
            // Ensure request succeeded
            let status = (json["responseStatus"] as? NSNumber)?.intValue ?? (json["responseStatus"] as? Int) ?? 0
            guard status == 200 else { return nil }
            if let resp = json["responseData"] as? [String: Any],
               let translated = resp["translatedText"] as? String, !translated.isEmpty {
                return translated
            }
            // Fallback to best match if responseData is weak/empty
            if let best = extractBestFromMyMemoryMatches(json: json) { return best }
        }
        return nil
    }

    private func translateViaMyMemoryVariants(q: String, src: String, tgt: String) async throws -> String? {
        // Try exact pair
        if let t = try? await translateViaMyMemory(q: q, src: src, tgt: tgt), let best = pickValidTranslation(original: q, candidate: t) { return best }
        // Try auto-detect source
        if let t = try? await translateViaMyMemory(q: q, src: "auto", tgt: tgt), let best = pickValidTranslation(original: q, candidate: t) { return best }
        // Try locale-specific Sinhala if source is Sinhala
        let srcAlt = (src == "si") ? "si-LK" : src
        if srcAlt != src, let t = try? await translateViaMyMemory(q: q, src: srcAlt, tgt: tgt), let best = pickValidTranslation(original: q, candidate: t) { return best }
        // Try locale-specific Sinhala if target is Sinhala
        let tgtAlt = (tgt == "si") ? "si-LK" : tgt
        if tgtAlt != tgt, let t = try? await translateViaMyMemory(q: q, src: src, tgt: tgtAlt), let best = pickValidTranslation(original: q, candidate: t) { return best }
        // Small pause and one more auto retry
        try? await Task.sleep(nanoseconds: 200_000_000)
        if let t = try? await translateViaMyMemory(q: q, src: "auto", tgt: tgt), let best = pickValidTranslation(original: q, candidate: t) { return best }
        return nil
    }

    private func translateViaLibre(q: String, src: String, tgt: String, endpoint: String = "https://libretranslate.com/translate") async throws -> String? {
        guard let url = URL(string: endpoint) else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        let body: [String: Any] = ["q": q, "source": src, "target": tgt, "format": "text"]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let translated = json["translatedText"] as? String {
            return translated
        }
        return nil
    }

    private func translateViaLibreWithFallbacks(q: String, src: String, tgt: String) async throws -> String? {
        // Try primary endpoint
        if let t = try? await translateViaLibre(q: q, src: src, tgt: tgt, endpoint: "https://libretranslate.com/translate") { return t }
        // Try mirror
        if let t = try? await translateViaLibre(q: q, src: src, tgt: tgt, endpoint: "https://libretranslate.de/translate") { return t }
        // Try source auto-detect on primary
        if let t = try? await translateViaLibre(q: q, src: "auto", tgt: tgt, endpoint: "https://libretranslate.com/translate") { return t }
        // Try source auto-detect on mirror
        if let t = try? await translateViaLibre(q: q, src: "auto", tgt: tgt, endpoint: "https://libretranslate.de/translate") { return t }
        return nil
    }

    private func pickValidTranslation(original: String, candidate: String?) -> String? {
        guard let candidate = candidate?.trimmingCharacters(in: .whitespacesAndNewlines), !candidate.isEmpty else { return nil }
        let normalized = normalizeWeirdPercentEncoding(candidate)
        let percentDecoded = normalized.removingPercentEncoding ?? normalized
        let decoded = decodeHTMLEntities(percentDecoded)
        // If provider returns nearly identical text (case-insensitive) or still URL-encoded, treat as invalid
        let same = decoded.caseInsensitiveCompare(original) == .orderedSame
        let looksEncoded = isLikelyPercentEncoded(candidate) || isLikelyPercentEncoded(decoded)
        let looksError = decoded.uppercased().contains("INVALID EMAIL") || decoded.uppercased().contains("ERROR ") || decoded.uppercased() == "ERROR"
        // Reject mixed-language results where Latin overwhelms Sinhala for Sinhala target cases
        if containsLatin(decoded) && containsSinhala(decoded) {
            let latin = countLatin(decoded)
            let sinhala = countSinhala(decoded)
            if latin >= sinhala { return nil }
        }
        // If target is English and output has some Latin words, prefer accepting it even if minor Sinhala punctuation remains.
        if (langCode(targetLang) == "en") {
            let hasLatinWord = decoded.split(separator: " ").contains { token in token.range(of: "[A-Za-z]", options: .regularExpression) != nil }
            if hasLatinWord { return decoded }
            // Otherwise, if it's still Sinhala-heavy, reject to trigger fallback
            if containsSinhala(decoded) { return nil }
        }
        if same || looksEncoded || looksError { return nil }
        return decoded
    }

    private func isLikelyPercentEncoded(_ s: String) -> Bool {
        guard s.contains("%") else { return false }
        // Simple heuristic: presence of multiple %XX triplets
        var count = 0
        let scalars = Array(s.utf8)
        var i = 0
        while i + 2 < scalars.count {
            if scalars[i] == 37 { // '%'
                let h1 = scalars[i+1]
                let h2 = scalars[i+2]
                if isHex(h1) && isHex(h2) { count += 1; i += 3; continue }
            }
            i += 1
        }
        return count >= 2
    }
    private func isHex(_ b: UInt8) -> Bool { (48...57).contains(b) || (65...70).contains(b) || (97...102).contains(b) }

    private func decodeHTMLEntities(_ s: String) -> String {
        guard let data = s.data(using: .utf8) else { return s }
        if let attr = try? NSAttributedString(
            data: data,
            options: [.documentType: NSAttributedString.DocumentType.html,
                      .characterEncoding: String.Encoding.utf8.rawValue],
            documentAttributes: nil) {
            let str = attr.string.trimmingCharacters(in: .whitespacesAndNewlines)
            return str.isEmpty ? s : str
        }
        return s
    }

    private func normalizeWeirdPercentEncoding(_ s: String) -> String {
        // Fix patterns like "%E0% B7% 83" by removing spaces after % and between triplets
        var out = s.replacingOccurrences(of: "% ", with: "%")
        if let regex = try? NSRegularExpression(pattern: "(%[0-9A-Fa-f]{2})\\s+(?=%[0-9A-Fa-f]{2})", options: []) {
            let range = NSRange(out.startIndex..<out.endIndex, in: out)
            out = regex.stringByReplacingMatches(in: out, options: [], range: range, withTemplate: "$1")
        }
        return out
    }

    private func extractBestFromMyMemoryMatches(json: [String: Any]) -> String? {
        guard let matches = json["matches"] as? [[String: Any]] else { return nil }
        var bestQuality = -1
        var bestText: String?
        for m in matches {
            let q = (m["quality"] as? NSString)?.integerValue ?? (m["quality"] as? Int) ?? 0
            if let t = m["translation"] as? String {
                if q > bestQuality, let valid = pickValidTranslation(original: "", candidate: t) { // original unused here
                    bestQuality = q
                    bestText = valid
                }
            }
        }
        return bestText
    }

    private func libreSupports(_ code: String) -> Bool {
        let supported: Set<String> = ["en","ar","az","zh","cs","nl","fr","de","hi","it","ja","ko","pl","pt","ru","es","tr","uk","vi"]
        return supported.contains(code)
    }

    private func localFallback(q: String, src: String, tgt: String) -> String? {
        let punctuation = CharacterSet(charactersIn: ".!?၊၊–—:;()[]{}\n")
        let key = q.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: punctuation).joined().trimmingCharacters(in: .whitespacesAndNewlines)
        // EN -> SI
        if src == "en", (tgt == "si" || tgt == "si-LK") {
            let map: [String: String] = [
                "hello": "හෙලෝ",
                "hi": "හයි",
                "good morning": "සුභ උදෑසනක්",
                "good afternoon": "සුභ දවල්වෙලාවක්",
                "good evening": "සුභ සන්ධ්‍යාවක්",
                "good night": "සුභ රාත්රියක්",
                "thank you": "ස්තූතියි",
                "please": "කරුණාකර",
                "sorry": "සමාවෙන්න",
                "i like you": "මට ඔබ කැමතියි",
                "you are beautiful": "ඔබ සුන්දරයි"
            ]
            return map[key]
        }
        // SI -> EN
        if (src == "si" || src == "si-LK"), tgt == "en" {
            let map: [String: String] = [
                "හෙලෝ": "hello",
                "හයි": "hi",
                "සුභ උදෑසනක්": "good morning",
                "සුභ දවල්වෙලාවක්": "good afternoon",
                "සුභ සන්ධ්‍යාවක්": "good evening",
                "සුභ රාත්රියක්": "good night",
                "ස්තූතියි": "thank you",
                "කරුණාකර": "please",
                "සමාවෙන්න": "sorry",
                "මට ඔබ කැමතියි": "i like you",
                "ඔබ සුන්දරයි": "you are beautiful",
                "ආයුබෝවන්": "hello",
                "අද": "today",
                "අදෝ": "oh",
                "මට බඩගිනිය": "i am hungry",
                "ඔබට කොහොමද": "how are you",
                "මට උදව් කරන්න": "please help me"
            ]
            return map[key]
        }
        return nil
    }

    private func containsSinhala(_ s: String) -> Bool { s.unicodeScalars.contains { $0.value >= 0x0D80 && $0.value <= 0x0DFF } }
    private func containsLatin(_ s: String) -> Bool { s.unicodeScalars.contains { ($0.value >= 65 && $0.value <= 90) || ($0.value >= 97 && $0.value <= 122) } }
    private func countSinhala(_ s: String) -> Int { s.unicodeScalars.reduce(0) { $0 + ((0x0D80...0x0DFF).contains(Int($1.value)) ? 1 : 0) } }
    private func countLatin(_ s: String) -> Int { s.unicodeScalars.reduce(0) { $0 + (((65...90).contains(Int($1.value)) || (97...122).contains(Int($1.value))) ? 1 : 0) } }

    // Chunked fallback: translate sentence-by-sentence, then word-by-word if needed
    private func translateByChunks(q: String, src: String, tgt: String) async throws -> String? {
        let sentences = splitIntoSentencesPreservingDelimiters(q)
        guard !sentences.isEmpty else { return nil }
        var out: [String] = []
        for s in sentences {
            let trimmed = s.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            if let t = try? await translateViaMyMemoryVariants(q: trimmed, src: src, tgt: tgt), let best = pickValidTranslation(original: trimmed, candidate: t) {
                out.append(best)
            } else {
                let words = trimmed.split(separator: " ")
                if words.count <= 2 {
                    out.append(trimmed)
                } else {
                    var wb: [String] = []
                    for w in words {
                        let ws = String(w)
                        if let tw = try? await translateViaMyMemoryVariants(q: ws, src: src, tgt: tgt), let bw = pickValidTranslation(original: ws, candidate: tw) {
                            wb.append(bw)
                        } else {
                            wb.append(ws)
                        }
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    out.append(wb.joined(separator: " "))
                }
            }
            try? await Task.sleep(nanoseconds: 120_000_000)
        }
        return out.joined(separator: " ")
    }

    private func splitIntoSentencesPreservingDelimiters(_ text: String) -> [String] {
        var result: [String] = []
        var buffer = ""
        for ch in text {
            buffer.append(ch)
            if ch == "." || ch == "!" || ch == "?" || ch == "\n" {
                result.append(buffer)
                buffer = ""
            }
        }
        if !buffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { result.append(buffer) }
        return result
    }

    private func copyOutput() {
        UIPasteboard.general.string = outputText
    }

    private func configureAudio() {
        if authChecked { return }
        if isPreview { return }
        guard hasRequiredPrivacyKeys() else {
            translateError = "Missing Info.plist keys: NSMicrophoneUsageDescription and NSSpeechRecognitionUsageDescription."
            return
        }
        SFSpeechRecognizer.requestAuthorization { _ in }
        if #available(iOS 17.0, *) {
            #if canImport(AVFAudio)
            AVAudioApplication.requestRecordPermission { _ in }
            #else
            AVAudioSession.sharedInstance().requestRecordPermission { _ in }
            #endif
        } else {
            AVAudioSession.sharedInstance().requestRecordPermission { _ in }
        }
        authChecked = true
    }

    private func hasRequiredPrivacyKeys() -> Bool {
        let mic = Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") as? String
        let speech = Bundle.main.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") as? String
        return mic != nil && speech != nil
    }

    private func startListening() {
        if isPreview { return }
        if !authChecked {
            configureAudio()
            if !authChecked { return }
        }
        guard !audioEngine.isRunning else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true)
        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { return }
        request.shouldReportPartialResults = true
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }
        audioEngine.prepare()
        try? audioEngine.start()
        let locale = Locale(identifier: speechLocaleId())
        let recognizer = SFSpeechRecognizer(locale: locale)
        task = recognizer?.recognitionTask(with: request) { result, error in
            if let result = result {
                inputText = result.bestTranscription.formattedString
            }
            if error != nil || (result?.isFinal ?? false) {
                stopListening()
                Task { await performTranslate() }
            }
        }
        listening = true
    }

    private func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        listening = false
    }
}
