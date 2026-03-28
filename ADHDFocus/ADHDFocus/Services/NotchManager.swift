import AppKit
import SwiftUI

@Observable
final class NotchManager {
    private var panel: NotchPanel?
    private var syncTimer: Timer?
    weak var engine: FocusEngine?

    var companionState: CompanionState = .idle
    var modeName: String?
    var remainingSeconds: Int = 0
    var isActive: Bool = false

    var notchWidth: CGFloat = 200
    var notchHeight: CGFloat = 38
    var screenWidth: CGFloat = 1440

    func setup() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.frame
        screenWidth = screenFrame.width

        if screen.hasNotch {
            let ns = screen.notchSize
            notchWidth = ns.width
            notchHeight = ns.height
        } else {
            // No notch — use menu bar height
            let menuBarHeight = screenFrame.maxY - screen.visibleFrame.maxY
            notchHeight = max(menuBarHeight, 24)
            notchWidth = 200
        }

        // Panel exactly covers the menu bar area, full width
        let panelFrame = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.maxY - notchHeight,
            width: screenFrame.width,
            height: notchHeight
        )

        let panel = NotchPanel(contentRect: panelFrame)

        let hostingView = NSHostingView(rootView:
            NotchObservingView(manager: self)
        )
        hostingView.frame = NSRect(origin: .zero, size: panelFrame.size)
        hostingView.autoresizingMask = [.width, .height]

        panel.contentView = hostingView
        panel.orderFrontRegardless()
        self.panel = panel

        syncTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let engine = self.engine else { return }
            self.remainingSeconds = engine.pomodoroTimer?.remainingSeconds ?? 0
        }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            if self?.companionState == .blocked {
                self?.companionState = self?.isActive == true ? .working : .idle
            }
        }
    }
}

struct NotchObservingView: View {
    @Bindable var manager: NotchManager

    var body: some View {
        NotchContentView(
            companionState: manager.companionState,
            modeName: manager.modeName,
            remainingSeconds: manager.remainingSeconds,
            isActive: manager.isActive,
            notchWidth: manager.notchWidth,
            notchHeight: manager.notchHeight,
            screenWidth: manager.screenWidth
        )
    }
}
