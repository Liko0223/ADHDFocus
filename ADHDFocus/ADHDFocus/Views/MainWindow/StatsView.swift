import SwiftUI
import SwiftData

struct StatsView: View {
    @Query private var sessions: [FocusSession]
    @Query private var blockEvents: [BlockEvent]

    private var todaySessions: [FocusSession] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return sessions.filter { $0.startedAt >= startOfDay }
    }

    private var todayBlockEvents: [BlockEvent] {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        return blockEvents.filter { $0.timestamp >= startOfDay }
    }

    private var totalFocusMinutes: Int {
        todaySessions.reduce(0) { $0 + $1.totalWorkSeconds } / 60
    }

    private var completedPomodoros: Int {
        todaySessions.reduce(0) { $0 + $1.completedPomodoros }
    }

    private var blockedCount: Int {
        todayBlockEvents.count
    }

    private var streakDays: Int {
        var streak = 0
        var date = Calendar.current.startOfDay(for: Date())
        let calendar = Calendar.current

        while true {
            let dayStart = date
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: date)!
            let hasSessions = sessions.contains { $0.startedAt >= dayStart && $0.startedAt < dayEnd }
            if hasSessions {
                streak += 1
                date = calendar.date(byAdding: .day, value: -1, to: date)!
            } else {
                break
            }
        }
        return streak
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("今日概览")
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                StatCard(icon: "clock.fill", title: "专注时长", value: "\(totalFocusMinutes)", unit: "分钟", color: .purple)
                StatCard(icon: "checkmark.circle.fill", title: "番茄钟", value: "\(completedPomodoros)", unit: "个完成", color: .green)
                StatCard(icon: "hand.raised.fill", title: "拦截次数", value: "\(blockedCount)", unit: "次", color: .orange)
                StatCard(icon: "flame.fill", title: "连续天数", value: "\(streakDays)", unit: "天", color: .red)
            }

            Spacer()
        }
        .padding(24)
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
