import AppKit
import SwiftUI

final class BlockOverlayWindow: NSPanel {
    private var pollTimer: Timer?
    private var blockedBundleID: String?

    init(blockedApp: NSRunningApplication, modeName: String, remainingSeconds: Int) {
        self.blockedBundleID = blockedApp.bundleIdentifier

        // Cover the entire screen
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        super.init(
            contentRect: screenFrame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        // Above everything, captures input
        level = .screenSaver
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        ignoresMouseEvents = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovable = false

        let content = BlockOverlayContent(
            appName: blockedApp.localizedName ?? "应用",
            modeName: modeName,
            remainingSeconds: remainingSeconds,
            onGoBack: { [weak self] in
                self?.goBackToWork()
            }
        )
        contentView = NSHostingView(rootView: content)

        // Keep checking: if user somehow switched away, dismiss
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self, let bundleID = self.blockedBundleID else { return }
            let frontApp = NSWorkspace.shared.frontmostApplication
            // If the blocked app is no longer frontmost (user clicked "go back"), dismiss
            if frontApp?.bundleIdentifier != bundleID && frontApp?.bundleIdentifier != "com.lilinke.ADHDFocus" {
                self.dismiss()
            }
        }
    }

    private func goBackToWork() {
        dismiss()
        // Activate our own app to pull focus away from the blocked app
        NSApp.activate(ignoringOtherApps: true)
        // Also hide the blocked app
        if let bundleID = blockedBundleID {
            for app in NSWorkspace.shared.runningApplications {
                if app.bundleIdentifier == bundleID {
                    app.hide()
                    break
                }
            }
        }
    }

    func dismiss() {
        pollTimer?.invalidate()
        pollTimer = nil
        orderOut(nil)
    }

    deinit {
        pollTimer?.invalidate()
    }

    // Prevent the panel from ever losing key status while shown
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

struct BlockOverlayContent: View {
    let appName: String
    let modeName: String
    let remainingSeconds: Int
    let onGoBack: () -> Void

    var body: some View {
        ZStack {
            // Full-screen dark backdrop
            Color.black.opacity(0.75)
                .ignoresSafeArea()

            // Center card
            VStack(spacing: 20) {
                Text("🚫")
                    .font(.system(size: 56))

                Text("\(appName) 暂时不可用")
                    .font(.title.weight(.semibold))
                    .foregroundStyle(.white)

                Text("当前处于「\(modeName)」模式")
                    .font(.title3)
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
                    .font(.body)
                }

                Button {
                    onGoBack()
                } label: {
                    Text("回到工作")
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(48)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
