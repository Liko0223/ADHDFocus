import AppKit
import SwiftUI

@Observable
final class NotchManager {
    private var panel: NotchPanel?
    private var hitTestView: NotchHitTestView?

    var companionState: CompanionState = .idle
    var modeName: String?
    var remainingSeconds: Int = 0
    var isActive: Bool = false

    func setup() {
        guard let screen = NSScreen.main, screen.hasNotch else { return }

        let notchFrame = screen.notchFrame
        // Create a wider frame to include content on both sides of the notch
        let panelWidth = notchFrame.width + 120  // Extra space for text
        let panelFrame = NSRect(
            x: notchFrame.origin.x - 60,
            y: notchFrame.origin.y,
            width: panelWidth,
            height: notchFrame.height
        )

        let panel = NotchPanel(contentRect: panelFrame)

        let hostingView = NSHostingView(rootView:
            NotchObservingView(manager: self)
        )
        hostingView.frame = NSRect(origin: .zero, size: panelFrame.size)
        hostingView.autoresizingMask = [.width, .height]

        let hitTest = NotchHitTestView()
        hitTest.activeRect = notchFrame
        hitTest.frame = NSRect(origin: .zero, size: panelFrame.size)
        hitTest.autoresizingMask = [.width, .height]
        hitTest.addSubview(hostingView)

        panel.contentView = hitTest
        panel.orderFrontRegardless()

        self.panel = panel
        self.hitTestView = hitTest
    }

    func updateState(isActive: Bool, modeName: String?, remainingSeconds: Int, isOnBreak: Bool) {
        self.isActive = isActive
        self.modeName = modeName
        self.remainingSeconds = remainingSeconds

        if !isActive {
            companionState = .idle
        } else if isOnBreak {
            companionState = .resting
        } else {
            companionState = .working
        }
    }

    func showBlocked() {
        companionState = .blocked
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.companionState == .blocked {
                self?.companionState = self?.isActive == true ? .working : .idle
            }
        }
    }
}

// Bridge view that observes NotchManager
struct NotchObservingView: View {
    @Bindable var manager: NotchManager

    var body: some View {
        NotchContentView(
            companionState: manager.companionState,
            modeName: manager.modeName,
            remainingSeconds: manager.remainingSeconds,
            isActive: manager.isActive
        )
    }
}
