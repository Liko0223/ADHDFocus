import SwiftUI
import SwiftData
import AppKit

extension Notification.Name {
    static let showOnboarding = Notification.Name("showOnboarding")
    static let expandNotchPanel = Notification.Name("expandNotchPanel")
}

@main
struct ADHDFocusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            MainWindowView(engine: appDelegate.engine)
                .modelContainer(appDelegate.container)
                .frame(minWidth: 700, minHeight: 500)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let engine = FocusEngine()
    let container: ModelContainer
    private var appMonitor: AppMonitor?
    private var currentSession: FocusSession?
    private var rulesServer: RulesServer?
    private var notchManager = NotchManager()
    private var autoTriggerService: AutoTriggerService?
    private var mainWindow: NSWindow?
    private var onboardingWindow: NSWindow?

    override init() {
        print("[ADHD] AppDelegate init called")
        let schema = Schema([FocusMode.self, FocusSession.self, BlockEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            // If store is corrupted, fall back to in-memory
            _ = error // Using in-memory store as fallback
            let memConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [memConfig])
        }
        super.init()
        seedDefaultModesIfNeeded()

        // Schedule setup on next run loop (after SwiftUI finishes init)
        DispatchQueue.main.async { [weak self] in
            self?.doSetup()
        }
    }

    private func doSetup() {
        setupEngine()
        InstalledAppsProvider.shared.preload()

        NotificationCenter.default.addObserver(forName: .showOnboarding, object: nil, queue: .main) { [weak self] _ in
            self?.showOnboarding()
        }
        NotificationCenter.default.addObserver(forName: .expandNotchPanel, object: nil, queue: .main) { [weak self] _ in
            self?.notchManager.expand()
        }

        // Show onboarding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.showOnboardingIfNeeded()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Backup: doSetup is idempotent via notchManager.panel check
    }

    func openMainWindow() {
        NSApp.setActivationPolicy(.regular)
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let contentView = MainWindowView(engine: engine)
            .modelContainer(container)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 520),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.title = "ADHD Focus"
        window.contentView = NSHostingView(rootView: contentView)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        mainWindow = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func showOnboardingIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding") else { return }
        showOnboarding()
    }

    func showOnboarding() {
        // Close existing onboarding window if any
        onboardingWindow?.close()
        onboardingWindow = nil

        // LSUIElement apps need regular policy to show windows
        NSApp.setActivationPolicy(.regular)

        let view = OnboardingView(engine: engine) { [weak self] in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            NSApp.setActivationPolicy(.accessory)
        }
        .modelContainer(container)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 560),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        window.title = "ADHD Focus"
        window.styleMask.remove(.miniaturizable)
        window.contentView = NSHostingView(rootView: view)
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }

    private func setupEngine() {
        NotificationManager.shared.requestPermission()

        // Setup notch companion
        notchManager.engine = engine
        notchManager.modelContainer = container
        notchManager.openMainWindow = { [weak self] in
            self?.openMainWindow()
        }
        notchManager.setup()

        // Setup auto-trigger
        let trigger = AutoTriggerService(engine: engine, modelContext: container.mainContext, notchManager: notchManager)
        trigger.startWatching()
        autoTriggerService = trigger

        notchManager.onIgnoreSuggestion = { [weak trigger] in
            trigger?.ignoreCurrentApp()
        }

        let monitor = AppMonitor(engine: engine, modelContext: container.mainContext)
        appMonitor = monitor

        let server = RulesServer(engine: engine)
        server.start()
        rulesServer = server

        engine.onModeActivated = { [weak self, weak trigger] mode in
            guard let self else { return }
            trigger?.pause()
            monitor.startMonitoring()

            let session = FocusSession(modeID: mode.id, modeName: mode.name, statsTag: mode.statsTag)
            container.mainContext.insert(session)
            currentSession = session

            notchManager.updateState(
                isActive: true,
                modeName: mode.name,
                remainingSeconds: engine.pomodoroTimer?.remainingSeconds ?? 0,
                isOnBreak: false
            )
        }

        engine.onModeDeactivated = { [weak self, weak trigger] in
            guard let self else { return }
            trigger?.resume()
            monitor.stopMonitoring()

            if let session = currentSession {
                session.endedAt = Date()
                session.totalWorkSeconds = Int(Date().timeIntervalSince(session.startedAt))
                let pomodoros = engine.pomodoroTimer?.completedPomodoros ?? 0
                session.completedPomodoros = pomodoros
                try? container.mainContext.save()
            }
            currentSession = nil

            notchManager.updateState(isActive: false, modeName: nil, remainingSeconds: 0, isOnBreak: false)
        }

        engine.onPomodoroPhaseChange = { [weak self] phase in
            guard let self else { return }
            NotificationManager.shared.sendPomodoroNotification(phase: phase)
            notchManager.updateState(
                isActive: true,
                modeName: engine.activeMode?.name,
                remainingSeconds: engine.pomodoroTimer?.remainingSeconds ?? 0,
                isOnBreak: engine.pomodoroTimer?.isOnBreak ?? false
            )
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
