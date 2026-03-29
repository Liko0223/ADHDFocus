import SwiftUI

extension Notification.Name {
    static let triggerCelebration = Notification.Name("triggerCelebration")
}

enum ParticleShape: CaseIterable {
    case circle, square, star
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
    var rotation: Double
    var rotationSpeed: Double
    var shape: ParticleShape
}

struct CelebrationView: View {
    @State private var particles: [Particle] = []
    @State private var isActive = false
    @State private var startTime: Date?
    private let duration: Double = 2.5
    private let fadeStart: Double = 2.0

    private static let colors: [Color] = [
        Color(red: 1.0, green: 0.84, blue: 0.0),   // gold
        Color(red: 0.6, green: 0.4, blue: 1.0),     // purple
        Color(red: 0.3, green: 0.7, blue: 1.0),     // blue
        Color(red: 1.0, green: 0.5, blue: 0.7),     // pink
        Color(red: 0.3, green: 0.9, blue: 0.5),     // green
        Color(red: 1.0, green: 0.6, blue: 0.2),     // orange
    ]

    var body: some View {
        Group {
            if isActive {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        guard let start = startTime else { return }
                        let elapsed = timeline.date.timeIntervalSince(start)
                        let gravity: CGFloat = 400

                        let globalOpacity: Double
                        if elapsed > fadeStart {
                            globalOpacity = max(0, 1.0 - (elapsed - fadeStart) / (duration - fadeStart))
                        } else {
                            globalOpacity = 1.0
                        }

                        for particle in particles {
                            let t = CGFloat(elapsed)
                            let px = size.width / 2 + particle.x + particle.vx * t
                            let py = size.height / 2 + particle.y + particle.vy * t + 0.5 * gravity * t * t
                            let rot = Angle.degrees(particle.rotation + particle.rotationSpeed * elapsed)
                            let alpha = particle.opacity * globalOpacity

                            guard alpha > 0.01 else { continue }

                            var particleContext = context
                            particleContext.translateBy(x: px, y: py)
                            particleContext.rotate(by: rot)
                            particleContext.opacity = alpha

                            let s = particle.size
                            let rect = CGRect(x: -s / 2, y: -s / 2, width: s, height: s)

                            switch particle.shape {
                            case .circle:
                                particleContext.fill(
                                    Path(ellipseIn: rect),
                                    with: .color(particle.color)
                                )
                            case .square:
                                particleContext.fill(
                                    Path(rect),
                                    with: .color(particle.color)
                                )
                            case .star:
                                particleContext.fill(
                                    starPath(in: rect),
                                    with: .color(particle.color)
                                )
                            }
                        }

                        if elapsed >= duration {
                            DispatchQueue.main.async {
                                isActive = false
                                particles = []
                                startTime = nil
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .triggerCelebration)) { _ in
            trigger()
        }
    }

    private func trigger() {
        var newParticles: [Particle] = []
        let count = Int.random(in: 55...75)

        for _ in 0..<count {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 200...600)
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed * 0.7 - CGFloat.random(in: 200...400) // bias upward

            newParticles.append(Particle(
                x: CGFloat.random(in: -5...5),
                y: CGFloat.random(in: -5...5),
                vx: vx,
                vy: vy,
                size: CGFloat.random(in: 3...7),
                color: Self.colors.randomElement()!,
                opacity: Double.random(in: 0.7...1.0),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -360...360),
                shape: ParticleShape.allCases.randomElement()!
            ))
        }

        particles = newParticles
        startTime = Date()
        isActive = true
    }

    private func starPath(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outerRadius = min(rect.width, rect.height) / 2
        let innerRadius = outerRadius * 0.4
        let points = 5

        var path = Path()
        for i in 0..<(points * 2) {
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let radius = i.isMultiple(of: 2) ? outerRadius : innerRadius
            let point = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        path.closeSubpath()
        return path
    }
}
