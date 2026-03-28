import Foundation

final class DNDController {
    func enableDND() {
        runShortcut("Enable DND")
    }

    func disableDND() {
        runShortcut("Disable DND")
    }

    private func runShortcut(_ name: String) {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        task.arguments = ["run", name]
        // Suppress all output to avoid triggering system dialogs
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
        } catch {
            // Silently fail — user may not have created the shortcut
        }
    }
}
