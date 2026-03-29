import Testing
import Foundation
@testable import ADHDFocus

@Test func focusEngineStartsInactive() {
    let engine = FocusEngine()
    #expect(engine.isActive == false)
    #expect(engine.activeMode == nil)
}

@Test func focusEngineActivatesMode() {
    let engine = FocusEngine()
    let mode = FocusMode(name: "Test", icon: "🎨", statsTag: "test")
    engine.activate(mode: mode)
    #expect(engine.isActive == true)
    #expect(engine.activeMode?.name == "Test")
}

@Test func focusEngineDeactivates() {
    let engine = FocusEngine()
    let mode = FocusMode(name: "Test", icon: "🎨", statsTag: "test")
    engine.activate(mode: mode)
    engine.deactivate()
    #expect(engine.isActive == false)
    #expect(engine.activeMode == nil)
}

@Test func focusEngineShouldBlockApp() {
    let engine = FocusEngine()
    let mode = FocusMode(name: "Design", icon: "🎨", statsTag: "design")
    mode.blockedApps = ["com.tencent.xinWeChat"]
    mode.defaultAppPolicy = .allow
    engine.activate(mode: mode)

    #expect(engine.shouldBlockApp(bundleID: "com.tencent.xinWeChat") == true)
    #expect(engine.shouldBlockApp(bundleID: "com.figma.Desktop") == false)
}

@Test func focusEngineAllowsEverythingOnBreak() {
    let engine = FocusEngine()
    let mode = FocusMode(
        name: "Design", icon: "🎨", statsTag: "design",
        workDuration: 1, breakDuration: 5
    )
    mode.blockedApps = ["com.tencent.xinWeChat"]
    mode.defaultAppPolicy = .block
    engine.activate(mode: mode)

    #expect(engine.shouldBlockApp(bundleID: "com.tencent.xinWeChat") == true)
    engine.pomodoroTimer?.simulateTick(seconds: 1)
    #expect(engine.shouldBlockApp(bundleID: "com.tencent.xinWeChat") == false)
}

@Test func focusEngineDoesNotBlockWhenInactive() {
    let engine = FocusEngine()
    #expect(engine.shouldBlockApp(bundleID: "com.tencent.xinWeChat") == false)
}
