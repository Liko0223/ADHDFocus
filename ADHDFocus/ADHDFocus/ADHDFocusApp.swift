import SwiftUI
import SwiftData
import AppKit

@main
struct ADHDFocusApp: App {
    @State private var engine = FocusEngine()
    @State private var appMonitor: AppMonitor?
    @State private var currentSession: FocusSession?
    @State private var rulesServer: RulesServer?
    @State private var notchManager = NotchManager()

    let container: ModelContainer
    private let dndController = DNDController()

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

        // Request accessibility permission if not granted
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }

        NotificationManager.shared.requestPermission()

        // Setup notch companion
        notchManager.engine = engine
        notchManager.setup()

        let monitor = AppMonitor(engine: engine, modelContext: container.mainContext)
        appMonitor = monitor

        // Start local HTTP server for Chrome Extension
        let server = RulesServer(engine: engine)
        server.start()
        rulesServer = server

        engine.onModeActivated = { [self] mode in
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

        let ctx = container.mainContext
        engine.onModeDeactivated = { [self] in
            monitor.stopMonitoring()
            dndController.disableDND()

            if let session = currentSession {
                session.endedAt = Date()
                session.totalWorkSeconds = Int(Date().timeIntervalSince(session.startedAt))
                session.completedPomodoros = engine.pomodoroTimer?.completedPomodoros ?? 0
                try? ctx.save()
            }
            currentSession = nil

            notchManager.updateState(isActive: false, modeName: nil, remainingSeconds: 0, isOnBreak: false)
        }

        engine.onPomodoroPhaseChange = { [self] phase in
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
