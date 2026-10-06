import Foundation
import Testing
@testable import MataSehat

@MainActor struct BreakCustomizationTests {
    private func time(_ seconds: Double) -> ClockSnapshot {
        ClockSnapshot(wall: Date(timeIntervalSince1970: 1_000 + seconds), monotonic: seconds)
    }
    private func initial(sounds: Bool = true) -> ReminderState {
        var settings = ReminderSettings.defaults
        settings.screenBreakSoundsEnabled = sounds
        return ReminderEngine.initial(settings: settings, pause: .active, at: time(0))
    }
    @Test func invitationSoundsOnceAndCompletionSoundsOnlyAtDeadline() {
        let invitation = ReminderEngine.reduce(initial(), event: .tick, at: time(1_200))
        #expect(invitation.commands.filter { $0 == .playSound(.breakInvitation) }.count == 1)
        let repeated = ReminderEngine.reduce(invitation.state, event: .requestBreak, at: time(1_201))
        #expect(!repeated.commands.contains(.playSound(.breakInvitation)))
        let started = ReminderEngine.reduce(repeated.state, event: .startBreak, at: time(1_210))
        #expect(!started.commands.contains(.playSound(.breakInvitation)))
        let early = ReminderEngine.reduce(started.state, event: .tick, at: time(1_229))
        #expect(!early.commands.contains(.playSound(.breakCompleted)))
        let completed = ReminderEngine.reduce(early.state, event: .tick, at: time(1_230))
        #expect(completed.commands.filter { $0 == .playSound(.breakCompleted) }.count == 1)
        #expect(!ReminderEngine.reduce(completed.state, event: .tick, at: time(1_231))
            .commands.contains(.playSound(.breakCompleted)))
    }
    @Test(arguments: [ReminderEvent.finishBreak, .suspend, .pause(.manual)])
    func interruptedRestHasNoCompletionSound(event: ReminderEvent) {
        let resting = ReminderEngine.reduce(initial(), event: .startBreak, at: time(0)).state
        let result = ReminderEngine.reduce(resting, event: event, at: time(5))
        #expect(!result.commands.contains(.playSound(.breakCompleted)))
    }
    @Test func disabledSoundsSilenceBothEvents() {
        let invitation = ReminderEngine.reduce(initial(sounds: false), event: .requestBreak, at: time(0))
        #expect(!invitation.commands.contains(.playSound(.breakInvitation)))
        let resting = ReminderEngine.reduce(invitation.state, event: .startBreak, at: time(0)).state
        #expect(!ReminderEngine.reduce(resting, event: .tick, at: time(20))
            .commands.contains(.playSound(.breakCompleted)))
    }
    @Test func changingTimingsPreservesOngoingRestAndUsesNewSettingsNextTime() {
        let resting = ReminderEngine.reduce(initial(), event: .startBreak, at: time(0)).state
        var settings = resting.settings
        settings.screenBreakDuration = 90
        settings.screenBreakInterval = 600
        let changed = ReminderEngine.reduce(resting, event: .settingsChanged(settings), at: time(5)).state
        #expect(changed.breakPhase == .resting(until: 20))
        #expect(changed.breakDuration == 20)
        let finished = ReminderEngine.reduce(changed, event: .tick, at: time(20)).state
        #expect(finished.nextBreakDue == 620)
        let next = ReminderEngine.reduce(finished, event: .startBreak, at: time(30)).state
        #expect(next.breakPhase == .resting(until: 120))
        #expect(next.breakDuration == 90)
    }
    @Test func intervalChangeReschedulesWaitingCycleButDurationChangeDoesNot() {
        let state = initial()
        var settings = state.settings
        settings.screenBreakDuration = 45
        let durationChange = ReminderEngine.reduce(state, event: .settingsChanged(settings), at: time(10)).state
        #expect(durationChange.nextBreakDue == 1_200)
        settings.screenBreakInterval = 300
        let intervalChange = ReminderEngine.reduce(durationChange, event: .settingsChanged(settings), at: time(20)).state
        #expect(intervalChange.nextBreakDue == 320)
    }
    @Test func invitationUpdatesDurationWithoutReplayingSound() {
        let invitation = ReminderEngine.reduce(initial(), event: .requestBreak, at: time(0)).state
        var settings = invitation.settings
        settings.screenBreakDuration = 60
        let result = ReminderEngine.reduce(invitation, event: .settingsChanged(settings), at: time(1))
        #expect(result.state.breakDuration == 60)
        #expect(result.commands.contains(.showBreak))
        #expect(!result.commands.contains(.playSound(.breakInvitation)))
    }
    @Test func controllerDeliversConfiguredDurationAndSoundsWithoutNativeWindows() {
        let fixture = ControllerFixture()
        var settings = ReminderSettings.defaults
        settings.screenBreakDuration = 45
        fixture.store.value = StoredPreferences(settings: settings, pause: .active)
        let sounds = RecordedSounds()
        let controller = fixture.make(soundPlayer: sounds)
        controller.start()
        controller.send(.requestBreak)
        #expect(sounds.played == [.breakInvitation])
        #expect(fixture.breaks.durations == [45])
        fixture.breaks.action?(.startBreak)
        #expect(fixture.scheduler.delay == 45)
        fixture.clock.advance(45)
        fixture.scheduler.fire()
        #expect(sounds.played == [.breakInvitation, .breakCompleted])
        #expect(controller.state.breakPhase == .waiting)
        controller.stop()
    }
}

@MainActor private final class RecordedSounds: ReminderSoundPlaying {
    var played: [ReminderSound] = []
    func play(_ sound: ReminderSound) { played.append(sound) }
}
