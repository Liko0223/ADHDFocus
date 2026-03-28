import SwiftUI
import SwiftData

@main
struct ADHDFocusApp: App {
    @State private var engine = FocusEngine()
    @State private var appMonitor: AppMonitor?
    @State private var currentSession: FocusSession?
    @State private var nativeMessagingHost: NativeMessagingHost?

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

        NotificationManager.shared.requestPermission()

        let monitor = AppMonitor(engine: engine, modelContext: container.mainContext)
        appMonitor = monitor

        let messagingHost = NativeMessagingHost(engine: engine)
        nativeMessagingHost = messagingHost

        engine.onModeActivated = { mode in
            monitor.startMonitoring()
            if mode.enableDND { dndController.enableDND() }

            let session = FocusSession(modeID: mode.id, modeName: mode.name, statsTag: mode.statsTag)
            container.mainContext.insert(session)
            currentSession = session
            messagingHost.sendRulesUpdate()
        }

        let ctx = container.mainContext
        engine.onModeDeactivated = {
            monitor.stopMonitoring()
            dndController.disableDND()

            if let session = currentSession {
                session.endedAt = Date()
                session.totalWorkSeconds = Int(Date().timeIntervalSince(session.startedAt))
                session.completedPomodoros = engine.pomodoroTimer?.completedPomodoros ?? 0
                try? ctx.save()
            }
            currentSession = nil
            messagingHost.sendRulesUpdate()
        }

        engine.onPomodoroPhaseChange = { phase in
            NotificationManager.shared.sendPomodoroNotification(phase: phase)
            messagingHost.sendRulesUpdate()
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
