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
        manager.notchWidth + sideExtension * 2
    }

    private var currentWidth: CGFloat {
        manager.isExpanded ? max(expandedWidth, manager.notchWidth + 40) : collapsedWidth
    }

    private var currentHeight: CGFloat {
        if manager.isExpanded {
            return manager.notchHeight + expandedPanelHeight
        } else if manager.isSuggesting {
            return manager.notchHeight + 56
        } else {
            return manager.notchHeight
        }
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
                    bottomCornerRadius: (manager.isExpanded || manager.isSuggesting) ? bottomCornerRadius : topCornerRadius,
                    notchHeight: manager.notchHeight,
                    isExpanded: manager.isExpanded
                )
                .fill(.black)
                .frame(width: currentWidth, height: currentHeight)
                .shadow(color: .black.opacity(manager.isExpanded ? 0.4 : 0), radius: 16)
                .overlay(
                    // Celebration glow
                    manager.isCelebrating ?
                    RoundedRectangle(cornerRadius: bottomCornerRadius)
                        .stroke(
                            AngularGradient(
                                colors: [.purple, .blue, .cyan, .green, .yellow, .orange, .pink, .purple],
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .blur(radius: 6)
                        .frame(width: currentWidth, height: currentHeight)
                        .opacity(manager.isCelebrating ? 1 : 0)
                    : nil
                )

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
                                if !manager.isSuggesting {
                                    manager.toggleExpanded()
                                }
                            }

                        if manager.isSuggesting {
                            suggestionBar
                                .frame(width: currentWidth)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
                .frame(width: currentWidth, height: currentHeight)
                .clipped()
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)


        }
        .animation(panelAnimation, value: manager.isExpanded)
        .animation(panelAnimation, value: manager.isActive)
        .animation(panelAnimation, value: manager.isSuggesting)
        .animation(.easeInOut(duration: 0.5), value: manager.isCelebrating)
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

                PixelCompanionView(state: manager.companionState, time: timeline.date.timeIntervalSinceReferenceDate)
                    .frame(width: 30, height: 30)
                    .offset(y: bob + 2)
                    .rotationEffect(.degrees(sway))
            }
            .frame(width: sideExtension)

            // Center: notch gap
            Spacer()
                .frame(minWidth: manager.isExpanded ? 20 : manager.notchWidth)

            // Right: timer or idle text
            Group {
                if manager.isActive {
                    let isPaused = manager.engine?.pomodoroTimer?.isPaused == true
                    if manager.remainingSeconds > 0 {
                        HStack(spacing: 2) {
                            if isPaused {
                                Text("⏸")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            Text(formatTime(manager.remainingSeconds))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(isPaused ? 0.5 : 0.9))
                        }
                        .contentShape(Rectangle())
                        .help(isPaused ? "点击继续" : "点击暂停")
                        .onTapGesture {
                            if isPaused {
                                manager.engine?.pomodoroTimer?.resume()
                            } else {
                                manager.engine?.pomodoroTimer?.pause()
                            }
                        }
                    } else {
                        Circle()
                            .fill(.green)
                            .frame(width: 6, height: 6)
                    }
                } else if manager.isCelebrating {
                    Text("🎉 Good job!")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.9))
                } else {
                    Text(idleGreeting)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .offset(y: -2)
            .frame(width: sideExtension)
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
                            .foregroundStyle(.white.opacity(0.9))
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

                        Button {
                            if manager.engine?.pomodoroTimer?.isPaused == true {
                                manager.engine?.pomodoroTimer?.resume()
                            } else {
                                manager.engine?.pomodoroTimer?.pause()
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: manager.engine?.pomodoroTimer?.isPaused == true ? "play.fill" : "pause.fill")
                                    .font(.system(size: 8))
                                Text(manager.engine?.pomodoroTimer?.isPaused == true ? "继续" : "暂停")
                                    .font(.caption2)
                            }
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.white.opacity(0.1))
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

    // MARK: - Suggestion bar

    private var suggestionBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Text
            if let appName = manager.suggestedAppName {
                Text("在用 \(appName)~ 要专注吗？")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(1)
            }

            // Bottom row: mode activate button + dismiss button
            HStack(spacing: 8) {
                if let mode = manager.suggestedMode {
                    Button {
                        manager.acceptSuggestion()
                    } label: {
                        HStack(spacing: 5) {
                            Text(mode.icon)
                                .font(.system(size: 10))
                            Text(mode.name)
                                .font(.system(size: 10, weight: .medium))
                            Image(systemName: "play.fill")
                                .font(.system(size: 7))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.6))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    manager.onIgnoreSuggestion?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(5)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: 56)
    }

    private var idleGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<6: return "😴 Sleep~"
        case 6..<9: return "🌅 Morning!"
        case 9..<12: return "☀️ Ready~"
        case 12..<14: return "🍱 Lunch?"
        case 14..<18: return "☕ Go go!"
        case 18..<21: return "🌙 Evening"
        default: return "✨ Relax~"
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

// MARK: - Pixel Cat Face (compact for notch bar)

struct PixelCompanionView: View {
    let state: CompanionState
    var time: Double = 0

    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            let px = s / 7

            let fur = Color(red: 0.95, green: 0.65, blue: 0.25)
            let white = Color(red: 0.98, green: 0.96, blue: 0.92)
            let eye = Color(red: 0.15, green: 0.15, blue: 0.20)
            let nose = Color(red: 0.90, green: 0.55, blue: 0.55)
            let darkFur = Color(red: 0.75, green: 0.45, blue: 0.15)

            let cx = s / 2

            // Ears
            p(context, cx - px * 2.5, px * 0, px, px, fur)
            p(context, cx - px * 1.5, px * 0, px, px, fur)
            p(context, cx + px * 0.5, px * 0, px, px, fur)
            p(context, cx + px * 1.5, px * 0, px, px, fur)
            // Inner ears
            p(context, cx - px * 2, px * 0.3, px * 0.6, px * 0.5, nose.opacity(0.4))
            p(context, cx + px * 1.1, px * 0.3, px * 0.6, px * 0.5, nose.opacity(0.4))

            // Head (5 wide, 3 tall)
            let hy = px * 1
            for row in 0..<3 {
                for col in 0..<5 {
                    p(context, cx - px * 2.5 + CGFloat(col) * px, hy + CGFloat(row) * px, px, px, fur)
                }
            }

            // White muzzle
            p(context, cx - px * 1, hy + px * 1.8, px * 2, px * 1, white)

            // Eyes
            let blink = time.truncatingRemainder(dividingBy: 3.5)
            if state == .working {
                p(context, cx - px * 1.5, hy + px * 0.9, px * 0.8, px * 0.25, eye)
                p(context, cx + px * 0.7, hy + px * 0.9, px * 0.8, px * 0.25, eye)
            } else {
                let eh: CGFloat = blink > 3.2 ? px * 0.1 : px * 0.6
                context.fill(Path(ellipseIn: CGRect(x: cx - px * 1.6, y: hy + px * 0.7, width: px * 0.8, height: eh)), with: .color(eye))
                context.fill(Path(ellipseIn: CGRect(x: cx + px * 0.7, y: hy + px * 0.7, width: px * 0.8, height: eh)), with: .color(eye))
            }

            // Nose
            p(context, cx - px * 0.3, hy + px * 1.8, px * 0.5, px * 0.35, nose)

            // Whiskers
            p(context, cx - px * 2.3, hy + px * 2.1, px * 0.8, px * 0.12, darkFur.opacity(0.3))
            p(context, cx + px * 1.5, hy + px * 2.1, px * 0.8, px * 0.12, darkFur.opacity(0.3))
            p(context, cx - px * 2.2, hy + px * 2.5, px * 0.7, px * 0.12, darkFur.opacity(0.25))
            p(context, cx + px * 1.5, hy + px * 2.5, px * 0.7, px * 0.12, darkFur.opacity(0.25))

            // Typing paws when working
            if state == .working {
                let pawY = hy + px * 3.2
                let frame = Int(time * 6) % 2
                let leftPawY = pawY + (frame == 0 ? -px * 0.4 : px * 0.2)
                let rightPawY = pawY + (frame == 0 ? px * 0.2 : -px * 0.4)
                // Left paw
                p(context, cx - px * 2, leftPawY, px * 1.2, px * 0.8, white)
                p(context, cx - px * 1.8, leftPawY + px * 0.1, px * 0.3, px * 0.3, nose.opacity(0.3))
                // Right paw
                p(context, cx + px * 0.8, rightPawY, px * 1.2, px * 0.8, white)
                p(context, cx + px * 1.0, rightPawY + px * 0.1, px * 0.3, px * 0.3, nose.opacity(0.3))
            }
        }
    }

    private func p(_ ctx: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: Color) {
        ctx.fill(Path(CGRect(x: x, y: y, width: w, height: h)), with: .color(c))
    }
}
