import AppKit
import SwiftUI

@MainActor
final class CelebrationManager {
    private var window: NSWindow?

    func showCelebration() {
        // Don't stack celebrations
        if window != nil { return }

        guard let screen = NSScreen.main else { return }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .transient]
        window.hasShadow = false

        let celebrationView = CelebrationView()
        window.contentView = NSHostingView(rootView: celebrationView)
        window.orderFrontRegardless()
        self.window = window

        // Trigger the animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            NotificationCenter.default.post(name: .triggerCelebration, object: nil)
        }

        // Close window after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            self?.window?.close()
            self?.window = nil
        }
    }
}
