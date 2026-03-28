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
    var notchWidth: CGFloat
    var notchHeight: CGFloat
    var screenWidth: CGFloat

    private let sideExtension: CGFloat = 80
    private let cornerRadius: CGFloat = 14
    private let characterSize: CGFloat = 28

    private var totalWidth: CGFloat {
        notchWidth + sideExtension * 2
    }

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2

            ZStack {
                // Black background extending from notch
                NotchExtensionShape(cornerRadius: cornerRadius)
                    .fill(.black)
                    .frame(width: totalWidth, height: geo.size.height)
                    .position(x: centerX, y: geo.size.height / 2)

                // Left: mode name (in the menu bar strip, to the left of notch)
                if isActive, let name = modeName {
                    Text(name)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.8))
                        .position(
                            x: centerX - notchWidth / 2 - sideExtension / 2,
                            y: notchHeight / 2
                        )
                }

                // Right: timer (in the menu bar strip, to the right of notch)
                if isActive, remainingSeconds > 0 {
                    Text(formatTime(remainingSeconds))
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.purple)
                        .position(
                            x: centerX + notchWidth / 2 + sideExtension / 2,
                            y: notchHeight / 2
                        )
                }

                // Character: below the notch, peeking out
                TimelineView(.animation(minimumInterval: 1.0 / 24)) { timeline in
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
                        .frame(width: characterSize, height: characterSize)
                        .offset(y: bob)
                        .rotationEffect(.degrees(sway))
                        .position(
                            x: centerX,
                            y: notchHeight + characterSize / 2 - 4
                        )
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct NotchExtensionShape: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let cr = cornerRadius

        // Top-left to top-right (flat top, merges with system notch)
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))

        // Right side down
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - cr))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: rect.width - cr, y: rect.height),
            control: CGPoint(x: rect.width, y: rect.height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: cr, y: rect.height))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.height - cr),
            control: CGPoint(x: 0, y: rect.height)
        )

        path.closeSubpath()
        return path
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
                case .idle: return Color(red: 0.55, green: 0.36, blue: 0.96)
                case .working: return Color(red: 0.35, green: 0.78, blue: 0.98)
                case .resting: return Color(red: 0.27, green: 0.85, blue: 0.45)
                case .blocked: return Color(red: 0.98, green: 0.35, blue: 0.35)
                }
            }()

            // Head (rows 0-2, cols 2-5)
            for row in 0...2 {
                for col in 2...5 {
                    drawPixel(context: context, col: col, row: row, size: px, color: bodyColor.opacity(0.9))
                }
            }

            // Eyes
            drawPixel(context: context, col: 3, row: 1, size: px, color: .white)
            drawPixel(context: context, col: 4, row: 1, size: px, color: .white)

            // Body (rows 3-5, cols 2-5)
            for row in 3...5 {
                for col in 2...5 {
                    drawPixel(context: context, col: col, row: row, size: px, color: bodyColor)
                }
            }

            // Arms
            for row in 3...4 {
                drawPixel(context: context, col: 1, row: row, size: px, color: bodyColor.opacity(0.7))
                drawPixel(context: context, col: 6, row: row, size: px, color: bodyColor.opacity(0.7))
            }

            // Legs
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
