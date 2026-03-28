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

    // Fixed side extension — character always at the same position
    private let sideExtension: CGFloat = 70
    private let expandedWidth: CGFloat = 340
    private let expandedPanelHeight: CGFloat = 260
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
                // Black background — always with outward top corners
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
                    if manager.isExpanded {
                        expandedContent
                            .frame(width: currentWidth)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    } else {
                        collapsedBar
                            .frame(width: currentWidth, height: manager.notchHeight)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                manager.toggleExpanded()
                            }
                    }
                }
                .frame(width: currentWidth, height: currentHeight)
                .clipped()
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
            // Scene fills from very top (including notch row) to mid panel
            CompanionSceneView(state: manager.companionState, sceneWidth: currentWidth, focusModeName: manager.modeName)
                .frame(height: manager.notchHeight + 120)

            // Controls below with consistent 12px spacing
            VStack(spacing: 12) {
                // Status row
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

                // Mode grid
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
                        manager.openMainWindow?()
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
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 16)
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

// MARK: - Pixel Companion (matches scene character style)

struct PixelCompanionView: View {
    let state: CompanionState

    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            let px = s / 10

            let bodyColor: Color = {
                switch state {
                case .idle, .working, .resting: return Color(red: 0.28, green: 0.65, blue: 0.95)
                case .blocked: return Color(red: 0.95, green: 0.28, blue: 0.28)
                }
            }()
            let skinColor = Color(red: 0.98, green: 0.86, blue: 0.72)
            let eyeColor = Color(red: 0.18, green: 0.14, blue: 0.25)

            let cx = s / 2  // center x
            let startY = px  // top padding

            // Head (round: 5 wide, 4 tall, corners clipped)
            let headPixels: [(Int, Int)] = [
                (1,0),(2,0),(3,0),
                (0,1),(1,1),(2,1),(3,1),(4,1),
                (0,2),(1,2),(2,2),(3,2),(4,2),
                (1,3),(2,3),(3,3),
            ]
            for (hc, hr) in headPixels {
                let hx = cx - px * 2.5 + CGFloat(hc) * px
                let hy = startY + CGFloat(hr) * px
                context.fill(Path(CGRect(x: hx, y: hy, width: px, height: px)), with: .color(skinColor))
            }

            // Eyes
            let eyeLX = cx - px * 1.1
            let eyeRX = cx + px * 0.3
            let eyeY = startY + px * 1.2
            context.fill(Path(ellipseIn: CGRect(x: eyeLX, y: eyeY, width: px * 0.7, height: px * 0.7)), with: .color(eyeColor))
            context.fill(Path(ellipseIn: CGRect(x: eyeRX, y: eyeY, width: px * 0.7, height: px * 0.7)), with: .color(eyeColor))

            // Rosy cheeks
            if state == .idle || state == .resting {
                let rosy = Color(red: 0.95, green: 0.60, blue: 0.60).opacity(0.45)
                context.fill(Path(ellipseIn: CGRect(x: cx - px * 1.8, y: startY + px * 2.2, width: px, height: px * 0.5)), with: .color(rosy))
                context.fill(Path(ellipseIn: CGRect(x: cx + px * 0.8, y: startY + px * 2.2, width: px, height: px * 0.5)), with: .color(rosy))
            }

            // Body (4 wide, 3 tall)
            for row in 0..<3 {
                for col in 0..<4 {
                    let bx = cx - px * 2 + CGFloat(col) * px
                    let by = startY + px * 4 + CGFloat(row) * px
                    context.fill(Path(CGRect(x: bx, y: by, width: px, height: px)), with: .color(bodyColor))
                }
            }

            // Arms
            context.fill(Path(CGRect(x: cx - px * 3, y: startY + px * 4.5, width: px, height: px * 1.5)), with: .color(bodyColor.opacity(0.7)))
            context.fill(Path(CGRect(x: cx + px * 2, y: startY + px * 4.5, width: px, height: px * 1.5)), with: .color(bodyColor.opacity(0.7)))

            // Legs
            context.fill(Path(CGRect(x: cx - px * 1.5, y: startY + px * 7, width: px, height: px * 1.2)), with: .color(bodyColor.opacity(0.6)))
            context.fill(Path(CGRect(x: cx + px * 0.5, y: startY + px * 7, width: px, height: px * 1.2)), with: .color(bodyColor.opacity(0.6)))
        }
    }
}
