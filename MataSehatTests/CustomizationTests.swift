import Foundation
import Testing
@testable import MataSehat

@MainActor struct CustomizationTests {
    private let now = ClockSnapshot(wall: Date(timeIntervalSince1970: 1_000), monotonic: 0)

    @Test(arguments: [3.0, 4.0]) func shortIntervalsReachTheScheduler(interval: Double) {
        var settings = ReminderSettings.defaults
        settings.interval = interval
        let state = ReminderEngine.initial(settings: settings, pause: .active, at: now)
        #expect(state.nextDue == interval)
    }

    @Test func firstInstallationSchedulesBlinkAfterFiveSeconds() {
        let state = ReminderEngine.initial(settings: .defaults, pause: .active, at: now)
        #expect(state.nextDue == 5)
    }

    @Test func dimmingAcceptsHalfOpacityAndOneTenthSecond() {
        var settings = ReminderSettings.defaults
        settings.effect = .dim
        settings.effects[.dim] = EffectSettings(opacity: 0.5, duration: 0.1)
        let state = ReminderEngine.initial(settings: settings, pause: .active, at: now)
        let result = ReminderEngine.reduce(state, event: .preview, at: now)
        #expect(result.state.presentation?.settings == EffectSettings(opacity: 0.5, duration: 0.1))
    }

    @Test func customBreakPeriodAndDurationAreUsed() {
        var settings = ReminderSettings.defaults
        settings.screenBreakInterval = 900
        settings.screenBreakDuration = 45
        let initial = ReminderEngine.initial(settings: settings, pause: .active, at: now)
        #expect(initial.nextBreakDue == 900)
        let start = ReminderEngine.reduce(initial, event: .startBreak, at: now)
        #expect(start.state.breakPhase == .resting(until: 45))
    }

    @Test func displayedWholeUnitsMatchScheduledBreak() {
        var settings = ReminderSettings.defaults
        settings.screenBreakInterval = 90
        settings.screenBreakDuration = 20.5
        let initial = ReminderEngine.initial(settings: settings, pause: .active, at: now)
        #expect(initial.nextBreakDue == 120)
        let start = ReminderEngine.reduce(initial, event: .startBreak, at: now)
        #expect(start.state.breakDuration == 21)
        #expect(start.state.breakPhase == .resting(until: 21))
    }

    @Test func newSettingsSurviveStoreRecreation() throws {
        let name = "MataSehat.customization.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        var settings = ReminderSettings.defaults
        settings.effect = .dim
        settings.interval = 4
        settings.eyePosition = .bottomLeading
        settings.eyeScale = 1.75
        settings.effects[.eye] = EffectSettings(opacity: 0.65, duration: 1.8)
        settings.effects[.dim] = EffectSettings(opacity: 0.5, duration: 0.1)
        settings.screenBreaksEnabled = false
        settings.screenBreakInterval = 3_600
        settings.screenBreakDuration = 120
        settings.screenBreakSoundsEnabled = false
        settings.pauseOption = .manual
        let stored = StoredPreferences(settings: settings, pause: .manual)
        PreferencesStore(defaults: defaults).save(stored)
        #expect(PreferencesStore(defaults: try #require(UserDefaults(suiteName: name))).load() == stored)
    }

}
