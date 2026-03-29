import Foundation
import SwiftData

enum AppPolicy: String, Codable {
    case allow
    case remind
    case block
}

enum Strictness: String, Codable {
    case overlay     // Window overlay with "allow 5 min" option
    case forceQuit   // Terminate the app immediately
    case remind      // Legacy — treated as overlay
    case delayAllow  // Legacy — treated as overlay

    var effective: Strictness {
        switch self {
        case .remind, .delayAllow: return .overlay
        default: return self
        }
    }
}

@Model
final class FocusMode {
    var id: UUID
    var name: String
    var icon: String
    var statsTag: String

    // App rules
    var allowedApps: [String]   // Bundle IDs
    var blockedApps: [String]   // Bundle IDs
    var defaultAppPolicy: AppPolicy

    // URL rules (when browser is in allowed apps)
    var allowedURLs: [String]   // Domain patterns
    var blockedURLs: [String]   // Domain patterns
    var defaultURLPolicy: AppPolicy

    // Restriction strategy
    var strictness: Strictness
    var cooldownMinutes: Int

    // Pomodoro config (stored in seconds)
    var workDuration: Int
    var breakDuration: Int
    var longBreakDuration: Int
    var longBreakInterval: Int

    // Environment
    var enableDND: Bool
    var hideDock: Bool

    // Auto-trigger
    var triggerApps: [String]  // Bundle IDs that trigger this mode (empty = use allowedApps)
    var triggerDelay: Int      // Seconds before triggering suggestion (default 60)

    var isPreset: Bool
    var sortOrder: Int

    init(
        name: String,
        icon: String,
        statsTag: String,
        allowedApps: [String] = [],
        blockedApps: [String] = [],
        defaultAppPolicy: AppPolicy = .allow,
        allowedURLs: [String] = [],
        blockedURLs: [String] = [],
        defaultURLPolicy: AppPolicy = .block,
        strictness: Strictness = .overlay,
        cooldownMinutes: Int = 0,
        workDuration: Int = 25 * 60,
        breakDuration: Int = 5 * 60,
        longBreakDuration: Int = 15 * 60,
        longBreakInterval: Int = 4,
        enableDND: Bool = true,
        hideDock: Bool = false,
        triggerApps: [String] = [],
        triggerDelay: Int = 60,
        isPreset: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.statsTag = statsTag
        self.allowedApps = allowedApps
        self.blockedApps = blockedApps
        self.defaultAppPolicy = defaultAppPolicy
        self.allowedURLs = allowedURLs
        self.blockedURLs = blockedURLs
        self.defaultURLPolicy = defaultURLPolicy
        self.strictness = strictness
        self.cooldownMinutes = cooldownMinutes
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.longBreakInterval = longBreakInterval
        self.enableDND = enableDND
        self.hideDock = hideDock
        self.triggerApps = triggerApps
        self.triggerDelay = triggerDelay
        self.isPreset = isPreset
        self.sortOrder = sortOrder
    }

    func isAppAllowed(bundleID: String) -> Bool {
        if allowedApps.contains(bundleID) { return true }
        if blockedApps.contains(bundleID) { return false }
        return defaultAppPolicy == .allow
    }

    func isURLAllowed(_ urlString: String) -> Bool {
        guard let host = URL(string: urlString)?.host()?.lowercased() else { return false }
        for pattern in allowedURLs {
            if host == pattern || host.hasSuffix("." + pattern) { return true }
        }
        for pattern in blockedURLs {
            if host == pattern || host.hasSuffix("." + pattern) { return false }
        }
        return defaultURLPolicy == .allow
    }
}
