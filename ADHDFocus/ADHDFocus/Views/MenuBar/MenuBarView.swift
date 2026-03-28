import SwiftUI
import SwiftData

struct MenuBarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FocusMode.sortOrder) private var modes: [FocusMode]
    var engine: FocusEngine

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("ADHD Focus")
                    .font(.headline)
                Spacer()
                if engine.isActive {
                    Text("专注中")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
            }

            // Active mode + timer
            if let mode = engine.activeMode {
                VStack(spacing: 8) {
                    HStack {
                        Text(mode.icon)
                            .font(.title2)
                        Text(mode.name)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        if let timer = engine.pomodoroTimer, timer.isRunning {
                            Text(formatTime(timer.remainingSeconds))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let timer = engine.pomodoroTimer, timer.isRunning {
                        ProgressView(value: timer.progress)
                            .tint(timer.isOnBreak ? .green : .purple)
                    }
                }
                .padding(10)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Mode grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(modes) { mode in
                    Button {
                        if engine.activeMode?.id == mode.id {
                            return
                        }
                        engine.activate(mode: mode)
                    } label: {
                        VStack(spacing: 4) {
                            Text(mode.icon)
                                .font(.title3)
                            Text(mode.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            engine.activeMode?.id == mode.id
                                ? Color.purple.opacity(0.2)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    engine.activeMode?.id == mode.id
                                        ? Color.purple
                                        : Color.secondary.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Stop button
                if engine.isActive {
                    Button {
                        engine.deactivate()
                    } label: {
                        VStack(spacing: 4) {
                            Text("⏸️")
                                .font(.title3)
                            Text("结束专注")
                                .font(.caption2)
                                .foregroundStyle(.red)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider()

            // Open main window
            Button {
                openWindow(id: "main")
                NSApp.activate(ignoringOtherApps: true)
            } label: {
                Text("打开主窗口 →")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .frame(width: 280)
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
