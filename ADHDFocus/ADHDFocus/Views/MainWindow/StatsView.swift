import SwiftUI
import SwiftData
import AppKit

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusSession.startedAt, order: .reverse) private var sessions: [FocusSession]
    @Query(sort: \BlockEvent.timestamp, order: .reverse) private var blockEvents: [BlockEvent]

    @State private var todaySessions: [FocusSession] = []
    @State private var todayBlockEvents: [BlockEvent] = []

    private func refreshTodayData() {
        let startOfDay = Calendar.current.startOfDay(for: Date())
        todaySessions = sessions.filter { $0.startedAt >= startOfDay }
        todayBlockEvents = Array(blockEvents.filter { $0.timestamp >= startOfDay }.prefix(50))
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
        ScrollView {
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

            // Block details (last 10)
            if !todayBlockEvents.isEmpty {
                let recentEvents = Array(todayBlockEvents.prefix(10))
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("拦截记录")
                            .font(.headline)
                        Spacer()
                        Text("最近 \(min(todayBlockEvents.count, 10)) 条")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }

                    ForEach(recentEvents) { event in
                        BlockEventRow(event: event)
                    }
                }
                .padding(16)
                .background(.quaternary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()

            Button {
                clearAllData()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.caption)
                    Text("清除历史数据")
                        .font(.caption)
                }
                .foregroundStyle(.red.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .padding(24)
        }
        .onAppear { refreshTodayData() }
        .onChange(of: sessions.count) { _, _ in refreshTodayData() }
        .onChange(of: blockEvents.count) { _, _ in refreshTodayData() }
    }

    private func clearAllData() {
        for s in sessions { modelContext.delete(s) }
        for e in blockEvents { modelContext.delete(e) }
        try? modelContext.save()
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

struct BlockEventRow: View {
    let event: BlockEvent

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: event.type == .app ? "app.badge.fill" : "globe")
                .foregroundStyle(.orange)
                .frame(width: 20)

            if event.type == .app, let info = AppInfoCache.shared.info(for: event.target) {
                Image(nsImage: info.icon)
                    .resizable()
                    .frame(width: 16, height: 16)
                Text(info.name)
                    .font(.body)
            } else {
                Text(event.target)
                    .font(.body)
            }

            Spacer()

            Text(event.modeName)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(event.timestamp, style: .time)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}
