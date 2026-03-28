import SwiftUI

/// Pixel art scene where the companion character lives
struct CompanionSceneView: View {
    let state: CompanionState
    let sceneWidth: CGFloat
    let focusModeName: String?
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
                    drawWorkingSceneForMode(context: context, size: size, px: px, t: t)
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
        .onChange(of: state) { _, newState in
            if newState == .blocked {
                startBlockedSequence()
            } else {
                blockedTimer?.invalidate()
                blockedFlashActive = false
                startWalking()
            }
        }
    }

    // MARK: - Working scene dispatcher

    private func drawWorkingSceneForMode(context: GraphicsContext, size: CGSize, px: CGFloat, t: Double) {
        guard let name = focusModeName else {
            drawWorkingScene(context: context, size: size, px: px, t: t)
            return
        }
        if name.contains("设计") || name.lowercased().contains("design") {
            drawDesignStudioScene(context: context, size: size, px: px, t: t)
        } else if name.contains("调研") || name.contains("灵感") || name.lowercased().contains("research") {
            drawResearchLibraryScene(context: context, size: size, px: px, t: t)
        } else if name.contains("沟通") || name.contains("协作") || name.lowercased().contains("communicat") {
            drawCommunicationCafeScene(context: context, size: size, px: px, t: t)
        } else if name.contains("写作") || name.contains("整理") || name.lowercased().contains("writ") {
            drawWritersDeskScene(context: context, size: size, px: px, t: t)
        } else {
            drawWorkingScene(context: context, size: size, px: px, t: t)
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

        // Speech bubble
        drawSpeechBubble(context: context, x: charX, y: charY - px * 2, text: "Ready~ 💤", px: px, t: t)
    }

    // MARK: - Scene: Working (default cozy workspace)

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

        // Speech bubble
        drawSpeechBubble(context: context, x: charX, y: charY - px * 2, text: "Focusing 🎯", px: px, t: t)
    }

    // MARK: - Scene: Design Studio (深度设计)

    private func drawDesignStudioScene(context: GraphicsContext, size: CGSize, px: CGFloat, t: Double) {
        let groundY = size.height - 22

        // Warm amber background
        let bgGrad = Gradient(colors: [
            Color(red: 0.16, green: 0.10, blue: 0.06),
            Color(red: 0.22, green: 0.14, blue: 0.08)
        ])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(bgGrad, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )

        // Wall / floor
        context.fill(
            Path(CGRect(x: 0, y: groundY - 2, width: size.width, height: 4)),
            with: .color(Color(red: 0.32, green: 0.22, blue: 0.14))
        )
        context.fill(
            Path(CGRect(x: 0, y: groundY + 2, width: size.width, height: size.height - groundY - 2)),
            with: .color(Color(red: 0.24, green: 0.16, blue: 0.10))
        )

        // Color swatches on wall (left side, small colored squares)
        let swatchColors: [Color] = [
            Color(red: 0.90, green: 0.30, blue: 0.30),
            Color(red: 0.30, green: 0.70, blue: 0.90),
            Color(red: 0.95, green: 0.80, blue: 0.20),
            Color(red: 0.40, green: 0.80, blue: 0.45),
            Color(red: 0.75, green: 0.35, blue: 0.85),
            Color(red: 0.95, green: 0.55, blue: 0.25),
        ]
        for (i, sc) in swatchColors.enumerated() {
            let sx = size.width * 0.08 + CGFloat(i % 3) * px * 2.5
            let sy = groundY - px * 14 + CGFloat(i / 3) * px * 2.5
            fillPx(context: context, x: sx, y: sy, width: px * 2, height: px * 2, color: sc)
            fillPx(context: context, x: sx, y: sy, width: px * 2, height: px * 0.4, color: sc.opacity(0.5))
        }

        // Warm lamp (left wall)
        let lampX = size.width * 0.06
        let lampY = groundY - px * 11
        // Lamp bracket
        fillPx(context: context, x: lampX, y: lampY, width: px * 0.6, height: px * 3, color: Color(red: 0.55, green: 0.45, blue: 0.30))
        // Lamp shade
        fillPx(context: context, x: lampX - px, y: lampY - px * 1.5, width: px * 2.5, height: px * 1.5, color: Color(red: 0.85, green: 0.65, blue: 0.25))
        // Lamp glow
        context.fill(
            Path(ellipseIn: CGRect(x: lampX - px * 4, y: lampY - px * 3, width: px * 9, height: px * 8)),
            with: .color(Color(red: 0.98, green: 0.85, blue: 0.40).opacity(0.06 + sin(t * 1.5) * 0.02))
        )

        // Easel (right-center)
        let easelX = size.width * 0.68
        // Easel legs (A-frame)
        let legColor = Color(red: 0.45, green: 0.30, blue: 0.15)
        fillPx(context: context, x: easelX - px * 3, y: groundY - px * 12, width: px * 0.8, height: px * 12, color: legColor)
        fillPx(context: context, x: easelX + px * 2.5, y: groundY - px * 12, width: px * 0.8, height: px * 12, color: legColor)
        // Back leg
        fillPx(context: context, x: easelX + px * 4, y: groundY - px * 10, width: px * 0.6, height: px * 10, color: legColor.opacity(0.6))
        // Canvas shelf
        fillPx(context: context, x: easelX - px * 3, y: groundY - px * 5, width: px * 6.5, height: px * 0.8, color: legColor)

        // Canvas on easel
        let canvasColor = Color(red: 0.95, green: 0.92, blue: 0.85)
        fillPx(context: context, x: easelX - px * 2.5, y: groundY - px * 12, width: px * 5.5, height: px * 7, color: canvasColor)
        // Canvas border
        fillPx(context: context, x: easelX - px * 2.5, y: groundY - px * 12, width: px * 5.5, height: px * 0.4, color: Color(red: 0.60, green: 0.50, blue: 0.35))
        fillPx(context: context, x: easelX - px * 2.5, y: groundY - px * 5.4, width: px * 5.5, height: px * 0.4, color: Color(red: 0.60, green: 0.50, blue: 0.35))
        fillPx(context: context, x: easelX - px * 2.5, y: groundY - px * 12, width: px * 0.4, height: px * 7, color: Color(red: 0.60, green: 0.50, blue: 0.35))
        fillPx(context: context, x: easelX + px * 2.6, y: groundY - px * 12, width: px * 0.4, height: px * 7, color: Color(red: 0.60, green: 0.50, blue: 0.35))

        // Paint splatches on canvas (cycle through colors over time)
        let splatchPhase = Int(t * 0.3) % 4
        let splatchColors: [[Color]] = [
            [.red.opacity(0.6), .blue.opacity(0.5), .yellow.opacity(0.6)],
            [.purple.opacity(0.5), .orange.opacity(0.6), .green.opacity(0.5)],
            [.cyan.opacity(0.5), .pink.opacity(0.6), .yellow.opacity(0.5)],
            [.orange.opacity(0.6), .blue.opacity(0.5), .red.opacity(0.5)],
        ]
        let curSplatch = splatchColors[splatchPhase]
        // Splatch 1
        context.fill(
            Path(ellipseIn: CGRect(x: easelX - px * 1.5, y: groundY - px * 10.5, width: px * 2, height: px * 1.5)),
            with: .color(curSplatch[0])
        )
        // Splatch 2
        context.fill(
            Path(ellipseIn: CGRect(x: easelX + px * 0.5, y: groundY - px * 8.5, width: px * 1.5, height: px * 2)),
            with: .color(curSplatch[1])
        )
        // Splatch 3
        context.fill(
            Path(ellipseIn: CGRect(x: easelX - px * 0.5, y: groundY - px * 7.5, width: px * 2.5, height: px * 1.2)),
            with: .color(curSplatch[2])
        )

        // Paint palette on small table (left of easel)
        let tableX = easelX - px * 8
        // Small table
        fillPx(context: context, x: tableX - px * 2.5, y: groundY - px * 3.5, width: px * 5, height: px * 0.8, color: Color(red: 0.42, green: 0.28, blue: 0.14))
        fillPx(context: context, x: tableX - px * 2, y: groundY - px * 2.7, width: px * 0.8, height: px * 2.7, color: Color(red: 0.35, green: 0.22, blue: 0.10))
        fillPx(context: context, x: tableX + px * 1.2, y: groundY - px * 2.7, width: px * 0.8, height: px * 2.7, color: Color(red: 0.35, green: 0.22, blue: 0.10))
        // Palette (oval)
        context.fill(
            Path(ellipseIn: CGRect(x: tableX - px * 2, y: groundY - px * 5, width: px * 3.5, height: px * 1.5)),
            with: .color(Color(red: 0.78, green: 0.68, blue: 0.52))
        )
        // Paint dots on palette
        let paletteDots: [(CGFloat, CGFloat, Color)] = [
            (-1.2, -4.3, .red), (-0.2, -4.5, .blue), (0.6, -4.2, .yellow),
        ]
        for (dx, dy, c) in paletteDots {
            context.fill(
                Path(ellipseIn: CGRect(x: tableX + dx * px, y: groundY + dy * px, width: px * 0.6, height: px * 0.6)),
                with: .color(c.opacity(0.8))
            )
        }
        // Brushes (two thin lines standing up)
        fillPx(context: context, x: tableX + px * 1.5, y: groundY - px * 6.5, width: px * 0.3, height: px * 3, color: Color(red: 0.50, green: 0.35, blue: 0.18))
        fillPx(context: context, x: tableX + px * 2, y: groundY - px * 7, width: px * 0.3, height: px * 3.5, color: Color(red: 0.45, green: 0.30, blue: 0.15))
        // Brush tips
        fillPx(context: context, x: tableX + px * 1.4, y: groundY - px * 7, width: px * 0.5, height: px * 0.5, color: .red.opacity(0.7))
        fillPx(context: context, x: tableX + px * 1.9, y: groundY - px * 7.5, width: px * 0.5, height: px * 0.5, color: .blue.opacity(0.7))

        // Paint drops falling occasionally
        let dropCycle = t.truncatingRemainder(dividingBy: 2.5) / 2.5
        if dropCycle < 0.6 {
            let dropY = groundY - px * 5 + CGFloat(dropCycle) * px * 8
            let dropAlpha = 1.0 - dropCycle / 0.6
            let dropColor = curSplatch[Int(t) % curSplatch.count]
            context.fill(
                Path(CGRect(x: easelX - px * 0.2, y: dropY, width: px * 0.5, height: px * 0.8)),
                with: .color(dropColor.opacity(dropAlpha))
            )
        }

        // Character stands at easel, arm moves painting
        let charX = easelX - px * 5
        let headBob = sin(t * 1.0) * 0.5
        let charY = groundY - 32 + headBob
        drawCharacter(context: context, x: charX, y: charY, px: px,
                      state: state, facingRight: true, t: t,
                      isJumping: false, jumpProgress: 0)

        // Painting arm (moves up/down as if painting)
        let paintArmY = charY + px * 4 + sin(t * 2.5) * px * 1.5
        let armColor = Color(red: 0.28, green: 0.65, blue: 0.95).opacity(0.85)
        let handCol = Color(red: 0.98, green: 0.86, blue: 0.72).opacity(0.9)
        fillPx(context: context, x: charX + px * 2, y: paintArmY, width: px, height: px, color: armColor)
        fillPx(context: context, x: charX + px * 3, y: paintArmY - px * 0.3, width: px * 0.8, height: px * 0.8, color: handCol)

        // Speech bubble
        drawSpeechBubble(context: context, x: charX, y: charY - px * 2, text: "Designing ✨", px: px, t: t)
    }

    // MARK: - Scene: Research Library (调研灵感)

    private func drawResearchLibraryScene(context: GraphicsContext, size: CGSize, px: CGFloat, t: Double) {
        let groundY = size.height - 22

        // Warm dark library background
        let bgGrad = Gradient(colors: [
            Color(red: 0.10, green: 0.08, blue: 0.12),
            Color(red: 0.15, green: 0.12, blue: 0.16)
        ])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(bgGrad, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )

        // Floor
        context.fill(
            Path(CGRect(x: 0, y: groundY - 2, width: size.width, height: 4)),
            with: .color(Color(red: 0.30, green: 0.22, blue: 0.16))
        )
        context.fill(
            Path(CGRect(x: 0, y: groundY + 2, width: size.width, height: size.height - groundY - 2)),
            with: .color(Color(red: 0.22, green: 0.15, blue: 0.10))
        )

        // Left bookshelf (tall)
        drawTallBookshelf(context: context, x: size.width * 0.05, groundY: groundY, px: px, t: t)
        // Right bookshelf (tall)
        drawTallBookshelf(context: context, x: size.width * 0.82, groundY: groundY, px: px, t: t)

        // Small window with starlight (back wall center-right)
        let winX = size.width * 0.70
        let winY = groundY - px * 14
        fillPx(context: context, x: winX, y: winY, width: px * 3, height: px * 3, color: Color(red: 0.06, green: 0.06, blue: 0.18))
        // Window frame
        fillPx(context: context, x: winX - px * 0.3, y: winY - px * 0.3, width: px * 3.6, height: px * 0.3, color: Color(red: 0.50, green: 0.38, blue: 0.25))
        fillPx(context: context, x: winX - px * 0.3, y: winY + px * 3, width: px * 3.6, height: px * 0.3, color: Color(red: 0.50, green: 0.38, blue: 0.25))
        fillPx(context: context, x: winX - px * 0.3, y: winY - px * 0.3, width: px * 0.3, height: px * 3.6, color: Color(red: 0.50, green: 0.38, blue: 0.25))
        fillPx(context: context, x: winX + px * 3, y: winY - px * 0.3, width: px * 0.3, height: px * 3.6, color: Color(red: 0.50, green: 0.38, blue: 0.25))
        // Stars in window
        let winStarBright = (sin(t * 2.0) + 1) / 2 * 0.6 + 0.4
        fillPx(context: context, x: winX + px * 0.5, y: winY + px * 0.5, width: px * 0.4, height: px * 0.4, color: Color.white.opacity(winStarBright))
        fillPx(context: context, x: winX + px * 2.0, y: winY + px * 1.2, width: px * 0.3, height: px * 0.3, color: Color.white.opacity(winStarBright * 0.7))
        fillPx(context: context, x: winX + px * 1.2, y: winY + px * 2.2, width: px * 0.35, height: px * 0.35, color: Color.white.opacity(winStarBright * 0.8))

        // Comfy reading chair (center)
        let chairX = size.width * 0.45
        // Chair back
        fillPx(context: context, x: chairX - px * 3, y: groundY - px * 8, width: px * 6, height: px * 5, color: Color(red: 0.50, green: 0.22, blue: 0.18))
        // Chair cushion
        fillPx(context: context, x: chairX - px * 3.5, y: groundY - px * 3.5, width: px * 7, height: px * 2, color: Color(red: 0.58, green: 0.28, blue: 0.22))
        // Chair armrests
        fillPx(context: context, x: chairX - px * 4, y: groundY - px * 5, width: px * 1.2, height: px * 3.5, color: Color(red: 0.45, green: 0.20, blue: 0.15))
        fillPx(context: context, x: chairX + px * 2.8, y: groundY - px * 5, width: px * 1.2, height: px * 3.5, color: Color(red: 0.45, green: 0.20, blue: 0.15))
        // Chair legs
        fillPx(context: context, x: chairX - px * 3.5, y: groundY - px * 1.5, width: px * 0.8, height: px * 1.5, color: Color(red: 0.35, green: 0.18, blue: 0.10))
        fillPx(context: context, x: chairX + px * 2.7, y: groundY - px * 1.5, width: px * 0.8, height: px * 1.5, color: Color(red: 0.35, green: 0.18, blue: 0.10))

        // Floating magnifying glass (moves slowly around)
        let magX = size.width * 0.55 + CGFloat(sin(t * 0.6)) * px * 6
        let magY = groundY - px * 12 + CGFloat(cos(t * 0.45)) * px * 2
        // Glass circle
        context.stroke(
            Path(ellipseIn: CGRect(x: magX, y: magY, width: px * 2.5, height: px * 2.5)),
            with: .color(Color(red: 0.75, green: 0.65, blue: 0.50).opacity(0.5)),
            lineWidth: px * 0.4
        )
        // Handle
        fillPx(context: context, x: magX + px * 2, y: magY + px * 2, width: px * 1.5, height: px * 0.5, color: Color(red: 0.55, green: 0.40, blue: 0.25).opacity(0.5))

        // Lightbulb above character (blinks occasionally = inspiration)
        let bulbCycle = t.truncatingRemainder(dividingBy: 4.0)
        let bulbOn = bulbCycle > 3.0 && bulbCycle < 3.8
        let charX = chairX
        let charY = groundY - px * 3.5 - 32 + sin(t * 0.8) * 0.5

        if bulbOn {
            let bulbY = charY - px * 3
            // Bulb shape
            context.fill(
                Path(ellipseIn: CGRect(x: charX - px * 0.5, y: bulbY, width: px * 1.5, height: px * 1.5)),
                with: .color(Color(red: 0.98, green: 0.92, blue: 0.40))
            )
            // Glow
            context.fill(
                Path(ellipseIn: CGRect(x: charX - px * 2, y: bulbY - px, width: px * 4.5, height: px * 3.5)),
                with: .color(Color(red: 0.98, green: 0.92, blue: 0.40).opacity(0.12))
            )
            // Base
            fillPx(context: context, x: charX, y: bulbY + px * 1.3, width: px * 0.6, height: px * 0.5, color: Color(red: 0.60, green: 0.55, blue: 0.45))
        }

        // Character sitting in chair, turning pages
        drawCharacter(context: context, x: charX, y: charY, px: px,
                      state: state, facingRight: true, t: t,
                      isJumping: false, jumpProgress: 0)

        // Book in character's hands (small rectangle)
        let pageFlip = Int(t * 0.8) % 2
        let bookY = charY + px * 5
        fillPx(context: context, x: charX + px * 1.5, y: bookY, width: px * 2.5, height: px * 1.8, color: Color(red: 0.55, green: 0.22, blue: 0.18))
        // Page (flips)
        let pageX = charX + px * (pageFlip == 0 ? 2.0 : 2.8)
        fillPx(context: context, x: pageX, y: bookY + px * 0.2, width: px * 1, height: px * 1.4, color: Color(red: 0.92, green: 0.88, blue: 0.80))

        // Speech bubble
        drawSpeechBubble(context: context, x: charX, y: charY - px * 2, text: "Exploring 🔍", px: px, t: t)

        // Ambient warm glow from reading
        context.fill(
            Path(ellipseIn: CGRect(x: chairX - px * 6, y: groundY - px * 10, width: px * 12, height: px * 8)),
            with: .color(Color(red: 0.95, green: 0.80, blue: 0.45).opacity(0.04))
        )
    }

    // MARK: - Scene: Communication Cafe (沟通协作)

    private func drawCommunicationCafeScene(context: GraphicsContext, size: CGSize, px: CGFloat, t: Double) {
        let groundY = size.height - 22

        // Warm cozy cafe background
        let bgGrad = Gradient(colors: [
            Color(red: 0.16, green: 0.12, blue: 0.08),
            Color(red: 0.20, green: 0.15, blue: 0.10)
        ])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(bgGrad, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )

        // Floor
        context.fill(
            Path(CGRect(x: 0, y: groundY - 2, width: size.width, height: 4)),
            with: .color(Color(red: 0.30, green: 0.22, blue: 0.14))
        )
        context.fill(
            Path(CGRect(x: 0, y: groundY + 2, width: size.width, height: size.height - groundY - 2)),
            with: .color(Color(red: 0.22, green: 0.16, blue: 0.10))
        )

        // Hanging light above table
        let lightX = size.width * 0.50
        let lightY = groundY - px * 16
        // Wire
        fillPx(context: context, x: lightX, y: 0, width: px * 0.3, height: lightY - 0, color: Color(red: 0.35, green: 0.30, blue: 0.25))
        // Shade (trapezoid approximation with rects)
        fillPx(context: context, x: lightX - px * 1.5, y: lightY, width: px * 3.3, height: px * 1.5, color: Color(red: 0.72, green: 0.55, blue: 0.30))
        fillPx(context: context, x: lightX - px * 1, y: lightY - px * 0.5, width: px * 2.3, height: px * 0.5, color: Color(red: 0.65, green: 0.48, blue: 0.25))
        // Light glow
        let flickCafe = 0.85 + sin(t * 1.6) * 0.08
        context.fill(
            Path(ellipseIn: CGRect(x: lightX - px * 5, y: lightY, width: px * 10, height: px * 10)),
            with: .color(Color(red: 0.98, green: 0.82, blue: 0.45).opacity(0.08 * flickCafe))
        )
        // Bulb
        context.fill(
            Path(ellipseIn: CGRect(x: lightX - px * 0.4, y: lightY + px * 1, width: px * 1.2, height: px * 0.8)),
            with: .color(Color(red: 0.98, green: 0.90, blue: 0.55).opacity(flickCafe))
        )

        // Round table (center)
        let tableX = size.width * 0.50
        // Table top (ellipse)
        context.fill(
            Path(ellipseIn: CGRect(x: tableX - px * 4, y: groundY - px * 4.5, width: px * 8, height: px * 2)),
            with: .color(Color(red: 0.50, green: 0.35, blue: 0.20))
        )
        // Table leg
        fillPx(context: context, x: tableX - px * 0.5, y: groundY - px * 2.5, width: px, height: px * 2.5, color: Color(red: 0.40, green: 0.28, blue: 0.15))
        // Table base
        fillPx(context: context, x: tableX - px * 1.5, y: groundY - px * 0.5, width: px * 3, height: px * 0.5, color: Color(red: 0.40, green: 0.28, blue: 0.15))

        // Coffee cups on table (two)
        drawSmallCoffeeCup(context: context, x: tableX - px * 2, y: groundY - px * 5.5, px: px, t: t)
        drawSmallCoffeeCup(context: context, x: tableX + px * 1, y: groundY - px * 5.5, px: px, t: t)

        // Small phone/device on table
        fillPx(context: context, x: tableX - px * 0.5, y: groundY - px * 5.5, width: px * 1, height: px * 1.5, color: Color(red: 0.20, green: 0.20, blue: 0.25))
        fillPx(context: context, x: tableX - px * 0.3, y: groundY - px * 5.3, width: px * 0.6, height: px * 0.9, color: Color(red: 0.30, green: 0.45, blue: 0.60).opacity(0.7))

        // Chair left (where character sits)
        let chairLX = tableX - px * 6
        fillPx(context: context, x: chairLX - px * 1.5, y: groundY - px * 5, width: px * 3, height: px * 1, color: Color(red: 0.45, green: 0.30, blue: 0.18))
        fillPx(context: context, x: chairLX - px * 1.5, y: groundY - px * 7, width: px * 3, height: px * 0.8, color: Color(red: 0.40, green: 0.26, blue: 0.15))
        fillPx(context: context, x: chairLX - px * 1.2, y: groundY - px * 4, width: px * 0.6, height: px * 4, color: Color(red: 0.38, green: 0.24, blue: 0.12))
        fillPx(context: context, x: chairLX + px * 0.8, y: groundY - px * 4, width: px * 0.6, height: px * 4, color: Color(red: 0.38, green: 0.24, blue: 0.12))

        // Chair right (empty)
        let chairRX = tableX + px * 6
        fillPx(context: context, x: chairRX - px * 1.5, y: groundY - px * 5, width: px * 3, height: px * 1, color: Color(red: 0.45, green: 0.30, blue: 0.18))
        fillPx(context: context, x: chairRX - px * 1.5, y: groundY - px * 7, width: px * 3, height: px * 0.8, color: Color(red: 0.40, green: 0.26, blue: 0.15))
        fillPx(context: context, x: chairRX - px * 1.2, y: groundY - px * 4, width: px * 0.6, height: px * 4, color: Color(red: 0.38, green: 0.24, blue: 0.12))
        fillPx(context: context, x: chairRX + px * 0.8, y: groundY - px * 4, width: px * 0.6, height: px * 4, color: Color(red: 0.38, green: 0.24, blue: 0.12))

        // Speech bubbles floating up periodically
        let bubbles: [(Double, CGFloat, CGFloat)] = [
            (0.0, -px * 3, -px * 2),
            (1.5, px * 2, -px * 4),
            (3.0, -px * 1, -px * 6),
        ]
        for (phase, offX, offYBase) in bubbles {
            let bubbleCycle = (t + phase).truncatingRemainder(dividingBy: 4.0) / 4.0
            if bubbleCycle < 0.7 {
                let bx = chairLX + offX
                let by = groundY - px * 10 + offYBase - CGFloat(bubbleCycle) * px * 6
                let alpha = (1.0 - bubbleCycle / 0.7) * 0.6
                // Bubble bg
                context.fill(
                    Path(roundedRect: CGRect(x: bx, y: by, width: px * 3, height: px * 1.5),
                         cornerRadius: px * 0.4),
                    with: .color(Color.white.opacity(alpha))
                )
                // Dots inside bubble
                for di in 0..<3 {
                    context.fill(
                        Path(ellipseIn: CGRect(x: bx + px * 0.4 + CGFloat(di) * px * 0.7, y: by + px * 0.5, width: px * 0.4, height: px * 0.4)),
                        with: .color(Color(red: 0.40, green: 0.40, blue: 0.50).opacity(alpha))
                    )
                }
            }
        }

        // Character sits at table, animated talking
        let charX = chairLX
        let talkBob = sin(t * 3.0) * px * 0.3  // subtle body movement while talking
        let charY = groundY - px * 5 - 32 + talkBob
        drawCharacter(context: context, x: charX, y: charY, px: px,
                      state: state, facingRight: true, t: t,
                      isJumping: false, jumpProgress: 0)

        // Speech bubble
        drawSpeechBubble(context: context, x: charX, y: charY - px * 2, text: "Chatting 💬", px: px, t: t)
    }

    // MARK: - Scene: Writer's Desk (写作整理)

    private func drawWritersDeskScene(context: GraphicsContext, size: CGSize, px: CGFloat, t: Double) {
        let groundY = size.height - 22

        // Calm, cool-warm background
        let bgGrad = Gradient(colors: [
            Color(red: 0.12, green: 0.11, blue: 0.14),
            Color(red: 0.16, green: 0.14, blue: 0.16)
        ])
        context.fill(
            Path(CGRect(origin: .zero, size: size)),
            with: .linearGradient(bgGrad, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height))
        )

        // Floor
        context.fill(
            Path(CGRect(x: 0, y: groundY - 2, width: size.width, height: 4)),
            with: .color(Color(red: 0.26, green: 0.20, blue: 0.18))
        )
        context.fill(
            Path(CGRect(x: 0, y: groundY + 2, width: size.width, height: size.height - groundY - 2)),
            with: .color(Color(red: 0.20, green: 0.15, blue: 0.13))
        )

        // Small notes/papers pinned on wall behind
        let noteColors: [Color] = [
            Color(red: 0.95, green: 0.92, blue: 0.70),
            Color(red: 0.75, green: 0.88, blue: 0.95),
            Color(red: 0.95, green: 0.80, blue: 0.80),
            Color(red: 0.82, green: 0.95, blue: 0.80),
        ]
        let notePositions: [(CGFloat, CGFloat)] = [
            (0.25, 0.15), (0.35, 0.12), (0.45, 0.18), (0.32, 0.25),
        ]
        for (i, (nx, ny)) in notePositions.enumerated() {
            let noteX = nx * size.width
            let noteY = ny * size.height
            fillPx(context: context, x: noteX, y: noteY, width: px * 2, height: px * 2.5, color: noteColors[i % noteColors.count].opacity(0.5))
            // Pin dot
            fillPx(context: context, x: noteX + px * 0.7, y: noteY - px * 0.2, width: px * 0.5, height: px * 0.5, color: Color.red.opacity(0.6))
        }

        // Clean writing desk (center-right)
        let deskX = size.width * 0.60
        // Desk surface
        fillPx(context: context, x: deskX - px * 7, y: groundY - px * 4, width: px * 14, height: px * 1.5, color: Color(red: 0.55, green: 0.42, blue: 0.28))
        fillPx(context: context, x: deskX - px * 7, y: groundY - px * 4.5, width: px * 14, height: px * 0.5, color: Color(red: 0.48, green: 0.36, blue: 0.22))
        // Desk legs
        fillPx(context: context, x: deskX - px * 6.5, y: groundY - px * 2.5, width: px * 1, height: px * 2.5, color: Color(red: 0.40, green: 0.28, blue: 0.15))
        fillPx(context: context, x: deskX + px * 5.5, y: groundY - px * 2.5, width: px * 1, height: px * 2.5, color: Color(red: 0.40, green: 0.28, blue: 0.15))

        // Stack of papers/notebook on desk
        let stackX = deskX + px * 2
        for si in 0..<3 {
            let soy = CGFloat(si) * px * 0.4
            fillPx(context: context, x: stackX - px * 0.2 + CGFloat(si) * px * 0.1, y: groundY - px * 5 - soy, width: px * 2.5, height: px * 0.4, color: Color(red: 0.92, green: 0.88, blue: 0.80).opacity(0.9 - Double(si) * 0.1))
        }

        // Notebook open on desk
        let nbX = deskX - px * 2
        fillPx(context: context, x: nbX, y: groundY - px * 5.5, width: px * 3.5, height: px * 1.5, color: Color(red: 0.90, green: 0.86, blue: 0.78))
        // Lines on notebook
        for li in 0..<3 {
            fillPx(context: context, x: nbX + px * 0.3, y: groundY - px * 5.3 + CGFloat(li) * px * 0.4, width: px * 2.8, height: px * 0.15, color: Color(red: 0.60, green: 0.55, blue: 0.50).opacity(0.3))
        }

        // Pen/pencil writing on notebook (moves)
        let penAngle = sin(t * 2.0) * px * 0.8
        let penX = nbX + px * 1.5 + penAngle
        let penY = groundY - px * 5.8
        // Pencil body
        fillPx(context: context, x: penX, y: penY - px * 2, width: px * 0.3, height: px * 2.5, color: Color(red: 0.85, green: 0.72, blue: 0.20))
        // Pencil tip
        fillPx(context: context, x: penX, y: penY + px * 0.3, width: px * 0.3, height: px * 0.3, color: Color(red: 0.25, green: 0.22, blue: 0.20))

        // Cup of tea with steam
        let teaX = deskX + px * 5
        // Cup
        fillPx(context: context, x: teaX, y: groundY - px * 6, width: px * 2, height: px * 2, color: Color(red: 0.85, green: 0.82, blue: 0.75))
        // Tea surface
        fillPx(context: context, x: teaX + px * 0.15, y: groundY - px * 6.1, width: px * 1.7, height: px * 0.4, color: Color(red: 0.55, green: 0.70, blue: 0.45))
        // Steam
        for si in 0..<2 {
            let progress = (t * 0.8 + Double(si) * 0.5).truncatingRemainder(dividingBy: 1.0)
            let sy = groundY - px * 6 - CGFloat(progress) * px * 4
            let sx = teaX + px * 0.8 + CGFloat(sin(progress * 3.14 + Double(si))) * px * 0.4
            let alpha = (1.0 - progress) * 0.4
            context.fill(
                Path(CGRect(x: sx, y: sy, width: px * 0.4, height: px * 0.4)),
                with: .color(Color.white.opacity(alpha))
            )
        }

        // Small plant on desk (right end)
        let plantX = deskX - px * 5.5
        // Pot
        fillPx(context: context, x: plantX, y: groundY - px * 5.5, width: px * 1.8, height: px * 1.5, color: Color(red: 0.70, green: 0.42, blue: 0.25))
        // Leaves
        context.fill(
            Path(ellipseIn: CGRect(x: plantX - px * 0.3, y: groundY - px * 7.5, width: px * 2.4, height: px * 2)),
            with: .color(Color(red: 0.30, green: 0.62, blue: 0.28))
        )
        context.fill(
            Path(ellipseIn: CGRect(x: plantX + px * 0.2, y: groundY - px * 8.5, width: px * 1.5, height: px * 1.5)),
            with: .color(Color(red: 0.25, green: 0.55, blue: 0.24))
        )
        // Stem
        fillPx(context: context, x: plantX + px * 0.7, y: groundY - px * 6, width: px * 0.3, height: px * 1.5, color: Color(red: 0.25, green: 0.50, blue: 0.22))

        // Completed page floating to the side occasionally
        let pageCycle = t.truncatingRemainder(dividingBy: 5.0) / 5.0
        if pageCycle > 0.6 && pageCycle < 0.95 {
            let pageProgress = (pageCycle - 0.6) / 0.35
            let pageX = deskX - px * 2 + CGFloat(pageProgress) * px * 12
            let pageY = groundY - px * 8 - CGFloat(sin(pageProgress * .pi)) * px * 6
            let pageAlpha = 1.0 - pageProgress * 0.8
            // Floating page
            fillPx(context: context, x: pageX, y: pageY, width: px * 2, height: px * 2.5, color: Color(red: 0.92, green: 0.88, blue: 0.80).opacity(pageAlpha))
            // Text lines on page
            fillPx(context: context, x: pageX + px * 0.2, y: pageY + px * 0.5, width: px * 1.5, height: px * 0.15, color: Color(red: 0.50, green: 0.45, blue: 0.40).opacity(pageAlpha * 0.5))
            fillPx(context: context, x: pageX + px * 0.2, y: pageY + px * 1.0, width: px * 1.2, height: px * 0.15, color: Color(red: 0.50, green: 0.45, blue: 0.40).opacity(pageAlpha * 0.5))
        }

        // Character hunched over desk, hand moves writing
        let charX = deskX - px * 3
        let headBob = sin(t * 0.9) * 0.4
        let charY = groundY - 32 + headBob
        drawCharacter(context: context, x: charX, y: charY, px: px,
                      state: state, facingRight: true, t: t,
                      isJumping: false, jumpProgress: 0)

        // Writing hand animation
        let writeHandX = charX + px * 2.5 + sin(t * 2.0) * px * 0.5
        let writeHandY = charY + px * 5
        let handCol = Color(red: 0.98, green: 0.86, blue: 0.72).opacity(0.9)
        fillPx(context: context, x: writeHandX, y: writeHandY, width: px * 0.8, height: px * 0.8, color: handCol)

        // Speech bubble
        drawSpeechBubble(context: context, x: charX, y: charY - px * 2, text: "Writing ✍️", px: px, t: t)
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

    private func drawTallBookshelf(context: GraphicsContext, x: CGFloat, groundY: CGFloat, px: CGFloat, t: Double) {
        let shelf  = Color(red: 0.38, green: 0.25, blue: 0.14)
        let shelfW = px * 8

        // Side panels (taller)
        context.fill(Path(CGRect(x: x, y: groundY - px * 16, width: px * 0.8, height: px * 16)), with: .color(shelf))
        context.fill(Path(CGRect(x: x + shelfW, y: groundY - px * 16, width: px * 0.8, height: px * 16)), with: .color(shelf))
        // Top
        context.fill(Path(CGRect(x: x, y: groundY - px * 16, width: shelfW + px * 0.8, height: px * 0.8)), with: .color(shelf))

        // Four shelves
        for row in 0..<4 {
            let sy = groundY - px * CGFloat(row * 4 + 4)
            context.fill(Path(CGRect(x: x, y: sy, width: shelfW + px * 0.8, height: px * 0.6)), with: .color(shelf))
        }

        // Books (colorful spines)
        let bookColors: [Color] = [
            Color(red: 0.75, green: 0.22, blue: 0.22),
            Color(red: 0.22, green: 0.55, blue: 0.75),
            Color(red: 0.65, green: 0.55, blue: 0.15),
            Color(red: 0.35, green: 0.65, blue: 0.35),
            Color(red: 0.60, green: 0.25, blue: 0.60),
            Color(red: 0.82, green: 0.50, blue: 0.18),
            Color(red: 0.25, green: 0.60, blue: 0.55),
        ]
        for row in 0..<4 {
            let sy = groundY - px * (CGFloat(row * 4) + 7.5)
            var bx = x + px * 1
            for bi in 0..<4 {
                let color = bookColors[(row * 4 + bi) % bookColors.count]
                let bw = px * (bi % 3 == 0 ? 1.5 : 1.0)
                let bh = px * CGFloat([3.0, 3.2, 2.8, 3.5][bi % 4])
                context.fill(Path(CGRect(x: bx, y: sy + (px * 3.5 - bh), width: bw, height: bh)), with: .color(color))
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

    private func drawSmallCoffeeCup(context: GraphicsContext, x: CGFloat, y: CGFloat, px: CGFloat, t: Double) {
        let cupColor = Color(red: 0.82, green: 0.76, blue: 0.65)
        // Cup body
        fillPx(context: context, x: x, y: y, width: px * 1.5, height: px * 1.2, color: cupColor)
        // Coffee surface
        fillPx(context: context, x: x + px * 0.1, y: y - px * 0.1, width: px * 1.3, height: px * 0.3, color: Color(red: 0.30, green: 0.18, blue: 0.10))
        // Handle
        fillPx(context: context, x: x + px * 1.5, y: y + px * 0.2, width: px * 0.4, height: px * 0.7, color: cupColor)
        // Steam
        let steamPhase = t.truncatingRemainder(dividingBy: 1.0)
        let sy = y - CGFloat(steamPhase) * px * 2.5
        let alpha = (1.0 - steamPhase) * 0.35
        context.fill(
            Path(CGRect(x: x + px * 0.5 + CGFloat(sin(steamPhase * 3.14)) * px * 0.3, y: sy, width: px * 0.35, height: px * 0.35)),
            with: .color(Color.white.opacity(alpha))
        )
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

    // MARK: - Speech bubble

    private func drawSpeechBubble(context: GraphicsContext, x: CGFloat, y: CGFloat, text: String, px: CGFloat, t: Double) {
        // Gentle float animation
        let floatY = y + sin(t * 1.5) * 1.5

        let textWidth = CGFloat(text.count) * px * 1.6 + px * 3
        let bubbleH = px * 4
        let bubbleX = x - textWidth / 2
        let bubbleY = floatY - bubbleH

        // Bubble background (rounded rect)
        let bubbleRect = CGRect(x: bubbleX, y: bubbleY, width: textWidth, height: bubbleH)
        context.fill(
            Path(roundedRect: bubbleRect, cornerRadius: px),
            with: .color(.white.opacity(0.92))
        )

        // Tail (small triangle pointing down)
        var tail = Path()
        tail.move(to: CGPoint(x: x - px, y: bubbleY + bubbleH))
        tail.addLine(to: CGPoint(x: x, y: bubbleY + bubbleH + px * 1.5))
        tail.addLine(to: CGPoint(x: x + px, y: bubbleY + bubbleH))
        tail.closeSubpath()
        context.fill(tail, with: .color(.white.opacity(0.92)))

        // Text
        let resolvedText = context.resolve(
            Text(text)
                .font(.system(size: px * 2.2, weight: .medium, design: .rounded))
                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
        )
        context.draw(resolvedText, at: CGPoint(x: x, y: bubbleY + bubbleH / 2), anchor: .center)
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

    // MARK: - Cat Character

    private func drawCharacter(context: GraphicsContext, x: CGFloat, y: CGFloat, px: CGFloat,
                                state: CompanionState, facingRight: Bool, t: Double,
                                isJumping: Bool, jumpProgress: CGFloat) {
        let furColor = Color(red: 0.95, green: 0.65, blue: 0.25) // orange tabby
        let darkFur = Color(red: 0.75, green: 0.45, blue: 0.15)
        let white = Color(red: 0.98, green: 0.96, blue: 0.92)
        let eyeCol = Color(red: 0.15, green: 0.15, blue: 0.20)
        let noseCol = Color(red: 0.90, green: 0.55, blue: 0.55)
        let walkFrame = Int(t * 5) % 2

        // Shadow
        let shadowOp = isJumping ? 0.12 : 0.25
        let shadowW: CGFloat = isJumping ? px * 5 : px * 7
        context.fill(
            Path(ellipseIn: CGRect(x: x - shadowW / 2, y: y + px * 8, width: shadowW, height: px * 1.2)),
            with: .color(Color.black.opacity(shadowOp))
        )

        // Ears
        fillPx(context: context, x: x - px * 2.5, y: y - px * 0.5, size: px, color: furColor)
        fillPx(context: context, x: x - px * 1.5, y: y - px * 0.5, size: px, color: furColor)
        fillPx(context: context, x: x + px * 0.5, y: y - px * 0.5, size: px, color: furColor)
        fillPx(context: context, x: x + px * 1.5, y: y - px * 0.5, size: px, color: furColor)
        // Inner ears
        fillPx(context: context, x: x - px * 2, y: y, width: px * 0.6, height: px * 0.5, color: noseCol.opacity(0.4))
        fillPx(context: context, x: x + px * 1, y: y, width: px * 0.6, height: px * 0.5, color: noseCol.opacity(0.4))

        // Head (5 wide, 3 tall)
        for row in 0..<3 {
            for col in 0..<5 {
                fillPx(context: context, x: x - px * 2.5 + CGFloat(col) * px, y: y + px * 0.5 + CGFloat(row) * px, size: px, color: furColor)
            }
        }

        // White muzzle
        fillPx(context: context, x: x - px * 1, y: y + px * 2, width: px * 2, height: px * 1.2, color: white)

        // Eyes
        let blinkCycle = t.truncatingRemainder(dividingBy: 3.5)
        if state == .working {
            // Half-closed focused eyes
            fillPx(context: context, x: x - px * 1.5, y: y + px * 1.2, width: px * 0.8, height: px * 0.3, color: eyeCol)
            fillPx(context: context, x: x + px * 0.7, y: y + px * 1.2, width: px * 0.8, height: px * 0.3, color: eyeCol)
        } else if state == .blocked {
            // Wide startled eyes
            context.fill(Path(ellipseIn: CGRect(x: x - px * 1.6, y: y + px * 0.9, width: px, height: px)), with: .color(eyeCol))
            context.fill(Path(ellipseIn: CGRect(x: x + px * 0.6, y: y + px * 0.9, width: px, height: px)), with: .color(eyeCol))
        } else {
            let eyeH: CGFloat = blinkCycle > 3.2 ? px * 0.15 : px * 0.7
            context.fill(Path(ellipseIn: CGRect(x: x - px * 1.5, y: y + px * 1, width: px * 0.8, height: eyeH)), with: .color(eyeCol))
            context.fill(Path(ellipseIn: CGRect(x: x + px * 0.7, y: y + px * 1, width: px * 0.8, height: eyeH)), with: .color(eyeCol))
        }

        // Nose
        fillPx(context: context, x: x - px * 0.3, y: y + px * 2, width: px * 0.6, height: px * 0.4, color: noseCol)

        // Whiskers
        fillPx(context: context, x: x - px * 2.5, y: y + px * 2.3, width: px * 0.8, height: px * 0.15, color: darkFur.opacity(0.3))
        fillPx(context: context, x: x + px * 1.7, y: y + px * 2.3, width: px * 0.8, height: px * 0.15, color: darkFur.opacity(0.3))

        // Body (4 wide, 3 tall)
        let bodyY = y + px * 3.5
        for row in 0..<3 {
            for col in 0..<4 {
                fillPx(context: context, x: x - px * 2 + CGFloat(col) * px, y: bodyY + CGFloat(row) * px, size: px, color: furColor)
            }
        }
        // Belly
        fillPx(context: context, x: x - px * 0.5, y: bodyY + px * 0.5, width: px, height: px * 2, color: white.opacity(0.7))

        // Paws
        let pawY = bodyY + px * 3
        if state == .working {
            // Sitting paws
            fillPx(context: context, x: x - px * 1.5, y: pawY, size: px, color: white)
            fillPx(context: context, x: x + px * 0.5, y: pawY, size: px, color: white)
        } else {
            // Walking paws
            let legOff: CGFloat = walkFrame == 0 ? px * 0.5 : -px * 0.5
            fillPx(context: context, x: x - px * 1.5 + legOff, y: pawY, size: px, color: white)
            fillPx(context: context, x: x + px * 0.5 - legOff, y: pawY, size: px, color: white)
        }

        // Tail — animated wave
        let tailDir: CGFloat = facingRight ? 1 : -1
        let tailWave = sin(t * 3) * px * 0.8
        fillPx(context: context, x: x + px * 2 * tailDir, y: bodyY + px + tailWave, size: px, color: furColor)
        fillPx(context: context, x: x + px * 3 * tailDir, y: bodyY + px * 0.5 + tailWave * 0.5, size: px, color: darkFur)
    }

    private func fillPx(context: GraphicsContext, x: CGFloat, y: CGFloat, size: CGFloat, color: Color) {
        context.fill(
            Path(CGRect(x: x, y: y, width: size, height: size)),
            with: .color(color)
        )
    }

    private func fillPx(context: GraphicsContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: Color) {
        context.fill(
            Path(CGRect(x: x, y: y, width: width, height: height)),
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
