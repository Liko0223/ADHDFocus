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

    // Fixed side extension — character always at the same position
    private let sideExtension: CGFloat = 70
    private let expandedWidth: CGFloat = 340
    private let expandedPanelHeight: CGFloat = 360
    private let bottomCornerRadius: CGFloat = 16
    private let topCornerRadius: CGFloat = 10  // outward curve radius

    // Collapsed: idle = just character side, active = both sides
    private var collapsedWidth: CGFloat {
        if manager.isActive {
            return manager.notchWidth + sideExtension * 2
        } else {
            return manager.notchWidth + sideExtension + 16 // left side + small right padding
        }
    }

    // Collapsed offset so character stays in same position
    // When idle (narrower), shift right so left edge stays same
    private var collapsedOffsetX: CGFloat {
        if manager.isActive {
            return 0
        } else {
            return -(sideExtension - 16) / 2
        }
    }

    private var currentWidth: CGFloat {
        manager.isExpanded ? max(expandedWidth, manager.notchWidth + 40) : collapsedWidth
    }

    private var currentHeight: CGFloat {
        manager.isExpanded ? manager.notchHeight + expandedPanelHeight : manager.notchHeight
    }

    private var panelAnimation: Animation {
        manager.isExpanded
            ? .spring(response: 0.35, dampingFraction: 0.8)
            : .spring(response: 0.3, dampingFraction: 1.0)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Black background with notch-style shape
                NotchShape(
                    topCornerRadius: topCornerRadius,
                    bottomCornerRadius: manager.isExpanded ? bottomCornerRadius : topCornerRadius,
                    notchHeight: manager.notchHeight,
                    isExpanded: manager.isExpanded
                )
                .fill(.black)
                .frame(width: currentWidth, height: currentHeight)
                .shadow(color: .black.opacity(manager.isExpanded ? 0.4 : 0), radius: 16)

                VStack(spacing: 0) {
                    // Top bar
                    collapsedBar
                        .frame(width: currentWidth, height: manager.notchHeight)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            manager.toggleExpanded()
                        }

                    if manager.isExpanded {
                        expandedContent
                            .frame(width: currentWidth)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .frame(width: currentWidth)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .offset(x: manager.isExpanded ? 0 : collapsedOffsetX)
        }
        .animation(panelAnimation, value: manager.isExpanded)
        .animation(panelAnimation, value: manager.isActive)
    }

    // MARK: - Collapsed bar

    private var collapsedBar: some View {
        HStack(spacing: 0) {
            // Left: character (always same position)
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

            // Center: notch gap
            Spacer()
                .frame(minWidth: manager.isExpanded ? 20 : manager.notchWidth)

            // Right: timer (only when active)
            if manager.isActive {
                Group {
                    if manager.remainingSeconds > 0 {
                        Text(formatTime(manager.remainingSeconds))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.purple)
                    } else {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                    }
                }
                .frame(width: sideExtension)
            }
        }
    }

    // MARK: - Expanded panel

    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Scene fills top half, edge to edge
            CompanionSceneView(state: manager.companionState, sceneWidth: currentWidth)
                .frame(height: 140)

            // Controls below
            VStack(spacing: 8) {
                // Status + mode grid
                HStack(spacing: 6) {
                    if manager.isActive, let name = manager.modeName {
                        Circle().fill(.green).frame(width: 6, height: 6)
                        Text(name)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.white)
                    } else {
                        Text("选择模式")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                    if manager.isActive, manager.remainingSeconds > 0 {
                        Text(formatTime(manager.remainingSeconds))
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(.purple)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                    ForEach(modes) { mode in
                        Button {
                            manager.activateMode(mode)
                        } label: {
                            HStack(spacing: 6) {
                                Text(mode.icon).font(.callout)
                                Text(mode.name)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
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
                .padding(.horizontal, 14)

                // Bottom bar
                HStack(spacing: 10) {
                    if manager.isActive {
                        Button {
                            manager.deactivateMode()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "stop.fill").font(.system(size: 8))
                                Text("结束").font(.caption2)
                            }
                            .foregroundStyle(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
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
                        Image(systemName: "gearshape")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(6)
                            .background(Color.white.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// MARK: - Notch Shape
// Top corners curve outward (concave) to blend with screen bezel
// Bottom corners curve inward (convex) like normal rounded corners

struct NotchShape: Shape {
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let notchHeight: CGFloat
    let isExpanded: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let tcr = topCornerRadius
        let bcr = bottomCornerRadius

        // Top-left: start outside the rect, curve inward
        // Point starts at (-tcr, 0) and curves to (0, tcr)
        // This creates the outward concave curve that blends with the screen bezel
        path.move(to: CGPoint(x: -tcr, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: tcr),
            control: CGPoint(x: 0, y: 0)
        )

        // Left edge down
        path.addLine(to: CGPoint(x: 0, y: rect.height - bcr))

        // Bottom-left: normal inward rounded corner
        path.addQuadCurve(
            to: CGPoint(x: bcr, y: rect.height),
            control: CGPoint(x: 0, y: rect.height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: rect.width - bcr, y: rect.height))

        // Bottom-right: normal inward rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.height - bcr),
            control: CGPoint(x: rect.width, y: rect.height)
        )

        // Right edge up
        path.addLine(to: CGPoint(x: rect.width, y: tcr))

        // Top-right: outward concave curve
        path.addQuadCurve(
            to: CGPoint(x: rect.width + tcr, y: 0),
            control: CGPoint(x: rect.width, y: 0)
        )

        // Top edge (goes through the area above, connects back)
        path.closeSubpath()
        return path
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
                for col in 2...5 { drawPixel(context: context, col: col, row: row, size: px, color: bodyColor.opacity(0.9)) }
            }
            drawPixel(context: context, col: 3, row: 1, size: px, color: .white)
            drawPixel(context: context, col: 4, row: 1, size: px, color: .white)
            for row in 3...5 {
                for col in 2...5 { drawPixel(context: context, col: col, row: row, size: px, color: bodyColor) }
            }
            for row in 3...4 {
                drawPixel(context: context, col: 1, row: row, size: px, color: bodyColor.opacity(0.7))
                drawPixel(context: context, col: 6, row: row, size: px, color: bodyColor.opacity(0.7))
            }
            for col in 2...5 { drawPixel(context: context, col: col, row: 6, size: px, color: bodyColor.opacity(0.6)) }
        }
    }

    private func drawPixel(context: GraphicsContext, col: Int, row: Int, size: CGFloat, color: Color) {
        context.fill(
            Path(CGRect(x: CGFloat(col) * size, y: CGFloat(row) * size, width: size, height: size)),
            with: .color(color)
        )
    }
}
