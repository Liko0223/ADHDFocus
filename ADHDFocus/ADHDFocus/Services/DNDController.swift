import Foundation

final class DNDController {
    func enableDND() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        task.arguments = ["run", "Enable DND"]
        try? task.run()
    }

    func disableDND() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        task.arguments = ["run", "Disable DND"]
        try? task.run()
    }
}
