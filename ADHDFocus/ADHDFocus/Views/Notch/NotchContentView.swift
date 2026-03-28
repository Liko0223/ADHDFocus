import SwiftUI
import SwiftData

enum CompanionState: String {
    case idle, working, resting, blocked

    var bobDuration: Double {
        switch self {
        case .idle: return 2.0
        case .working: return 0.6
        case .resting: return 3.0
        case .blocked: return 1.0
        }
    }

    var bobAmplitude: CGFloat {
        switch self {
        case .idle: return 1.5
        case .working: return 1.0
        case .resting: return 0.5
        case .blocked: return 0
        }
    }

    var swayAmplitude: Double {
        switch self {
        case .idle: return 0.5
        case .working: return 0.3
        case .resting: return 1.0
        case .blocked: return 0
        }
    }
}

struct NotchContentView: View {
    @Bindable var manager: NotchManager
    @Query(sort: \FocusMode.sortOrder) private var modes: [FocusMode]
    @Environment(\.openWindow) private var openWindow

    private let sideExtension: CGFloat = 70
    private let expandedWidth: CGFloat = 340
    private let expandedPanelHeight: CGFloat = 380
    private let cornerRadius: CGFloat = 16

    private var collapsedTotalWidth: CGFloat {
        manager.notchWidth + sideExtension * 2
    }

    private var panelAnimation: Animation {
        manager.isExpanded
            ? .spring(response: 0.35, dampingFraction: 0.8)
            : .spring(response: 0.3, dampingFraction: 1.0)
    }

    private var currentWidth: CGFloat {
        manager.isExpanded ? max(expandedWidth, manager.notchWidth + 40) : collapsedTotalWidth
    }

    private var currentHeight: CGFloat {
        manager.isExpanded ? manager.notchHeight + expandedPanelHeight : manager.notchHeight
    }

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2

            ZStack(alignment: .top) {
                // Black background
                UnevenRoundedRectangle(
                    topLeadingRadius: 0,
                    bottomLeadingRadius: manager.isExpanded ? cornerRadius : 0,
                    bottomTrailingRadius: manager.isExpanded ? cornerRadius : 0,
                    topTrailingRadius: 0
                )
                .fill(.black)
                .frame(width: currentWidth, height: currentHeight)
                .shadow(color: .black.opacity(manager.isExpanded ? 0.5 : 0), radius: 20)

                VStack(spacing: 0) {
                    // Top bar: character left, timer right
                    collapsedBar
                        .frame(height: manager.notchHeight)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            manager.toggleExpanded()
                        }

                    // Expanded content
                    if manager.isExpanded {
                        expandedContent
                            .frame(width: currentWidth)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .frame(width: currentWidth)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .offset(x: 0, y: 0)
        }
        .animation(panelAnimation, value: manager.isExpanded)
    }

    // MARK: - Collapsed bar

    private var collapsedBar: some View {
        HStack(spacing: 0) {
            // Left: character
            TimelineView(.animation(minimumInterval: 1.0 / 24)) { timeline in
                let bob = BobAnimation.bobOffset(
                    at: timeline.date,
                    duration: manager.companionState.bobDuration,
                    amplitude: manager.companionState.bobAmplitude
                )
                let sway = BobAnimation.swayDegrees(
                    at: timeline.date,
                    duration: 2.5,
                    amplitude: manager.companionState.swayAmplitude
                )

                PixelCompanionView(state: manager.companionState)
                    .frame(width: 22, height: 22)
                    .offset(y: bob)
                    .rotationEffect(.degrees(sway))
            }
            .frame(width: sideExtension)

            // Center: notch space (hardware blocks this)
            Spacer()
                .frame(width: manager.notchWidth)

            // Right: timer or status
            Group {
                if manager.isActive, manager.remainingSeconds > 0 {
                    Text(formatTime(manager.remainingSeconds))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.purple)
                } else if manager.isActive {
                    Circle()
                        .fill(.green)
                        .frame(width: 6, height: 6)
                } else {
                    EmptyView()
                }
            }
            .frame(width: sideExtension)
        }
    }

    // MARK: - Expanded panel

    private var expandedContent: some View {
        VStack(spacing: 16) {
            // Status header
            if manager.isActive, let name = manager.modeName {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text(name)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                    Spacer()
                    if manager.remainingSeconds > 0 {
                        Text(formatTime(manager.remainingSeconds))
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(.purple)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }

            // Mode grid
            VStack(alignment: .leading, spacing: 8) {
                Text(manager.isActive ? "切换模式" : "选择模式")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 16)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(modes) { mode in
                        Button {
                            manager.activateMode(mode)
                        } label: {
                            HStack(spacing: 8) {
                                Text(mode.icon)
                                    .font(.body)
                                Text(mode.name)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                manager.engine?.activeMode?.id == mode.id
                                    ? Color.purple.opacity(0.3)
                                    : Color.white.opacity(0.08)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        manager.engine?.activeMode?.id == mode.id
                                            ? Color.purple.opacity(0.6)
                                            : Color.white.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }

            Spacer()

            // Bottom actions
            HStack(spacing: 12) {
                if manager.isActive {
                    Button {
                        manager.deactivateMode()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "stop.fill")
                                .font(.caption2)
                            Text("结束专注")
                                .font(.caption)
                        }
                        .foregroundStyle(.red)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    openWindow(id: "main")
                    NSApp.activate(ignoringOtherApps: true)
                    manager.collapse()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.caption2)
                        Text("设置")
                            .font(.caption)
                    }
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Pixel Companion

struct PixelCompanionView: View {
    let state: CompanionState

    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            let px = s / 8

            let bodyColor: Color = {
                switch state {
                case .idle: return Color(red: 0.55, green: 0.36, blue: 0.96)
                case .working: return Color(red: 0.35, green: 0.78, blue: 0.98)
                case .resting: return Color(red: 0.27, green: 0.85, blue: 0.45)
                case .blocked: return Color(red: 0.98, green: 0.35, blue: 0.35)
                }
            }()

            for row in 0...2 {
                for col in 2...5 {
                    drawPixel(context: context, col: col, row: row, size: px, color: bodyColor.opacity(0.9))
                }
            }
            drawPixel(context: context, col: 3, row: 1, size: px, color: .white)
            drawPixel(context: context, col: 4, row: 1, size: px, color: .white)

            for row in 3...5 {
                for col in 2...5 {
                    drawPixel(context: context, col: col, row: row, size: px, color: bodyColor)
                }
            }
            for row in 3...4 {
                drawPixel(context: context, col: 1, row: row, size: px, color: bodyColor.opacity(0.7))
                drawPixel(context: context, col: 6, row: row, size: px, color: bodyColor.opacity(0.7))
            }
            drawPixel(context: context, col: 2, row: 6, size: px, color: bodyColor.opacity(0.6))
            drawPixel(context: context, col: 3, row: 6, size: px, color: bodyColor.opacity(0.6))
            drawPixel(context: context, col: 4, row: 6, size: px, color: bodyColor.opacity(0.6))
            drawPixel(context: context, col: 5, row: 6, size: px, color: bodyColor.opacity(0.6))
        }
    }

    private func drawPixel(context: GraphicsContext, col: Int, row: Int, size: CGFloat, color: Color) {
        context.fill(
            Path(CGRect(x: CGFloat(col) * size, y: CGFloat(row) * size, width: size, height: size)),
            with: .color(color)
        )
    }
}
