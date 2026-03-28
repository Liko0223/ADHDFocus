import Foundation
import Observation

enum PomodoroPhase: String {
    case idle
    case work
    case break_
    case longBreak
}

@Observable
final class PomodoroTimer {
    let workDuration: Int
    let breakDuration: Int
    let longBreakDuration: Int
    let longBreakInterval: Int

    private(set) var phase: PomodoroPhase = .idle
    private(set) var remainingSeconds: Int = 0
    private(set) var completedPomodoros: Int = 0

    private var timer: Timer?

    var isOnBreak: Bool {
        phase == .break_ || phase == .longBreak
    }

    var isDisabled: Bool {
        workDuration == 0
    }

    var isRunning: Bool {
        phase != .idle
    }

    var progress: Double {
        let total: Int
        switch phase {
        case .idle: return 0
        case .work: total = workDuration
        case .break_: total = breakDuration
        case .longBreak: total = longBreakDuration
        }
        guard total > 0 else { return 0 }
        return 1.0 - (Double(remainingSeconds) / Double(total))
    }

    var onPhaseChange: ((PomodoroPhase) -> Void)?

    init(workDuration: Int, breakDuration: Int, longBreakDuration: Int, longBreakInterval: Int) {
        self.workDuration = workDuration
        self.breakDuration = breakDuration
        self.longBreakDuration = longBreakDuration
        self.longBreakInterval = longBreakInterval
    }

    func start() {
        guard !isDisabled else { return }
        phase = .work
        remainingSeconds = workDuration
        completedPomodoros = 0
        startTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        phase = .idle
        remainingSeconds = 0
    }

    func simulateTick(seconds: Int) {
        for _ in 0..<seconds {
            tick()
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard remainingSeconds > 0 else { return }
        remainingSeconds -= 1
        if remainingSeconds == 0 {
            transitionPhase()
        }
    }

    private func transitionPhase() {
        switch phase {
        case .work:
            completedPomodoros += 1
            if completedPomodoros % longBreakInterval == 0 {
                phase = .longBreak
                remainingSeconds = longBreakDuration
            } else {
                phase = .break_
                remainingSeconds = breakDuration
            }
        case .break_, .longBreak:
            phase = .work
            remainingSeconds = workDuration
        case .idle:
            break
        }
        onPhaseChange?(phase)
    }
}
