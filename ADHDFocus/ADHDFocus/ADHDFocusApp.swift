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
