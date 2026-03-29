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

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.8) { [weak self] in
            self?.window?.orderOut(nil)
            self?.window = nil
        }
    }
}

struct ScreenGlowView: View {
    @State private var opacity: Double = 0
    private let glowWidth: CGFloat = 60
    private let color: Color

    private static let palette: [Color] = [
        Color(red: 0.3, green: 0.85, blue: 0.5),  // green
        Color(red: 0.4, green: 0.6, blue: 1.0),   // blue
        Color(red: 1.0, green: 0.65, blue: 0.2),   // orange
        Color(red: 0.6, green: 0.4, blue: 1.0),    // purple
        Color(red: 0.3, green: 0.8, blue: 0.9),    // cyan
        Color(red: 1.0, green: 0.5, blue: 0.6),    // pink
    ]

    init() {
        color = Self.palette.randomElement()!
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                LinearGradient(colors: [color.opacity(0.7), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: glowWidth)
                    .frame(maxWidth: .infinity)
                    .position(x: geo.size.width / 2, y: glowWidth / 2)

                LinearGradient(colors: [color.opacity(0.7), .clear], startPoint: .bottom, endPoint: .top)
                    .frame(height: glowWidth)
                    .frame(maxWidth: .infinity)
                    .position(x: geo.size.width / 2, y: geo.size.height - glowWidth / 2)

                LinearGradient(colors: [color.opacity(0.6), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: glowWidth)
                    .frame(maxHeight: .infinity)
                    .position(x: glowWidth / 2, y: geo.size.height / 2)

                LinearGradient(colors: [color.opacity(0.6), .clear], startPoint: .trailing, endPoint: .leading)
                    .frame(width: glowWidth)
                    .frame(maxHeight: .infinity)
                    .position(x: geo.size.width - glowWidth / 2, y: geo.size.height / 2)
            }
            .opacity(opacity)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.8)) {
                    opacity = 0
                }
            }
        }
    }
}
