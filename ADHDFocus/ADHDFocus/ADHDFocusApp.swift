import SwiftUI
import SwiftData
import AppKit

@main
struct ADHDFocusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Window("ADHD Focus", id: "main") {
            MainWindowView(engine: appDelegate.engine)
                .modelContainer(appDelegate.container)
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

    override init() {
        let schema = Schema([FocusMode.self, FocusSession.self, BlockEvent.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        container = try! ModelContainer(for: schema, configurations: [config])
        super.init()
        seedDefaultModesIfNeeded()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupEngine()

        // Close main window on launch — notch is the primary entry point
        DispatchQueue.main.async {
            for window in NSApp.windows where !(window is NotchPanel) {
                window.close()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func setupEngine() {
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }

        NotificationManager.shared.requestPermission()

        // Setup notch companion
        notchManager.engine = engine
        notchManager.modelContainer = container
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
                session.completedPomodoros = engine.pomodoroTimer?.completedPomodoros ?? 0
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
