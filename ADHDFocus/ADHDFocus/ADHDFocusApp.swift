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
            MainWindowView(engine: engine)
                .modelContainer(for: [FocusMode.self, FocusSession.self, BlockEvent.self])
        }
    }
}
