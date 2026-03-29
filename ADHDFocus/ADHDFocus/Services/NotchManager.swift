import AppKit
import SwiftUI
import SwiftData

@MainActor @Observable
final class NotchManager {
    private var panel: NotchPanel?
    private var syncTimer: Timer?
    private var clickMonitor: Any?
    weak var engine: FocusEngine?
    var modelContainer: ModelContainer?
    var openMainWindow: (() -> Void)?
    var onIgnoreSuggestion: (() -> Void)?

    // State
    var companionState: CompanionState = .idle
    var modeName: String?
    var remainingSeconds: Int = 0
    var isActive: Bool = false
    var isExpanded: Bool = false
    var isSuggesting: Bool = false
    var suggestedMode: FocusMode?
    var suggestedAppName: String?
    private var suggestionTimer: Timer?

    // Geometry
    var notchWidth: CGFloat = 200
    var notchHeight: CGFloat = 38
    var screenWidth: CGFloat = 1440
    var targetScreen: NSScreen?

    private let collapsedSideExtension: CGFloat = 70
    private let expandedWidth: CGFloat = 340
    private let expandedHeight: CGFloat = 260

    var collapsedTotalWidth: CGFloat {
        notchWidth + collapsedSideExtension * 2
    }

    func setup() {
        guard modelContainer != nil else {
            return
        }
        // Prefer the screen with a notch (built-in display)
        let screen = NSScreen.screens.first(where: { $0.hasNotch }) ?? NSScreen.main
        guard let screen else { return }
        targetScreen = screen

        let screenFrame = screen.frame
        screenWidth = screenFrame.width

        if screen.hasNotch {
            let ns = screen.notchSize
            notchWidth = ns.width
            notchHeight = ns.height
        } else {
            let menuBarHeight = screenFrame.maxY - screen.visibleFrame.maxY
            notchHeight = max(menuBarHeight, 24)
            notchWidth = 200
        }

        // Panel starts from the very top of the screen, tall enough for expanded state
        let maxPanelHeight = expandedHeight + notchHeight
        let panelFrame = NSRect(
            x: screenFrame.origin.x,
            y: screenFrame.maxY - maxPanelHeight,
            width: screenFrame.width,
            height: maxPanelHeight
        )
        // Note: panel top = screenFrame.maxY - maxPanelHeight
        // Content is top-aligned, scene fills from y=0 of the content

        let panel = NotchPanel(contentRect: panelFrame)

        let hostingView = NSHostingView(rootView:
            NotchObservingView(manager: self)
                .modelContainer(modelContainer!)
        )
        hostingView.frame = NSRect(origin: .zero, size: panelFrame.size)
        hostingView.autoresizingMask = [.width, .height]

        let hitTest = NotchHitTestView()
        hitTest.manager = self
        hitTest.frame = NSRect(origin: .zero, size: panelFrame.size)
        hitTest.autoresizingMask = [.width, .height]
        hitTest.addSubview(hostingView)

        panel.contentView = hitTest
        panel.orderFrontRegardless()
        self.panel = panel

        syncTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let engine = self.engine else { return }
                self.remainingSeconds = engine.pomodoroTimer?.remainingSeconds ?? 0
            }
        }

        // Monitor clicks outside to collapse
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            guard let self, self.isExpanded else { return }
            self.collapse()
        }
    }

    func toggleExpanded() {
        if isExpanded {
            collapse()
        } else {
            expand()
        }
    }

    func expand() {
        dismissSuggestion()
        isExpanded = true
    }

    func collapse() {
        isExpanded = false
    }

    func activateMode(_ mode: FocusMode) {
        engine?.activate(mode: mode)
        collapse()
    }

    func deactivateMode() {
        engine?.deactivate()
        collapse()
    }

    func showSuggestion(mode: FocusMode, appName: String) {
        suggestedMode = mode
        suggestedAppName = appName
        isSuggesting = true

        // Auto-dismiss after 5 seconds
        suggestionTimer?.invalidate()
        suggestionTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.dismissSuggestion()
        }
    }

    func dismissSuggestion() {
        suggestionTimer?.invalidate()
        suggestionTimer = nil
        isSuggesting = false
        suggestedMode = nil
        suggestedAppName = nil
    }

    func acceptSuggestion() {
        guard let mode = suggestedMode else { return }
        dismissSuggestion()
        engine?.activate(mode: mode)
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

    // Hit test rect for the current state
    func activeRect(in screenFrame: NSRect) -> NSRect {
        let centerX = screenFrame.midX
        if isExpanded {
            let w = max(expandedWidth, notchWidth + 40)
            return NSRect(
                x: centerX - w / 2,
                y: screenFrame.maxY - notchHeight - expandedHeight,
                width: w,
                height: notchHeight + expandedHeight
            )
        } else if isSuggesting {
            return NSRect(
                x: centerX - collapsedTotalWidth / 2,
                y: screenFrame.maxY - notchHeight - 40,
                width: collapsedTotalWidth,
                height: notchHeight + 40
            )
        } else {
            return NSRect(
                x: centerX - collapsedTotalWidth / 2,
                y: screenFrame.maxY - notchHeight,
                width: collapsedTotalWidth,
                height: notchHeight
            )
        }
    }
}

// Bridge view
struct NotchObservingView: View {
    @Bindable var manager: NotchManager

    var body: some View {
        NotchContentView(manager: manager)
    }
}
