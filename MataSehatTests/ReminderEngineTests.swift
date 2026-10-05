import Foundation
import Testing
@testable import MataSehat

@MainActor
struct ReminderEngineTests {
    private let wall = Date(timeIntervalSince1970: 1_000)
    private func time(_ mono: Double, wallOffset: Double? = nil) -> ClockSnapshot {
        ClockSnapshot(wall: wall.addingTimeInterval(wallOffset ?? mono), monotonic: mono)
    }
    private func initial(pause: PauseState = .active) -> ReminderState {
        ReminderEngine.initial(settings: .defaults, pause: pause, at: time(0))
    }
    @Test func startsAfterFullIntervalAndKeepsCadence() throws {
        var state = initial()
        #expect(state.nextDue == 10)
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(9)).commands.isEmpty)
        let result = ReminderEngine.reduce(state, event: .tick, at: time(10))
        #expect(result.commands.count == 1)
        state = result.state
        let presentation = try #require(state.presentation)
        #expect(state.nextDue == 20)
        state = ReminderEngine.reduce(state, event: .effectFinished(presentation.id), at: time(11)).state
        #expect(state.nextDue == 20)
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(20)).state.presentation != nil)
    }
    @Test(arguments: [5, 15, 30, 60]) func pauseUsesWallTime(minutes: Int) {
        let result = ReminderEngine.reduce(initial(), event: .pause(.minutes(minutes)), at: time(2))
        #expect(result.state.pause == .until(wall.addingTimeInterval(2 + Double(minutes * 60))))
        #expect(result.state.nextDue == nil)
        #expect(result.state.presentation == nil)
    }
    @Test func replacingPauseAndResumeResetInterval() {
        var state = ReminderEngine.reduce(initial(), event: .pause(.minutes(15)), at: time(0)).state
        state = ReminderEngine.reduce(state, event: .pause(.minutes(5)), at: time(100)).state
        #expect(state.pause == .until(wall.addingTimeInterval(400)))
        state = ReminderEngine.reduce(state, event: .resume, at: time(110)).state
        #expect(state.pause == .active)
        #expect(state.nextDue == 120)
    }
    @Test func expiredPauseAfterSleepStartsFreshInterval() {
        var state = initial(pause: .until(wall.addingTimeInterval(300)))
        state = ReminderEngine.reduce(state, event: .suspend, at: time(20)).state
        #expect(state.suspended)
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(600)).commands.isEmpty)
        state = ReminderEngine.reduce(state, event: .wake, at: time(600)).state
        #expect(state.pause == .active)
        #expect(state.nextDue == 610)
        #expect(state.presentation == nil)
    }
    @Test func manualPauseNeverExpiresAndSurvivesWake() {
        var state = initial(pause: .manual)
        state = ReminderEngine.reduce(state, event: .wake, at: time(50_000)).state
        #expect(state.pause == .manual)
        #expect(state.nextDue == nil)
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(60_000)).commands.isEmpty)
    }
    @Test(arguments: [PauseState.manual, .until(Date(timeIntervalSince1970: 1_300))])
    func previewPreservesPauseAndRejectsOldCompletion(pause: PauseState) throws {
        var state = ReminderEngine.reduce(initial(pause: pause), event: .preview, at: time(1)).state
        let first = try #require(state.presentation)
        state = ReminderEngine.reduce(state, event: .preview, at: time(1.5)).state
        let second = try #require(state.presentation)
        #expect(first.id != second.id)
        #expect(state.pause == pause)
        state = ReminderEngine.reduce(state, event: .effectFinished(first.id), at: time(2)).state
        #expect(state.presentation?.id == second.id)
        state = ReminderEngine.reduce(state, event: .effectFinished(second.id), at: time(2.5)).state
        #expect(state.presentation == nil)
        #expect(state.pause == pause)
    }
    @Test func previewBlocksScheduledSignalThenStartsFullInterval() throws {
        var state = ReminderEngine.reduce(initial(), event: .preview, at: time(9.5)).state
        let id = try #require(state.presentation?.id)
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(10)).commands.isEmpty)
        state = ReminderEngine.reduce(state, event: .effectFinished(id), at: time(10.5)).state
        #expect(state.nextDue == 20.5)
    }
    @Test func lateTickDoesNotQueueMissedSignalsAndWallJumpDoesNotChangeInterval() {
        var state = initial()
        let jump = ReminderEngine.reduce(state, event: .tick, at: time(1, wallOffset: 50_000))
        #expect(jump.commands.isEmpty)
        #expect(jump.state.nextDue == 10)
        state = ReminderEngine.reduce(state, event: .tick, at: time(100)).state
        #expect(state.presentation != nil)
        #expect(state.nextDue == 110)
    }
    @Test func settingsChangeHidesPresentationAndResetsInterval() {
        var state = ReminderEngine.reduce(initial(), event: .tick, at: time(10)).state
        var settings = ReminderSettings.defaults
        settings.interval = 30
        settings.effect = .dim
        state = ReminderEngine.reduce(state, event: .settingsChanged(settings), at: time(10.5)).state
        #expect(state.presentation == nil)
        #expect(state.nextDue == 40.5)
        #expect(state.settings == settings)
    }
    @Test func restorationNormalizesExpiredPause() {
        #expect(initial(pause: .until(wall.addingTimeInterval(-1))).pause == .active)
        #expect(initial(pause: .manual).nextDue == nil)
    }
    @Test func validationPreservesValidFieldsAndRepairsNonfiniteValues() {
        var settings = ReminderSettings.defaults
        settings.effect = .centerEye
        settings.interval = .infinity
        settings.effects[.dim] = EffectSettings(opacity: .nan, duration: 0.8)
        settings.effects[.cornerEye] = EffectSettings(opacity: 5, duration: -.infinity)
        settings.pauseOption = .minutes(2)
        let value = settings.validated()
        #expect(value.effect == .centerEye)
        #expect(value.interval == 10)
        #expect(value.effects[.dim]?.opacity == 0.06)
        #expect(value.effects[.dim]?.duration == 0.8)
        #expect(value.effects[.cornerEye]?.opacity == 0.8)
        #expect(value.effects[.cornerEye]?.duration == 1)
        #expect(value.pauseOption == .minutes(15))
    }
}
