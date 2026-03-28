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
    var companionState: CompanionState
    var modeName: String?
    var remainingSeconds: Int
    var isActive: Bool

    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            if isActive {
                // Left side: timer info
                VStack(spacing: 2) {
                    Text(modeName ?? "")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                    if remainingSeconds > 0 {
                        Text(formatTime(remainingSeconds))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.purple)
                    }
                }
                .padding(.trailing, 6)
            }

            // Center: pixel character
            TimelineView(.animation(minimumInterval: 1.0 / 30)) { timeline in
                let bob = BobAnimation.bobOffset(
                    at: timeline.date,
                    duration: companionState.bobDuration,
                    amplitude: companionState.bobAmplitude
                )
                let sway = BobAnimation.swayDegrees(
                    at: timeline.date,
                    duration: 2.0,
                    amplitude: companionState.swayAmplitude
                )

                PixelCompanionView(state: companionState)
                    .frame(width: 28, height: 28)
                    .offset(y: bob)
                    .rotationEffect(.degrees(sway))
            }

            if isActive {
                // Right side: status dot
                Circle()
                    .fill(.green)
                    .frame(width: 5, height: 5)
                    .padding(.leading, 6)
            }

            Spacer()
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// Placeholder pixel companion — will be replaced with real sprite sheets later
struct PixelCompanionView: View {
    let state: CompanionState

    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let s = min(size.width, size.height)
                let px = s / 8  // 8x8 pixel grid

                // Simple pixel character
                let bodyColor: Color = {
                    switch state {
                    case .idle: return .purple
                    case .working: return .blue
                    case .resting: return .green
                    case .blocked: return .red
                    }
                }()

                // Body (center 4x4)
                for row in 2...5 {
                    for col in 2...5 {
                        context.fill(
                            Path(CGRect(x: CGFloat(col) * px, y: CGFloat(row) * px, width: px, height: px)),
                            with: .color(bodyColor)
                        )
                    }
                }

                // Head (top center 4x2)
                for row in 0...1 {
                    for col in 2...5 {
                        context.fill(
                            Path(CGRect(x: CGFloat(col) * px, y: CGFloat(row) * px, width: px, height: px)),
                            with: .color(bodyColor.opacity(0.9))
                        )
                    }
                }

                // Eyes (row 1, col 3 and 4)
                let eyeColor = Color.white
                context.fill(
                    Path(CGRect(x: 3 * px, y: 1 * px, width: px, height: px)),
                    with: .color(eyeColor)
                )
                context.fill(
                    Path(CGRect(x: 4 * px, y: 1 * px, width: px, height: px)),
                    with: .color(eyeColor)
                )

                // Feet (bottom)
                context.fill(
                    Path(CGRect(x: 2 * px, y: 6 * px, width: px, height: px)),
                    with: .color(bodyColor.opacity(0.7))
                )
                context.fill(
                    Path(CGRect(x: 5 * px, y: 6 * px, width: px, height: px)),
                    with: .color(bodyColor.opacity(0.7))
                )
            }
        }
    }
}
