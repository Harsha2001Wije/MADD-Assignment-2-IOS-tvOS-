//
//  HomeView.swift
//  TravelTalk
//
//  Created by Cascade on 2025-11-16.
//

import SwiftUI
import SafariServices

struct HomeView: View {
    @Binding var selectedTab: Int
    @Environment(\.openURL) private var openURL
    @State private var goProfile: Bool = false
    @State private var goTranslator: Bool = false
    @State private var goMap: Bool = false
    @State private var goTrips: Bool = false
    @State private var showEmergency: Bool = false
    @State private var amountInput: String = "100"
    @State private var fromCode: String = "USD"
    @State private var toCode: String = "LKR"
    @State private var rate: Double = 300.50
    @State private var converting: Bool = false
    @State private var showTrainWeb: Bool = false
    @State private var trainURL: URL? = nil
    @State private var navPath: [String] = []
    var body: some View {
        NavigationStack(path: $navPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header()

                    Text("Hello, Alex!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 6)

                    heroCard()

                    sectionTitle("Quick Access")
                    quickAccess()

                    sectionTitle("Currency Converter")
                    currencyCard()

                    sectionTitle("Recent Phrases")
                    phrasesRow()

                    featureGrid()

                    tripsCard()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar(.hidden)
            // iOS 16+ style boolean destinations
            .navigationDestination(isPresented: $goTranslator) { TranslatorView() }
            .navigationDestination(isPresented: $goMap) { MapView() }
            .navigationDestination(isPresented: $goTrips) { TripsView() }
        }
        .preferredColorScheme(.dark)
        .navigationDestination(for: String.self) { route in
            switch route {
            case "profile": ProfileView()
            default: EmptyView()
            }
        }
        .confirmationDialog("Emergency Contacts", isPresented: $showEmergency, titleVisibility: .visible) {
            Button("Police (119)") { if let u = URL(string: "tel://119") { openURL(u) } }
            Button("Ambulance (1990)") { if let u = URL(string: "tel://1990") { openURL(u) } }
            Button("Fire (110)") { if let u = URL(string: "tel://110") { openURL(u) } }
        }
        .task { await fetchRate() }
        .sheet(isPresented: $showTrainWeb) {
            if let url = trainURL {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }

    @ViewBuilder
    private func header() -> some View {
        HStack {
            Text("TravelTalk")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            Button(action: { selectedTab = 4 }) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
        }
    }

    private func heroCard() -> some View {
        // Base card with image/gradient + dark overlays
        let base = Group {
            if UIImage(named: "HomeHero") != nil {
                Image("HomeHero")
                    .resizable()
                    .scaledToFill()
            } else {
                LinearGradient(colors: [Color(hex: 0x1F2937), Color(hex: 0x0F172A)], startPoint: .top, endPoint: .bottom)
            }
        }
        .overlay(
            LinearGradient(
                colors: [Color.black.opacity(0.15), Color.black.opacity(0.80)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            LinearGradient(
                colors: [Color.black.opacity(0.0), Color.black.opacity(0.90)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 96), alignment: .bottom
        )

        return base
            .frame(height: 150)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discover Sri Lanka")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.7), radius: 10, x: 0, y: 2)
                    Text("Your essential travel companion")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.98))
                        .shadow(color: .black.opacity(0.7), radius: 10, x: 0, y: 2)
                }
                .padding(14)
            }
    }

    @ViewBuilder
    private func quickAccess() -> some View {
        VStack(spacing: 12) {
            quickRow(icon: "tram.fill", tint: Color(hex: 0x2563EB), title: "Today: Train to Ella", subtitle: "View tickets & schedule") {
                openTrainSchedule()
            }
            quickRow(icon: "sos.circle.fill", tint: Color(hex: 0xDC2626), title: "Emergency Contacts", subtitle: "Police, Ambulance, Fire") {
                showEmergency = true
            }
        }
    }

    @ViewBuilder
    private func quickRow(icon: String, tint: Color, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.15))
                    Image(systemName: icon)
                        .foregroundColor(.white)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                    Text(subtitle)
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 13))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func currencyCard() -> some View {
        ZStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading) {
                        Text("You give")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 12))
                        TextField("0", text: $amountInput)
                            .keyboardType(.decimalPad)
                            .foregroundColor(.white)
                            .font(.system(size: 24, weight: .bold))
                        Text(fromCode)
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("You get")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.system(size: 12))
                        Text(convertedAmount())
                            .foregroundColor(Color(hex: 0x3B82F6))
                            .font(.system(size: 24, weight: .bold))
                        Text(toCode)
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                Text(rateLine())
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: 11))
            }

            Button(action: swapCurrencies) {
                Image(systemName: "arrow.left.arrow.right.circle.fill")
                    .foregroundColor(Color(hex: 0x3B82F6))
                    .font(.system(size: 28))
                    .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func phrasesRow() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                phraseChip("ආයුබෝවන්\nHello")
                phraseChip("ස්තුතියි\nThank you")
                phraseChip("හෙලෝ\nHi")
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private func phraseChip(_ text: String) -> some View {
        Text(text)
            .multilineTextAlignment(.center)
            .foregroundColor(.white)
            .font(.system(size: 13))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func featureGrid() -> some View {
        HStack(spacing: 12) {
            Spacer(minLength: 0)
            featureTile(title: "Smart\nTranslator", color1: 0xF59E0B, color2: 0xD97706, icon: "mic.fill") { goTranslator = true }
                .frame(width: 160)
            featureTile(title: "Nearby\nEssentials", color1: 0x3B82F6, color2: 0x2563EB, icon: "location.fill") { goMap = true }
                .frame(width: 160)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func featureTile(title: String, color1: UInt, color2: UInt, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                LinearGradient(colors: [Color(hex: color1), Color(hex: color2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.black.opacity(0.85))
                        .padding(8)
                        .background(Color.white.opacity(0.9), in: Circle())
                    Text(title)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
                .padding(14)
            }
            .frame(height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func tripsCard() -> some View {
        Button(action: { goTrips = true }) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .padding(10)
                    .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Trips")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                    Text("Itineraries & saved places")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.system(size: 13))
                }
                Spacer()
            }
            .padding(14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .foregroundColor(.white.opacity(0.9))
            .font(.system(size: 15, weight: .semibold))
            .padding(.top, 6)
    }
}

// MARK: - Currency helpers
extension HomeView {
    private func swapCurrencies() {
        let tmp = fromCode
        fromCode = toCode
        toCode = tmp
        Task { await fetchRate() }
    }

    private func convertedAmount() -> String {
        let amount = Double(amountInput) ?? 0
        let value = amount * rate
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    private func rateLine() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 4
        let r = formatter.string(from: NSNumber(value: rate)) ?? String(rate)
        return "1 \(fromCode) = \(r) \(toCode). Rates are for reference only."
    }

    private func fetchRate() async {
        if fromCode == toCode { rate = 1; return }
        converting = true
        let urlStr = "https://api.exchangerate.host/latest?base=\(fromCode)&symbols=\(toCode)"
        guard let url = URL(string: urlStr) else { converting = false; return }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let rates = json["rates"] as? [String: Any],
               let val = rates[toCode] as? Double {
                await MainActor.run { rate = val }
            }
        } catch {
            // keep previous rate on failure
        }
        converting = false
    }

    private func openTrainSchedule() {
        // Try official railway site first; open in in-app Safari sheet
        let candidates = [
            "https://eservices.railway.gov.lk/schedule/searchTrain.action?lang=en",
            "https://seat61.com/SriLanka.htm",
            "https://www.google.com/search?q=train+schedule+to+Ella+Sri+Lanka"
        ]
        for s in candidates {
            if let url = URL(string: s) {
                trainURL = url
                showTrainWeb = true
                return
            }
        }
    }
}

#if DEBUG
#Preview("Home") {
    HomeView(selectedTab: .constant(0))
        .environmentObject(ThemeManager())
}
#endif

// MARK: - Safari wrapper
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    func updateUIViewController(_ vc: SFSafariViewController, context: Context) {}
}
