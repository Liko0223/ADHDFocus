import SwiftUI

extension Notification.Name {
    static let triggerCelebration = Notification.Name("triggerCelebration")
}

struct CelebrationView: View {
    @State private var confetti: [ConfettiPiece] = []
    @State private var isActive = false

    private static let colors: [Color] = [
        Color(red: 1.0, green: 0.84, blue: 0.0),
        Color(red: 0.6, green: 0.4, blue: 1.0),
        Color(red: 0.3, green: 0.7, blue: 1.0),
        Color(red: 1.0, green: 0.5, blue: 0.7),
        Color(red: 0.3, green: 0.9, blue: 0.5),
        Color(red: 1.0, green: 0.6, blue: 0.2),
    ]

    var body: some View {
        GeometryReader { geo in
            if isActive {
                ZStack {
                    ForEach(confetti) { piece in
                        ConfettiPieceView(piece: piece, screenSize: geo.size)
                    }
                }
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: .triggerCelebration)) { _ in
            trigger()
        }
    }

    private func trigger() {
        var pieces: [ConfettiPiece] = []
        for _ in 0..<30 {
            pieces.append(ConfettiPiece(
                color: Self.colors.randomElement()!,
                size: CGFloat.random(in: 4...8),
                xOffset: CGFloat.random(in: -300...300),
                yOffset: CGFloat.random(in: -500 ... -100),
                rotation: Double.random(in: -360...360)
            ))
        }
        confetti = pieces
        isActive = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [self] in
            isActive = false
            confetti = []
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let xOffset: CGFloat
    let yOffset: CGFloat
    let rotation: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    let screenSize: CGSize

    @State private var animate = false

    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: piece.size, height: piece.size * CGFloat.random(in: 0.5...1.5))
            .rotationEffect(.degrees(animate ? piece.rotation : 0))
            .position(
                x: screenSize.width / 2 + (animate ? piece.xOffset : 0),
                y: screenSize.height / 2 + (animate ? piece.yOffset + 800 : 0)
            )
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 2.5)) {
                    animate = true
                }
            }
    }
}
