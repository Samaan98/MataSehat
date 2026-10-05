import Foundation
import Testing
@testable import MataSehat

@MainActor struct ScreenBreakEngineTests {
    private func time(_ seconds: Double) -> ClockSnapshot {
        ClockSnapshot(wall: Date(timeIntervalSince1970: 1_000 + seconds), monotonic: seconds)
    }
    private func initial(pause: PauseState = .active) -> ReminderState {
        ReminderEngine.initial(settings: .defaults, pause: pause, at: time(0))
    }
    @Test func fiveSecondBlinkIntervalIsUsedByScheduler() {
        var settings = ReminderSettings.defaults
        settings.interval = 5
        let state = ReminderEngine.initial(settings: settings, pause: .active, at: time(0))
        #expect(state.nextDue == 5)
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(4.9)).state.presentation == nil)
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(5)).state.presentation != nil)
    }
    @Test func twentyMinutesShowsInvitationWithoutStartingRest() {
        var state = initial()
        #expect(state.nextBreakDue == 1_200)
        state = ReminderEngine.reduce(state, event: .tick, at: time(1_199)).state
        #expect(state.breakPhase == .waiting)
        state = ReminderEngine.reduce(state, event: .tick, at: time(1_200)).state
        #expect(state.breakPhase == .invitation)
        #expect(state.presentation == nil)
        #expect(state.nextBreakDue == nil)
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(1_250)).state.breakPhase == .invitation)
    }
    @Test func restStartsOnClickAndFinishesAfterFullTwentySeconds() {
        var state = ReminderEngine.reduce(initial(), event: .tick, at: time(1_200)).state
        state = ReminderEngine.reduce(state, event: .startBreak, at: time(1_230)).state
        #expect(state.breakPhase == .resting(until: 1_250))
        #expect(state.nextDue == nil)
        #expect(state.presentation == nil)
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(1_249)).state.breakPhase == .resting(until: 1_250))
        state = ReminderEngine.reduce(state, event: .tick, at: time(1_250)).state
        #expect(state.breakPhase == .waiting)
        #expect(state.nextDue == 1_260)
        #expect(state.nextBreakDue == 2_450)
    }
    @Test func snoozeRemindsInFiveMinutes() {
        var state = ReminderEngine.reduce(initial(), event: .tick, at: time(1_200)).state
        state = ReminderEngine.reduce(state, event: .snoozeBreak, at: time(1_210)).state
        #expect(state.breakPhase == .waiting)
        #expect(state.nextBreakDue == 1_510)
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(1_509)).state.breakPhase == .waiting)
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(1_510)).state.breakPhase == .invitation)
    }
    @Test func blinkSettingsAndPreviewDoNotPostponeBreak() throws {
        var state = initial()
        var settings = state.settings
        settings.interval = 5
        state = ReminderEngine.reduce(state, event: .settingsChanged(settings), at: time(200)).state
        #expect(state.nextBreakDue == 1_200)
        state = ReminderEngine.reduce(state, event: .preview, at: time(500)).state
        let id = try #require(state.presentation?.id)
        state = ReminderEngine.reduce(state, event: .effectFinished(id), at: time(501)).state
        #expect(state.nextBreakDue == 1_200)
    }
    @Test func settingsAndPreviewCannotInterruptRest() {
        var state = ReminderEngine.reduce(initial(), event: .startBreak, at: time(100)).state
        var settings = state.settings
        settings.effect = .dim
        state = ReminderEngine.reduce(state, event: .settingsChanged(settings), at: time(101)).state
        state = ReminderEngine.reduce(state, event: .preview, at: time(102)).state
        #expect(state.breakPhase == .resting(until: 120))
        #expect(state.presentation == nil)
        #expect(state.nextDue == nil)
    }
    @Test func disablingAutomaticBreaksStillAllowsManualRest() {
        var state = ReminderEngine.reduce(initial(), event: .tick, at: time(1_200)).state
        var settings = state.settings
        settings.screenBreaksEnabled = false
        state = ReminderEngine.reduce(state, event: .settingsChanged(settings), at: time(1_201)).state
        #expect(state.breakPhase == .waiting)
        #expect(state.nextBreakDue == nil)
        state = ReminderEngine.reduce(state, event: .startBreak, at: time(1_202)).state
        #expect(state.breakPhase == .resting(until: 1_222))
        state = ReminderEngine.reduce(state, event: .tick, at: time(1_222)).state
        #expect(state.nextBreakDue == nil)
        #expect(state.nextDue == 1_232)
    }
    @Test(arguments: [true, false]) func automaticPreferenceDoesNotCancelCurrentRest(enabled: Bool) {
        var settings = ReminderSettings.defaults
        settings.screenBreaksEnabled = !enabled
        var state = ReminderEngine.initial(settings: settings, pause: .active, at: time(0))
        state = ReminderEngine.reduce(state, event: .startBreak, at: time(100)).state
        settings.screenBreaksEnabled = enabled
        let change = ReminderEngine.reduce(state, event: .settingsChanged(settings), at: time(101))
        #expect(change.state.breakPhase == .resting(until: 120))
        #expect(change.state.nextDue == nil)
        #expect(change.state.nextBreakDue == nil)
        #expect(!change.commands.contains(.hideBreak))
        state = ReminderEngine.reduce(change.state, event: .tick, at: time(120)).state
        #expect(state.breakPhase == .waiting)
        #expect(state.nextDue == 130)
        #expect(state.nextBreakDue == (enabled ? 1_320 : nil))
    }
    @Test func pauseAndSleepHideCardAndWakeStartsFreshCycle() {
        var state = ReminderEngine.reduce(initial(), event: .tick, at: time(1_200)).state
        state = ReminderEngine.reduce(state, event: .pause(.manual), at: time(1_201)).state
        #expect(state.breakPhase == .waiting)
        #expect(state.nextBreakDue == nil)
        state = ReminderEngine.reduce(state, event: .resume, at: time(1_300)).state
        #expect(state.nextBreakDue == 2_500)
        state = ReminderEngine.reduce(state, event: .startBreak, at: time(1_400)).state
        state = ReminderEngine.reduce(state, event: .suspend, at: time(1_405)).state
        #expect(state.breakPhase == .waiting)
        state = ReminderEngine.reduce(state, event: .wake, at: time(9_000)).state
        #expect(state.nextBreakDue == 10_200)
    }
    @Test func manualRestPreservesGlobalPause() {
        var state = ReminderEngine.reduce(initial(pause: .manual), event: .startBreak, at: time(50)).state
        #expect(state.breakPhase == .resting(until: 70))
        state = ReminderEngine.reduce(state, event: .tick, at: time(70)).state
        #expect(state.pause == .manual)
        #expect(state.nextDue == nil)
        #expect(state.nextBreakDue == nil)
    }
    @Test func clockJumpDoesNotFinishRestEarly() {
        let state = ReminderEngine.reduce(initial(), event: .startBreak, at: time(0)).state
        let result = ReminderEngine.reduce(state, event: .tick,
            at: ClockSnapshot(wall: Date(timeIntervalSince1970: 50_000), monotonic: 1))
        #expect(result.state.breakPhase == .resting(until: 20))
    }
    @Test func expiredPauseNoticedBySettingsStartsBreakCycle() {
        let state = initial(pause: .until(Date(timeIntervalSince1970: 1_005)))
        let result = ReminderEngine.reduce(state, event: .settingsChanged(state.settings), at: time(6))
        #expect(result.state.pause == .active)
        #expect(result.state.nextBreakDue == 1_206)
    }
    @Test func requestCardPreservesPauseAndCannotRestartAnOngoingRest() {
        var state = ReminderEngine.reduce(initial(pause: .manual), event: .requestBreak, at: time(10)).state
        #expect(state.breakPhase == .invitation)
        #expect(state.pause == .manual)
        state = ReminderEngine.reduce(state, event: .startBreak, at: time(20)).state
        state = ReminderEngine.reduce(state, event: .requestBreak, at: time(21)).state
        state = ReminderEngine.reduce(state, event: .startBreak, at: time(22)).state
        #expect(state.breakPhase == .resting(until: 40))
        state = ReminderEngine.reduce(state, event: .finishBreak, at: time(25)).state
        #expect(state.breakPhase == .waiting)
        #expect(state.pause == .manual)
        #expect(state.nextBreakDue == nil)
    }
}
