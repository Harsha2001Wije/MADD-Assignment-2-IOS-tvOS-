import SwiftUI
import UIKit

struct DriverGalleryView: View {
    @EnvironmentObject private var router: Router

    private let columns: [GridItem] = Array(repeating: GridItem(.fixed(300), spacing: 28, alignment: .top), count: 5)
    private let legends: [Legend] = [
        .init(name: "Ayrton Senna", assetName: "Ayrton", flagAssetName: "flag_br", accent: .red),
        .init(name: "Michael Schumacher", assetName: "Micheal", flagAssetName: "flag_de", accent: .orange),
        .init(name: "Niki Lauda", assetName: "Niki", flagAssetName: "flag_at", accent: .red),
        .init(name: "Alain Prost", assetName: "Alain", flagAssetName: "flag_fr", accent: Color(red: 0.0, green: 0.55, blue: 1.0)),
        .init(name: "Lewis Hamilton", assetName: "Lewis", flagAssetName: "flag_gb", accent: .gray),
        .init(name: "Mika Häkkinen", assetName: "Mika", flagAssetName: "flag_fi", accent: .orange),
        .init(name: "Fernando Alonso", assetName: "Fernando", flagAssetName: "flag_es", accent: Color(red: 0.0, green: 0.55, blue: 1.0)),
        .init(name: "Jackie Stewart", assetName: "Jackie", flagAssetName: "flag_gb", accent: Color(red: 0.0, green: 0.55, blue: 1.0)),
        .init(name: "Jim Clark", assetName: "Jim", flagAssetName: "flag_gb", accent: .green),
        .init(name: "Juan Manuel Fangio", assetName: "Juan", flagAssetName: "flag_ar", accent: .red)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                HStack(spacing: 18) {
                    EnhancedBackButton(action: { router.pop() })

                    Text("F1 Legends Archive")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Spacer()
                    
                    LegendaryCarsButton(action: {
                        router.push(.legendaryCars)
                    })
                }

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: columns, alignment: .center, spacing: 32) {
                        ForEach(legends) { legend in
                            LegendCard(legend: legend)
                        }
                    }
                    .frame(maxWidth: 1600)
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding(.horizontal, 50)
            .padding(.top, 30)
        }
    }
}

private struct Legend: Identifiable {
    let id = UUID()
    let name: String
    let assetName: String
    let flagAssetName: String?
    let accent: Color
}

private struct LegendCard: View {
    @EnvironmentObject private var router: Router
    let legend: Legend
    @FocusState private var isFocused: Bool

    var body: some View {
        Button {
            print("🏎️ Legend card clicked: \(legend.name)")
            if legend.name == "Ayrton Senna" {
                router.push(.driverProfile(.ayrtonSenna))
            }
        } label: {
            ZStack(alignment: .bottomLeading) {
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        if UIImage(named: legend.assetName) != nil {
                            Image(legend.assetName)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 300, height: 420)
                                .clipped()
                        } else {
                            LinearGradient(colors: [legend.accent.opacity(0.15), .black.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                                .frame(width: 300, height: 420)
                        }
                    }
                    .frame(width: 300, height: 420)

                    Group {
                        if let flag = legend.flagAssetName, UIImage(named: flag) != nil {
                            Image(flag)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 32, height: 22)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .stroke(Color.white.opacity(0.9), lineWidth: 1)
                                )
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(Color.white.opacity(0.9))
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(.blue)
                            }
                            .frame(width: 32, height: 22)
                        }
                    }
                    .padding(10)
                }

                LinearGradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
                    .allowsHitTesting(false)

                Text(legend.name)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                    .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 2)
            }
            .frame(width: 300, height: 420)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(
                color: legend.accent.opacity(isFocused ? 0.8 : 0.0),
                radius: isFocused ? 40 : 0,
                x: 0,
                y: 0
            )
            .shadow(
                color: .black.opacity(isFocused ? 0.6 : 0.4),
                radius: isFocused ? 35 : 12,
                x: 0,
                y: isFocused ? 28 : 12
            )
            .scaleEffect(isFocused ? 1.12 : 1.0)
            .offset(y: isFocused ? -8 : 0)
            .brightness(isFocused ? 0.15 : 0.0)
            .saturation(isFocused ? 1.2 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isFocused)
        }
        .buttonStyle(.plain)
        .focusable()
        .focused($isFocused)
        .onTapGesture {
            print("🏎️ Legend card tapped: \(legend.name)")
            if legend.name == "Ayrton Senna" {
                router.push(.driverProfile(.ayrtonSenna))
            } else if legend.name == "Lewis Hamilton" {
                router.push(.driverProfile(.lewisHamilton))
            }
        }
        #if os(tvOS)
        .onPlayPauseCommand {
            print("🏎️ Legend card - Play/Pause: \(legend.name)")
            if legend.name == "Ayrton Senna" {
                router.push(.driverProfile(.ayrtonSenna))
            } else if legend.name == "Lewis Hamilton" {
                router.push(.driverProfile(.lewisHamilton))
            }
        }
        #endif
        .onChange(of: isFocused, initial: false) { _, _ in }
    }
}

// MARK: - Enhanced Back Button

private struct EnhancedBackButton: View {
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    isFocused ?
                    LinearGradient(
                        colors: [Color.red.opacity(0.3), Color.red.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(
                            isFocused ? Color.red : Color.white.opacity(0.15),
                            lineWidth: isFocused ? 3 : 1
                        )
                )
                .shadow(
                    color: isFocused ? Color.red.opacity(0.5) : .clear,
                    radius: isFocused ? 20 : 0,
                    x: 0,
                    y: 0
                )
            
            Image(systemName: "chevron.left")
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(isFocused ? Color.red : .white)
                .shadow(
                    color: isFocused ? Color.red.opacity(0.3) : .clear,
                    radius: isFocused ? 4 : 0,
                    x: 0,
                    y: 0
                )
        }
        .frame(width: 64, height: 64)
        .scaleEffect(isFocused ? 1.1 : 1.0)
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
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
    }
}

// MARK: - Legendary Cars Button

private struct LegendaryCarsButton: View {
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    isFocused ?
                    LinearGradient(
                        colors: [Color.red.opacity(0.4), Color.orange.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [Color.white.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(
                            isFocused ? Color.red : Color.white.opacity(0.2),
                            lineWidth: isFocused ? 3 : 2
                        )
                )
                .shadow(
                    color: isFocused ? Color.red.opacity(0.6) : .clear,
                    radius: isFocused ? 25 : 0,
                    x: 0,
                    y: 0
                )
            
            HStack(spacing: 12) {
                Image(systemName: "car.fill")
                    .font(.system(size: 24, weight: .bold))
                
                Text("Legendary Cars")
                    .font(.system(size: 24, weight: .bold))
            }
            .foregroundStyle(isFocused ? Color.white : .white.opacity(0.9))
            .shadow(
                color: isFocused ? Color.red.opacity(0.4) : .clear,
                radius: isFocused ? 6 : 0,
                x: 0,
                y: 0
            )
        }
        .frame(width: 280, height: 64)
        .scaleEffect(isFocused ? 1.08 : 1.0)
        .focusable()
        .focused($isFocused)
        .onTapGesture {
            print("🏎️ Legendary Cars button tapped!")
            action()
        }
        #if os(tvOS)
        .onPlayPauseCommand {
            print("🏎️ Legendary Cars button - Play/Pause command!")
            action()
        }
        #endif
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
    }
}
