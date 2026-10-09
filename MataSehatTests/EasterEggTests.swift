import Foundation
import Testing
@testable import MataSehat

@MainActor struct EasterEggTests {
    private let now = ClockSnapshot(wall: Date(timeIntervalSince1970: 1_000), monotonic: 0)

    @Test func testModeCyclesThroughAllEyesWithoutRepeats() throws {
        var state = initial(testMode: true)
        for _ in 0..<2 {
            for expected in EyeVariant.easterEggs {
                let result = ReminderEngine.reduce(state, event: .preview, at: now)
                let shown = try #require(result.state.presentation)
                #expect(shown.eyeVariant == expected)
                state = ReminderEngine.reduce(result.state, event: .effectFinished(shown.id), at: now).state
            }
        }
    }

    @Test func scheduledEyesCycleOnlyAtEveryTenthReminder() throws {
        var state = initial()
        let variants = EyeVariant.easterEggs
        for count in 1...(10 * (variants.count + 1)) {
            let result = ReminderEngine.reduce(state, event: .tick, at: time(Double(count * 5)))
            let shown = try #require(result.state.presentation)
            let expected: EyeVariant = count.isMultiple(of: 10) ? variants[(count / 10 - 1) % variants.count] : .standard
            #expect(shown.eyeVariant == expected)
            #expect(result.state.easterEggProgress == count % 10)
            #expect(result.commands == [.show(shown)])
            state = ReminderEngine.reduce(result.state, event: .effectFinished(shown.id), at: time(Double(count * 5 + 1))).state
        }
    }

    @Test func previewsAndOverlappingTicksDoNotSpendTheCounterOrSequence() throws {
        var state = initial()
        state.easterEggProgress = 9
        let preview = ReminderEngine.reduce(state, event: .preview, at: now)
        let previewID = try #require(preview.state.presentation?.id)
        #expect(preview.state.presentation?.eyeVariant == .standard)
        #expect(preview.state.easterEggProgress == 9)
        state = ReminderEngine.reduce(preview.state, event: .effectFinished(previewID), at: now).state
        let due = ReminderEngine.reduce(state, event: .tick, at: time(5))
        #expect(due.state.presentation?.eyeVariant == .sauron)
        let overlap = ReminderEngine.reduce(due.state, event: .tick, at: time(10))
        #expect(overlap.state.presentation == due.state.presentation)
        #expect(overlap.state.easterEggProgress == 0)
        state = ReminderEngine.reduce(overlap.state, event: .effectFinished(try #require(due.state.presentation?.id)), at: time(10)).state
        state.easterEggProgress = 9
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(15)).state.presentation?.eyeVariant == .cipher)
    }

    @Test func testModeSharesOneSequenceBetweenPreviewsAndScheduledShows() throws {
        var state = initial(testMode: true)
        for (index, variant) in EyeVariant.easterEggs.enumerated() {
            let event: ReminderEvent = index.isMultiple(of: 2) ? .preview : .tick
            let result = ReminderEngine.reduce(state, event: event, at: time(Double((index + 1) * 5)))
            let shown = try #require(result.state.presentation)
            #expect(shown.eyeVariant == variant)
            #expect(result.state.easterEggProgress == 0)
            state = ReminderEngine.reduce(result.state, event: .effectFinished(shown.id), at: time(Double((index + 1) * 5))).state
        }
    }

    @Test(arguments: [false, true])
    func disablingTheFeatureWinsOverTestMode(testMode: Bool) {
        let state = initial(enabled: false, testMode: testMode)
        let result = ReminderEngine.reduce(state, event: .tick, at: time(5))
        #expect(result.state.presentation?.eyeVariant == .standard)
        #expect(result.state.easterEggProgress == 0)
        #expect(result.state.nextEasterEggIndex == 0)
    }

    @Test func dimmingPauseAndRestDoNotSpendTheCounterOrSequence() {
        var state = initial(testMode: true)
        state.easterEggProgress = 9
        var dimSettings = state.settings
        dimSettings.effect = .dim
        state = ReminderEngine.reduce(state, event: .settingsChanged(dimSettings), at: now).state
        let dim = ReminderEngine.reduce(state, event: .tick, at: time(5))
        #expect(dim.state.presentation?.eyeVariant == .standard)
        #expect(dim.state.easterEggProgress == 9)
        #expect(dim.state.nextEasterEggIndex == 0)
        state = ReminderEngine.reduce(dim.state, event: .pause(.manual), at: time(6)).state
        let paused = ReminderEngine.reduce(state, event: .tick, at: time(100))
        #expect(paused.state.presentation == nil)
        #expect(paused.state.easterEggProgress == 9)
        #expect(paused.state.nextEasterEggIndex == 0)
        state = ReminderEngine.reduce(paused.state, event: .startBreak, at: time(100)).state
        let resting = ReminderEngine.reduce(state, event: .tick, at: time(101))
        #expect(resting.state.presentation == nil)
        #expect(resting.state.easterEggProgress == 9)
        #expect(resting.state.nextEasterEggIndex == 0)
    }

    @Test func togglingModesResetsCadenceButKeepsTheNextEye() throws {
        var state = initial(testMode: true)
        state = ReminderEngine.reduce(state, event: .preview, at: now).state
        #expect(state.presentation?.eyeVariant == .sauron)
        state.easterEggProgress = 9
        var settings = state.settings
        settings.easterEggTestMode = false
        state = ReminderEngine.reduce(state, event: .settingsChanged(settings), at: now).state
        #expect(state.easterEggProgress == 0)
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(5)).state.presentation?.eyeVariant == .standard)
        settings.easterEggsEnabled = false
        state = ReminderEngine.reduce(state, event: .settingsChanged(settings), at: now).state
        settings.easterEggsEnabled = true
        state = ReminderEngine.reduce(state, event: .settingsChanged(settings), at: now).state
        state.easterEggProgress = 9
        #expect(ReminderEngine.reduce(state, event: .tick, at: time(5)).state.presentation?.eyeVariant == .cipher)
    }

    @Test(arguments: EyeVariant.easterEggs)
    func unusualEyesKeepPositionSizeVisibilityAndDuration(variant: EyeVariant) throws {
        var state = initial(testMode: true)
        state.nextEasterEggIndex = try #require(EyeVariant.easterEggs.firstIndex(of: variant))
        state.settings.eyePosition = .random
        state.settings.eyeScale = 1.75
        state.settings.effects[.eye] = EffectSettings(opacity: 0.65, duration: 1.8)
        let result = ReminderEngine.reduce(state, event: .preview, at: now, chooseEyePosition: { .bottomTrailing })
        #expect(result.state.presentation?.eyeVariant == variant)
        #expect(result.state.presentation?.eyePosition == .bottomTrailing)
        #expect(result.state.presentation?.eyeScale == 1.75)
        #expect(result.state.presentation?.settings == EffectSettings(opacity: 0.65, duration: 1.8))
    }

    @Test func oldOrMalformedPreferencesKeepSafeDefaults() throws {
        let name = "MataSehat.easterEggDefaults.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(2, forKey: "matasehat.schemaVersion")
        defaults.set(30, forKey: "matasehat.interval")
        for value in [nil, "true", "false"] as [String?] {
            defaults.set(value, forKey: "matasehat.easterEggsEnabled")
            defaults.set(value, forKey: "matasehat.easterEggTestMode")
            let settings = try #require(PreferencesStore(defaults: defaults).load()?.settings)
            #expect(settings.easterEggsEnabled)
            #expect(!settings.easterEggTestMode)
            #expect(settings.interval == 30)
        }
    }

    @Test(arguments: [(true, false), (true, true), (false, false), (false, true)])
    func bothSwitchesSurviveLoadingAndSaving(enabled: Bool, testMode: Bool) throws {
        let name = "MataSehat.easterEggs.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(2, forKey: "matasehat.schemaVersion")
        defaults.set(enabled, forKey: "matasehat.easterEggsEnabled")
        defaults.set(testMode, forKey: "matasehat.easterEggTestMode")
        let stored = try #require(PreferencesStore(defaults: defaults).load())
        defaults.removeObject(forKey: "matasehat.easterEggsEnabled")
        defaults.removeObject(forKey: "matasehat.easterEggTestMode")
        PreferencesStore(defaults: defaults).save(stored)
        #expect(defaults.object(forKey: "matasehat.easterEggsEnabled") as? Bool == enabled)
        #expect(defaults.object(forKey: "matasehat.easterEggTestMode") as? Bool == testMode)
    }

    private func initial(enabled: Bool = true, testMode: Bool = false) -> ReminderState {
        var settings = ReminderSettings.defaults
        settings.easterEggsEnabled = enabled
        settings.easterEggTestMode = testMode
        settings.screenBreaksEnabled = false
        return ReminderEngine.initial(settings: settings, pause: .active, at: now)
    }

    private func time(_ seconds: Double) -> ClockSnapshot {
        ClockSnapshot(wall: now.wall.addingTimeInterval(seconds), monotonic: seconds)
    }
}
