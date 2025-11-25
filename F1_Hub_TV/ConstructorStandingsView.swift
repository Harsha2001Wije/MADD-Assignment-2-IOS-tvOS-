import SwiftUI

struct ConstructorStandingsView: View {
    var backgroundAssetName: String = "fullScreenCover"
    @EnvironmentObject private var router: Router
    private let contentWidth: CGFloat = 1400

    var body: some View {
        ZStack {
            Image(backgroundAssetName)
                .resizable()
                .scaledToFill()
                .blur(radius: 26)
                .saturation(0.7)
                .overlay(Color.black.opacity(0.78))
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 20) {
                // Top bar: Back button (left) and Driver Standing button (right)
                HStack {
                    EnhancedBackButton(action: { router.pop() })

                    Spacer()
                    
                    EnhancedDriverStandingButton(action: { router.push(.driverStandings) })
                }
                .frame(maxWidth: contentWidth)
                .padding(.horizontal, 140)
                .padding(.top, 28)

                // Title
                Text("Constructor Standings")
                    .font(.system(size: 56, weight: .black))
                    .foregroundStyle(.white)
                    .frame(maxWidth: contentWidth, alignment: .leading)
                    .padding(.horizontal, 140)

                // Rows
                VStack(spacing: 14) {
                    ForEach(constructors, id: \.position) { item in
                        ConstructorRow(item: item)
                            .frame(maxWidth: contentWidth)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var constructors: [ConstructorItem] {
        [
            ConstructorItem(position: 1, team: "Mercedes-AMG Petronas F1 Team", points: 613.5, logoAsset: "Mercedeze", logoURL: nil, accent: .teal),
            ConstructorItem(position: 2, team: "Red Bull Racing Honda", points: 585.5, logoAsset: "Redbull", logoURL: nil, accent: .blue),
            ConstructorItem(position: 3, team: "Scuderia Ferrari", points: 323.5, logoAsset: "Ferrari", logoURL: nil, accent: .red),
            ConstructorItem(position: 4, team: "McLaren F1 Team", points: 275.0, logoAsset: "Mclaren", logoURL: nil, accent: .orange),
            ConstructorItem(position: 5, team: "Alpine F1 Team", points: 155.0, logoAsset: "Alpine", logoURL: nil, accent: .cyan)
        ]
    }
}

struct ConstructorItem: Hashable {
    let position: Int
    let team: String
    let points: Double
    let logoAsset: String?
    let logoURL: URL?
    let accent: Color
}

private struct ConstructorRow: View {
    var item: ConstructorItem
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 24) {
            // Big position number column
            Text("\(item.position)")
                .font(.system(size: 54, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 80, alignment: .trailing)

            // Main card
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(isFocused ? 0.9 : 0.12), lineWidth: 2)
                    )

                HStack(spacing: 20) {
                    // Team logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.06))
                        
                        Group {
                            if let assetName = item.logoAsset {
                                Image(assetName)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(6)
                            } else if let url = item.logoURL {
                                AsyncImage(url: url) { phase in
                                    switch phase {
                                    case .success(let img): img.resizable().scaledToFit().padding(6)
                                    case .empty: Color.clear
                                    case .failure(_): Color.clear
                                    @unknown default: Color.clear
                                    }
                                }
                            } else {
                                Color.clear
                            }
                        }
                    }
                    .frame(width: 72, height: 72)

                    // Team name
                    Text(item.team)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    // Points block with accent gradient
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(colors: [item.accent.opacity(0.35), item.accent.opacity(0.9)], startPoint: .leading, endPoint: .trailing)
                            )
                        Text(String(format: "%.1f PTS", item.points))
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                    }
                    .frame(width: 300, height: 64)
                }
                .padding(18)
            }
            .frame(height: 112)
            .shadow(color: .black.opacity(isFocused ? 0.7 : 0.4), radius: isFocused ? 22 : 10, x: 0, y: isFocused ? 16 : 8)
            .scaleEffect(isFocused ? 1.02 : 1.0)
            .offset(x: isFocused ? 8 : 0)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
        }
        .padding(.horizontal, 140)
        .focusable()
        .focused($isFocused)
    }
}

// MARK: - Enhanced Button Components

private struct EnhancedBackButton: View {
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isFocused ?
                            [Color.white.opacity(0.25), Color.gray.opacity(0.15)] :
                            [Color.white.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            isFocused ? Color.white.opacity(0.8) : Color.white.opacity(0.2),
                            lineWidth: isFocused ? 2.5 : 1.5
                        )
                )
                .shadow(
                    color: isFocused ? Color.white.opacity(0.3) : .black.opacity(0.2),
                    radius: isFocused ? 16 : 6,
                    x: 0,
                    y: isFocused ? 8 : 3
                )
                .shadow(
                    color: .black.opacity(isFocused ? 0.3 : 0.1),
                    radius: isFocused ? 6 : 3,
                    x: 0,
                    y: isFocused ? 3 : 1
                )
            
            Image(systemName: "chevron.left")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(isFocused ? .white : .white.opacity(0.9))
                .shadow(
                    color: isFocused ? Color.white.opacity(0.3) : .clear,
                    radius: isFocused ? 4 : 0,
                    x: 0,
                    y: 0
                )
        }
        .frame(width: 56, height: 56)
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .focusable()
        .focused($isFocused)
        .onTapGesture {
            print("⬅️ Back button tapped!")
            action()
        }
        #if os(tvOS)
        .onPlayPauseCommand {
            print("⬅️ Back button - Play/Pause command!")
            action()
        }
        #endif
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isFocused)
        .accessibilityLabel("Back")
    }
}

private struct EnhancedDriverStandingButton: View {
    let action: () -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text("Driver Standing")
                .foregroundStyle(isFocused ? Color.blue : .white)
                .font(.system(size: 22, weight: .semibold))
                .shadow(
                    color: isFocused ? Color.blue.opacity(0.3) : .clear,
                    radius: isFocused ? 4 : 0,
                    x: 0,
                    y: 0
                )

            // Underline
            Rectangle()
                .fill(
                    isFocused ?
                    LinearGradient(
                        colors: [Color.blue, Color.blue.opacity(0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color.blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: isFocused ? 4 : 3)
                .shadow(
                    color: isFocused ? Color.blue.opacity(0.6) : .clear,
                    radius: isFocused ? 6 : 0,
                    x: 0,
                    y: 0
                )
        }
        .focusable()
        .focused($isFocused)
        .onTapGesture {
            print("🏎️ Driver Standing button tapped!")
            action()
        }
        #if os(tvOS)
        .onPlayPauseCommand {
            print("🏎️ Driver Standing - Play/Pause command!")
            action()
        }
        #endif
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isFocused)
    }
}

#Preview {
    ConstructorStandingsView()
}
