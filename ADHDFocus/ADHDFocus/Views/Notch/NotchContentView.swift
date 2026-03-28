import SwiftUI

enum CompanionState: String {
    case idle
    case working
    case resting
    case blocked

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
        case .idle: return 2.0
        case .working: return 1.5
        case .resting: return 1.0
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
    var companionState: CompanionState
    var modeName: String?
    var remainingSeconds: Int
    var isActive: Bool
    var notchWidth: CGFloat
    var notchHeight: CGFloat

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2

            ZStack {
                // Left of notch: mode name
                if isActive, let name = modeName {
                    Text(name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                        .position(
                            x: centerX - notchWidth / 2 - 50,
                            y: geo.size.height - notchHeight / 2
                        )
                }

                // Right of notch: timer
                if isActive, remainingSeconds > 0 {
                    Text(formatTime(remainingSeconds))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.purple)
                        .position(
                            x: centerX + notchWidth / 2 + 40,
                            y: geo.size.height - notchHeight / 2
                        )
                }

                // Character sitting on top of the notch bottom edge
                TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                    let bob = BobAnimation.bobOffset(
                        at: timeline.date,
                        duration: companionState.bobDuration,
                        amplitude: companionState.bobAmplitude
                    )
                    let sway = BobAnimation.swayDegrees(
                        at: timeline.date,
                        duration: 2.5,
                        amplitude: companionState.swayAmplitude
                    )

                    PixelCompanionView(state: companionState)
                        .frame(width: 24, height: 24)
                        .offset(y: bob)
                        .rotationEffect(.degrees(sway))
                        .position(
                            x: centerX,
                            y: geo.size.height - notchHeight - 2
                        )
                }
            }
        }
        .ignoresSafeArea()
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct PixelCompanionView: View {
    let state: CompanionState

    var body: some View {
        Canvas { context, size in
            let s = min(size.width, size.height)
            let px = s / 8

            let bodyColor: Color = {
                switch state {
                case .idle: return .purple
                case .working: return .cyan
                case .resting: return .green
                case .blocked: return .red
                }
            }()

            let headColor = bodyColor.opacity(0.85)

            // Head (rows 0-2, cols 2-5)
            for row in 0...2 {
                for col in 2...5 {
                    context.fill(
                        Path(CGRect(x: CGFloat(col) * px, y: CGFloat(row) * px, width: px, height: px)),
                        with: .color(headColor)
                    )
                }
            }

            // Eyes (row 1, cols 3 and 4) - white
            context.fill(
                Path(CGRect(x: 3 * px, y: 1 * px, width: px, height: px)),
                with: .color(.white)
            )
            context.fill(
                Path(CGRect(x: 4 * px, y: 1 * px, width: px, height: px)),
                with: .color(.white)
            )

            // Pupils (row 1, cols 3 and 4) - tiny black dot
            let pupilSize = px * 0.4
            let pupilOffset = (px - pupilSize) / 2
            context.fill(
                Path(CGRect(x: 3 * px + pupilOffset + 1, y: 1 * px + pupilOffset, width: pupilSize, height: pupilSize)),
                with: .color(.black)
            )
            context.fill(
                Path(CGRect(x: 4 * px + pupilOffset + 1, y: 1 * px + pupilOffset, width: pupilSize, height: pupilSize)),
                with: .color(.black)
            )

            // Body (rows 3-5, cols 2-5)
            for row in 3...5 {
                for col in 2...5 {
                    context.fill(
                        Path(CGRect(x: CGFloat(col) * px, y: CGFloat(row) * px, width: px, height: px)),
                        with: .color(bodyColor)
                    )
                }
            }

            // Arms (row 3-4, cols 1 and 6)
            for row in 3...4 {
                context.fill(
                    Path(CGRect(x: 1 * px, y: CGFloat(row) * px, width: px, height: px)),
                    with: .color(bodyColor.opacity(0.7))
                )
                context.fill(
                    Path(CGRect(x: 6 * px, y: CGFloat(row) * px, width: px, height: px)),
                    with: .color(bodyColor.opacity(0.7))
                )
            }

            // Feet (row 6, cols 2-3 and 4-5)
            context.fill(
                Path(CGRect(x: 2 * px, y: 6 * px, width: px * 2, height: px)),
                with: .color(bodyColor.opacity(0.6))
            )
            context.fill(
                Path(CGRect(x: 4 * px, y: 6 * px, width: px * 2, height: px)),
                with: .color(bodyColor.opacity(0.6))
            )
        }
    }
}
