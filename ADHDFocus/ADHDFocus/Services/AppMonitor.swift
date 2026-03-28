import Foundation
import AppKit
import SwiftData

final class AppMonitor {
    private let engine: FocusEngine
    private let modelContext: ModelContext
    private var launchObservation: NSObjectProtocol?
    private var activationObservation: NSObjectProtocol?
    private var overlayWindow: BlockOverlayWindow?

    private let exemptApps = Set([
        "com.lilinke.ADHDFocus",
        "com.apple.finder",
        "com.apple.loginwindow",
        "com.apple.SystemPreferences",
        "com.apple.systempreferences",
        "com.apple.dock",
        "com.apple.WindowManager",
        "com.apple.controlcenter",
        "com.apple.SecurityAgent"
    ])

    init(engine: FocusEngine, modelContext: ModelContext) {
        self.engine = engine
        self.modelContext = modelContext
    }

    func startMonitoring() {
        // Monitor new app launches
        launchObservation = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.handleBlockedApp(app)
        }

        // Monitor app activation (user switches to a blocked app)
        activationObservation = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.handleBlockedApp(app)
        }

        // Check currently running apps
        checkRunningApps()
    }

    func stopMonitoring() {
        if let obs = launchObservation {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
        if let obs = activationObservation {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
        launchObservation = nil
        activationObservation = nil
        dismissOverlay()
    }

    private func checkRunningApps() {
        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular else { continue }
            handleBlockedApp(app)
        }
    }

    private func handleBlockedApp(_ app: NSRunningApplication) {
        guard let bundleID = app.bundleIdentifier else { return }
        if exemptApps.contains(bundleID) { return }
        if app.activationPolicy != .regular { return }
        guard engine.shouldBlockApp(bundleID: bundleID) else { return }

        // Record block event
        let event = BlockEvent(
            type: .app,
            target: bundleID,
            modeName: engine.activeMode?.name ?? ""
        )
        modelContext.insert(event)
        try? modelContext.save()

        // Show overlay instead of killing the app
        showOverlay(for: app)
    }

    private func showOverlay(for app: NSRunningApplication) {
        dismissOverlay()

        let overlay = BlockOverlayWindow(
            blockedApp: app,
            modeName: engine.activeMode?.name ?? "",
            remainingSeconds: engine.pomodoroTimer?.remainingSeconds ?? 0
        )
        overlay.makeKeyAndOrderFront(nil)
        overlayWindow = overlay
    }

    private func dismissOverlay() {
        overlayWindow?.dismiss()
        overlayWindow = nil
    }
}
