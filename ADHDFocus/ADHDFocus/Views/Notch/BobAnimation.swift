import SwiftUI

struct BobAnimation {
    static func bobOffset(at date: Date, duration: Double, amplitude: CGFloat) -> CGFloat {
        guard amplitude > 0, duration > 0 else { return 0 }
        let t = date.timeIntervalSinceReferenceDate
        let phase = fmod(t / duration, 1.0)
        let inFirstHalf = phase < 0.5
        let u = inFirstHalf ? phase * 2 : (phase - 0.5) * 2
        let eased = u < 0.5 ? 4 * u * u * u : 1 - pow(-2 * u + 2, 3) / 2
        let wave = inFirstHalf ? 1 - 2 * eased : -1 + 2 * eased
        return wave * amplitude
    }

    static func swayDegrees(at date: Date, duration: Double, amplitude: Double) -> Double {
        guard amplitude > 0, duration > 0 else { return 0 }
        let t = date.timeIntervalSinceReferenceDate
        let phase = fmod(t / duration, 1.0)
        return sin(phase * .pi * 2) * amplitude
    }
}
