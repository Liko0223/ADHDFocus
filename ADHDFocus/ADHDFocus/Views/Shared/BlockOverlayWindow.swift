import AppKit
import SwiftUI

final class BlockOverlayWindow: NSPanel {
    private var trackingApp: NSRunningApplication?
    private var pollTimer: Timer?

    init(blockedApp: NSRunningApplication, modeName: String, remainingSeconds: Int) {
        self.trackingApp = blockedApp

        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        // Float above everything
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovable = false

        let content = BlockOverlayContent(
            appName: blockedApp.localizedName ?? "应用",
            modeName: modeName,
            remainingSeconds: remainingSeconds,
            onDismiss: { [weak self] in
                self?.dismiss()
            }
        )
        contentView = NSHostingView(rootView: content)

        positionOverApp(blockedApp)
        startTrackingApp(blockedApp)
    }

    private func positionOverApp(_ app: NSRunningApplication) {
        // Position in center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - frame.width / 2
            let y = screenFrame.midY - frame.height / 2
            setFrameOrigin(NSPoint(x: x, y: y))
        }
    }

    private func startTrackingApp(_ app: NSRunningApplication) {
        // Dismiss overlay when the blocked app is no longer frontmost
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            if let trackingApp = self.trackingApp {
                if trackingApp.isTerminated || !trackingApp.isActive {
                    self.dismiss()
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
}

struct BlockOverlayContent: View {
    let appName: String
    let modeName: String
    let remainingSeconds: Int
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Text("🚫")
                .font(.system(size: 48))

            Text("\(appName) 暂时不可用")
                .font(.title2.weight(.semibold))
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
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
            }

            Button {
                onDismiss()
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

            Spacer()
        }
        .frame(width: 480, height: 320)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}
