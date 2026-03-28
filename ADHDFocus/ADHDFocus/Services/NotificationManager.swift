import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private var permissionRequested = false

    func requestPermission() {
        guard !permissionRequested else { return }
        permissionRequested = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    func sendBlockedAppNotification(appName: String, modeName: String, remainingSeconds: Int) {
        let content = UNMutableNotificationContent()
        content.title = "\(appName) 已被暂时限制"
        content.body = "当前模式「\(modeName)」不允许使用此应用"
        if remainingSeconds > 0 {
            let minutes = remainingSeconds / 60
            content.body += "，番茄钟剩余 \(minutes) 分钟"
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "blocked-app-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func sendPomodoroNotification(phase: PomodoroPhase) {
        let content = UNMutableNotificationContent()
        switch phase {
        case .work:
            content.title = "休息结束"
            content.body = "回到工作状态，保持专注 💪"
        case .break_:
            content.title = "番茄钟完成！"
            content.body = "休息一下吧，起来走走 ☕"
        case .longBreak:
            content.title = "长休息时间！"
            content.body = "你已经连续完成多个番茄钟，好好休息 🌴"
        case .idle:
            return
        }
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "pomodoro-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
