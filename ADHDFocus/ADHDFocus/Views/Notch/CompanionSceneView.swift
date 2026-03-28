import SwiftUI

/// Pixel art scene where the companion character lives
struct CompanionSceneView: View {
    let state: CompanionState
    let sceneWidth: CGFloat
    let sceneHeight: CGFloat = 120

    // Character movement
    @State private var characterX: CGFloat = 0.5  // 0...1 normalized position
    @State private var walkDirection: CGFloat = 1  // 1 = right, -1 = left
    @State private var walkTimer: Timer?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 16)) { timeline in
            Canvas { context, size in
                let px: CGFloat = 4  // pixel size for scene elements

                // Sky gradient (dark)
                let skyGradient = Gradient(colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.08, green: 0.06, blue: 0.2)
                ])
                context.fill(
                    Path(CGRect(origin: .zero, size: size)),
                    with: .linearGradient(skyGradient, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
                )

                // Stars
                drawStars(context: context, size: size, time: timeline.date, px: px)

                // Ground
                let groundY = size.height - 20
                drawGround(context: context, size: size, groundY: groundY, px: px)

                // Decorations based on state
                switch state {
                case .working:
                    drawDesk(context: context, x: size.width * 0.75, groundY: groundY, px: px)
                    drawLamp(context: context, x: size.width * 0.2, groundY: groundY, px: px, time: timeline.date)
                case .resting:
                    drawTree(context: context, x: size.width * 0.15, groundY: groundY, px: px)
                    drawFlowers(context: context, groundY: groundY, size: size, px: px, time: timeline.date)
                    drawTree(context: context, x: size.width * 0.85, groundY: groundY, px: px)
                case .idle:
                    drawTree(context: context, x: size.width * 0.18, groundY: groundY, px: px)
                    drawBench(context: context, x: size.width * 0.78, groundY: groundY, px: px)
                case .blocked:
                    drawWarningSign(context: context, x: size.width * 0.75, groundY: groundY, px: px, time: timeline.date)
                }

                // Character
                let charX = characterX * (size.width - 40) + 20
                let bob = BobAnimation.bobOffset(
                    at: timeline.date,
                    duration: state.bobDuration,
                    amplitude: state.bobAmplitude * 1.5
                )
                let charY = groundY - 32 + bob

                drawCharacter(context: context, x: charX, y: charY, px: px, state: state, facingRight: walkDirection > 0, time: timeline.date)
            }
        }
        .frame(height: sceneHeight)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onAppear { startWalking() }
        .onDisappear { walkTimer?.invalidate() }
        .onChange(of: state) { startWalking() }
    }

    // MARK: - Character movement

    private func startWalking() {
        walkTimer?.invalidate()

        let interval: TimeInterval = {
            switch state {
            case .working: return 3.0   // Stays mostly still
            case .resting: return 1.2   // Wanders more
            case .idle: return 2.0
            case .blocked: return 0     // Doesn't walk
            }
        }()

        guard interval > 0 else { return }

        walkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            withAnimation(.easeInOut(duration: interval * 0.8)) {
                // Random walk
                let step = CGFloat.random(in: 0.05...0.15)
                if characterX > 0.8 { walkDirection = -1 }
                else if characterX < 0.2 { walkDirection = 1 }
                else if Bool.random() { walkDirection *= -1 }

                characterX = max(0.1, min(0.9, characterX + step * walkDirection))
            }
        }
    }

    // MARK: - Drawing functions

    private func drawStars(context: GraphicsContext, size: CGSize, time: Date, px: CGFloat) {
        let t = time.timeIntervalSinceReferenceDate
        let starPositions: [(CGFloat, CGFloat, CGFloat)] = [
            (0.1, 0.15, 0.3), (0.3, 0.08, 0.7), (0.5, 0.2, 0.1),
            (0.7, 0.12, 0.5), (0.85, 0.25, 0.9), (0.2, 0.3, 0.4),
            (0.6, 0.05, 0.6), (0.9, 0.18, 0.2), (0.4, 0.28, 0.8),
        ]
        for (nx, ny, phase) in starPositions {
            let twinkle = (sin(t * 2 + phase * 10) + 1) / 2 * 0.6 + 0.4
            let starColor = Color.white.opacity(twinkle * 0.8)
            context.fill(
                Path(CGRect(x: nx * size.width, y: ny * size.height, width: px * 0.8, height: px * 0.8)),
                with: .color(starColor)
            )
        }
    }

    private func drawGround(context: GraphicsContext, size: CGSize, groundY: CGFloat, px: CGFloat) {
        // Dark grass base
        context.fill(
            Path(CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)),
            with: .color(Color(red: 0.1, green: 0.2, blue: 0.1))
        )

        // Grass tufts
        let grassColor1 = Color(red: 0.15, green: 0.35, blue: 0.12)
        let grassColor2 = Color(red: 0.12, green: 0.28, blue: 0.1)
        for i in stride(from: CGFloat(0), to: size.width, by: px * 3) {
            let c = i.truncatingRemainder(dividingBy: px * 6) < px * 3 ? grassColor1 : grassColor2
            context.fill(
                Path(CGRect(x: i, y: groundY, width: px * 2, height: px)),
                with: .color(c)
            )
        }
    }

    private func drawTree(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat) {
        let trunk = Color(red: 0.35, green: 0.2, blue: 0.1)
        let leaves = Color(red: 0.12, green: 0.4, blue: 0.15)
        let lightLeaves = Color(red: 0.18, green: 0.5, blue: 0.2)

        // Trunk
        context.fill(Path(CGRect(x: x - px, y: groundY - px * 6, width: px * 2, height: px * 6)), with: .color(trunk))

        // Leaves (triangle-ish)
        for row in 0..<4 {
            let w = CGFloat(4 - row) * px
            let ly = groundY - px * 6 - CGFloat(row) * px * 1.5 - px * 2
            let c = row % 2 == 0 ? leaves : lightLeaves
            context.fill(Path(CGRect(x: x - w, y: ly, width: w * 2, height: px * 2)), with: .color(c))
        }
    }

    private func drawDesk(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat) {
        let wood = Color(red: 0.4, green: 0.25, blue: 0.12)
        let screen = Color(red: 0.2, green: 0.35, blue: 0.5)
        let screenGlow = Color(red: 0.3, green: 0.5, blue: 0.7)

        // Desk surface
        context.fill(Path(CGRect(x: x - px * 5, y: groundY - px * 4, width: px * 10, height: px * 1.5)), with: .color(wood))
        // Legs
        context.fill(Path(CGRect(x: x - px * 4, y: groundY - px * 4, width: px, height: px * 4)), with: .color(wood))
        context.fill(Path(CGRect(x: x + px * 3, y: groundY - px * 4, width: px, height: px * 4)), with: .color(wood))
        // Monitor
        context.fill(Path(CGRect(x: x - px * 2, y: groundY - px * 8, width: px * 5, height: px * 3.5)), with: .color(screen))
        context.fill(Path(CGRect(x: x - px * 1.5, y: groundY - px * 7.5, width: px * 4, height: px * 2.5)), with: .color(screenGlow))
    }

    private func drawLamp(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat, time: Date) {
        let post = Color(red: 0.3, green: 0.3, blue: 0.35)
        let glow = Color(red: 0.9, green: 0.75, blue: 0.3)
        let t = time.timeIntervalSinceReferenceDate
        let flicker = 0.7 + sin(t * 3) * 0.15

        // Post
        context.fill(Path(CGRect(x: x - px * 0.5, y: groundY - px * 8, width: px, height: px * 8)), with: .color(post))
        // Top
        context.fill(Path(CGRect(x: x - px * 1.5, y: groundY - px * 9, width: px * 3, height: px)), with: .color(post))
        // Light
        context.fill(
            Path(CGRect(x: x - px, y: groundY - px * 8.5, width: px * 2, height: px)),
            with: .color(glow.opacity(flicker))
        )
        // Glow circle
        let glowRect = CGRect(x: x - px * 3, y: groundY - px * 11, width: px * 6, height: px * 6)
        context.fill(Path(ellipseIn: glowRect), with: .color(glow.opacity(0.08 * flicker)))
    }

    private func drawFlowers(context: GraphicsContext, groundY: CGFloat, size: CGSize, px: CGFloat, time: Date) {
        let t = time.timeIntervalSinceReferenceDate
        let positions: [(CGFloat, Color)] = [
            (0.3, Color(red: 0.9, green: 0.3, blue: 0.4)),
            (0.45, Color(red: 0.9, green: 0.7, blue: 0.2)),
            (0.55, Color(red: 0.5, green: 0.3, blue: 0.9)),
            (0.7, Color(red: 0.9, green: 0.4, blue: 0.6)),
        ]
        for (nx, color) in positions {
            let fx = nx * size.width
            let sway = sin(t * 1.5 + nx * 10) * 1.5
            // Stem
            context.fill(Path(CGRect(x: fx, y: groundY - px * 3, width: px * 0.5, height: px * 3)), with: .color(Color(red: 0.15, green: 0.35, blue: 0.12)))
            // Flower head
            context.fill(Path(CGRect(x: fx - px * 0.5 + sway, y: groundY - px * 4, width: px * 1.5, height: px * 1.5)), with: .color(color))
        }
    }

    private func drawBench(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat) {
        let wood = Color(red: 0.45, green: 0.3, blue: 0.15)
        // Seat
        context.fill(Path(CGRect(x: x - px * 4, y: groundY - px * 3, width: px * 8, height: px)), with: .color(wood))
        // Back
        context.fill(Path(CGRect(x: x - px * 4, y: groundY - px * 5, width: px * 8, height: px)), with: .color(wood))
        // Legs
        context.fill(Path(CGRect(x: x - px * 3, y: groundY - px * 3, width: px, height: px * 3)), with: .color(wood))
        context.fill(Path(CGRect(x: x + px * 2, y: groundY - px * 3, width: px, height: px * 3)), with: .color(wood))
        // Back supports
        context.fill(Path(CGRect(x: x - px * 3, y: groundY - px * 5, width: px, height: px * 2)), with: .color(wood))
        context.fill(Path(CGRect(x: x + px * 2, y: groundY - px * 5, width: px, height: px * 2)), with: .color(wood))
    }

    private func drawWarningSign(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat, time: Date) {
        let t = time.timeIntervalSinceReferenceDate
        let blink = sin(t * 4) > 0

        let post = Color(red: 0.3, green: 0.3, blue: 0.3)
        let signColor = blink ? Color(red: 0.9, green: 0.2, blue: 0.2) : Color(red: 0.6, green: 0.15, blue: 0.15)

        context.fill(Path(CGRect(x: x, y: groundY - px * 6, width: px, height: px * 6)), with: .color(post))
        context.fill(Path(CGRect(x: x - px * 2, y: groundY - px * 8, width: px * 5, height: px * 3)), with: .color(signColor))
        // "!" mark
        context.fill(Path(CGRect(x: x + px * 0.3, y: groundY - px * 7.5, width: px * 0.8, height: px * 1.5)), with: .color(.white))
        context.fill(Path(CGRect(x: x + px * 0.3, y: groundY - px * 5.5, width: px * 0.8, height: px * 0.5)), with: .color(.white))
    }

    // MARK: - Character (larger, more detailed)

    private func drawCharacter(context: GraphicsContext, x: CGFloat, y: CGFloat, px: CGFloat, state: CompanionState, facingRight: Bool, time: Date) {
        let bodyColor: Color = {
            switch state {
            case .idle: return Color(red: 0.55, green: 0.36, blue: 0.96)
            case .working: return Color(red: 0.35, green: 0.78, blue: 0.98)
            case .resting: return Color(red: 0.27, green: 0.85, blue: 0.45)
            case .blocked: return Color(red: 0.98, green: 0.35, blue: 0.35)
            }
        }()

        let dir: CGFloat = facingRight ? 1 : -1
        let t = time.timeIntervalSinceReferenceDate
        let walkFrame = Int(t * 4) % 2  // Simple 2-frame walk

        // Shadow
        context.fill(
            Path(ellipseIn: CGRect(x: x - px * 3, y: y + px * 7.5, width: px * 6, height: px * 1.5)),
            with: .color(.black.opacity(0.3))
        )

        // Head (rows 0-2, 4px wide)
        for row in 0..<3 {
            for col in -2..<2 {
                let cx = x + CGFloat(col) * px + (facingRight ? 0 : 0)
                let cy = y + CGFloat(row) * px
                fillPx(context: context, x: cx, y: cy, size: px, color: bodyColor.opacity(0.9))
            }
        }

        // Eyes (row 1)
        let eyeOffset: CGFloat = facingRight ? -0.5 : 0.5
        fillPx(context: context, x: x - px + eyeOffset * px, y: y + px, size: px, color: .white)
        fillPx(context: context, x: x + eyeOffset * px, y: y + px, size: px, color: .white)

        // Body (rows 3-5)
        for row in 3..<6 {
            for col in -2..<2 {
                fillPx(context: context, x: x + CGFloat(col) * px, y: y + CGFloat(row) * px, size: px, color: bodyColor)
            }
        }

        // Arms (rows 3-4)
        let armSwing = walkFrame == 0 ? px : -px
        fillPx(context: context, x: x - px * 3, y: y + px * 3 + armSwing * 0.3, size: px, color: bodyColor.opacity(0.7))
        fillPx(context: context, x: x + px * 2, y: y + px * 3 - armSwing * 0.3, size: px, color: bodyColor.opacity(0.7))

        // Legs (row 6) - walk animation
        let legOffset: CGFloat = walkFrame == 0 ? px * 0.5 : -px * 0.5
        fillPx(context: context, x: x - px * 1.5 + legOffset, y: y + px * 6, size: px, color: bodyColor.opacity(0.6))
        fillPx(context: context, x: x + px * 0.5 - legOffset, y: y + px * 6, size: px, color: bodyColor.opacity(0.6))
    }

    private func fillPx(context: GraphicsContext, x: CGFloat, y: CGFloat, size: CGFloat, color: Color) {
        context.fill(
            Path(CGRect(x: x, y: y, width: size, height: size)),
            with: .color(color)
        )
    }
}
