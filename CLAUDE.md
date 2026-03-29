# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
cd ADHDFocus
brew install xcodegen        # one-time setup
xcodegen generate            # regenerate after adding/removing files
xcodebuild -scheme ADHDFocus -destination 'platform=macOS' build
xcodebuild -scheme ADHDFocus -configuration Release -derivedDataPath build  # release build
```

Run tests:
```bash
xcodebuild test -scheme ADHDFocus -destination 'platform=macOS'
```

Tests use Swift Testing (`@Test`, `#expect`) not XCTest.

After creating or deleting Swift files, always run `xcodegen generate` before building.

## Architecture

**Core flow:** `AppDelegate.doSetup()` → creates `FocusEngine` + `NotchManager` + `AppMonitor` + `RulesServer` + `AutoTriggerService`, wires them together via callbacks.

### Services (in `ADHDFocus/Services/`)

- **FocusEngine** — Central state machine (`@Observable`). Owns active `FocusMode` and `PomodoroTimer`. Exposes `shouldBlockApp(bundleID:)` and `shouldBlockURL(_:)`. Communicates via closures: `onModeActivated`, `onModeDeactivated`, `onPomodoroPhaseChange`.

- **NotchManager** — Manages the notch NSPanel UI (`@MainActor @Observable`). Handles expand/collapse, suggestion half-panel, celebration glow. Owns a `NotchHitTestView` that dynamically calculates clickable regions based on `activeRect(in:)`.

- **AppMonitor** — Listens to `NSWorkspace.didActivateApplicationNotification`. When a blocked app is activated, shows `BlockOverlayManager` per-window overlays (using `CGWindowListCopyWindowInfo` for positioning). Dedupes block events (1 per app per 60s). Manages 5-min temp-allow list.

- **AutoTriggerService** — Polls every 1s. When user stays on a trigger-eligible app longer than `triggerDelay`, calls `notchManager.showSuggestion()`. Caches mode list to avoid per-tick SwiftData fetch. Pauses during active focus mode.

- **RulesServer** — `NWListener` TCP server on port 52836. Serves JSON at `/rules` for Chrome Extension to poll. No auth, localhost only.

- **PomodoroTimer** — Tick-based countdown (`@Observable`). Phases: `idle → work → break_ → work → ... → longBreak`. `simulateTick(seconds:)` for testing without real timers.

### Data (SwiftData, in `Models/`)

- **FocusMode** — App/URL allow/block lists, Pomodoro config, strictness, trigger config. Methods: `isAppAllowed(bundleID:)`, `isURLAllowed(_:)`. Legacy enum values (`remind`, `delayAllow`) map to `overlay` via `.effective`.
- **FocusSession** — Tracks one focus session (start/end time, pomodoros completed).
- **BlockEvent** — Logs blocked app/URL attempts for stats.
- **DefaultModes** — Seeds 4 presets on first launch. Missing presets auto-restored on subsequent launches.

### UI (in `Views/`)

- **Notch/** — `NotchPanel` (borderless NSPanel, level `.mainMenu+3`), `NotchContentView` (collapsed bar + expanded panel + suggestion bar), `CompanionSceneView` (~1800 lines of Canvas pixel art with per-mode scenes).
- **MainWindow/** — `NavigationSplitView` with modes/stats/settings tabs. Created as `NSWindow` on demand via `AppDelegate.openMainWindow()`.
- **Onboarding/** — 4-step first-launch wizard. Controlled by `UserDefaults` key `AppConstants.hasCompletedOnboarding`.
- **Shared/** — `BlockOverlayWindow` (per-window frosted glass overlay using `NSVisualEffectView`), `AppPickerView` (searchable app selector).

### Chrome Extension (in `ChromeExtension/`)

Manifest V3. Polls `http://localhost:52836/rules` every 2s. Blocks URLs via `webNavigation.onBeforeNavigate`. Blocked page (`blocked.html` + `blocked.js`) supports "go back" and "allow 5 min".

## Key Patterns

- **`AppConstants`** — Centralized constants (exempt apps set, UserDefaults keys). Defined in `ADHDFocusApp.swift`.
- **`AppInfoCache`** — Singleton caching app names/icons from bundle IDs. Defined in `ModeEditorView.swift`, used across views.
- **LSUIElement = true** — App hides from Dock. Windows require `NSApp.setActivationPolicy(.regular)` before showing, `.accessory` after closing.
- **Screen detection** — `NSScreen.screens.first(where: { $0.hasNotch })` preferred over `NSScreen.main` for notch panel placement.
- **Callback ordering** — `FocusEngine.deactivate()` calls `onModeDeactivated` *before* clearing `pomodoroTimer`, so callers can read final state.

## Gotchas

- SourceKit often shows false red errors (Cannot find type X) due to indexing. If `xcodebuild build` succeeds, ignore them.
- `xcodebuild` must run from `ADHDFocus/` subdirectory (where `project.yml` and `.xcodeproj` live), not project root.
- Accessibility permission resets on every Xcode rebuild (new binary = new app identity). Normal during development.
- `defaults delete com.lilinke.ADHDFocus` to reset all app state. Must kill app first or UserDefaults cache overwrites.
- `CompanionSceneView.swift` is ~1800 lines. Each focus mode has a separate drawing function. Don't try to refactor into smaller files without testing performance.
