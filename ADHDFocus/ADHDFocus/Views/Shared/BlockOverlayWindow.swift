import AppKit
import SwiftUI
import CoreGraphics

// Manages multiple overlay panels, one per window of the blocked app
final class BlockOverlayManager {
    private var overlays: [CGWindowID: BlockOverlayPanel] = [:]
    private var pollTimer: Timer?
    private var blockedApp: NSRunningApplication?
    private var modeName: String = ""
    private var remainingSeconds: Int = 0
    private var onTempAllow: ((String) -> Void)?

    func showOverlays(for app: NSRunningApplication, modeName: String, remainingSeconds: Int, onTempAllow: ((String) -> Void)? = nil) {
        dismissAll()
        self.blockedApp = app
        self.modeName = modeName
        self.remainingSeconds = remainingSeconds
        self.onTempAllow = onTempAllow

        updateOverlays()

        // Poll to track window movement/resize and new windows
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.updateOverlays()
        }
    }

    func dismissAll() {
        pollTimer?.invalidate()
        pollTimer = nil
        for (_, overlay) in overlays {
            overlay.orderOut(nil)
        }
        overlays.removeAll()
        blockedApp = nil
    }

    private func updateOverlays() {
        guard let app = blockedApp, !app.isTerminated else {
            dismissAll()
            return
        }

        // If blocked app is no longer active, dismiss overlays
        if NSWorkspace.shared.frontmostApplication?.processIdentifier != app.processIdentifier {
            dismissAll()
            return
        }

        let pid = app.processIdentifier
        let windowInfoList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []

        var activeWindowIDs = Set<CGWindowID>()

        for info in windowInfoList {
            guard let windowPID = info[kCGWindowOwnerPID as String] as? pid_t,
                  windowPID == pid,
                  let windowID = info[kCGWindowNumber as String] as? CGWindowID,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: CGFloat],
                  let layer = info[kCGWindowLayer as String] as? Int,
                  layer == 0  // Only normal windows (layer 0)
            else { continue }

            let cgX = boundsDict["X"] ?? 0
            let cgY = boundsDict["Y"] ?? 0
            let width = boundsDict["Width"] ?? 0
            let height = boundsDict["Height"] ?? 0

            // Skip tiny windows (toolbars, popups)
            if width < 100 || height < 100 { continue }

            // Convert CG coordinates (top-left origin) to NS coordinates (bottom-left origin)
            let screenHeight = NSScreen.screens.first?.frame.height ?? 1080
            let nsY = screenHeight - cgY - height
            let frame = NSRect(x: cgX, y: nsY, width: width, height: height)

            activeWindowIDs.insert(windowID)

            if let existing = overlays[windowID] {
                // Update position if window moved
                existing.setFrame(frame, display: false)
            } else {
                // Create new overlay for this window
                let bundleID = app.bundleIdentifier ?? ""
                let panel = BlockOverlayPanel(
                    frame: frame,
                    appName: app.localizedName ?? "应用",
                    modeName: modeName,
                    remainingSeconds: remainingSeconds,
                    onGoBack: { [weak self] in
                        self?.goBackToWork()
                    },
                    onTempAllow: { [weak self] in
                        self?.onTempAllow?(bundleID)
                    }
                )
                panel.orderFrontRegardless()
                overlays[windowID] = panel
            }
        }

        // Remove overlays for windows that no longer exist
        for (windowID, overlay) in overlays where !activeWindowIDs.contains(windowID) {
            overlay.orderOut(nil)
            overlays.removeValue(forKey: windowID)
        }
    }

    private func goBackToWork() {
        let app = blockedApp
        dismissAll()
        // Hide the blocked app and activate ours
        app?.hide()
        NSApp.activate(ignoringOtherApps: true)
    }
}

// Individual overlay panel for one window
final class BlockOverlayPanel: NSPanel {
    init(frame: NSRect, appName: String, modeName: String, remainingSeconds: Int, onGoBack: @escaping () -> Void, onTempAllow: @escaping () -> Void) {
        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovable = false

        // Use NSVisualEffectView as the root content view for proper frosted glass blur.
        // SwiftUI .ultraThinMaterial does not blend with content behind a transparent NSPanel,
        // but NSVisualEffectView does.
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow       // dark-tinted blur, readable against any bg
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true

        let content = BlockOverlayContent(
            appName: appName,
            modeName: modeName,
            remainingSeconds: remainingSeconds,
            onGoBack: onGoBack,
            onTempAllow: onTempAllow
        )
        let hostingView = NSHostingView(rootView: content)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        hostingView.layer?.backgroundColor = .clear

        visualEffect.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
        ])

        contentView = visualEffect
    }

    override var canBecomeKey: Bool { true }
}

struct BlockOverlayContent: View {
    let appName: String
    let modeName: String
    let remainingSeconds: Int
    let onGoBack: () -> Void
    let onTempAllow: () -> Void

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 16) {
                Text("🚫")
                    .font(.system(size: 40))

                Text("\(appName) 暂时不可用")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                Text("当前处于「\(modeName)」模式")
                    .font(.body)
                    .foregroundStyle(.white.opacity(0.7))

                if remainingSeconds > 0 {
                    let minutes = remainingSeconds / 60
                    let seconds = remainingSeconds % 60
                    HStack(spacing: 4) {
                        Text("番茄钟剩余")
                            .foregroundStyle(.white.opacity(0.5))
                        Text(String(format: "%02d:%02d", minutes, seconds))
                            .monospacedDigit()
                            .foregroundStyle(.purple)
                            .fontWeight(.bold)
                    }
                    .font(.subheadline)
                }

                HStack(spacing: 12) {
                    Button {
                        onGoBack()
                    } label: {
                        Text("回到工作")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(.purple)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    Button {
                        onTempAllow()
                    } label: {
                        Text("允许 5 分钟")
                            .font(.body.weight(.medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
