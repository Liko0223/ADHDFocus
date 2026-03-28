import SwiftUI

/// Pixel art scene where the companion character lives
struct CompanionSceneView: View {
    let state: CompanionState
    let sceneWidth: CGFloat
    let sceneHeight: CGFloat = 120

    // Character movement
    @State private var characterX: CGFloat = 0.45
    @State private var walkDirection: CGFloat = 1
    @State private var walkTimer: Timer?
    @State private var isJumping: Bool = false
    @State private var jumpProgress: CGFloat = 0
    @State private var jumpTimer: Timer?

    // Blocked state flash
    @State private var blockedFlashActive: Bool = false
    @State private var blockedTimer: Timer?
    @State private var preBlockedState: CompanionState = .idle

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 16)) { timeline in
            Canvas { context, size in
                let px: CGFloat = 4

                let t = timeline.date.timeIntervalSinceReferenceDate

                // Draw scene background + elements
                switch state {
                case .idle:
                    drawIdleScene(context: context, size: size, px: px, t: t)
                case .working:
                    drawWorkingScene(context: context, size: size, px: px, t: t)
                case .resting:
                    drawRestingScene(context: context, size: size, px: px, t: t)
                case .blocked:
                    drawBlockedScene(context: context, size: size, px: px, t: t)
                }
            }
        }
        .frame(height: sceneHeight)
        .onAppear { startWalking() }
        .onDisappear {
            walkTimer?.invalidate()
            jumpTimer?.invalidate()
            blockedTimer?.invalidate()
        }
        .onChange(of: state) { newState in
            if newState == .blocked {
                startBlockedSequence()
            } else {
                blockedTimer?.invalidate()
                blockedFlashActive = false
                startWalking()
            }
        }
    }

    // MARK: - Scene: Idle (cozy nighttime park)

    private func drawIdleScene(context: GraphicsContext, size: CGSize, px: CGFloat, t: Double) {
        let groundY = size.height - 22

        // Night sky gradient
        let skyGrad = Gradient(colors: [
            Color(red: 0.04, green: 0.04, blue: 0.14),
            Color(red: 0.07, green: 0.06, blue: 0.22)
        ])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(skyGrad, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )

        // Moon
        let moonX = size.width * 0.82
        let moonY: CGFloat = 14
        context.fill(
            Path(ellipseIn: CGRect(x: moonX, y: moonY, width: px * 3, height: px * 3)),
            with: .color(Color(red: 0.95, green: 0.92, blue: 0.7))
        )
        // Moon glow
        context.fill(
            Path(ellipseIn: CGRect(x: moonX - px, y: moonY - px, width: px * 5, height: px * 5)),
            with: .color(Color(red: 0.95, green: 0.92, blue: 0.5).opacity(0.12))
        )

        // Stars (twinkling)
        let stars: [(CGFloat, CGFloat, Double)] = [
            (0.08, 0.12, 0.2), (0.18, 0.22, 0.8), (0.32, 0.07, 0.4),
            (0.44, 0.18, 1.1), (0.56, 0.08, 0.6), (0.65, 0.25, 0.3),
            (0.72, 0.14, 0.9), (0.52, 0.32, 1.5), (0.14, 0.38, 0.7),
            (0.38, 0.28, 0.1), (0.88, 0.20, 1.3), (0.76, 0.35, 0.5),
        ]
        for (nx, ny, phase) in stars {
            let twinkle = (sin(t * 1.8 + phase * 6.28) + 1) / 2 * 0.55 + 0.45
            let starSize = px * (nx.truncatingRemainder(dividingBy: 0.3) < 0.15 ? 0.7 : 0.5)
            context.fill(
                Path(CGRect(x: nx * size.width, y: ny * size.height, width: starSize, height: starSize)),
                with: .color(Color.white.opacity(twinkle * 0.85))
            )
        }

        // Dark ground
        context.fill(
            Path(CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)),
            with: .color(Color(red: 0.06, green: 0.14, blue: 0.08))
        )
        drawNightGrassTufts(context: context, size: size, groundY: groundY, px: px)

        // Bush left
        drawBush(context: context, x: size.width * 0.12, groundY: groundY, px: px)
        // Street lamp
        drawStreetLamp(context: context, x: size.width * 0.55, groundY: groundY, px: px, t: t)
        // Bench
        drawBench(context: context, x: size.width * 0.72, groundY: groundY, px: px)
        // Bush right
        drawBush(context: context, x: size.width * 0.90, groundY: groundY, px: px)

        // Fireflies
        drawFireflies(context: context, size: size, groundY: groundY, px: px, t: t)

        // Character
        let charX = characterX * (size.width - 48) + 24
        let bobAmt = sin(t * 1.4) * 1.2
        let charY = groundY - 32 + bobAmt
        drawCharacter(context: context, x: charX, y: charY, px: px,
                      state: state, facingRight: walkDirection > 0, t: t,
                      isJumping: isJumping, jumpProgress: jumpProgress)
    }

    // MARK: - Scene: Working (cozy workspace)

    private func drawWorkingScene(context: GraphicsContext, size: CGSize, px: CGFloat, t: Double) {
        let groundY = size.height - 22

        // Warm indoor background
        let bgGrad = Gradient(colors: [
            Color(red: 0.14, green: 0.10, blue: 0.08),
            Color(red: 0.18, green: 0.13, blue: 0.10)
        ])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(bgGrad, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )

        // Wall / floor distinction
        context.fill(
            Path(CGRect(x: 0, y: groundY - 2, width: size.width, height: 4)),
            with: .color(Color(red: 0.28, green: 0.20, blue: 0.14))
        )
        context.fill(
            Path(CGRect(x: 0, y: groundY + 2, width: size.width, height: size.height - groundY - 2)),
            with: .color(Color(red: 0.20, green: 0.14, blue: 0.10))
        )

        // Bookshelf (background left)
        drawBookshelf(context: context, x: size.width * 0.12, groundY: groundY, px: px, t: t)

        // Desk + monitor (right area)
        let deskX = size.width * 0.72
        drawWorkDesk(context: context, x: deskX, groundY: groundY, px: px, t: t)

        // Warm table lamp (right of desk)
        drawDeskLamp(context: context, x: deskX + px * 5, groundY: groundY, px: px, t: t)

        // Character sits near desk — typing animation
        let charX = deskX - px * 6
        let headBob = sin(t * 1.2) * 0.6
        let charY = groundY - 32 + headBob
        drawCharacter(context: context, x: charX, y: charY, px: px,
                      state: state, facingRight: true, t: t,
                      isJumping: false, jumpProgress: 0)

        // Typing hands animation (arms move up/down alternately)
        let typingFrame = Int(t * 6) % 2
        let leftHandY = charY + px * 5 + (typingFrame == 0 ? -px * 0.8 : px * 0.3)
        let rightHandY = charY + px * 5 + (typingFrame == 0 ? px * 0.3 : -px * 0.8)
        let handColor = Color(red: 0.98, green: 0.86, blue: 0.72).opacity(0.9)
        fillPx(context: context, x: charX + px * 2.5, y: leftHandY, size: px * 0.8, color: handColor)
        fillPx(context: context, x: charX + px * 4, y: rightHandY, size: px * 0.8, color: handColor)

        // Thinking dots near character
        drawThinkingDots(context: context, x: charX - px * 2, y: charY - px * 3, px: px, t: t)
    }

    // MARK: - Scene: Resting (bright garden)

    private func drawRestingScene(context: GraphicsContext, size: CGSize, px: CGFloat, t: Double) {
        let groundY = size.height - 22

        // Dawn/dusk sky
        let skyGrad = Gradient(colors: [
            Color(red: 0.38, green: 0.22, blue: 0.40),
            Color(red: 0.72, green: 0.42, blue: 0.28),
            Color(red: 0.95, green: 0.72, blue: 0.42)
        ])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(skyGrad, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )

        // Bright ground
        context.fill(
            Path(CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)),
            with: .color(Color(red: 0.22, green: 0.52, blue: 0.18))
        )
        drawBrightGrassTufts(context: context, size: size, groundY: groundY, px: px)

        // Trees
        drawBrightTree(context: context, x: size.width * 0.10, groundY: groundY, px: px, t: t)
        drawBrightTree(context: context, x: size.width * 0.88, groundY: groundY, px: px, t: t)

        // Picnic blanket
        drawPicnicBlanket(context: context, x: size.width * 0.70, groundY: groundY, px: px)

        // Flowers
        drawGardenFlowers(context: context, size: size, groundY: groundY, px: px, t: t)

        // Pixel cat companion
        drawPixelCat(context: context, x: size.width * 0.82, groundY: groundY, px: px, t: t)

        // Butterflies
        drawButterflies(context: context, size: size, groundY: groundY, px: px, t: t)

        // Character walks freely, bouncy
        let charX = characterX * (size.width - 48) + 24
        let jumpOffset: CGFloat = isJumping ? -sin(jumpProgress * .pi) * px * 4 : 0
        let bobAmt = sin(t * 2.2) * 1.8
        let charY = groundY - 32 + bobAmt + jumpOffset
        drawCharacter(context: context, x: charX, y: charY, px: px,
                      state: state, facingRight: walkDirection > 0, t: t,
                      isJumping: isJumping, jumpProgress: jumpProgress)
    }

    // MARK: - Scene: Blocked (storm warning)

    private func drawBlockedScene(context: GraphicsContext, size: CGSize, px: CGFloat, t: Double) {
        let groundY = size.height - 22

        // Stormy red sky
        let flashIntensity = max(0, sin(t * 12) * 0.5 + 0.2)
        let skyGrad = Gradient(colors: [
            Color(red: 0.22 + flashIntensity * 0.3, green: 0.04, blue: 0.04),
            Color(red: 0.14 + flashIntensity * 0.2, green: 0.05, blue: 0.08)
        ])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(skyGrad, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )

        // Lightning flash overlay
        let lightningFlash = max(0.0, sin(t * 7 + 1.2))
        if lightningFlash > 0.85 {
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(Color.white.opacity((lightningFlash - 0.85) * 2.5))
            )
        }

        // Dark stormy ground
        context.fill(
            Path(CGRect(x: 0, y: groundY, width: size.width, height: size.height - groundY)),
            with: .color(Color(red: 0.08, green: 0.06, blue: 0.04))
        )

        // Warning sign (blinking)
        let blink = sin(t * 6) > 0
        drawBlockedWarningSign(context: context, x: size.width * 0.72, groundY: groundY, px: px, blink: blink)

        // Character looks startled — trembles
        let tremble = sin(t * 22) * px * 0.6
        let charX = size.width * 0.35 + tremble
        let charY = groundY - 34
        drawCharacter(context: context, x: charX, y: charY, px: px,
                      state: state, facingRight: true, t: t,
                      isJumping: false, jumpProgress: 0)
    }

    // MARK: - Scene elements: Idle

    private func drawNightGrassTufts(context: GraphicsContext, size: CGSize, groundY: CGFloat, px: CGFloat) {
        let c1 = Color(red: 0.10, green: 0.26, blue: 0.10)
        let c2 = Color(red: 0.07, green: 0.18, blue: 0.07)
        for i in stride(from: CGFloat(0), to: size.width, by: px * 3.5) {
            let c = i.truncatingRemainder(dividingBy: px * 7) < px * 3.5 ? c1 : c2
            context.fill(Path(CGRect(x: i, y: groundY, width: px * 2, height: px)), with: .color(c))
        }
    }

    private func drawBush(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat) {
        let dark  = Color(red: 0.08, green: 0.22, blue: 0.09)
        let mid   = Color(red: 0.12, green: 0.30, blue: 0.12)
        let light = Color(red: 0.16, green: 0.38, blue: 0.14)
        // Bottom row
        context.fill(Path(CGRect(x: x - px * 3, y: groundY - px * 2, width: px * 6, height: px * 2)), with: .color(dark))
        // Middle
        context.fill(Path(CGRect(x: x - px * 2.5, y: groundY - px * 3.5, width: px * 5, height: px * 1.5)), with: .color(mid))
        // Top bumps
        context.fill(Path(ellipseIn: CGRect(x: x - px * 2, y: groundY - px * 5, width: px * 4, height: px * 2)), with: .color(mid))
        context.fill(Path(ellipseIn: CGRect(x: x - px * 3.5, y: groundY - px * 4, width: px * 3, height: px * 2)), with: .color(dark))
        context.fill(Path(ellipseIn: CGRect(x: x + px * 0.5, y: groundY - px * 4, width: px * 3, height: px * 2)), with: .color(light))
    }

    private func drawStreetLamp(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat, t: Double) {
        let post  = Color(red: 0.32, green: 0.30, blue: 0.36)
        let glow  = Color(red: 0.92, green: 0.78, blue: 0.38)
        let flick = 0.80 + sin(t * 2.2) * 0.10

        // Post
        context.fill(Path(CGRect(x: x - px * 0.5, y: groundY - px * 10, width: px, height: px * 10)), with: .color(post))
        // Arm
        context.fill(Path(CGRect(x: x - px * 2.5, y: groundY - px * 10, width: px * 3, height: px * 0.8)), with: .color(post))
        // Lamp cap
        context.fill(Path(CGRect(x: x - px * 2.5, y: groundY - px * 11, width: px * 3, height: px * 0.8)), with: .color(post))
        // Bulb
        context.fill(
            Path(ellipseIn: CGRect(x: x - px * 2, y: groundY - px * 10.5, width: px * 2, height: px * 1.2)),
            with: .color(glow.opacity(flick))
        )
        // Glow halo
        context.fill(
            Path(ellipseIn: CGRect(x: x - px * 5.5, y: groundY - px * 14, width: px * 8, height: px * 7)),
            with: .color(glow.opacity(0.07 * flick))
        )
        // Ground pool of light
        context.fill(
            Path(ellipseIn: CGRect(x: x - px * 4, y: groundY - px * 1.5, width: px * 7, height: px * 2)),
            with: .color(glow.opacity(0.06 * flick))
        )
    }

    private func drawBench(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat) {
        let wood = Color(red: 0.40, green: 0.26, blue: 0.12)
        let dark = Color(red: 0.30, green: 0.18, blue: 0.08)
        // Back rest
        context.fill(Path(CGRect(x: x - px * 4, y: groundY - px * 5.5, width: px * 8, height: px * 1)), with: .color(wood))
        // Seat
        context.fill(Path(CGRect(x: x - px * 4, y: groundY - px * 3.5, width: px * 8, height: px * 1.2)), with: .color(wood))
        // Legs
        context.fill(Path(CGRect(x: x - px * 3.5, y: groundY - px * 3.5, width: px * 0.8, height: px * 3.5)), with: .color(dark))
        context.fill(Path(CGRect(x: x + px * 2.7, y: groundY - px * 3.5, width: px * 0.8, height: px * 3.5)), with: .color(dark))
        // Back supports
        context.fill(Path(CGRect(x: x - px * 3.5, y: groundY - px * 5.5, width: px * 0.8, height: px * 2)), with: .color(dark))
        context.fill(Path(CGRect(x: x + px * 2.7, y: groundY - px * 5.5, width: px * 0.8, height: px * 2)), with: .color(dark))
    }

    private func drawFireflies(context: GraphicsContext, size: CGSize, groundY: CGFloat, px: CGFloat, t: Double) {
        let ffPositions: [(Double, Double, Double, Double)] = [
            (0.15, 0.6, 1.2, 0.5),
            (0.35, 0.5, 0.8, 1.1),
            (0.50, 0.7, 1.6, 0.3),
            (0.65, 0.55, 0.9, 0.8),
            (0.80, 0.65, 1.4, 0.1),
            (0.25, 0.75, 0.7, 1.4),
        ]
        for (bx, by, speed, phase) in ffPositions {
            let fx = CGFloat(bx) * size.width + CGFloat(sin(t * speed + phase * 6.28) * 14)
            let fy = CGFloat(by) * groundY  + CGFloat(cos(t * speed * 1.2 + phase) * 8)
            let bright = (sin(t * 3.5 + phase * 8) + 1) / 2
            if bright > 0.3 {
                context.fill(
                    Path(ellipseIn: CGRect(x: fx, y: fy, width: px * 0.8, height: px * 0.8)),
                    with: .color(Color(red: 0.88, green: 0.95, blue: 0.25).opacity(bright * 0.9))
                )
                // Small glow
                context.fill(
                    Path(ellipseIn: CGRect(x: fx - px * 0.6, y: fy - px * 0.6, width: px * 2, height: px * 2)),
                    with: .color(Color(red: 0.88, green: 0.95, blue: 0.25).opacity(bright * 0.15))
                )
            }
        }
    }

    // MARK: - Scene elements: Working

    private func drawBookshelf(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat, t: Double) {
        let shelf  = Color(red: 0.35, green: 0.22, blue: 0.12)
        let shelfW = px * 10

        // Side panels
        context.fill(Path(CGRect(x: x - px * 0.5, y: groundY - px * 15, width: px, height: px * 15)), with: .color(shelf))
        context.fill(Path(CGRect(x: x + shelfW - px * 0.5, y: groundY - px * 15, width: px, height: px * 15)), with: .color(shelf))

        // Three shelves
        for row in 0..<3 {
            let sy = groundY - px * CGFloat(row * 5 + 5)
            context.fill(Path(CGRect(x: x - px * 0.5, y: sy, width: shelfW + px, height: px * 0.8)), with: .color(shelf))
        }

        // Books on shelves
        let bookColors: [Color] = [
            Color(red: 0.7, green: 0.2, blue: 0.2),
            Color(red: 0.2, green: 0.5, blue: 0.7),
            Color(red: 0.6, green: 0.5, blue: 0.1),
            Color(red: 0.3, green: 0.6, blue: 0.3),
            Color(red: 0.55, green: 0.2, blue: 0.55),
            Color(red: 0.8, green: 0.45, blue: 0.15),
        ]
        for row in 0..<3 {
            let sy = groundY - px * CGFloat(row * 5 + 9)
            var bx = x + px * 0.5
            for bi in 0..<5 {
                let color = bookColors[(row * 3 + bi) % bookColors.count]
                let bw = px * (bi % 2 == 0 ? 1.6 : 1.2)
                context.fill(Path(CGRect(x: bx, y: sy, width: bw, height: px * 4)), with: .color(color))
                bx += bw + px * 0.3
                if bx > x + shelfW - px { break }
            }
        }
    }

    private func drawWorkDesk(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat, t: Double) {
        let wood  = Color(red: 0.42, green: 0.28, blue: 0.14)
        let dark  = Color(red: 0.28, green: 0.18, blue: 0.08)
        let scrBg = Color(red: 0.12, green: 0.25, blue: 0.42)
        let scrGl = Color(red: 0.22, green: 0.48, blue: 0.72)

        // Desk surface
        context.fill(Path(CGRect(x: x - px * 6, y: groundY - px * 4, width: px * 12, height: px * 1.5)), with: .color(wood))
        context.fill(Path(CGRect(x: x - px * 6, y: groundY - px * 4.8, width: px * 12, height: px * 0.8)), with: .color(wood.opacity(0.6)))
        // Legs
        context.fill(Path(CGRect(x: x - px * 5.5, y: groundY - px * 2.5, width: px * 1.2, height: px * 2.5)), with: .color(dark))
        context.fill(Path(CGRect(x: x + px * 4.3, y: groundY - px * 2.5, width: px * 1.2, height: px * 2.5)), with: .color(dark))

        // Monitor stand
        context.fill(Path(CGRect(x: x - px * 0.5, y: groundY - px * 6.5, width: px, height: px * 2.5)), with: .color(dark))
        context.fill(Path(CGRect(x: x - px * 2, y: groundY - px * 5, width: px * 4, height: px * 0.8)), with: .color(dark))

        // Monitor body
        context.fill(Path(CGRect(x: x - px * 4, y: groundY - px * 13, width: px * 8, height: px * 6.5)), with: .color(dark))
        // Screen
        let screenFlicker = 0.9 + sin(t * 60) * 0.02
        context.fill(Path(CGRect(x: x - px * 3.5, y: groundY - px * 12.5, width: px * 7, height: px * 5.5)), with: .color(scrBg.opacity(screenFlicker)))
        // Screen content lines (simulated code)
        for lineI in 0..<4 {
            let lineW = px * CGFloat([3.0, 5.0, 2.5, 4.0][lineI])
            context.fill(
                Path(CGRect(x: x - px * 3, y: groundY - px * CGFloat(12 - lineI), width: lineW, height: px * 0.5)),
                with: .color(scrGl.opacity(0.7))
            )
        }

        // Coffee cup on desk
        drawCoffeeCup(context: context, x: x - px * 4.5, groundY: groundY, px: px, t: t)
    }

    private func drawCoffeeCup(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat, t: Double) {
        let cupColor = Color(red: 0.80, green: 0.74, blue: 0.62)
        let coffeeBg = Color(red: 0.28, green: 0.16, blue: 0.08)

        // Cup body
        context.fill(Path(CGRect(x: x - px, y: groundY - px * 6, width: px * 2.5, height: px * 2)), with: .color(cupColor))
        // Coffee surface
        context.fill(Path(CGRect(x: x - px * 0.8, y: groundY - px * 6.2, width: px * 2.1, height: px * 0.6)), with: .color(coffeeBg))
        // Handle
        let handlePath = Path { p in
            p.addRect(CGRect(x: x + px * 1.5, y: groundY - px * 5.8, width: px * 0.8, height: px * 1.4))
        }
        context.fill(handlePath, with: .color(cupColor))
        context.fill(Path(CGRect(x: x + px * 1.5, y: groundY - px * 5.3, width: px * 0.5, height: px * 0.6)), with: .color(Color(red: 0.18, green: 0.12, blue: 0.08)))

        // Steam (3 rising pixels cycling)
        let steamCycle = t.truncatingRemainder(dividingBy: 1.2) / 1.2
        for si in 0..<3 {
            let progress = (steamCycle + Double(si) * 0.33).truncatingRemainder(dividingBy: 1.0)
            let sy = groundY - px * 6 - CGFloat(progress) * px * 5
            let sx = x + CGFloat(sin(progress * 3.14 + Double(si))) * px * 0.6
            let alpha = (1.0 - progress) * 0.5
            context.fill(
                Path(CGRect(x: sx, y: sy, width: px * 0.6, height: px * 0.6)),
                with: .color(Color.white.opacity(alpha))
            )
        }
    }

    private func drawDeskLamp(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat, t: Double) {
        let metal = Color(red: 0.55, green: 0.48, blue: 0.35)
        let glow  = Color(red: 0.98, green: 0.82, blue: 0.45)
        let flick = 0.85 + sin(t * 1.8) * 0.08

        // Base
        context.fill(Path(CGRect(x: x - px * 1.5, y: groundY - px * 5, width: px * 3, height: px * 0.8)), with: .color(metal))
        // Stem
        context.fill(Path(CGRect(x: x - px * 0.5, y: groundY - px * 8.5, width: px, height: px * 3.5)), with: .color(metal))
        // Head (angled)
        context.fill(Path(CGRect(x: x - px * 2.5, y: groundY - px * 9.5, width: px * 3, height: px * 1.2)), with: .color(metal))
        // Bulb glow
        context.fill(
            Path(ellipseIn: CGRect(x: x - px * 2, y: groundY - px * 9.2, width: px * 2, height: px * 0.8)),
            with: .color(glow.opacity(flick))
        )
        // Light cone on desk
        context.fill(
            Path(ellipseIn: CGRect(x: x - px * 4, y: groundY - px * 5.5, width: px * 6, height: px * 2)),
            with: .color(glow.opacity(0.10 * flick))
        )
    }

    private func drawThinkingDots(context: GraphicsContext, x: CGFloat, y: CGFloat, px: CGFloat, t: Double) {
        for di in 0..<3 {
            let phase = t * 2.5 + Double(di) * 0.6
            let bounce = -CGFloat(max(0, sin(phase))) * px * 1.5
            let dotAlpha = 0.5 + (sin(phase) + 1) / 2 * 0.5
            context.fill(
                Path(ellipseIn: CGRect(x: x + CGFloat(di) * px * 1.8, y: y + bounce, width: px, height: px)),
                with: .color(Color(red: 0.8, green: 0.72, blue: 0.98).opacity(dotAlpha))
            )
        }
    }

    // MARK: - Scene elements: Resting

    private func drawBrightGrassTufts(context: GraphicsContext, size: CGSize, groundY: CGFloat, px: CGFloat) {
        let c1 = Color(red: 0.28, green: 0.60, blue: 0.22)
        let c2 = Color(red: 0.22, green: 0.50, blue: 0.18)
        for i in stride(from: CGFloat(0), to: size.width, by: px * 3) {
            let c = i.truncatingRemainder(dividingBy: px * 6) < px * 3 ? c1 : c2
            context.fill(Path(CGRect(x: i, y: groundY, width: px * 2, height: px)), with: .color(c))
        }
    }

    private func drawBrightTree(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat, t: Double) {
        let trunk = Color(red: 0.42, green: 0.26, blue: 0.12)
        let l1 = Color(red: 0.20, green: 0.55, blue: 0.18)
        let l2 = Color(red: 0.30, green: 0.68, blue: 0.24)
        let l3 = Color(red: 0.15, green: 0.44, blue: 0.14)

        // Sway
        let sway = CGFloat(sin(t * 0.7 + (x / 100))) * px * 0.4

        context.fill(Path(CGRect(x: x - px, y: groundY - px * 7, width: px * 2, height: px * 7)), with: .color(trunk))
        let rows: [(CGFloat, CGFloat, CGFloat, Color)] = [
            (-5, groundY - px * 7, px * 10, l1),
            (-4, groundY - px * 10, px * 8, l2),
            (-3, groundY - px * 13, px * 6, l1),
            (-2, groundY - px * 15.5, px * 4, l3),
        ]
        for (_, ly, w, c) in rows {
            context.fill(Path(CGRect(x: x - w / 2 + sway, y: ly, width: w, height: px * 2.5)), with: .color(c))
        }
    }

    private func drawPicnicBlanket(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat) {
        let red   = Color(red: 0.82, green: 0.22, blue: 0.22)
        let white = Color(red: 0.95, green: 0.92, blue: 0.88)
        // Base
        context.fill(Path(CGRect(x: x - px * 5, y: groundY - px * 1.2, width: px * 10, height: px * 1.2)), with: .color(red))
        // Checkers
        for ci in 0..<5 {
            if ci % 2 == 0 {
                context.fill(Path(CGRect(x: x - px * 5 + CGFloat(ci) * px * 2, y: groundY - px * 1.2, width: px * 2, height: px * 0.6)), with: .color(white.opacity(0.4)))
            }
        }
    }

    private func drawGardenFlowers(context: GraphicsContext, size: CGSize, groundY: CGFloat, px: CGFloat, t: Double) {
        let positions: [(CGFloat, Color)] = [
            (0.28, Color(red: 0.95, green: 0.35, blue: 0.45)),
            (0.38, Color(red: 0.98, green: 0.78, blue: 0.22)),
            (0.48, Color(red: 0.62, green: 0.35, blue: 0.95)),
            (0.57, Color(red: 0.98, green: 0.48, blue: 0.65)),
            (0.62, Color(red: 0.35, green: 0.75, blue: 0.95)),
        ]
        let stem = Color(red: 0.20, green: 0.50, blue: 0.15)
        for (nx, color) in positions {
            let fx = nx * size.width
            let sway = CGFloat(sin(t * 1.8 + Double(nx) * 12)) * 1.8
            // Stem
            context.fill(Path(CGRect(x: fx, y: groundY - px * 3.5, width: px * 0.6, height: px * 3.5)), with: .color(stem))
            // Petals (4 directions)
            let hx = fx - px * 0.3 + sway
            let hy = groundY - px * 5
            context.fill(Path(ellipseIn: CGRect(x: hx - px * 0.8, y: hy - px * 0.3, width: px * 0.8, height: px * 0.8)), with: .color(color.opacity(0.8)))
            context.fill(Path(ellipseIn: CGRect(x: hx + px * 0.5, y: hy - px * 0.3, width: px * 0.8, height: px * 0.8)), with: .color(color.opacity(0.8)))
            context.fill(Path(ellipseIn: CGRect(x: hx + px * 0.1, y: hy - px * 1.1, width: px * 0.8, height: px * 0.8)), with: .color(color.opacity(0.8)))
            context.fill(Path(ellipseIn: CGRect(x: hx + px * 0.1, y: hy + px * 0.5, width: px * 0.8, height: px * 0.8)), with: .color(color.opacity(0.8)))
            // Center
            context.fill(Path(ellipseIn: CGRect(x: hx, y: hy - px * 0.2, width: px * 1.0, height: px * 1.0)), with: .color(.white.opacity(0.9)))
        }
    }

    private func drawPixelCat(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat, t: Double) {
        let body = Color(red: 0.80, green: 0.70, blue: 0.55)
        let dark = Color(red: 0.40, green: 0.30, blue: 0.22)
        let tailWag = CGFloat(sin(t * 2.2)) * px

        // Tail
        context.fill(Path(CGRect(x: x + px * 1.5 + tailWag, y: groundY - px * 3, width: px * 2.5, height: px * 0.8)), with: .color(body))
        context.fill(Path(CGRect(x: x + px * 3.5 + tailWag, y: groundY - px * 4.5, width: px * 1.5, height: px * 1.5)), with: .color(body))

        // Body
        context.fill(Path(CGRect(x: x - px * 1.5, y: groundY - px * 3.5, width: px * 4, height: px * 3)), with: .color(body))

        // Head
        context.fill(Path(ellipseIn: CGRect(x: x - px * 2.5, y: groundY - px * 7, width: px * 4, height: px * 3.5)), with: .color(body))

        // Ears
        context.fill(Path(CGRect(x: x - px * 2.2, y: groundY - px * 9, width: px * 1.2, height: px * 1.5)), with: .color(body))
        context.fill(Path(CGRect(x: x + px * 0.8, y: groundY - px * 9, width: px * 1.2, height: px * 1.5)), with: .color(body))
        // Ear inner
        context.fill(Path(CGRect(x: x - px * 2, y: groundY - px * 8.8, width: px * 0.8, height: px * 1.0)), with: .color(Color(red: 0.95, green: 0.7, blue: 0.7)))
        context.fill(Path(CGRect(x: x + px, y: groundY - px * 8.8, width: px * 0.8, height: px * 1.0)), with: .color(Color(red: 0.95, green: 0.7, blue: 0.7)))

        // Eyes (blinking)
        let blinkCycle = t.truncatingRemainder(dividingBy: 3.5)
        let eyeH: CGFloat = blinkCycle > 3.2 ? px * 0.25 : px * 0.7
        context.fill(Path(ellipseIn: CGRect(x: x - px * 1.8, y: groundY - px * 6.2, width: px * 0.7, height: eyeH)), with: .color(dark))
        context.fill(Path(ellipseIn: CGRect(x: x + px * 0.5, y: groundY - px * 6.2, width: px * 0.7, height: eyeH)), with: .color(dark))

        // Nose
        context.fill(Path(ellipseIn: CGRect(x: x - px * 0.6, y: groundY - px * 5.2, width: px * 0.7, height: px * 0.5)), with: .color(Color(red: 0.85, green: 0.45, blue: 0.45)))

        // Legs
        context.fill(Path(CGRect(x: x - px * 1.2, y: groundY - px * 0.8, width: px * 1.2, height: px)), with: .color(body))
        context.fill(Path(CGRect(x: x + px * 0.5, y: groundY - px * 0.8, width: px * 1.2, height: px)), with: .color(body))
    }

    private func drawButterflies(context: GraphicsContext, size: CGSize, groundY: CGFloat, px: CGFloat, t: Double) {
        let butterflies: [(Double, Double, Double, Color)] = [
            (0.20, 0.6, 0.6, Color(red: 0.95, green: 0.55, blue: 0.25)),
            (0.50, 0.5, 0.9, Color(red: 0.55, green: 0.25, blue: 0.95)),
            (0.75, 0.65, 0.7, Color(red: 0.25, green: 0.75, blue: 0.55)),
        ]
        for (bx, by, speed, color) in butterflies {
            // Curved path motion
            let fx = CGFloat(bx) * size.width + CGFloat(sin(t * speed) * 28)
            let fy = CGFloat(by) * groundY + CGFloat(cos(t * speed * 1.3) * 14)
            // Wing flutter
            let wingOpen = abs(sin(t * 6 * speed + bx * 3))
            let wingW = px * wingOpen * 2
            // Wings
            context.fill(Path(CGRect(x: fx - wingW - px * 0.3, y: fy - px * 0.5, width: wingW, height: px)), with: .color(color.opacity(0.8)))
            context.fill(Path(CGRect(x: fx + px * 0.3, y: fy - px * 0.5, width: wingW, height: px)), with: .color(color.opacity(0.8)))
            // Body
            context.fill(Path(CGRect(x: fx - px * 0.3, y: fy - px * 0.5, width: px * 0.6, height: px)), with: .color(color.opacity(0.9)))
        }
    }

    // MARK: - Scene elements: Blocked

    private func drawBlockedWarningSign(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat, blink: Bool) {
        let post = Color(red: 0.35, green: 0.28, blue: 0.22)
        let signFg = blink ? Color(red: 0.98, green: 0.18, blue: 0.18) : Color(red: 0.65, green: 0.12, blue: 0.12)
        let signBg = blink ? Color(red: 0.98, green: 0.82, blue: 0.12) : Color(red: 0.55, green: 0.45, blue: 0.08)

        // Post
        context.fill(Path(CGRect(x: x, y: groundY - px * 8, width: px, height: px * 8)), with: .color(post))

        // Triangle warning sign
        var tri = Path()
        tri.move(to: CGPoint(x: x + px * 0.5, y: groundY - px * 14))
        tri.addLine(to: CGPoint(x: x - px * 4, y: groundY - px * 8.5))
        tri.addLine(to: CGPoint(x: x + px * 5, y: groundY - px * 8.5))
        tri.closeSubpath()
        context.fill(tri, with: .color(signBg))

        // Border
        context.stroke(tri, with: .color(signFg), lineWidth: px * 0.4)

        // "!" mark
        context.fill(Path(CGRect(x: x + px * 0.2, y: groundY - px * 12.5, width: px * 0.8, height: px * 2)), with: .color(signFg))
        context.fill(Path(ellipseIn: CGRect(x: x + px * 0.15, y: groundY - px * 9.8, width: px * 0.9, height: px * 0.9)), with: .color(signFg))
    }

    // MARK: - Character

    private func drawCharacter(context: GraphicsContext, x: CGFloat, y: CGFloat, px: CGFloat,
                                state: CompanionState, facingRight: Bool, t: Double,
                                isJumping: Bool, jumpProgress: CGFloat) {
        let bodyColor: Color
        let skinColor = Color(red: 0.98, green: 0.86, blue: 0.72)

        switch state {
        case .idle, .working, .resting:
            bodyColor = Color(red: 0.28, green: 0.65, blue: 0.95)
        case .blocked:
            bodyColor = Color(red: 0.95, green: 0.28, blue: 0.28)
        }

        let walkFrame = Int(t * 5) % 2
        let dir: CGFloat = facingRight ? 1 : -1

        // Shadow
        let shadowOpacity = isJumping ? 0.12 : 0.28
        let shadowW: CGFloat = isJumping ? px * 5 : px * 6
        context.fill(
            Path(ellipseIn: CGRect(x: x - shadowW / 2, y: y + px * 8.2, width: shadowW, height: px * 1.2)),
            with: .color(Color.black.opacity(shadowOpacity))
        )

        // --- Head (round, 5x5 pixel grid with rounded corners) ---
        // Head base: 5px wide x 4px tall
        let headOffsets: [(Int, Int)] = [
            // Row 0 (top): cols 1..3 (leaving corners for round look)
            (1,0),(2,0),(3,0),
            // Row 1: full width
            (0,1),(1,1),(2,1),(3,1),(4,1),
            // Row 2: full width
            (0,2),(1,2),(2,2),(3,2),(4,2),
            // Row 3: cols 1..3
            (1,3),(2,3),(3,3),
        ]
        for (hcol, hrow) in headOffsets {
            fillPx(context: context,
                   x: x - px * 2 + CGFloat(hcol) * px,
                   y: y + CGFloat(hrow) * px,
                   size: px, color: skinColor)
        }

        // --- Eyes ---
        if state == .working {
            // ">" shaped focused eyes
            let eyeCol = Color(red: 0.18, green: 0.14, blue: 0.25)
            if facingRight {
                // Left eye >
                fillPx(context: context, x: x - px * 0.8, y: y + px, size: px * 0.6, color: eyeCol)
                fillPx(context: context, x: x - px * 0.4, y: y + px * 1.4, size: px * 0.5, color: eyeCol)
                // Right eye >
                fillPx(context: context, x: x + px * 0.6, y: y + px, size: px * 0.6, color: eyeCol)
                fillPx(context: context, x: x + px * 1.0, y: y + px * 1.4, size: px * 0.5, color: eyeCol)
            } else {
                fillPx(context: context, x: x - px * 1.4, y: y + px * 1.4, size: px * 0.5, color: eyeCol)
                fillPx(context: context, x: x - px * 1.0, y: y + px, size: px * 0.6, color: eyeCol)
                fillPx(context: context, x: x + px * 0.2, y: y + px * 1.4, size: px * 0.5, color: eyeCol)
                fillPx(context: context, x: x + px * 0.6, y: y + px, size: px * 0.6, color: eyeCol)
            }
        } else if state == .blocked {
            // Startled "O" eyes
            let eyeCol = Color(red: 0.15, green: 0.12, blue: 0.20)
            context.fill(Path(ellipseIn: CGRect(x: x - px * 1.1, y: y + px * 0.8, width: px * 0.9, height: px * 0.9)), with: .color(eyeCol))
            context.fill(Path(ellipseIn: CGRect(x: x + px * 0.5, y: y + px * 0.8, width: px * 0.9, height: px * 0.9)), with: .color(eyeCol))
        } else {
            // Normal happy dot eyes
            let eyeCol = Color(red: 0.18, green: 0.14, blue: 0.25)
            let blinkCycle = t.truncatingRemainder(dividingBy: 4.0)
            let eyeH: CGFloat = blinkCycle > 3.7 ? px * 0.2 : px * 0.7
            let eyeLX: CGFloat = facingRight ? x - px * 0.9 : x - px * 0.9
            let eyeRX: CGFloat = facingRight ? x + px * 0.5 : x + px * 0.5
            context.fill(Path(ellipseIn: CGRect(x: eyeLX, y: y + px * 0.9, width: px * 0.7, height: eyeH)), with: .color(eyeCol))
            context.fill(Path(ellipseIn: CGRect(x: eyeRX, y: y + px * 0.9, width: px * 0.7, height: eyeH)), with: .color(eyeCol))
            // Rosy cheeks for idle/resting
            if state == .idle || state == .resting {
                let rosy = Color(red: 0.95, green: 0.60, blue: 0.60).opacity(0.45)
                context.fill(Path(ellipseIn: CGRect(x: x - px * 1.7, y: y + px * 1.8, width: px * 1.0, height: px * 0.6)), with: .color(rosy))
                context.fill(Path(ellipseIn: CGRect(x: x + px * 0.7, y: y + px * 1.8, width: px * 1.0, height: px * 0.6)), with: .color(rosy))
            }
        }

        // --- Body ---
        // Outfit/shirt: 4 wide x 3 tall
        let shirtOffsets: [(Int, Int)] = [
            (0,0),(1,0),(2,0),(3,0),
            (0,1),(1,1),(2,1),(3,1),
            (0,2),(1,2),(2,2),(3,2),
        ]
        for (sc, sr) in shirtOffsets {
            fillPx(context: context,
                   x: x - px * 2 + CGFloat(sc) * px,
                   y: y + px * 4 + CGFloat(sr) * px,
                   size: px, color: bodyColor)
        }

        // --- Arms ---
        let typingBounce: CGFloat = (state == .working) ? (Int(t * 6) % 2 == 0 ? -px * 0.5 : px * 0.3) : 0
        let armSwingAmt: CGFloat = (state == .working) ? typingBounce : (walkFrame == 0 ? px * 0.6 : -px * 0.6)
        let armLY = y + px * 4 + armSwingAmt
        let armRY = y + px * 4 - armSwingAmt
        // Left arm
        fillPx(context: context, x: x - px * 3, y: armLY, size: px, color: bodyColor.opacity(0.85))
        fillPx(context: context, x: x - px * 3, y: armLY + px, size: px, color: skinColor.opacity(0.85))
        // Right arm
        fillPx(context: context, x: x + px * 2, y: armRY, size: px, color: bodyColor.opacity(0.85))
        fillPx(context: context, x: x + px * 2, y: armRY + px, size: px, color: skinColor.opacity(0.85))

        // --- Legs ---
        if state == .working {
            // Sitting: legs in front
            fillPx(context: context, x: x - px * 1.5, y: y + px * 7, size: px, color: bodyColor.opacity(0.75))
            fillPx(context: context, x: x - px * 1.5, y: y + px * 8, size: px, color: bodyColor.opacity(0.65))
            fillPx(context: context, x: x + px * 0.5, y: y + px * 7, size: px, color: bodyColor.opacity(0.75))
            fillPx(context: context, x: x + px * 0.5, y: y + px * 8, size: px, color: bodyColor.opacity(0.65))
        } else {
            // Walking legs
            let legL: CGFloat = walkFrame == 0 ? px * 0.7 : -px * 0.7
            let legR: CGFloat = -legL
            // Left leg
            fillPx(context: context, x: x - px * 1.5 + legL * 0.4, y: y + px * 7, size: px, color: bodyColor.opacity(0.75))
            fillPx(context: context, x: x - px * 1.5 + legL * 0.8, y: y + px * 8, size: px, color: bodyColor.opacity(0.65))
            // Right leg
            fillPx(context: context, x: x + px * 0.5 + legR * 0.4, y: y + px * 7, size: px, color: bodyColor.opacity(0.75))
            fillPx(context: context, x: x + px * 0.5 + legR * 0.8, y: y + px * 8, size: px, color: bodyColor.opacity(0.65))
        }
    }

    private func fillPx(context: GraphicsContext, x: CGFloat, y: CGFloat, size: CGFloat, color: Color) {
        context.fill(
            Path(CGRect(x: x, y: y, width: size, height: size)),
            with: .color(color)
        )
    }

    // MARK: - Character movement

    private func startWalking() {
        walkTimer?.invalidate()
        jumpTimer?.invalidate()
        isJumping = false

        let interval: TimeInterval
        switch state {
        case .working:
            interval = 0  // Character stays at desk
            characterX = 0.72
            walkDirection = 1
            return
        case .resting: interval = 1.0
        case .idle:    interval = 2.2
        case .blocked: interval = 0
        }

        walkTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            withAnimation(.easeInOut(duration: interval * 0.75)) {
                let step = CGFloat.random(in: 0.06...0.16)
                if characterX > 0.82 { walkDirection = -1 }
                else if characterX < 0.18 { walkDirection = 1 }
                else if Bool.random() { walkDirection *= -1 }
                characterX = max(0.12, min(0.88, characterX + step * walkDirection))
            }
        }

        // Occasional jumps for resting state
        if state == .resting {
            jumpTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { _ in
                if Bool.random(probability: 0.4) {
                    triggerJump()
                }
            }
        }
    }

    private func triggerJump() {
        guard !isJumping else { return }
        isJumping = true
        jumpProgress = 0
        let jumpDuration: TimeInterval = 0.5
        let steps = 20
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) / Double(steps) * jumpDuration) {
                jumpProgress = CGFloat(i) / CGFloat(steps)
                if i == steps { isJumping = false }
            }
        }
    }

    private func startBlockedSequence() {
        walkTimer?.invalidate()
        jumpTimer?.invalidate()
        blockedTimer?.invalidate()

        // Return to idle after 2.5 seconds
        blockedTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
            // State change is handled externally; just restart walking if still blocked
        }
    }
}

// MARK: - Bool random helper

extension Bool {
    static func random(probability: Double) -> Bool {
        return Double.random(in: 0...1) < probability
    }
}
