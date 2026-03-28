import AppKit
import SwiftUI

final class NotchPanel: NSPanel {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        becomesKeyOnlyIfNeeded = true
        level = .mainMenu + 3
        collectionBehavior = [.fullScreenAuxiliary, .stationary, .canJoinAllSpaces, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

final class NotchHitTestView: NSView {
    weak var manager: NotchManager?

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let window, let manager else { return nil }
        let screenPoint = window.convertPoint(toScreen: convert(point, to: nil))
        guard let screen = NSScreen.main else { return nil }
        let activeRect = manager.activeRect(in: screen.frame)
        guard activeRect.contains(screenPoint) else { return nil }
        return super.hitTest(point)
    }
}
