import Foundation
import AppKit
import SwiftData

final class AppMonitor {
    private let engine: FocusEngine
    private let modelContext: ModelContext
    private var launchObservation: NSObjectProtocol?
    private var activationObservation: NSObjectProtocol?
    private let overlayManager = BlockOverlayManager()
    private var tempAllowedApps: [String: Date] = [:]  // bundleID -> expiry
    private var lastBlockRecord: [String: Date] = [:]  // bundleID -> last recorded time

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

    private func tempAllowApp(_ bundleID: String) {
        tempAllowedApps[bundleID] = Date().addingTimeInterval(5 * 60) // 5 minutes
        overlayManager.dismissAll()
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
        overlayManager.dismissAll()
        tempAllowedApps.removeAll()
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

        // Check temp allow
        if let expiry = tempAllowedApps[bundleID], Date() < expiry {
            return
        }
        tempAllowedApps.removeValue(forKey: bundleID)

        // Record block event (dedupe: once per app per 60 seconds)
        let now = Date()
        if let lastTime = lastBlockRecord[bundleID], now.timeIntervalSince(lastTime) < 60 {
            // Skip recording, still show overlay
        } else {
            lastBlockRecord[bundleID] = now
            let event = BlockEvent(
                type: .app,
                target: bundleID,
                modeName: engine.activeMode?.name ?? ""
            )
            modelContext.insert(event)
            try? modelContext.save()
        }

        let strictness = (engine.activeMode?.strictness ?? .overlay).effective

        switch strictness {
        case .forceQuit:
            app.terminate()
            NotificationManager.shared.sendBlockedAppNotification(
                appName: app.localizedName ?? bundleID,
                modeName: engine.activeMode?.name ?? "",
                remainingSeconds: engine.pomodoroTimer?.remainingSeconds ?? 0
            )
        default:
            overlayManager.showOverlays(
                for: app,
                modeName: engine.activeMode?.name ?? "",
                remainingSeconds: engine.pomodoroTimer?.remainingSeconds ?? 0,
                onTempAllow: { [weak self] bundleID in
                    self?.tempAllowApp(bundleID)
                }
            )
        }
    }
}
