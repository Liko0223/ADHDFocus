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
    @State private var startTime: Date?

    private let glowWidth: CGFloat = 60

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let hue1 = t.truncatingRemainder(dividingBy: 2.0) / 2.0
            let hue2 = (hue1 + 0.33).truncatingRemainder(dividingBy: 1.0)
            let c1 = Color(hue: hue1, saturation: 0.8, brightness: 1.0)
            let c2 = Color(hue: hue2, saturation: 0.8, brightness: 1.0)

            GeometryReader { geo in
                ZStack {
                    // Top
                    LinearGradient(colors: [c1.opacity(0.7), c2.opacity(0.3), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: glowWidth)
                        .frame(maxWidth: .infinity)
                        .position(x: geo.size.width / 2, y: glowWidth / 2)

                    // Bottom
                    LinearGradient(colors: [c2.opacity(0.7), c1.opacity(0.3), .clear], startPoint: .bottom, endPoint: .top)
                        .frame(height: glowWidth)
                        .frame(maxWidth: .infinity)
                        .position(x: geo.size.width / 2, y: geo.size.height - glowWidth / 2)

                    // Left
                    LinearGradient(colors: [c1.opacity(0.6), c2.opacity(0.2), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: glowWidth)
                        .frame(maxHeight: .infinity)
                        .position(x: glowWidth / 2, y: geo.size.height / 2)

                    // Right
                    LinearGradient(colors: [c2.opacity(0.6), c1.opacity(0.2), .clear], startPoint: .trailing, endPoint: .leading)
                        .frame(width: glowWidth)
                        .frame(maxHeight: .infinity)
                        .position(x: geo.size.width - glowWidth / 2, y: geo.size.height / 2)
                }
                .opacity(opacity)
            }
            .ignoresSafeArea()
        }
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
