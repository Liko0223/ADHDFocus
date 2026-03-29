import Testing
import Foundation
@testable import ADHDFocus

@Test func pomodoroTimerStartsInWorkPhase() {
    let timer = PomodoroTimer(
        workDuration: 10, breakDuration: 5, longBreakDuration: 15, longBreakInterval: 4
    )
    #expect(timer.phase == .idle)
    timer.start()
    #expect(timer.phase == .work)
    #expect(timer.remainingSeconds == 10)
    #expect(timer.completedPomodoros == 0)
}

@Test func pomodoroTimerTransitionsToBreak() {
    let timer = PomodoroTimer(
        workDuration: 1, breakDuration: 5, longBreakDuration: 15, longBreakInterval: 4
    )
    timer.start()
    timer.simulateTick(seconds: 1)
    #expect(timer.phase == .break_)
    #expect(timer.remainingSeconds == 5)
    #expect(timer.completedPomodoros == 1)
}

@Test func pomodoroTimerLongBreakAfterInterval() {
    let timer = PomodoroTimer(
        workDuration: 1, breakDuration: 1, longBreakDuration: 10, longBreakInterval: 2
    )
    timer.start()
    timer.simulateTick(seconds: 1) // end work 1 -> break
    timer.simulateTick(seconds: 1) // end break -> work
    timer.simulateTick(seconds: 1) // end work 2 -> long break
    #expect(timer.phase == .longBreak)
    #expect(timer.remainingSeconds == 10)
    #expect(timer.completedPomodoros == 2)
}

@Test func pomodoroTimerStop() {
    let timer = PomodoroTimer(
        workDuration: 25, breakDuration: 5, longBreakDuration: 15, longBreakInterval: 4
    )
    timer.start()
    timer.stop()
    #expect(timer.phase == .idle)
    #expect(timer.remainingSeconds == 0)
}

@Test func pomodoroTimerIsOnBreak() {
    let timer = PomodoroTimer(
        workDuration: 1, breakDuration: 5, longBreakDuration: 15, longBreakInterval: 4
    )
    timer.start()
    #expect(timer.isOnBreak == false)
    timer.simulateTick(seconds: 1)
    #expect(timer.isOnBreak == true)
}

@Test func pomodoroTimerDisabledWhenZeroDuration() {
    let timer = PomodoroTimer(
        workDuration: 0, breakDuration: 0, longBreakDuration: 0, longBreakInterval: 4
    )
    #expect(timer.isDisabled == true)
}
