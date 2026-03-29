import AppKit
import SwiftUI

@MainActor
final class CelebrationManager {
    private var window: NSWindow?

    func show() {
        guard window == nil else { return }
        guard let screen = NSScreen.main else { return }

        let win = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .floating
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        win.hasShadow = false

        let view = ScreenGlowView()
        win.contentView = NSHostingView(rootView: view)
        win.orderFrontRegardless()
        self.window = win

        // Auto close after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            self?.window?.orderOut(nil)
            self?.window = nil
        }
    }
}

/// Full-screen border glow effect — just 4 gradient rectangles on each edge
struct ScreenGlowView: View {
    @State private var opacity: Double = 0
    @State private var hue: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Top edge
                LinearGradient(
                    colors: [glowColor.opacity(0.6), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .position(x: geo.size.width / 2, y: 40)

                // Bottom edge
                LinearGradient(
                    colors: [glowColor.opacity(0.6), .clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 80)
                .frame(maxWidth: .infinity)
                .position(x: geo.size.width / 2, y: geo.size.height - 40)

                // Left edge
                LinearGradient(
                    colors: [glowColor.opacity(0.5), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 80)
                .frame(maxHeight: .infinity)
                .position(x: 40, y: geo.size.height / 2)

                // Right edge
                LinearGradient(
                    colors: [glowColor.opacity(0.5), .clear],
                    startPoint: .trailing,
                    endPoint: .leading
                )
                .frame(width: 80)
                .frame(maxHeight: .infinity)
                .position(x: geo.size.width - 40, y: geo.size.height / 2)
            }
            .opacity(opacity)
        }
        .ignoresSafeArea()
        .onAppear {
            // Fade in
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
            // Hue rotation for color cycling
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                hue = 1
            }
            // Fade out after 1.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 1.0)) {
                    opacity = 0
                }
            }
        }
    }

    private var glowColor: Color {
        Color(hue: hue, saturation: 0.7, brightness: 1.0)
    }
}
