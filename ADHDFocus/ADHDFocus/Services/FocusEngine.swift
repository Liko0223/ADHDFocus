import Foundation
import Observation

@Observable
final class FocusEngine {
    private(set) var activeMode: FocusMode?
    private(set) var pomodoroTimer: PomodoroTimer?
    private(set) var sessionStartedAt: Date?

    var isActive: Bool {
        activeMode != nil
    }

    var onModeActivated: ((FocusMode) -> Void)?
    var onModeDeactivated: (() -> Void)?
    var onPomodoroPhaseChange: ((PomodoroPhase) -> Void)?

    func activate(mode: FocusMode) {
        // Deactivate previous mode if any (prevents timer leak)
        if activeMode != nil {
            pomodoroTimer?.stop()
            pomodoroTimer = nil
            onModeDeactivated?()
        }
        activeMode = mode
        sessionStartedAt = Date()

        if mode.workDuration > 0 {
            let timer = PomodoroTimer(
                workDuration: mode.workDuration,
                breakDuration: mode.breakDuration,
                longBreakDuration: mode.longBreakDuration,
                longBreakInterval: mode.longBreakInterval
            )
            timer.onPhaseChange = { [weak self] phase in
                self?.onPomodoroPhaseChange?(phase)
            }
            pomodoroTimer = timer
            timer.start()
        } else {
            pomodoroTimer = nil
        }

        onModeActivated?(mode)
    }

    func deactivate() {
        pomodoroTimer?.stop()
        pomodoroTimer = nil
        activeMode = nil
        sessionStartedAt = nil
        onModeDeactivated?()
    }

    func shouldBlockApp(bundleID: String) -> Bool {
        guard let mode = activeMode else { return false }
        if pomodoroTimer?.isOnBreak == true { return false }
        return !mode.isAppAllowed(bundleID: bundleID)
    }

    func shouldBlockURL(_ urlString: String) -> Bool {
        guard let mode = activeMode else { return false }
        if pomodoroTimer?.isOnBreak == true { return false }
        return !mode.isURLAllowed(urlString)
    }

    func currentURLRules() -> [String: Any]? {
        guard let mode = activeMode else { return nil }
        let isOnBreak = pomodoroTimer?.isOnBreak ?? false
        return [
            "active": true,
            "onBreak": isOnBreak,
            "modeName": mode.name,
            "allowedURLs": mode.allowedURLs,
            "blockedURLs": mode.blockedURLs,
            "defaultPolicy": mode.defaultURLPolicy.rawValue,
            "remainingSeconds": pomodoroTimer?.remainingSeconds ?? 0
        ]
    }
}
