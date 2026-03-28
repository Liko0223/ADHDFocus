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

    // How much to extend on each side of the notch
    private let sideExtension: CGFloat = 80
    private let cornerRadius: CGFloat = 12

    private var totalWidth: CGFloat {
        notchWidth + sideExtension * 2
    }

    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let panelX = centerX - totalWidth / 2

            // Black background extending from notch
            ZStack(alignment: .top) {
                // Black shape that seamlessly extends from the notch
                NotchExtensionShape(
                    notchWidth: notchWidth,
                    totalWidth: totalWidth,
                    height: geo.size.height,
                    cornerRadius: cornerRadius
                )
                .fill(.black)
                .frame(width: totalWidth, height: geo.size.height)
                .position(x: centerX, y: geo.size.height / 2)

                // Content on the black area
                HStack(spacing: 0) {
                    // Left side: mode info
                    if isActive, let name = modeName {
                        Text(name)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.white.opacity(0.8))
                            .frame(width: sideExtension - 8)
                    } else {
                        Color.clear.frame(width: sideExtension - 8)
                    }

                    // Center: notch area (empty — hardware blocks this)
                    // Character sits at the bottom edge of this area
                    ZStack {
                        // Pixel character at the bottom center of notch
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
                                .frame(width: 20, height: 20)
                                .offset(y: bob)
                                .rotationEffect(.degrees(sway))
                        }
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 2)
                    }
                    .frame(width: notchWidth)

                    // Right side: timer
                    if isActive, remainingSeconds > 0 {
                        Text(formatTime(remainingSeconds))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.purple)
                            .frame(width: sideExtension - 8)
                    } else {
                        Color.clear.frame(width: sideExtension - 8)
                    }
                }
                .frame(width: totalWidth, height: geo.size.height)
                .position(x: centerX, y: geo.size.height / 2)
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

// Shape that extends seamlessly from the notch with rounded bottom corners
struct NotchExtensionShape: Shape {
    let notchWidth: CGFloat
    let totalWidth: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let sideWidth = (totalWidth - notchWidth) / 2

        // Start at top-left
        path.move(to: CGPoint(x: 0, y: 0))

        // Top edge (straight — connects to system notch)
        path.addLine(to: CGPoint(x: totalWidth, y: 0))

        // Right edge down to bottom-right corner
        path.addLine(to: CGPoint(x: totalWidth, y: height - cornerRadius))

        // Bottom-right corner
        path.addQuadCurve(
            to: CGPoint(x: totalWidth - cornerRadius, y: height),
            control: CGPoint(x: totalWidth, y: height)
        )

        // Bottom edge
        path.addLine(to: CGPoint(x: cornerRadius, y: height))

        // Bottom-left corner
        path.addQuadCurve(
            to: CGPoint(x: 0, y: height - cornerRadius),
            control: CGPoint(x: 0, y: height)
        )

        // Left edge back to top
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
                case .idle: return Color(red: 0.55, green: 0.36, blue: 0.96)    // purple
                case .working: return Color(red: 0.35, green: 0.78, blue: 0.98) // cyan
                case .resting: return Color(red: 0.27, green: 0.85, blue: 0.45) // green
                case .blocked: return Color(red: 0.98, green: 0.35, blue: 0.35) // red
                }
            }()

            // Head (rows 0-2, cols 2-5)
            for row in 0...2 {
                for col in 2...5 {
                    fillPixel(context: context, col: col, row: row, px: px, color: bodyColor.opacity(0.9))
                }
            }

            // Eyes (row 1, cols 3 and 4)
            fillPixel(context: context, col: 3, row: 1, px: px, color: .white)
            fillPixel(context: context, col: 4, row: 1, px: px, color: .white)

            // Body (rows 3-5, cols 2-5)
            for row in 3...5 {
                for col in 2...5 {
                    fillPixel(context: context, col: col, row: row, px: px, color: bodyColor)
                }
            }

            // Arms (rows 3-4, cols 1 and 6)
            for row in 3...4 {
                fillPixel(context: context, col: 1, row: row, px: px, color: bodyColor.opacity(0.7))
                fillPixel(context: context, col: 6, row: row, px: px, color: bodyColor.opacity(0.7))
            }

            // Legs (row 6, cols 2-3 and 4-5)
            fillPixel(context: context, col: 2, row: 6, px: px, color: bodyColor.opacity(0.6))
            fillPixel(context: context, col: 3, row: 6, px: px, color: bodyColor.opacity(0.6))
            fillPixel(context: context, col: 4, row: 6, px: px, color: bodyColor.opacity(0.6))
            fillPixel(context: context, col: 5, row: 6, px: px, color: bodyColor.opacity(0.6))
        }
    }

    private func fillPixel(context: GraphicsContext, col: Int, row: Int, px: CGFloat, color: Color) {
        context.fill(
            Path(CGRect(x: CGFloat(col) * px, y: CGFloat(row) * px, width: px, height: px)),
            with: .color(color)
        )
    }
}
