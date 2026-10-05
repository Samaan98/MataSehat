import Foundation

nonisolated struct ClockSnapshot: Sendable {
    let wall: Date
    let monotonic: TimeInterval
}
nonisolated protocol ReminderClock { func now() -> ClockSnapshot }

nonisolated struct SystemReminderClock: ReminderClock {
    func now() -> ClockSnapshot { ClockSnapshot(wall: Date(), monotonic: ProcessInfo.processInfo.systemUptime) }
}
