import SwiftUI
import SwiftData
import AppKit

@main
struct ADHDFocusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No default window — main window is opened on demand via AppDelegate
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let engine = FocusEngine()
    let container: ModelContainer
    private let dndController = DNDController()
    private var appMonitor: AppMonitor?
    private var currentSession: FocusSession?
    private var rulesServer: RulesServer?
    private var notchManager = NotchManager()
    private var mainWindow: NSWindow?

    override init() {
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
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupEngine()
        InstalledAppsProvider.shared.preload()
    }

    func openMainWindow() {
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

    private func setupEngine() {
        NotificationManager.shared.requestPermission()

        // Setup notch companion
        notchManager.engine = engine
        notchManager.modelContainer = container
        notchManager.openMainWindow = { [weak self] in
            self?.openMainWindow()
        }
        notchManager.setup()

        let monitor = AppMonitor(engine: engine, modelContext: container.mainContext)
        appMonitor = monitor

        let server = RulesServer(engine: engine)
        server.start()
        rulesServer = server

        engine.onModeActivated = { [weak self] mode in
            guard let self else { return }
            monitor.startMonitoring()
            if mode.enableDND { dndController.enableDND() }

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

        engine.onModeDeactivated = { [weak self] in
            guard let self else { return }
            monitor.stopMonitoring()
            dndController.disableDND()

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
