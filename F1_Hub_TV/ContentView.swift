//
//  ContentView.swift
//  F1 Race Hub TV 2.0
//
//  Created by STUDENT on 2025-11-21.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @EnvironmentObject private var router: Router
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Cards centered on screen
            VStack {
                Spacer()
                HStack(spacing: 44) {
                    HomeCard(
                        title: "Race Weekend Hub",
                        assetName: "card_weekend",
                        imageURL: nil,
                        action: {
                            router.push(.raceOverview)
                        }
                    )
                    
                    HomeCard(
                        title: "F1 Legends Archive",
                        assetName: "card_legends",
                        imageURL: nil,
                        action: {
                            router.push(.driverGallery)
                        }
                    )
                }
                Spacer()
            }
            
            // Weather button in top-right corner
            WeatherButton(action: {
                router.push(.weatherForecast)
            })
            .padding(.top, 60)
            .padding(.trailing, 80)
        }
    }
}

// MARK: - HomeCard
struct HomeCard: View {
    let title: String
    var assetName: String? = nil
    var imageURL: URL? = nil
    var action: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let assetName = assetName {
                Image(assetName)
                    .resizable()
                    .scaledToFill()
            } else if let imageURL = imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        EmptyView()
                    }
                }
            }

            Text(title)
                .font(.system(size: 46, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.bottom, 26)
                .shadow(color: .black.opacity(0.7), radius: 6, x: 0, y: 2)
        }
        .frame(width: 660, height: 360)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(isFocused ? 0.95 : 0.0), lineWidth: 2)
        )
        .shadow(color: Color.white.opacity(isFocused ? 0.5 : 0.0), radius: isFocused ? 18 : 0, x: 0, y: 0)
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onTapGesture {
            action()
        }
#if os(tvOS)
        .onPlayPauseCommand {
            action()
        }
#endif
    }
}

// MARK: - Weather Icon Button

struct WeatherButton: View {
    var action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: isFocused ?
                            [Color.cyan.opacity(0.4), Color.blue.opacity(0.3)] :
                            [Color.white.opacity(0.12), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(
                            isFocused ? Color.cyan : Color.white.opacity(0.2),
                            lineWidth: isFocused ? 3 : 1.5
                        )
                )
                .shadow(
                    color: isFocused ? Color.cyan.opacity(0.5) : .black.opacity(0.2),
                    radius: isFocused ? 20 : 8,
                    x: 0,
                    y: isFocused ? 10 : 4
                )
            
            Image(systemName: "cloud.sun.fill")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(
                    isFocused ?
                    LinearGradient(
                        colors: [Color.cyan, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [Color.white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(
                    color: isFocused ? Color.cyan.opacity(0.4) : .clear,
                    radius: isFocused ? 6 : 0,
                    x: 0,
                    y: 0
                )
        }
        .frame(width: 80, height: 80)
        .scaleEffect(isFocused ? 1.15 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isFocused)
        .focusable()
        .focused($isFocused)
        .onTapGesture {
            action()
        }
#if os(tvOS)
        .onPlayPauseCommand {
            action()
        }
#endif
    }
}

#Preview {
    ContentView()
}
