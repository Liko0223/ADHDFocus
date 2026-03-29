import Foundation
import AppKit
import SwiftData

@MainActor
final class AutoTriggerService {
    private let engine: FocusEngine
    private let modelContext: ModelContext
    private weak var notchManager: NotchManager?

    private var currentApp: String?
    private var currentAppName: String?
    private var appStartTime: Date?
    private var checkTimer: Timer?
    private var activationObserver: NSObjectProtocol?
    private var ignoredApps: Set<String> = []
    private var isWatching = false

    private let exemptApps: Set<String> = [
        "com.lilinke.ADHDFocus",
        "com.apple.finder",
        "com.apple.loginwindow",
        "com.apple.SystemPreferences",
        "com.apple.systempreferences",
        "com.apple.dock",
        "com.apple.WindowManager",
        "com.apple.controlcenter",
        "com.apple.SecurityAgent"
    ]

    init(engine: FocusEngine, modelContext: ModelContext, notchManager: NotchManager) {
        self.engine = engine
        self.modelContext = modelContext
        self.notchManager = notchManager
    }

    func startWatching() {
        guard !isWatching else { return }
        isWatching = true

        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                  let bundleID = app.bundleIdentifier else { return }
            Task { @MainActor in
                self?.onAppActivated(bundleID: bundleID, appName: app.localizedName ?? bundleID)
            }
        }

        checkTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkTrigger()
            }
        }
    }

    func stopWatching() {
        isWatching = false
        if let obs = activationObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
        activationObserver = nil
        checkTimer?.invalidate()
        checkTimer = nil
        currentApp = nil
        appStartTime = nil
    }

    func pause() {
        checkTimer?.invalidate()
        checkTimer = nil
    }

    func resume() {
        guard isWatching else { return }
        ignoredApps.removeAll()
        currentApp = nil
        appStartTime = nil
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkTrigger()
            }
        }
    }

    func ignoreCurrentApp() {
        if let app = currentApp {
            ignoredApps.insert(app)
        }
        notchManager?.dismissSuggestion()
    }

    private func onAppActivated(bundleID: String, appName: String) {
        if bundleID == currentApp { return }
        currentApp = bundleID
        currentAppName = appName
        appStartTime = Date()
    }

    private func checkTrigger() {
        guard !engine.isActive else { return }
        guard let bundleID = currentApp,
              let startTime = appStartTime else { return }
        if exemptApps.contains(bundleID) { return }
        if ignoredApps.contains(bundleID) { return }
        if notchManager?.isSuggesting == true { return }

        guard let matchedMode = matchMode(for: bundleID) else { return }

        let delay = matchedMode.triggerDelay > 0 ? matchedMode.triggerDelay : 60
        let elapsed = Int(Date().timeIntervalSince(startTime))

        if elapsed >= delay {
            notchManager?.showSuggestion(
                mode: matchedMode,
                appName: currentAppName ?? bundleID
            )
        }
    }

    private func matchMode(for bundleID: String) -> FocusMode? {
        let descriptor = FetchDescriptor<FocusMode>(sortBy: [SortDescriptor(\FocusMode.sortOrder)])
        guard let modes = try? modelContext.fetch(descriptor) else { return nil }

        // Priority 1: explicit triggerApps
        for mode in modes {
            if !mode.triggerApps.isEmpty && mode.triggerApps.contains(bundleID) {
                return mode
            }
        }

        // Priority 2: allowedApps inference (only for modes with triggerApps empty)
        for mode in modes {
            if mode.triggerApps.isEmpty && mode.allowedApps.contains(bundleID) {
                return mode
            }
        }

        return nil
    }
}
