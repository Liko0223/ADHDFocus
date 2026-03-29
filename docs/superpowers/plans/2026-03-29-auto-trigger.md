# Auto-Trigger Focus Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Automatically suggest a focus mode when the user has been using a relevant app for a configurable duration, via a "half-expanded" notch panel with one-click activation.

**Architecture:** AutoTriggerService monitors foreground app usage via NSWorkspace notifications. When usage exceeds the threshold, it matches the app to a FocusMode and tells NotchManager to show a suggestion UI. NotchManager enters a `isSuggesting` state with a compact button bar below the notch.

**Tech Stack:** SwiftUI, SwiftData, NSWorkspace, Timer

---

## File Structure

```
ADHDFocus/ADHDFocus/
├── Models/
│   └── FocusMode.swift              — Add triggerApps, triggerDelay fields
├── Services/
│   └── AutoTriggerService.swift     — NEW: monitors foreground app, matches modes, triggers suggestions
├── Views/
│   └── Notch/
│       └── NotchContentView.swift   — Add suggestion UI (half-expanded state)
├── ADHDFocusApp.swift               — Wire AutoTriggerService into lifecycle
└── NotchManager.swift               — Add isSuggesting state
```

---

### Task 1: Add triggerApps and triggerDelay to FocusMode

**Files:**
- Modify: `ADHDFocus/ADHDFocus/Models/FocusMode.swift`

- [ ] **Step 1: Add new fields to FocusMode**

In `FocusMode.swift`, add two new properties after `var hideDock: Bool`:

```swift
    // Auto-trigger
    var triggerApps: [String]  // Bundle IDs that trigger this mode (empty = use allowedApps)
    var triggerDelay: Int      // Seconds before triggering suggestion (default 60)
```

- [ ] **Step 2: Add parameters to init**

Add to the init signature after `hideDock`:

```swift
        triggerApps: [String] = [],
        triggerDelay: Int = 60,
```

And in the init body:

```swift
        self.triggerApps = triggerApps
        self.triggerDelay = triggerDelay
```

- [ ] **Step 3: Build to verify**

Run: `cd /Users/lilinke/Projects/Mac/ADHD/ADHDFocus && xcodebuild -scheme ADHDFocus -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: add triggerApps and triggerDelay fields to FocusMode"
```

---

### Task 2: Create AutoTriggerService

**Files:**
- Create: `ADHDFocus/ADHDFocus/Services/AutoTriggerService.swift`

- [ ] **Step 1: Create AutoTriggerService**

```swift
import Foundation
import AppKit
import SwiftData

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
            self?.onAppActivated(bundleID: bundleID, appName: app.localizedName ?? bundleID)
        }

        checkTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.checkTrigger()
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
            self?.checkTrigger()
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
```

- [ ] **Step 2: Regenerate project and build**

Run: `cd /Users/lilinke/Projects/Mac/ADHD/ADHDFocus && xcodegen generate && xcodebuild -scheme ADHDFocus -destination 'platform=macOS' build 2>&1 | tail -5`
Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: add AutoTriggerService — monitors foreground app and matches modes"
```

---

### Task 3: Add suggestion state to NotchManager

**Files:**
- Modify: `ADHDFocus/ADHDFocus/Services/NotchManager.swift`

- [ ] **Step 1: Add suggestion properties and methods**

Add these properties after `var isExpanded: Bool = false`:

```swift
    var isSuggesting: Bool = false
    var suggestedMode: FocusMode?
    var suggestedAppName: String?
    private var suggestionTimer: Timer?
```

Add these methods:

```swift
    func showSuggestion(mode: FocusMode, appName: String) {
        suggestedMode = mode
        suggestedAppName = appName
        isSuggesting = true

        // Auto-dismiss after 5 seconds
        suggestionTimer?.invalidate()
        suggestionTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.dismissSuggestion()
        }
    }

    func dismissSuggestion() {
        suggestionTimer?.invalidate()
        suggestionTimer = nil
        isSuggesting = false
        suggestedMode = nil
        suggestedAppName = nil
    }

    func acceptSuggestion() {
        guard let mode = suggestedMode else { return }
        dismissSuggestion()
        engine?.activate(mode: mode)
    }
```

Also update `expand()` to dismiss suggestion:

```swift
    func expand() {
        dismissSuggestion()
        isExpanded = true
    }
```

- [ ] **Step 2: Build**

Run: `cd /Users/lilinke/Projects/Mac/ADHD/ADHDFocus && xcodebuild -scheme ADHDFocus -destination 'platform=macOS' build 2>&1 | tail -5`

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: add suggestion state to NotchManager"
```

---

### Task 4: Add suggestion UI to NotchContentView

**Files:**
- Modify: `ADHDFocus/ADHDFocus/Views/Notch/NotchContentView.swift`

- [ ] **Step 1: Update currentHeight to account for suggestion state**

Find `private var currentHeight: CGFloat` and update:

```swift
    private var currentHeight: CGFloat {
        if manager.isExpanded {
            return manager.notchHeight + expandedPanelHeight
        } else if manager.isSuggesting {
            return manager.notchHeight + 40
        } else {
            return manager.notchHeight
        }
    }
```

- [ ] **Step 2: Add suggestion bar view**

Add a new computed property `suggestionBar` in NotchContentView:

```swift
    private var suggestionBar: some View {
        HStack(spacing: 8) {
            // Mode button (one-click activate)
            if let mode = manager.suggestedMode {
                Button {
                    manager.acceptSuggestion()
                } label: {
                    HStack(spacing: 5) {
                        Text(mode.icon)
                            .font(.system(size: 11))
                        Text(mode.name)
                            .font(.system(size: 11, weight: .medium))
                        Image(systemName: "play.fill")
                            .font(.system(size: 7))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.6))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Dismiss button
            Button {
                manager.onIgnoreSuggestion?()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(5)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .frame(height: 36)
    }
```

- [ ] **Step 3: Update collapsedBar right side text**

In the `collapsedBar`, update the idle greeting to show suggestion text when `isSuggesting`:

Replace the else branch that shows `idleGreeting` with:

```swift
                } else if manager.isSuggesting, let appName = manager.suggestedAppName {
                    let messages = [
                        "在用\(appName)~ 要专注吗？",
                        "\(appName)打开啦~ 专注？",
                    ]
                    Text(messages[abs(appName.hashValue) % messages.count])
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                } else {
                    Text(idleGreeting)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
```

- [ ] **Step 4: Wire suggestion bar into the main body VStack**

In the body, update the VStack to show the suggestion bar between collapsed and expanded:

```swift
                VStack(spacing: 0) {
                    if manager.isExpanded {
                        expandedContent
                            .frame(width: currentWidth)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        collapsedBar
                            .frame(width: currentWidth, height: manager.notchHeight)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if !manager.isSuggesting {
                                    manager.toggleExpanded()
                                }
                            }

                        if manager.isSuggesting {
                            suggestionBar
                                .frame(width: currentWidth)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
```

- [ ] **Step 5: Add animation for isSuggesting**

At the end of the body, add:

```swift
        .animation(panelAnimation, value: manager.isSuggesting)
```

- [ ] **Step 6: Build**

Run: `cd /Users/lilinke/Projects/Mac/ADHD/ADHDFocus && xcodebuild -scheme ADHDFocus -destination 'platform=macOS' build 2>&1 | tail -5`

- [ ] **Step 7: Commit**

```bash
git add -A && git commit -m "feat: add suggestion half-expanded UI to notch panel"
```

---

### Task 5: Wire AutoTriggerService into app lifecycle

**Files:**
- Modify: `ADHDFocus/ADHDFocus/ADHDFocusApp.swift`
- Modify: `ADHDFocus/ADHDFocus/Services/NotchManager.swift`

- [ ] **Step 1: Add onIgnoreSuggestion callback to NotchManager**

In `NotchManager.swift`, add after `var openMainWindow`:

```swift
    var onIgnoreSuggestion: (() -> Void)?
```

- [ ] **Step 2: Add AutoTriggerService to AppDelegate**

In `ADHDFocusApp.swift`, add property:

```swift
    private var autoTriggerService: AutoTriggerService?
```

In `setupEngine()`, after `notchManager.setup()`, add:

```swift
        // Setup auto-trigger
        let trigger = AutoTriggerService(engine: engine, modelContext: container.mainContext, notchManager: notchManager)
        trigger.startWatching()
        autoTriggerService = trigger

        notchManager.onIgnoreSuggestion = { [weak trigger] in
            trigger?.ignoreCurrentApp()
        }
```

Update `engine.onModeActivated` to pause auto-trigger:

```swift
        // Inside onModeActivated closure, add:
            trigger.pause()
```

Update `engine.onModeDeactivated` to resume auto-trigger:

```swift
        // Inside onModeDeactivated closure, add:
            trigger.resume()
```

- [ ] **Step 3: Build and test**

Run: `cd /Users/lilinke/Projects/Mac/ADHD/ADHDFocus && xcodebuild -scheme ADHDFocus -destination 'platform=macOS' build 2>&1 | tail -5`

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: wire AutoTriggerService into app lifecycle"
```

---

### Task 6: Add automation config to ModeEditorView

**Files:**
- Modify: `ADHDFocus/ADHDFocus/Views/MainWindow/ModeEditorView.swift`

- [ ] **Step 1: Add automation section**

In `ModeEditorView`, after the "环境与策略" section (the `editorSection("环境与策略")` block), add:

```swift
                // Automation
                HStack(alignment: .top, spacing: 16) {
                    editorSection("自动化") {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("触发应用")
                                    .font(.subheadline)
                                Spacer()
                                Button("选择") {
                                    showTriggerAppPicker = true
                                }
                                .controlSize(.small)
                            }

                            if mode.triggerApps.isEmpty {
                                Text("未设置（使用允许应用列表推断）")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            } else {
                                FlowLayout(spacing: 6) {
                                    ForEach(mode.triggerApps, id: \.self) { bundleID in
                                        AppChipView(bundleID: bundleID) {
                                            mode.triggerApps.removeAll { $0 == bundleID }
                                        }
                                    }
                                }
                            }

                            Divider()

                            HStack {
                                Text("触发延迟")
                                    .font(.subheadline)
                                Spacer()
                                Picker("", selection: $mode.triggerDelay) {
                                    Text("10 秒").tag(10)
                                    Text("30 秒").tag(30)
                                    Text("1 分钟").tag(60)
                                    Text("5 分钟").tag(300)
                                }
                                .labelsHidden()
                                .frame(width: 100)
                            }
                        }
                    }
                }
```

- [ ] **Step 2: Add state for trigger app picker**

Add to the `@State` properties:

```swift
    @State private var showTriggerAppPicker = false
```

Add the sheet at the end of the body (next to existing sheets):

```swift
        .sheet(isPresented: $showTriggerAppPicker) {
            AppPickerView(title: "选择触发应用", selectedBundleIDs: $mode.triggerApps)
        }
```

- [ ] **Step 3: Build**

Run: `cd /Users/lilinke/Projects/Mac/ADHD/ADHDFocus && xcodebuild -scheme ADHDFocus -destination 'platform=macOS' build 2>&1 | tail -5`

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: add automation config section to mode editor"
```
