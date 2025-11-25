//
//  SplashView.swift
//  TravelTalk
//
//  Created by Cascade on 2025-11-15.
//

import SwiftUI

private let introDuration: Double = 0.6    // fade/slide-in
private let holdDuration: Double = 1.2     // time visible before exit
private let outroDuration: Double = 0.35   // fade-out

struct SplashView: View {
    var onFinish: () -> Void

    @State private var opacity: Double = 0.0
    @State private var yOffset: CGFloat = 20

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x6C63FF), Color(hex: 0x45C5FF)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                LogoView()
                    .opacity(opacity)
                    .offset(y: yOffset)
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 8)

               
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                opacity = 1.0
                yOffset = 0
            }

            // Navigate after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeInOut(duration: 0.35)) {
                    opacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    onFinish()
                }
            }
        }
    }
}

private struct LogoView: View {
    var body: some View {
        Image("AppLogo")
            .renderingMode(.original)          // no template/tint
            .resizable()                        // allow layout sizing
            .interpolation(.high)               // better scaling quality
            .antialiased(true)
            .scaledToFit()                      // preserve aspect
            .frame(width: 350, height: 350)     // adjust as needed
            .accessibilityLabel("TravelTalk logo")
    }
}

private struct SpeechBubble: Shape {
    func path(in rect: CGRect) -> Path {
        let cornerRadius: CGFloat = min(rect.width, rect.height) * 0.22
        var path = Path(roundedRect: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: rect.height * 0.86), cornerRadius: cornerRadius)

        // Tail
        let tailWidth = rect.width * 0.22
        let tailHeight = rect.height * 0.22
        let tailX = rect.minX + rect.width * 0.25
        let tailY = rect.minY + rect.height * 0.78

        path.move(to: CGPoint(x: tailX, y: tailY))
        path.addLine(to: CGPoint(x: tailX + tailWidth * 0.5, y: tailY + tailHeight))
        path.addLine(to: CGPoint(x: tailX + tailWidth, y: tailY))
        path.closeSubpath()

        return path
    }
}

#Preview {
    SplashView(onFinish: {})
}
