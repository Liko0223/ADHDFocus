# ADHD Focus App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS native focus assistant for ADHD users that blocks distracting apps/websites through a mode-based system with Pomodoro timer and focus statistics.

**Architecture:** SwiftUI menu bar + main window app with a background app monitoring service (NSWorkspace), SwiftData persistence, and a Chrome Extension for URL blocking via Native Messaging.

**Tech Stack:** SwiftUI, SwiftData, NSWorkspace API, Chrome Extension (Manifest V3), Native Messaging Host, AppleScript (Do Not Disturb)

---

## File Structure

```
ADHDFocus/
├── ADHDFocus.xcodeproj
├── ADHDFocus/
│   ├── ADHDFocusApp.swift              — App entry point, menu bar + window setup
│   ├── Models/
│   │   ├── FocusMode.swift             — SwiftData model for focus modes
│   │   ├── FocusSession.swift          — SwiftData model for focus session records
│   │   ├── BlockEvent.swift            — SwiftData model for app/URL block events
│   │   └── DefaultModes.swift          — 4 preset mode definitions
│   ├── Services/
│   │   ├── FocusEngine.swift           — Central state machine: active mode, timer, break state
│   │   ├── AppMonitor.swift            — NSWorkspace app launch listener + termination
│   │   ├── PomodoroTimer.swift         — Pomodoro countdown logic with work/break/long-break
│   │   ├── DNDController.swift         — macOS Do Not Disturb toggle via AppleScript
│   │   ├── NativeMessagingHost.swift   — Stdio-based Native Messaging server for Chrome
│   │   └── NotificationManager.swift  — UNUserNotificationCenter wrapper
│   ├── Views/
│   │   ├── MenuBar/
│   │   │   └── MenuBarView.swift       — Popover: mode grid, timer, status
│   │   ├── MainWindow/
│   │   │   ├── MainWindowView.swift    — Tab container: modes, stats, settings
│   │   │   ├── ModeListView.swift      — List of all modes with add/edit/delete
│   │   │   ├── ModeEditorView.swift    — Edit mode: app rules, URL rules, timer, env
│   │   │   ├── StatsView.swift         — Today's focus stats dashboard
│   │   │   └── SettingsView.swift      — Global settings, permissions
│   │   └── Shared/
│   │       └── BlockedNotificationView.swift — Blocked app notification banner
│   └── Resources/
│       └── Assets.xcassets
├── ADHDFocusTests/
│   ├── FocusModeTests.swift
│   ├── PomodoroTimerTests.swift
│   ├── AppMonitorTests.swift
│   ├── FocusEngineTests.swift
│   └── NativeMessagingTests.swift
└── ChromeExtension/
    ├── manifest.json                   — Manifest V3 config
    ├── background.js                   — Service worker: Native Messaging + rule sync
    ├── content.js                      — Block page injection
    ├── blocked.html                    — Blocked URL page template
    ├── blocked.css                     — Blocked page styles
    └── icons/
        ├── icon16.png
        ├── icon48.png
        └── icon128.png
```

---

## Task 1: Xcode Project Setup

**Files:**
- Create: `ADHDFocus.xcodeproj` (via Xcode CLI)
- Create: `ADHDFocus/ADHDFocusApp.swift`

- [ ] **Step 1: Create Xcode project**

Open Xcode and create a new macOS App project:
- Product Name: `ADHDFocus`
- Organization Identifier: `com.lilinke`
- Interface: SwiftUI
- Storage: SwiftData
- Language: Swift
- Location: `/Users/lilinke/Projects/Mac/ADHD/`

Or via command line:
```bash
cd /Users/lilinke/Projects/Mac/ADHD
mkdir -p ADHDFocus/ADHDFocus/{Models,Services,Views/{MenuBar,MainWindow,Shared},Resources}
mkdir -p ADHDFocus/ADHDFocusTests
mkdir -p ADHDFocus/ChromeExtension/icons
```

- [ ] **Step 2: Create minimal app entry point**

Create `ADHDFocus/ADHDFocus/ADHDFocusApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct ADHDFocusApp: App {
    var body: some Scene {
        MenuBarExtra("ADHD Focus", systemImage: "brain.head.profile") {
            Text("ADHD Focus — Coming Soon")
                .padding()
        }
        .menuBarExtraStyle(.window)

        Window("ADHD Focus", id: "main") {
            Text("Main Window — Coming Soon")
                .frame(minWidth: 600, minHeight: 400)
        }
    }
}
```

- [ ] **Step 3: Build and run to verify**

Run: `Cmd+R` in Xcode (or `xcodebuild -scheme ADHDFocus build`)
Expected: App launches with a menu bar icon (brain icon) and clicking it shows "Coming Soon". A main window is available.

- [ ] **Step 4: Commit**

```bash
cd /Users/lilinke/Projects/Mac/ADHD
git add ADHDFocus/
git commit -m "feat: scaffold Xcode project with menu bar + main window"
```

---

## Task 2: SwiftData Models

**Files:**
- Create: `ADHDFocus/ADHDFocus/Models/FocusMode.swift`
- Create: `ADHDFocus/ADHDFocus/Models/FocusSession.swift`
- Create: `ADHDFocus/ADHDFocus/Models/BlockEvent.swift`
- Test: `ADHDFocus/ADHDFocusTests/FocusModeTests.swift`

- [ ] **Step 1: Write failing tests for FocusMode model**

Create `ADHDFocus/ADHDFocusTests/FocusModeTests.swift`:

```swift
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
    #expect(mode.strictness == .forceQuit)
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
    #expect(mode.isAppAllowed(bundleID: "com.apple.finder") == false) // default: block
}

@Test func focusModeURLRuleCheck() {
    let mode = FocusMode(name: "Design", icon: "🎨", statsTag: "design")
    mode.allowedURLs = ["dribbble.com", "behance.net"]
    mode.blockedURLs = ["weibo.com"]
    mode.defaultURLPolicy = .block

    #expect(mode.isURLAllowed("https://dribbble.com/shots") == true)
    #expect(mode.isURLAllowed("https://www.behance.net/gallery") == true)
    #expect(mode.isURLAllowed("https://weibo.com/home") == false)
    #expect(mode.isURLAllowed("https://twitter.com") == false) // default: block
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme ADHDFocus -destination 'platform=macOS'`
Expected: FAIL — `FocusMode` not defined

- [ ] **Step 3: Implement FocusMode model**

Create `ADHDFocus/ADHDFocus/Models/FocusMode.swift`:

```swift
import Foundation
import SwiftData

enum AppPolicy: String, Codable {
    case allow
    case remind
    case block
}

enum Strictness: String, Codable {
    case remind      // Show reminder, don't force quit
    case forceQuit   // Terminate the app immediately
    case delayAllow  // Allow after 5-minute buffer
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
        strictness: Strictness = .forceQuit,
        cooldownMinutes: Int = 0,
        workDuration: Int = 25 * 60,
        breakDuration: Int = 5 * 60,
        longBreakDuration: Int = 15 * 60,
        longBreakInterval: Int = 4,
        enableDND: Bool = true,
        hideDock: Bool = false,
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
        self.isPreset = isPreset
        self.sortOrder = sortOrder
    }

    func isAppAllowed(bundleID: String) -> Bool {
        if allowedApps.contains(bundleID) { return true }
        if blockedApps.contains(bundleID) { return false }
        return defaultAppPolicy == .allow
    }

    func isURLAllowed(_ urlString: String) -> Bool {
        guard let host = URL(string: urlString)?.host?.lowercased() else { return false }
        for pattern in allowedURLs {
            if host == pattern || host.hasSuffix("." + pattern) { return true }
        }
        for pattern in blockedURLs {
            if host == pattern || host.hasSuffix("." + pattern) { return false }
        }
        return defaultURLPolicy == .allow
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme ADHDFocus -destination 'platform=macOS'`
Expected: All 3 tests PASS

- [ ] **Step 5: Implement FocusSession and BlockEvent models**

Create `ADHDFocus/ADHDFocus/Models/FocusSession.swift`:

```swift
import Foundation
import SwiftData

@Model
final class FocusSession {
    var id: UUID
    var modeID: UUID
    var modeName: String
    var statsTag: String
    var startedAt: Date
    var endedAt: Date?
    var completedPomodoros: Int
    var totalWorkSeconds: Int

    init(modeID: UUID, modeName: String, statsTag: String) {
        self.id = UUID()
        self.modeID = modeID
        self.modeName = modeName
        self.statsTag = statsTag
        self.startedAt = Date()
        self.endedAt = nil
        self.completedPomodoros = 0
        self.totalWorkSeconds = 0
    }
}
```

Create `ADHDFocus/ADHDFocus/Models/BlockEvent.swift`:

```swift
import Foundation
import SwiftData

enum BlockEventType: String, Codable {
    case app
    case url
}

@Model
final class BlockEvent {
    var id: UUID
    var type: BlockEventType
    var target: String  // Bundle ID or URL domain
    var modeName: String
    var timestamp: Date

    init(type: BlockEventType, target: String, modeName: String) {
        self.id = UUID()
        self.type = type
        self.target = target
        self.modeName = modeName
        self.timestamp = Date()
    }
}
```

- [ ] **Step 6: Commit**

```bash
git add ADHDFocus/ADHDFocus/Models/ ADHDFocus/ADHDFocusTests/
git commit -m "feat: add SwiftData models for FocusMode, FocusSession, BlockEvent"
```

---

## Task 3: Default Mode Presets

**Files:**
- Create: `ADHDFocus/ADHDFocus/Models/DefaultModes.swift`

- [ ] **Step 1: Create preset definitions**

Create `ADHDFocus/ADHDFocus/Models/DefaultModes.swift`:

```swift
import Foundation

struct DefaultModes {
    static func createAll() -> [FocusMode] {
        [deepDesign(), researchInspiration(), communication(), writing()]
    }

    static func deepDesign() -> FocusMode {
        FocusMode(
            name: "深度设计",
            icon: "🎨",
            statsTag: "design",
            allowedApps: [
                "com.figma.Desktop",
                "com.bohemiancoding.sketch3",
                "com.adobe.Photoshop",
                "com.adobe.illustrator",
                "com.google.Chrome"  // browser allowed, URL rules apply
            ],
            blockedApps: [
                "com.tencent.xinWeChat",
                "com.electron.lark",
                "com.tinyspeck.slackmacgap"
            ],
            defaultAppPolicy: .block,
            allowedURLs: [
                "dribbble.com",
                "behance.net",
                "figma.com",
                "pinterest.com",
                "awwwards.com",
                "siteinspire.com",
                "fonts.google.com",
                "coolors.co",
                "unsplash.com"
            ],
            blockedURLs: [
                "weibo.com",
                "xiaohongshu.com",
                "bilibili.com",
                "douyin.com",
                "twitter.com",
                "x.com",
                "facebook.com",
                "instagram.com",
                "youtube.com"
            ],
            defaultURLPolicy: .remind,
            strictness: .forceQuit,
            enableDND: true,
            hideDock: false,
            isPreset: true,
            sortOrder: 0
        )
    }

    static func researchInspiration() -> FocusMode {
        FocusMode(
            name: "调研灵感",
            icon: "🔬",
            statsTag: "research",
            allowedApps: [
                "com.figma.Desktop",
                "com.bohemiancoding.sketch3",
                "com.google.Chrome",
                "com.apple.Notes",
                "com.apple.Preview"
            ],
            blockedApps: [
                "com.tencent.xinWeChat",
                "com.electron.lark"
            ],
            defaultAppPolicy: .remind,
            allowedURLs: [
                "dribbble.com",
                "behance.net",
                "figma.com",
                "pinterest.com",
                "awwwards.com",
                "siteinspire.com",
                "medium.com",
                "github.com",
                "stackoverflow.com"
            ],
            blockedURLs: [
                "weibo.com",
                "bilibili.com",
                "douyin.com"
            ],
            defaultURLPolicy: .remind,
            strictness: .remind,
            enableDND: true,
            hideDock: false,
            isPreset: true,
            sortOrder: 1
        )
    }

    static func communication() -> FocusMode {
        FocusMode(
            name: "沟通协作",
            icon: "💬",
            statsTag: "communication",
            allowedApps: [
                "com.tencent.xinWeChat",
                "com.electron.lark",
                "com.tinyspeck.slackmacgap",
                "com.google.Chrome",
                "com.figma.Desktop",
                "com.apple.mail"
            ],
            blockedApps: [],
            defaultAppPolicy: .allow,
            allowedURLs: [],
            blockedURLs: [
                "weibo.com",
                "bilibili.com",
                "douyin.com"
            ],
            defaultURLPolicy: .allow,
            strictness: .remind,
            workDuration: 0,  // Pomodoro disabled
            enableDND: false,
            hideDock: false,
            isPreset: true,
            sortOrder: 2
        )
    }

    static func writing() -> FocusMode {
        FocusMode(
            name: "写作整理",
            icon: "✍️",
            statsTag: "writing",
            allowedApps: [
                "md.obsidian",
                "com.apple.Notes",
                "com.apple.TextEdit",
                "notion.id",
                "com.google.Chrome"
            ],
            blockedApps: [
                "com.tencent.xinWeChat",
                "com.electron.lark",
                "com.tinyspeck.slackmacgap",
                "com.figma.Desktop"
            ],
            defaultAppPolicy: .block,
            allowedURLs: [
                "notion.so",
                "docs.google.com",
                "github.com"
            ],
            blockedURLs: [
                "weibo.com",
                "xiaohongshu.com",
                "bilibili.com",
                "douyin.com",
                "youtube.com"
            ],
            defaultURLPolicy: .block,
            strictness: .forceQuit,
            enableDND: true,
            hideDock: true,
            isPreset: true,
            sortOrder: 3
        )
    }
}
```

- [ ] **Step 2: Build to verify compilation**

Run: `xcodebuild -scheme ADHDFocus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ADHDFocus/ADHDFocus/Models/DefaultModes.swift
git commit -m "feat: add 4 preset focus modes for designers"
```

---

## Task 4: Pomodoro Timer Service

**Files:**
- Create: `ADHDFocus/ADHDFocus/Services/PomodoroTimer.swift`
- Test: `ADHDFocus/ADHDFocusTests/PomodoroTimerTests.swift`

- [ ] **Step 1: Write failing tests**

Create `ADHDFocus/ADHDFocusTests/PomodoroTimerTests.swift`:

```swift
import Testing
import Foundation
@testable import ADHDFocus

@Test func pomodoroTimerStartsInWorkPhase() {
    let timer = PomodoroTimer(
        workDuration: 10,
        breakDuration: 5,
        longBreakDuration: 15,
        longBreakInterval: 4
    )
    #expect(timer.phase == .idle)
    timer.start()
    #expect(timer.phase == .work)
    #expect(timer.remainingSeconds == 10)
    #expect(timer.completedPomodoros == 0)
}

@Test func pomodoroTimerTransitionsToBreak() {
    let timer = PomodoroTimer(
        workDuration: 1,
        breakDuration: 5,
        longBreakDuration: 15,
        longBreakInterval: 4
    )
    timer.start()
    timer.simulateTick(seconds: 1)
    #expect(timer.phase == .break_)
    #expect(timer.remainingSeconds == 5)
    #expect(timer.completedPomodoros == 1)
}

@Test func pomodoroTimerLongBreakAfterInterval() {
    let timer = PomodoroTimer(
        workDuration: 1,
        breakDuration: 1,
        longBreakDuration: 10,
        longBreakInterval: 2
    )
    timer.start()
    // Work 1 -> Break 1 -> Work 2 -> Long Break
    timer.simulateTick(seconds: 1) // end work 1 -> break
    timer.simulateTick(seconds: 1) // end break -> work
    timer.simulateTick(seconds: 1) // end work 2 -> long break
    #expect(timer.phase == .longBreak)
    #expect(timer.remainingSeconds == 10)
    #expect(timer.completedPomodoros == 2)
}

@Test func pomodoroTimerStop() {
    let timer = PomodoroTimer(
        workDuration: 25,
        breakDuration: 5,
        longBreakDuration: 15,
        longBreakInterval: 4
    )
    timer.start()
    timer.stop()
    #expect(timer.phase == .idle)
    #expect(timer.remainingSeconds == 0)
}

@Test func pomodoroTimerIsOnBreak() {
    let timer = PomodoroTimer(
        workDuration: 1,
        breakDuration: 5,
        longBreakDuration: 15,
        longBreakInterval: 4
    )
    timer.start()
    #expect(timer.isOnBreak == false)
    timer.simulateTick(seconds: 1)
    #expect(timer.isOnBreak == true)
}

@Test func pomodoroTimerDisabledWhenZeroDuration() {
    let timer = PomodoroTimer(
        workDuration: 0,
        breakDuration: 0,
        longBreakDuration: 0,
        longBreakInterval: 4
    )
    #expect(timer.isDisabled == true)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme ADHDFocus -destination 'platform=macOS'`
Expected: FAIL — `PomodoroTimer` not defined

- [ ] **Step 3: Implement PomodoroTimer**

Create `ADHDFocus/ADHDFocus/Services/PomodoroTimer.swift`:

```swift
import Foundation
import Observation

enum PomodoroPhase: String {
    case idle
    case work
    case break_
    case longBreak
}

@Observable
final class PomodoroTimer {
    let workDuration: Int
    let breakDuration: Int
    let longBreakDuration: Int
    let longBreakInterval: Int

    private(set) var phase: PomodoroPhase = .idle
    private(set) var remainingSeconds: Int = 0
    private(set) var completedPomodoros: Int = 0

    private var timer: Timer?

    var isOnBreak: Bool {
        phase == .break_ || phase == .longBreak
    }

    var isDisabled: Bool {
        workDuration == 0
    }

    var isRunning: Bool {
        phase != .idle
    }

    var progress: Double {
        let total: Int
        switch phase {
        case .idle: return 0
        case .work: total = workDuration
        case .break_: total = breakDuration
        case .longBreak: total = longBreakDuration
        }
        guard total > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(total))
    }

    var onPhaseChange: ((PomodoroPhase) -> Void)?

    init(workDuration: Int, breakDuration: Int, longBreakDuration: Int, longBreakInterval: Int) {
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.longBreakInterval = longBreakInterval
    }

    func start() {
        guard !isDisabled else { return }
        phase = .work
        remainingSeconds = workDuration
        completedPomodoros = 0
        startTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        phase = .idle
        remainingSeconds = 0
    }

    // For testing without real timers
    func simulateTick(seconds: Int) {
        for _ in 0..<seconds {
            tick()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            transitionPhase()
        }
    }

    private func transitionPhase() {
        switch phase {
        case .work:
            completedPomodoros += 1
            if completedPomodoros % longBreakInterval == 0 {
                phase = .longBreak
                remainingSeconds = longBreakDuration
            } else {
                phase = .break_
                remainingSeconds = breakDuration
            }
        case .break_, .longBreak:
            phase = .work
            remainingSeconds = workDuration
        case .idle:
            break
        }
        onPhaseChange?(phase)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme ADHDFocus -destination 'platform=macOS'`
Expected: All 6 Pomodoro tests PASS

- [ ] **Step 5: Commit**

```bash
git add ADHDFocus/ADHDFocus/Services/PomodoroTimer.swift ADHDFocus/ADHDFocusTests/PomodoroTimerTests.swift
git commit -m "feat: add PomodoroTimer with work/break/longBreak phases"
```

---

## Task 5: FocusEngine (Central State Machine)

**Files:**
- Create: `ADHDFocus/ADHDFocus/Services/FocusEngine.swift`
- Test: `ADHDFocus/ADHDFocusTests/FocusEngineTests.swift`

- [ ] **Step 1: Write failing tests**

Create `ADHDFocus/ADHDFocusTests/FocusEngineTests.swift`:

```swift
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

    // During work phase, app is blocked
    #expect(engine.shouldBlockApp(bundleID: "com.tencent.xinWeChat") == true)

    // Simulate entering break
    engine.pomodoroTimer?.simulateTick(seconds: 1)
    #expect(engine.shouldBlockApp(bundleID: "com.tencent.xinWeChat") == false)
}

@Test func focusEngineDoesNotBlockWhenInactive() {
    let engine = FocusEngine()
    #expect(engine.shouldBlockApp(bundleID: "com.tencent.xinWeChat") == false)
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme ADHDFocus -destination 'platform=macOS'`
Expected: FAIL — `FocusEngine` not defined

- [ ] **Step 3: Implement FocusEngine**

Create `ADHDFocus/ADHDFocus/Services/FocusEngine.swift`:

```swift
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

    /// Returns URL rules as a dictionary for Chrome Extension sync
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
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme ADHDFocus -destination 'platform=macOS'`
Expected: All 6 FocusEngine tests PASS

- [ ] **Step 5: Commit**

```bash
git add ADHDFocus/ADHDFocus/Services/FocusEngine.swift ADHDFocus/ADHDFocusTests/FocusEngineTests.swift
git commit -m "feat: add FocusEngine state machine with break-aware blocking"
```

---

## Task 6: App Monitor Service

**Files:**
- Create: `ADHDFocus/ADHDFocus/Services/AppMonitor.swift`
- Create: `ADHDFocus/ADHDFocus/Services/NotificationManager.swift`

- [ ] **Step 1: Implement NotificationManager**

Create `ADHDFocus/ADHDFocus/Services/NotificationManager.swift`:

```swift
import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sendBlockedAppNotification(appName: String, modeName: String, remainingSeconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "\(appName) 已被暂时限制"
        content.body = "当前模式「\(modeName)」不允许使用此应用"
        if remainingSeconds > 0 {
            let minutes = remainingSeconds / 60
            content.body += "，番茄钟剩余 \(minutes) 分钟"
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "blocked-app-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func sendPomodoroNotification(phase: PomodoroPhase) {
        let content = UNMutableNotificationContent()
        switch phase {
        case .work:
            content.title = "休息结束"
            content.body = "回到工作状态，保持专注 💪"
        case .break_:
            content.title = "番茄钟完成！"
            content.body = "休息一下吧，起来走走 ☕"
        case .longBreak:
            content.title = "长休息时间！"
            content.body = "你已经连续完成多个番茄钟，好好休息 🌴"
        case .idle:
            return
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "pomodoro-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
```

- [ ] **Step 2: Implement AppMonitor**

Create `ADHDFocus/ADHDFocus/Services/AppMonitor.swift`:

```swift
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

        // Never block ourselves or Finder
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

        // Record block event
        let event = BlockEvent(
            type: .app,
            target: bundleID,
            modeName: engine.activeMode?.name ?? ""
        )
        modelContext.insert(event)
        try? modelContext.save()

        // Terminate the app
        if engine.activeMode?.strictness == .forceQuit {
            app.terminate()
        }

        // Send notification
        NotificationManager.shared.sendBlockedAppNotification(
            appName: appName,
            modeName: engine.activeMode?.name ?? "",
            remainingSeconds: engine.pomodoroTimer?.remainingSeconds ?? 0
        )
    }
}
```

- [ ] **Step 3: Build to verify compilation**

Run: `xcodebuild -scheme ADHDFocus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add ADHDFocus/ADHDFocus/Services/AppMonitor.swift ADHDFocus/ADHDFocus/Services/NotificationManager.swift
git commit -m "feat: add AppMonitor with NSWorkspace launch detection and block notifications"
```

---

## Task 7: Do Not Disturb Controller

**Files:**
- Create: `ADHDFocus/ADHDFocus/Services/DNDController.swift`

- [ ] **Step 1: Implement DNDController**

Create `ADHDFocus/ADHDFocus/Services/DNDController.swift`:

```swift
import Foundation

final class DNDController {
    func enableDND() {
        let script = """
        tell application "System Events"
            tell application process "ControlCenter"
                -- Toggle Focus/DND via Shortcuts
            end tell
        end tell
        """
        // Use Shortcuts CLI for reliable DND control on macOS Monterey+
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        task.arguments = ["run", "Enable DND"]
        try? task.run()
    }

    func disableDND() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        task.arguments = ["run", "Disable DND"]
        try? task.run()
    }
}
```

> **Note for setup:** The user needs to create two Shortcuts in the macOS Shortcuts app:
> 1. "Enable DND" — Set Focus to Do Not Disturb, turned on
> 2. "Disable DND" — Set Focus to Do Not Disturb, turned off
>
> The app's Settings page should include instructions for this setup.

- [ ] **Step 2: Build to verify**

Run: `xcodebuild -scheme ADHDFocus build`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add ADHDFocus/ADHDFocus/Services/DNDController.swift
git commit -m "feat: add DNDController using macOS Shortcuts CLI"
```

---

## Task 8: Menu Bar View

**Files:**
- Create: `ADHDFocus/ADHDFocus/Views/MenuBar/MenuBarView.swift`
- Modify: `ADHDFocus/ADHDFocus/ADHDFocusApp.swift`

- [ ] **Step 1: Create MenuBarView**

Create `ADHDFocus/ADHDFocus/Views/MenuBar/MenuBarView.swift`:

```swift
import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusMode.sortOrder) private var modes: [FocusMode]
    @Bindable var engine: FocusEngine

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("ADHD Focus")
                    .font(.headline)
                Spacer()
                if engine.isActive {
                    Text("专注中")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
            }

            // Active mode + timer
            if let mode = engine.activeMode {
                VStack(spacing: 8) {
                    HStack {
                        Text(mode.icon)
                            .font(.title2)
                        Text(mode.name)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        if let timer = engine.pomodoroTimer, timer.isRunning {
                            Text(formatTime(timer.remainingSeconds))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let timer = engine.pomodoroTimer, timer.isRunning {
                        ProgressView(value: timer.progress)
                            .tint(timer.isOnBreak ? .green : .purple)
                    }
                }
                .padding(10)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Mode grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(modes) { mode in
                    Button {
                        if engine.activeMode?.id == mode.id {
                            return
                        }
                        engine.activate(mode: mode)
                    } label: {
                        VStack(spacing: 4) {
                            Text(mode.icon)
                                .font(.title3)
                            Text(mode.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            engine.activeMode?.id == mode.id
                                ? Color.purple.opacity(0.2)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    engine.activeMode?.id == mode.id
                                        ? Color.purple
                                        : Color.secondary.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Stop button
                if engine.isActive {
                    Button {
                        engine.deactivate()
                    } label: {
                        VStack(spacing: 4) {
                            Text("⏸️")
                                .font(.title3)
                            Text("结束专注")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Open main window
            Button {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Text("打开主窗口 →")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 280)
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
```

- [ ] **Step 2: Update ADHDFocusApp to use MenuBarView**

Replace `ADHDFocus/ADHDFocus/ADHDFocusApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct ADHDFocusApp: App {
    @State private var engine = FocusEngine()

    var body: some Scene {
        MenuBarExtra("ADHD Focus", systemImage: "brain.head.profile") {
            MenuBarView(engine: engine)
                .modelContainer(for: [FocusMode.self, FocusSession.self, BlockEvent.self])
        }
        .menuBarExtraStyle(.window)

        Window("ADHD Focus", id: "main") {
            Text("Main Window — Coming Soon")
                .frame(minWidth: 600, minHeight: 400)
                .modelContainer(for: [FocusMode.self, FocusSession.self, BlockEvent.self])
        }
    }
}
```

- [ ] **Step 3: Build and run to verify visually**

Run: `Cmd+R` in Xcode
Expected: Menu bar icon appears. Clicking it shows the popover with mode grid. (Modes will be empty until we seed default modes — that's fine for now.)

- [ ] **Step 4: Commit**

```bash
git add ADHDFocus/ADHDFocus/Views/MenuBar/MenuBarView.swift ADHDFocus/ADHDFocus/ADHDFocusApp.swift
git commit -m "feat: add MenuBarView with mode grid, timer, and status"
```

---

## Task 9: Main Window — Mode List & Editor

**Files:**
- Create: `ADHDFocus/ADHDFocus/Views/MainWindow/MainWindowView.swift`
- Create: `ADHDFocus/ADHDFocus/Views/MainWindow/ModeListView.swift`
- Create: `ADHDFocus/ADHDFocus/Views/MainWindow/ModeEditorView.swift`

- [ ] **Step 1: Create MainWindowView with tab navigation**

Create `ADHDFocus/ADHDFocus/Views/MainWindow/MainWindowView.swift`:

```swift
import SwiftUI

enum MainTab: String, CaseIterable {
    case modes = "模式"
    case stats = "统计"
    case settings = "设置"

    var icon: String {
        switch self {
        case .modes: return "rectangle.stack"
        case .stats: return "chart.bar"
        case .settings: return "gearshape"
        }
    }
}

struct MainWindowView: View {
    @State private var selectedTab: MainTab = .modes
    @Bindable var engine: FocusEngine

    var body: some View {
        NavigationSplitView {
            List(MainTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
            }
            .navigationSplitViewColumnWidth(min: 140, ideal: 160)
        } detail: {
            switch selectedTab {
            case .modes:
                ModeListView(engine: engine)
            case .stats:
                Text("统计 — Coming Soon")
            case .settings:
                Text("设置 — Coming Soon")
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}
```

- [ ] **Step 2: Create ModeListView**

Create `ADHDFocus/ADHDFocus/Views/MainWindow/ModeListView.swift`:

```swift
import SwiftUI
import SwiftData

struct ModeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusMode.sortOrder) private var modes: [FocusMode]
    @State private var selectedMode: FocusMode?
    @Bindable var engine: FocusEngine

    var body: some View {
        HSplitView {
            // Mode list
            VStack(spacing: 0) {
                List(modes, selection: $selectedMode) { mode in
                    HStack(spacing: 10) {
                        Text(mode.icon)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.name)
                                .font(.body.weight(.medium))
                            Text("\(mode.allowedApps.count) 个允许应用")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if engine.activeMode?.id == mode.id {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.vertical, 4)
                    .tag(mode)
                }
                .frame(minWidth: 200)

                Divider()

                HStack {
                    Button(action: addMode) {
                        Image(systemName: "plus")
                    }
                    Button(action: deleteSelectedMode) {
                        Image(systemName: "minus")
                    }
                    .disabled(selectedMode == nil)
                    Spacer()
                }
                .padding(8)
            }

            // Editor
            if let mode = selectedMode {
                ModeEditorView(mode: mode)
            } else {
                ContentUnavailableView("选择一个模式", systemImage: "rectangle.stack", description: Text("从左侧列表中选择模式进行编辑"))
            }
        }
    }

    private func addMode() {
        let mode = FocusMode(
            name: "新模式",
            icon: "⭐",
            statsTag: "custom",
            sortOrder: modes.count
        )
        modelContext.insert(mode)
        selectedMode = mode
    }

    private func deleteSelectedMode() {
        guard let mode = selectedMode else { return }
        if engine.activeMode?.id == mode.id {
            engine.deactivate()
        }
        modelContext.delete(mode)
        selectedMode = nil
    }
}
```

- [ ] **Step 3: Create ModeEditorView**

Create `ADHDFocus/ADHDFocus/Views/MainWindow/ModeEditorView.swift`:

```swift
import SwiftUI

struct ModeEditorView: View {
    @Bindable var mode: FocusMode
    @State private var newAllowedApp = ""
    @State private var newBlockedApp = ""
    @State private var newAllowedURL = ""
    @State private var newBlockedURL = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Basic info
                GroupBox("基本信息") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            TextField("图标", text: $mode.icon)
                                .frame(width: 50)
                            TextField("名称", text: $mode.name)
                        }
                        TextField("统计标签", text: $mode.statsTag)
                    }
                    .padding(8)
                }

                // App rules
                GroupBox("应用规则") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("允许的应用 (Bundle ID)")
                            .font(.caption.weight(.medium))
                        appListEditor(
                            items: $mode.allowedApps,
                            newItem: $newAllowedApp,
                            placeholder: "com.figma.Desktop"
                        )

                        Divider()

                        Text("禁止的应用 (Bundle ID)")
                            .font(.caption.weight(.medium))
                        appListEditor(
                            items: $mode.blockedApps,
                            newItem: $newBlockedApp,
                            placeholder: "com.tencent.xinWeChat"
                        )

                        Divider()

                        Picker("未列出的应用", selection: $mode.defaultAppPolicy) {
                            Text("允许").tag(AppPolicy.allow)
                            Text("提醒").tag(AppPolicy.remind)
                            Text("禁止").tag(AppPolicy.block)
                        }
                    }
                    .padding(8)
                }

                // URL rules
                GroupBox("浏览器规则") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("允许的网站")
                            .font(.caption.weight(.medium))
                        appListEditor(
                            items: $mode.allowedURLs,
                            newItem: $newAllowedURL,
                            placeholder: "dribbble.com"
                        )

                        Divider()

                        Text("禁止的网站")
                            .font(.caption.weight(.medium))
                        appListEditor(
                            items: $mode.blockedURLs,
                            newItem: $newBlockedURL,
                            placeholder: "weibo.com"
                        )

                        Divider()

                        Picker("未列出的网站", selection: $mode.defaultURLPolicy) {
                            Text("允许").tag(AppPolicy.allow)
                            Text("提醒").tag(AppPolicy.remind)
                            Text("禁止").tag(AppPolicy.block)
                        }
                    }
                    .padding(8)
                }

                // Restriction strategy
                GroupBox("限制策略") {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("严格程度", selection: $mode.strictness) {
                            Text("温和提醒").tag(Strictness.remind)
                            Text("强制退出").tag(Strictness.forceQuit)
                            Text("延迟允许").tag(Strictness.delayAllow)
                        }
                        HStack {
                            Text("冷却期（分钟）")
                            TextField("0", value: $mode.cooldownMinutes, format: .number)
                                .frame(width: 60)
                        }
                    }
                    .padding(8)
                }

                // Pomodoro config
                GroupBox("番茄钟") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("工作时长（分钟）")
                            TextField("25", value: Binding(
                                get: { mode.workDuration / 60 },
                                set: { mode.workDuration = $0 * 60 }
                            ), format: .number)
                            .frame(width: 60)
                        }
                        HStack {
                            Text("休息时长（分钟）")
                            TextField("5", value: Binding(
                                get: { mode.breakDuration / 60 },
                                set: { mode.breakDuration = $0 * 60 }
                            ), format: .number)
                            .frame(width: 60)
                        }
                        HStack {
                            Text("长休息时长（分钟）")
                            TextField("15", value: Binding(
                                get: { mode.longBreakDuration / 60 },
                                set: { mode.longBreakDuration = $0 * 60 }
                            ), format: .number)
                            .frame(width: 60)
                        }
                        HStack {
                            Text("每几轮后长休息")
                            TextField("4", value: $mode.longBreakInterval, format: .number)
                                .frame(width: 60)
                        }
                        if mode.workDuration == 0 {
                            Text("番茄钟已禁用（工作时长为 0）")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .padding(8)
                }

                // Environment
                GroupBox("环境配置") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("自动开启勿扰模式", isOn: $mode.enableDND)
                        Toggle("自动隐藏 Dock", isOn: $mode.hideDock)
                    }
                    .padding(8)
                }
            }
            .padding(20)
        }
    }

    @ViewBuilder
    private func appListEditor(items: Binding<[String]>, newItem: Binding<String>, placeholder: String) -> some View {
        ForEach(items.wrappedValue, id: \.self) { item in
            HStack {
                Text(item)
                    .font(.caption.monospaced())
                Spacer()
                Button {
                    items.wrappedValue.removeAll { $0 == item }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        HStack {
            TextField(placeholder, text: newItem)
                .font(.caption.monospaced())
                .onSubmit {
                    let value = newItem.wrappedValue.trimmingCharacters(in: .whitespaces)
                    if !value.isEmpty && !items.wrappedValue.contains(value) {
                        items.wrappedValue.append(value)
                        newItem.wrappedValue = ""
                    }
                }
            Button("添加") {
                let value = newItem.wrappedValue.trimmingCharacters(in: .whitespaces)
                if !value.isEmpty && !items.wrappedValue.contains(value) {
                    items.wrappedValue.append(value)
                    newItem.wrappedValue = ""
                }
            }
            .disabled(newItem.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
```

- [ ] **Step 4: Update ADHDFocusApp to use MainWindowView**

In `ADHDFocus/ADHDFocus/ADHDFocusApp.swift`, replace the `Window` scene:

```swift
Window("ADHD Focus", id: "main") {
    MainWindowView(engine: engine)
        .modelContainer(for: [FocusMode.self, FocusSession.self, BlockEvent.self])
}
```

- [ ] **Step 5: Build and run**

Run: `Cmd+R` in Xcode
Expected: Main window shows sidebar with 3 tabs (模式/统计/设置). 模式 tab shows split view with mode list and editor.

- [ ] **Step 6: Commit**

```bash
git add ADHDFocus/ADHDFocus/Views/
git commit -m "feat: add main window with mode list and editor views"
```

---

## Task 10: Seed Default Modes on First Launch

**Files:**
- Modify: `ADHDFocus/ADHDFocus/ADHDFocusApp.swift`

- [ ] **Step 1: Add first-launch seeding logic**

Update `ADHDFocus/ADHDFocus/ADHDFocusApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct ADHDFocusApp: App {
    @State private var engine = FocusEngine()

    let container: ModelContainer

    init() {
        let schema = Schema([FocusMode.self, FocusSession.self, BlockEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        container = try! ModelContainer(for: schema, configurations: [config])
        seedDefaultModesIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra("ADHD Focus", systemImage: "brain.head.profile") {
            MenuBarView(engine: engine)
        }
        .menuBarExtraStyle(.window)

        Window("ADHD Focus", id: "main") {
            MainWindowView(engine: engine)
        }
    }

    private func seedDefaultModesIfNeeded() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<FocusMode>(
            predicate: #Predicate { $0.isPreset == true }
        )
        let existingPresets = (try? context.fetchCount(descriptor)) ?? 0
        if existingPresets == 0 {
            for mode in DefaultModes.createAll() {
                context.insert(mode)
            }
            try? context.save()
        }
    }
}
```

Note: Remove `.modelContainer()` modifiers from individual views since the container is now shared at the App level. Add `.modelContainer(container)` to both scenes:

```swift
MenuBarExtra("ADHD Focus", systemImage: "brain.head.profile") {
    MenuBarView(engine: engine)
        .modelContainer(container)
}

Window("ADHD Focus", id: "main") {
    MainWindowView(engine: engine)
        .modelContainer(container)
}
```

- [ ] **Step 2: Build and run**

Run: `Cmd+R` in Xcode
Expected: On first launch, 4 preset modes appear in both the menu bar popover and the main window mode list.

- [ ] **Step 3: Commit**

```bash
git add ADHDFocus/ADHDFocus/ADHDFocusApp.swift
git commit -m "feat: seed 4 default focus modes on first launch"
```

---

## Task 11: Wire Up AppMonitor and DND in App Lifecycle

**Files:**
- Modify: `ADHDFocus/ADHDFocus/ADHDFocusApp.swift`

- [ ] **Step 1: Connect AppMonitor, DNDController, and NotificationManager to FocusEngine**

Update `ADHDFocusApp`:

```swift
@main
struct ADHDFocusApp: App {
    @State private var engine = FocusEngine()

    let container: ModelContainer
    private let dndController = DNDController()
    @State private var appMonitor: AppMonitor?

    init() {
        let schema = Schema([FocusMode.self, FocusSession.self, BlockEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        container = try! ModelContainer(for: schema, configurations: [config])
        seedDefaultModesIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra("ADHD Focus", systemImage: "brain.head.profile") {
            MenuBarView(engine: engine)
                .modelContainer(container)
                .onAppear { setupEngine() }
        }
        .menuBarExtraStyle(.window)

        Window("ADHD Focus", id: "main") {
            MainWindowView(engine: engine)
                .modelContainer(container)
        }
    }

    private func setupEngine() {
        guard appMonitor == nil else { return }

        NotificationManager.shared.requestPermission()

        let monitor = AppMonitor(engine: engine, modelContext: container.mainContext)
        appMonitor = monitor

        engine.onModeActivated = { mode in
            monitor.startMonitoring()
            if mode.enableDND { dndController.enableDND() }
            if mode.hideDock {
                NSApp.setActivationPolicy(.accessory)
            }
        }

        engine.onModeDeactivated = {
            monitor.stopMonitoring()
            dndController.disableDND()
        }

        engine.onPomodoroPhaseChange = { phase in
            NotificationManager.shared.sendPomodoroNotification(phase: phase)
        }
    }

    private func seedDefaultModesIfNeeded() {
        let context = container.mainContext
        let descriptor = FetchDescriptor<FocusMode>(
            predicate: #Predicate { $0.isPreset == true }
        )
        let existingPresets = (try? context.fetchCount(descriptor)) ?? 0
        if existingPresets == 0 {
            for mode in DefaultModes.createAll() {
                context.insert(mode)
            }
            try? context.save()
        }
    }
}
```

- [ ] **Step 2: Build and run to test the full flow**

Run: `Cmd+R` in Xcode
Expected: Click a mode in menu bar → app monitor starts → try opening a blocked app → it gets terminated → notification appears. Click "结束专注" → monitoring stops.

- [ ] **Step 3: Commit**

```bash
git add ADHDFocus/ADHDFocus/ADHDFocusApp.swift
git commit -m "feat: wire up AppMonitor, DND, and notifications to FocusEngine lifecycle"
```

---

## Task 12: Focus Statistics View

**Files:**
- Create: `ADHDFocus/ADHDFocus/Views/MainWindow/StatsView.swift`
- Modify: `ADHDFocus/ADHDFocus/Views/MainWindow/MainWindowView.swift`

- [ ] **Step 1: Create StatsView**

Create `ADHDFocus/ADHDFocus/Views/MainWindow/StatsView.swift`:

```swift
import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var sessions: [FocusSession]
    @Query private var blockEvents: [BlockEvent]

    private var todaySessions: [FocusSession] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return sessions.filter { $0.startedAt >= startOfDay }
    }

    private var todayBlockEvents: [BlockEvent] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return blockEvents.filter { $0.timestamp >= startOfDay }
    }

    private var totalFocusMinutes: Int {
        todaySessions.reduce(0) { $0 + $1.totalWorkSeconds } / 60
    }

    private var completedPomodoros: Int {
        todaySessions.reduce(0) { $0 + $1.completedPomodoros }
    }

    private var blockedCount: Int {
        todayBlockEvents.count
    }

    private var streakDays: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())
        let calendar = Calendar.current

        while true {
            let dayStart = date
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: date)!
            let hasSessions = sessions.contains { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
            if hasSessions {
                streak += 1
                date = calendar.date(byAdding: .day, value: -1, to: date)!
            } else {
                break
            }
        }
        return streak
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("今日概览")
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(
                    icon: "clock.fill",
                    title: "专注时长",
                    value: "\(totalFocusMinutes)",
                    unit: "分钟",
                    color: .purple
                )
                StatCard(
                    icon: "checkmark.circle.fill",
                    title: "番茄钟",
                    value: "\(completedPomodoros)",
                    unit: "个完成",
                    color: .green
                )
                StatCard(
                    icon: "hand.raised.fill",
                    title: "拦截次数",
                    value: "\(blockedCount)",
                    unit: "次",
                    color: .orange
                )
                StatCard(
                    icon: "flame.fill",
                    title: "连续天数",
                    value: "\(streakDays)",
                    unit: "天",
                    color: .red
                )
            }

            Spacer()
        }
        .padding(24)
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

- [ ] **Step 2: Wire StatsView into MainWindowView**

In `MainWindowView.swift`, update the `stats` case:

```swift
case .stats:
    StatsView()
```

- [ ] **Step 3: Record sessions in FocusEngine lifecycle**

Add session recording to `ADHDFocusApp.setupEngine()`. In the `onModeActivated` closure, create a `FocusSession` and insert it. In `onModeDeactivated`, finalize the session with `endedAt` and `totalWorkSeconds`.

Add these properties to `ADHDFocusApp`:

```swift
@State private var currentSession: FocusSession?
```

Update `setupEngine()`:

```swift
engine.onModeActivated = { mode in
    monitor.startMonitoring()
    if mode.enableDND { dndController.enableDND() }

    let session = FocusSession(modeID: mode.id, modeName: mode.name, statsTag: mode.statsTag)
    container.mainContext.insert(session)
    currentSession = session
}

engine.onModeDeactivated = {
    monitor.stopMonitoring()
    dndController.disableDND()

    if let session = currentSession {
        session.endedAt = Date()
        session.totalWorkSeconds = Int(Date().timeIntervalSince(session.startedAt))
        session.completedPomodoros = engine.pomodoroTimer?.completedPomodoros ?? 0
        try? container.mainContext.save()
    }
    currentSession = nil
}
```

- [ ] **Step 4: Build and run**

Run: `Cmd+R` in Xcode
Expected: 统计 tab shows 4 stat cards with today's data (all zeros initially).

- [ ] **Step 5: Commit**

```bash
git add ADHDFocus/ADHDFocus/Views/MainWindow/StatsView.swift ADHDFocus/ADHDFocus/Views/MainWindow/MainWindowView.swift ADHDFocus/ADHDFocus/ADHDFocusApp.swift
git commit -m "feat: add focus statistics dashboard with today's overview"
```

---

## Task 13: Settings View

**Files:**
- Create: `ADHDFocus/ADHDFocus/Views/MainWindow/SettingsView.swift`
- Modify: `ADHDFocus/ADHDFocus/Views/MainWindow/MainWindowView.swift`

- [ ] **Step 1: Create SettingsView**

Create `ADHDFocus/ADHDFocus/Views/MainWindow/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @State private var launchAtLogin = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("设置")
                    .font(.title2.weight(.semibold))

                // General
                GroupBox("通用") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("登录时自动启动", isOn: $launchAtLogin)
                    }
                    .padding(8)
                }

                // Permissions
                GroupBox("权限状态") {
                    VStack(alignment: .leading, spacing: 12) {
                        PermissionRow(
                            name: "辅助功能",
                            description: "监听和控制其他应用",
                            isGranted: AXIsProcessTrusted()
                        )
                        PermissionRow(
                            name: "通知",
                            description: "番茄钟提醒和拦截通知",
                            isGranted: true // checked async, simplified for MVP
                        )
                    }
                    .padding(8)
                }

                // DND Setup
                GroupBox("勿扰模式设置") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("需要在 macOS 快捷指令 App 中创建两个快捷指令：")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("1. \"Enable DND\" — 设置专注模式为勿扰，开启")
                            .font(.caption.monospaced())
                        Text("2. \"Disable DND\" — 设置专注模式为勿扰，关闭")
                            .font(.caption.monospaced())

                        Button("打开快捷指令") {
                            NSWorkspace.shared.open(URL(string: "shortcuts://")!)
                        }
                        .padding(.top, 4)
                    }
                    .padding(8)
                }

                // Chrome Extension
                GroupBox("Chrome 扩展") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("安装 Chrome 扩展以拦截被禁网站：")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("1. 打开 Chrome，进入 chrome://extensions")
                            .font(.caption)
                        Text("2. 开启「开发者模式」")
                            .font(.caption)
                        Text("3. 点击「加载已解压的扩展」")
                            .font(.caption)
                        Text("4. 选择 ADHDFocus 应用包内的 ChromeExtension 文件夹")
                            .font(.caption)
                    }
                    .padding(8)
                }

                // About
                GroupBox("关于") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ADHD Focus v1.0.0")
                            .font(.caption)
                        Text("为设计师打造的专注助手")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                }
            }
            .padding(24)
        }
    }
}

struct PermissionRow: View {
    let name: String
    let description: String
    let isGranted: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(name).font(.body)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: isGranted ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(isGranted ? .green : .orange)
            if !isGranted {
                Button("授权") {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
                .controlSize(.small)
            }
        }
    }
}
```

- [ ] **Step 2: Wire SettingsView into MainWindowView**

In `MainWindowView.swift`, update the `settings` case:

```swift
case .settings:
    SettingsView()
```

- [ ] **Step 3: Build and run**

Run: `Cmd+R` in Xcode
Expected: 设置 tab shows permissions status, DND setup instructions, Chrome extension setup guide.

- [ ] **Step 4: Commit**

```bash
git add ADHDFocus/ADHDFocus/Views/MainWindow/SettingsView.swift ADHDFocus/ADHDFocus/Views/MainWindow/MainWindowView.swift
git commit -m "feat: add settings view with permissions, DND setup, and Chrome extension guide"
```

---

## Task 14: Chrome Extension — Manifest and Background Script

**Files:**
- Create: `ADHDFocus/ChromeExtension/manifest.json`
- Create: `ADHDFocus/ChromeExtension/background.js`

- [ ] **Step 1: Create manifest.json**

Create `ADHDFocus/ChromeExtension/manifest.json`:

```json
{
  "manifest_version": 3,
  "name": "ADHD Focus — URL Blocker",
  "version": "1.0.0",
  "description": "Block distracting websites during focus sessions",
  "permissions": [
    "nativeMessaging",
    "tabs",
    "webNavigation",
    "storage"
  ],
  "background": {
    "service_worker": "background.js"
  },
  "content_scripts": [
    {
      "matches": ["<all_urls>"],
      "js": ["content.js"],
      "run_at": "document_start"
    }
  ],
  "icons": {
    "16": "icons/icon16.png",
    "48": "icons/icon48.png",
    "128": "icons/icon128.png"
  }
}
```

- [ ] **Step 2: Create background.js**

Create `ADHDFocus/ChromeExtension/background.js`:

```javascript
const NATIVE_HOST = "com.lilinke.adhdfocus";
let currentRules = null;
let nativePort = null;

function connectToNativeHost() {
  nativePort = chrome.runtime.connectNative(NATIVE_HOST);

  nativePort.onMessage.addListener((message) => {
    if (message.type === "rules_update") {
      currentRules = message.data;
      chrome.storage.local.set({ rules: currentRules });
    }
  });

  nativePort.onDisconnect.addListener(() => {
    nativePort = null;
    currentRules = null;
    chrome.storage.local.set({ rules: null });
    // Retry connection after delay
    setTimeout(connectToNativeHost, 5000);
  });

  // Request current rules
  nativePort.postMessage({ type: "get_rules" });
}

function isURLBlocked(url, rules) {
  if (!rules || !rules.active || rules.onBreak) return false;

  let host;
  try {
    host = new URL(url).hostname.toLowerCase();
  } catch {
    return false;
  }

  // Check allowed list first
  for (const pattern of rules.allowedURLs || []) {
    if (host === pattern || host.endsWith("." + pattern)) return false;
  }

  // Check blocked list
  for (const pattern of rules.blockedURLs || []) {
    if (host === pattern || host.endsWith("." + pattern)) return true;
  }

  // Default policy
  return rules.defaultPolicy === "block";
}

// Listen for navigation events
chrome.webNavigation.onBeforeNavigate.addListener((details) => {
  if (details.frameId !== 0) return; // Only main frame

  const rules = currentRules;
  if (isURLBlocked(details.url, rules)) {
    const params = new URLSearchParams({
      url: details.url,
      modeName: rules.modeName || "",
      remainingSeconds: String(rules.remainingSeconds || 0),
      allowedSites: (rules.allowedURLs || []).join(",")
    });
    chrome.tabs.update(details.tabId, {
      url: chrome.runtime.getURL("blocked.html") + "?" + params.toString()
    });
  }
});

// Provide rules to content scripts
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === "get_rules") {
    sendResponse(currentRules);
  }
});

// Start connection
connectToNativeHost();

// Also load cached rules on startup
chrome.storage.local.get("rules", (result) => {
  if (result.rules) currentRules = result.rules;
});
```

- [ ] **Step 3: Commit**

```bash
git add ADHDFocus/ChromeExtension/manifest.json ADHDFocus/ChromeExtension/background.js
git commit -m "feat: add Chrome Extension manifest and background service worker"
```

---

## Task 15: Chrome Extension — Blocked Page

**Files:**
- Create: `ADHDFocus/ChromeExtension/blocked.html`
- Create: `ADHDFocus/ChromeExtension/blocked.css`
- Create: `ADHDFocus/ChromeExtension/content.js`

- [ ] **Step 1: Create blocked.html**

Create `ADHDFocus/ChromeExtension/blocked.html`:

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
  <meta charset="UTF-8">
  <title>ADHD Focus — 页面已限制</title>
  <link rel="stylesheet" href="blocked.css">
</head>
<body>
  <div class="container">
    <div class="icon">🌊</div>
    <h1>这个网站暂时不可访问</h1>
    <p class="reason" id="reason"></p>

    <div class="timer-box" id="timerBox" style="display:none;">
      <p>番茄钟剩余 <strong id="timerValue"></strong></p>
    </div>

    <div class="suggestions" id="suggestions" style="display:none;">
      <p>💡 试试这些网站找灵感：</p>
      <div class="suggestion-links" id="suggestionLinks"></div>
    </div>

    <div class="actions">
      <button class="btn primary" onclick="window.history.back()">回到工作</button>
      <button class="btn secondary" id="allowBtn">允许 5 分钟</button>
    </div>
  </div>

  <script>
    const params = new URLSearchParams(window.location.search);
    const blockedURL = params.get("url") || "";
    const modeName = params.get("modeName") || "";
    const remainingSeconds = parseInt(params.get("remainingSeconds") || "0");
    const allowedSites = (params.get("allowedSites") || "").split(",").filter(Boolean);

    // Reason text
    let host = "";
    try { host = new URL(blockedURL).hostname; } catch {}
    document.getElementById("reason").textContent =
      `${host} 不在「${modeName}」的允许列表中`;

    // Timer
    if (remainingSeconds > 0) {
      document.getElementById("timerBox").style.display = "block";
      const minutes = Math.floor(remainingSeconds / 60);
      const seconds = remainingSeconds % 60;
      document.getElementById("timerValue").textContent =
        `${String(minutes).padStart(2, "0")}:${String(seconds).padStart(2, "0")}`;
    }

    // Suggestions
    if (allowedSites.length > 0) {
      document.getElementById("suggestions").style.display = "block";
      const container = document.getElementById("suggestionLinks");
      allowedSites.slice(0, 4).forEach(site => {
        const a = document.createElement("a");
        a.href = `https://${site}`;
        a.textContent = site;
        a.className = "suggestion-link";
        container.appendChild(a);
      });
    }

    // Allow 5 minutes button
    document.getElementById("allowBtn").addEventListener("click", () => {
      chrome.runtime.sendMessage({
        type: "temp_allow",
        url: blockedURL,
        minutes: 5
      }, () => {
        window.location.href = blockedURL;
      });
    });
  </script>
</body>
</html>
```

- [ ] **Step 2: Create blocked.css**

Create `ADHDFocus/ChromeExtension/blocked.css`:

```css
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
  background: #0a0a0f;
  color: #e0e0e0;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
}

.container {
  text-align: center;
  max-width: 480px;
  padding: 40px;
}

.icon {
  font-size: 64px;
  margin-bottom: 24px;
}

h1 {
  font-size: 22px;
  font-weight: 600;
  margin-bottom: 8px;
  color: #fff;
}

.reason {
  font-size: 14px;
  color: #888;
  margin-bottom: 24px;
}

.timer-box {
  background: #1a1a2e;
  border-radius: 10px;
  padding: 12px 20px;
  margin-bottom: 20px;
  display: inline-block;
}

.timer-box p {
  font-size: 13px;
  color: #aaa;
}

.timer-box strong {
  color: #8b5cf6;
  font-variant-numeric: tabular-nums;
}

.suggestions {
  margin-bottom: 24px;
}

.suggestions p {
  font-size: 13px;
  color: #aaa;
  margin-bottom: 10px;
}

.suggestion-links {
  display: flex;
  gap: 8px;
  justify-content: center;
  flex-wrap: wrap;
}

.suggestion-link {
  background: #1a1a2e;
  color: #58a6ff;
  text-decoration: none;
  padding: 6px 14px;
  border-radius: 6px;
  font-size: 13px;
  transition: background 0.2s;
}

.suggestion-link:hover {
  background: #252545;
}

.actions {
  display: flex;
  gap: 10px;
  justify-content: center;
  margin-top: 8px;
}

.btn {
  padding: 8px 20px;
  border-radius: 8px;
  font-size: 14px;
  cursor: pointer;
  border: none;
  transition: opacity 0.2s;
}

.btn:hover {
  opacity: 0.85;
}

.btn.primary {
  background: #8b5cf6;
  color: #fff;
}

.btn.secondary {
  background: #333;
  color: #aaa;
}
```

- [ ] **Step 3: Create content.js**

Create `ADHDFocus/ChromeExtension/content.js`:

```javascript
// Content script — lightweight check for temp-allowed URLs
// Main blocking happens in background.js via webNavigation
// This provides a fallback for single-page navigation

(function() {
  chrome.runtime.sendMessage({ type: "get_rules" }, (rules) => {
    // Rules are handled by background script
    // Content script is reserved for future SPA navigation detection
  });
})();
```

- [ ] **Step 4: Commit**

```bash
git add ADHDFocus/ChromeExtension/
git commit -m "feat: add Chrome Extension blocked page with suggestions and temp-allow"
```

---

## Task 16: Native Messaging Host

**Files:**
- Create: `ADHDFocus/ADHDFocus/Services/NativeMessagingHost.swift`
- Test: `ADHDFocus/ADHDFocusTests/NativeMessagingTests.swift`

- [ ] **Step 1: Write failing test for message encoding**

Create `ADHDFocus/ADHDFocusTests/NativeMessagingTests.swift`:

```swift
import Testing
import Foundation
@testable import ADHDFocus

@Test func nativeMessageEncoding() {
    let message: [String: Any] = [
        "type": "rules_update",
        "data": ["active": true, "modeName": "Test"]
    ]
    let encoded = NativeMessagingHost.encodeMessage(message)
    // First 4 bytes are message length (little-endian)
    let length = encoded.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self) }
    let jsonData = encoded.dropFirst(4)
    #expect(Int(length) == jsonData.count)

    let decoded = try! JSONSerialization.jsonObject(with: Data(jsonData)) as! [String: Any]
    #expect(decoded["type"] as? String == "rules_update")
}

@Test func nativeMessageDecoding() {
    let json = #"{"type":"get_rules"}"#
    let jsonData = json.data(using: .utf8)!
    var lengthBytes = UInt32(jsonData.count).littleEndian
    let lengthData = Data(bytes: &lengthBytes, count: 4)
    let fullMessage = lengthData + jsonData

    let decoded = NativeMessagingHost.decodeMessage(from: fullMessage)
    #expect(decoded?["type"] as? String == "get_rules")
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `xcodebuild test -scheme ADHDFocus -destination 'platform=macOS'`
Expected: FAIL — `NativeMessagingHost` not defined

- [ ] **Step 3: Implement NativeMessagingHost**

Create `ADHDFocus/ADHDFocus/Services/NativeMessagingHost.swift`:

```swift
import Foundation

final class NativeMessagingHost {
    private let engine: FocusEngine
    private var inputPipe: FileHandle?
    private var outputPipe: FileHandle?
    private var isRunning = false

    init(engine: FocusEngine) {
        self.engine = engine
    }

    /// Encode a message with 4-byte length prefix (Chrome Native Messaging protocol)
    static func encodeMessage(_ message: [String: Any]) -> Data {
        let jsonData = try! JSONSerialization.data(withJSONObject: message)
        var length = UInt32(jsonData.count).littleEndian
        var result = Data(bytes: &length, count: 4)
        result.append(jsonData)
        return result
    }

    /// Decode a message from 4-byte length prefix + JSON
    static func decodeMessage(from data: Data) -> [String: Any]? {
        guard data.count >= 4 else { return nil }
        let length = data.prefix(4).withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
        guard data.count >= 4 + Int(length) else { return nil }
        let jsonData = data[4..<(4 + Int(length))]
        return try? JSONSerialization.jsonObject(with: Data(jsonData)) as? [String: Any]
    }

    func start() {
        isRunning = true
        inputPipe = FileHandle.standardInput
        outputPipe = FileHandle.standardOutput

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.readLoop()
        }
    }

    func stop() {
        isRunning = false
    }

    func sendRulesUpdate() {
        guard let rules = engine.currentURLRules() else {
            sendMessage(["type": "rules_update", "data": ["active": false]])
            return
        }
        sendMessage(["type": "rules_update", "data": rules])
    }

    private func readLoop() {
        while isRunning {
            guard let input = inputPipe else { break }

            // Read 4-byte length
            let lengthData = input.readData(ofLength: 4)
            guard lengthData.count == 4 else { continue }

            let length = lengthData.withUnsafeBytes { $0.load(as: UInt32.self).littleEndian }
            guard length > 0, length < 1_000_000 else { continue }

            // Read message body
            let messageData = input.readData(ofLength: Int(length))
            guard let message = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any] else { continue }

            handleMessage(message)
        }
    }

    private func handleMessage(_ message: [String: Any]) {
        guard let type = message["type"] as? String else { return }

        switch type {
        case "get_rules":
            sendRulesUpdate()
        default:
            break
        }
    }

    private func sendMessage(_ message: [String: Any]) {
        let data = Self.encodeMessage(message)
        outputPipe?.write(data)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `xcodebuild test -scheme ADHDFocus -destination 'platform=macOS'`
Expected: Both NativeMessaging tests PASS

- [ ] **Step 5: Commit**

```bash
git add ADHDFocus/ADHDFocus/Services/NativeMessagingHost.swift ADHDFocus/ADHDFocusTests/NativeMessagingTests.swift
git commit -m "feat: add NativeMessagingHost for Chrome Extension communication"
```

---

## Task 17: Native Messaging Host Manifest

**Files:**
- Create: `ADHDFocus/ChromeExtension/install-native-host.sh`

- [ ] **Step 1: Create installation script**

Create `ADHDFocus/ChromeExtension/install-native-host.sh`:

```bash
#!/bin/bash
# Install Native Messaging Host manifest for Chrome

HOST_NAME="com.lilinke.adhdfocus"
APP_PATH="/Applications/ADHDFocus.app/Contents/MacOS/ADHDFocusNativeHost"
MANIFEST_DIR="$HOME/Library/Application Support/Google/Chrome/NativeMessagingHosts"

mkdir -p "$MANIFEST_DIR"

cat > "$MANIFEST_DIR/$HOST_NAME.json" << EOF
{
  "name": "$HOST_NAME",
  "description": "ADHD Focus Native Messaging Host",
  "path": "$APP_PATH",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://EXTENSION_ID_HERE/"
  ]
}
EOF

echo "Native Messaging Host manifest installed to:"
echo "  $MANIFEST_DIR/$HOST_NAME.json"
echo ""
echo "NOTE: Replace EXTENSION_ID_HERE with your Chrome extension ID."
echo "Find it at chrome://extensions after loading the extension."
```

- [ ] **Step 2: Make script executable**

```bash
chmod +x ADHDFocus/ChromeExtension/install-native-host.sh
```

- [ ] **Step 3: Commit**

```bash
git add ADHDFocus/ChromeExtension/install-native-host.sh
git commit -m "feat: add Native Messaging Host installation script"
```

---

## Task 18: Integration — Wire FocusEngine to Native Messaging

**Files:**
- Modify: `ADHDFocus/ADHDFocus/ADHDFocusApp.swift`

- [ ] **Step 1: Add NativeMessagingHost to app lifecycle**

In `ADHDFocusApp`, add a property:

```swift
@State private var nativeMessagingHost: NativeMessagingHost?
```

In `setupEngine()`, after creating the engine callbacks, add:

```swift
let messagingHost = NativeMessagingHost(engine: engine)
nativeMessagingHost = messagingHost

// Update Chrome extension when mode changes
let originalOnActivated = engine.onModeActivated
engine.onModeActivated = { mode in
    originalOnActivated?(mode)
    messagingHost.sendRulesUpdate()
}

let originalOnDeactivated = engine.onModeDeactivated
engine.onModeDeactivated = {
    originalOnDeactivated?()
    messagingHost.sendRulesUpdate()
}

let originalOnPhaseChange = engine.onPomodoroPhaseChange
engine.onPomodoroPhaseChange = { phase in
    originalOnPhaseChange?(phase)
    messagingHost.sendRulesUpdate()
}
```

- [ ] **Step 2: Build and run**

Run: `Cmd+R` in Xcode
Expected: BUILD SUCCEEDED. App starts and sends rule updates to Chrome Extension when modes change.

- [ ] **Step 3: Commit**

```bash
git add ADHDFocus/ADHDFocus/ADHDFocusApp.swift
git commit -m "feat: sync FocusEngine state to Chrome Extension via NativeMessaging"
```

---

## Task 19: Final Integration Test

**Files:** None (manual testing)

- [ ] **Step 1: Clean build and run**

```bash
xcodebuild clean build test -scheme ADHDFocus -destination 'platform=macOS'
```
Expected: All tests pass, clean build succeeds.

- [ ] **Step 2: Manual smoke test checklist**

Test the following flow manually:

1. Launch app → menu bar icon appears with 4 preset modes
2. Click "深度设计" → mode activates, timer starts
3. Open WeChat → it gets terminated, notification appears
4. Wait for timer to reach break → WeChat should be accessible
5. Click "结束专注" → all restrictions lifted
6. Open main window → check mode editor, modify a mode
7. Check 统计 tab → shows session data
8. Check 设置 tab → shows permission status

- [ ] **Step 3: Commit any fixes from smoke test**

```bash
git add -A
git commit -m "fix: address issues found during integration smoke test"
```

- [ ] **Step 4: Create .gitignore**

```bash
cat > /Users/lilinke/Projects/Mac/ADHD/.gitignore << 'EOF'
.DS_Store
*.xcuserdata
xcuserdata/
DerivedData/
.build/
.superpowers/
EOF
git add .gitignore
git commit -m "chore: add .gitignore"
```
