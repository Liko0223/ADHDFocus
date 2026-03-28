import Foundation
import AppKit
import SwiftData

final class AppMonitor {
    private let engine: FocusEngine
    private let modelContext: ModelContext
    private var observation: NSObjectProtocol?

    init(engine: FocusEngine, modelContext: ModelContext) {
        self.engine = engine
        self.modelContext = modelContext
    }

    func startMonitoring() {
        observation = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppLaunch(notification)
        }
    }

    func stopMonitoring() {
        if let observation {
            NSWorkspace.shared.notificationCenter.removeObserver(observation)
        }
        observation = nil
    }

    private func handleAppLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }

        let exemptApps = [
            "com.lilinke.ADHDFocus",
            "com.apple.finder",
            "com.apple.loginwindow",
            "com.apple.SystemPreferences",
            "com.apple.systempreferences"
        ]
        if exemptApps.contains(bundleID) { return }

        guard engine.shouldBlockApp(bundleID: bundleID) else { return }

        let appName = app.localizedName ?? bundleID

        let event = BlockEvent(
            type: .app,
            target: bundleID,
            modeName: engine.activeMode?.name ?? ""
        )
        modelContext.insert(event)
        try? modelContext.save()

        if engine.activeMode?.strictness == .forceQuit {
            app.terminate()
        }

        NotificationManager.shared.sendBlockedAppNotification(
            appName: appName,
            modeName: engine.activeMode?.name ?? "",
            remainingSeconds: engine.pomodoroTimer?.remainingSeconds ?? 0
        )
    }
}
