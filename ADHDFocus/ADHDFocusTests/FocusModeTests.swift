import Testing
import Foundation
@testable import ADHDFocus

@Test func focusModeDefaultValues() {
    let mode = FocusMode(name: "Test Mode", icon: "🎨", statsTag: "test")
    #expect(mode.name == "Test Mode")
    #expect(mode.icon == "🎨")
    #expect(mode.allowedApps.isEmpty)
    #expect(mode.blockedApps.isEmpty)
    #expect(mode.defaultAppPolicy == .allow)
    #expect(mode.allowedURLs.isEmpty)
    #expect(mode.blockedURLs.isEmpty)
    #expect(mode.defaultURLPolicy == .block)
    #expect(mode.strictness == .overlay)
    #expect(mode.cooldownMinutes == 0)
    #expect(mode.workDuration == 25 * 60)
    #expect(mode.breakDuration == 5 * 60)
    #expect(mode.longBreakDuration == 15 * 60)
    #expect(mode.longBreakInterval == 4)
    #expect(mode.enableDND == true)
    #expect(mode.hideDock == false)
}

@Test func focusModeAppRuleCheck() {
    let mode = FocusMode(name: "Design", icon: "🎨", statsTag: "design")
    mode.allowedApps = ["com.figma.Desktop", "com.bohemiancoding.sketch3"]
    mode.blockedApps = ["com.tencent.xinWeChat"]
    mode.defaultAppPolicy = .block

    #expect(mode.isAppAllowed(bundleID: "com.figma.Desktop") == true)
    #expect(mode.isAppAllowed(bundleID: "com.tencent.xinWeChat") == false)
    #expect(mode.isAppAllowed(bundleID: "com.apple.finder") == false)
}

@Test func focusModeURLRuleCheck() {
    let mode = FocusMode(name: "Design", icon: "🎨", statsTag: "design")
    mode.allowedURLs = ["dribbble.com", "behance.net"]
    mode.blockedURLs = ["weibo.com"]
    mode.defaultURLPolicy = .block

    #expect(mode.isURLAllowed("https://dribbble.com/shots") == true)
    #expect(mode.isURLAllowed("https://www.behance.net/gallery") == true)
    #expect(mode.isURLAllowed("https://weibo.com/home") == false)
    #expect(mode.isURLAllowed("https://twitter.com") == false)
}
