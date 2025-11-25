//
//  MainTabView.swift
//  TravelTalk
//
//  Created by Cascade on 2025-11-16.
//

import SwiftUI

struct MainTabView: View {
    @State private var selected: Int = 0
    @StateObject private var saved = SavedPhrasesStore()

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selected) {
                HomeView(selectedTab: $selected).tag(0)
                TranslatorView().tag(1)
                MapView().tag(2)
                TripsView().tag(3)
                ProfileView().tag(4)
            }
            .tint(Color(hex: 0x3B82F6))
            .toolbar(.hidden, for: .tabBar)

            GlassTabBar(selected: $selected)
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
        }
        .environmentObject(saved)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

private struct PlaceholderTab: View {
    let title: String
    let systemIcon: String
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 12) {
                Image(systemName: systemIcon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Text(title)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .preferredColorScheme(.dark)
    }
}

#if DEBUG
#Preview("Tabs") { MainTabView() }
#endif

private struct GlassTabBar: View {
    @Binding var selected: Int

    private struct Item: Identifiable { let id: Int; let title: String; let icon: String }
    private let items: [Item] = [
        .init(id: 0, title: "Home",       icon: "house.fill"),
        .init(id: 1, title: "Translator", icon: "waveform.circle.fill"),
        .init(id: 2, title: "Map",        icon: "map.fill"),
        .init(id: 3, title: "Trips",      icon: "airplane"),
        .init(id: 4, title: "Profile",    icon: "person.fill")
    ]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(items) { item in
                Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selected = item.id } }) {
                    HStack(spacing: 8) {
                        Image(systemName: icon(for: item))
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        if selected == item.id {
                            Text(item.title)
                                .foregroundColor(.white)
                                .font(.system(size: 13, weight: .semibold))
                                .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                    }
                    .padding(.horizontal, selected == item.id ? 14 : 12)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 24, x: 0, y: 10)
    }

    private func icon(for item: Item) -> String {
        switch item.id {
        case 0: return selected == 0 ? "house.fill" : "house"
        case 1: return selected == 1 ? "waveform.circle.fill" : "waveform.circle"
        case 2: return selected == 2 ? "map.fill" : "map"
        case 3: return selected == 3 ? "airplane.circle.fill" : "airplane.circle"
        default: return selected == 4 ? "person.fill" : "person"
        }
    }
}
