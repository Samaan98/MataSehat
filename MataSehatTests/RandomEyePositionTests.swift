import Foundation
import Testing
@testable import MataSehat

@MainActor struct RandomEyePositionTests {
    private let now = ClockSnapshot(wall: Date(timeIntervalSince1970: 1_000), monotonic: 0)

    @Test(arguments: EyePosition.fixedPositions)
    func scheduledRemindersCanChooseEachOfTheNinePositions(position: EyePosition) throws {
        var settings = ReminderSettings.defaults
        settings.eyePosition = .random
        let initial = ReminderEngine.initial(settings: settings, pause: .active, at: now)
        var choices = 0
        let result = ReminderEngine.reduce(initial, event: .tick, at: time(5), chooseEyePosition: {
            choices += 1
            return position
        })
        let presentation = try #require(result.state.presentation)
        #expect(choices == 1)
        #expect(presentation.eyePosition == position)
        #expect(result.commands == [.show(presentation)])
        #expect(result.state.settings.eyePosition == .random)
    }

    @Test func previewRerollsOnlyForANewPresentation() throws {
        var settings = ReminderSettings.defaults
        settings.eyePosition = .random
        let initial = ReminderEngine.initial(settings: settings, pause: .manual, at: now)
        var choices = 0
        func choose() -> EyePosition {
            choices += 1
            return choices == 1 ? .topLeading : .bottomTrailing
        }
        let first = ReminderEngine.reduce(initial, event: .preview, at: now, chooseEyePosition: choose)
        let presentation = try #require(first.state.presentation)
        #expect(presentation.eyePosition == .topLeading)
        let tick = ReminderEngine.reduce(first.state, event: .tick, at: time(0.5), chooseEyePosition: choose)
        #expect(tick.state.presentation == presentation)
        #expect(choices == 1)
        let second = ReminderEngine.reduce(tick.state, event: .preview, at: time(0.5), chooseEyePosition: choose)
        #expect(second.state.presentation?.eyePosition == .bottomTrailing)
        #expect(choices == 2)
        #expect(second.state.pause == .manual)
    }

    @Test func scheduledCompletionDoesNotChooseUntilTheNextReminder() throws {
        var settings = ReminderSettings.defaults
        settings.eyePosition = .random
        let initial = ReminderEngine.initial(settings: settings, pause: .active, at: now)
        var choices = 0
        func choose() -> EyePosition {
            choices += 1
            return choices == 1 ? .center : .leading
        }
        let first = ReminderEngine.reduce(initial, event: .tick, at: time(5), chooseEyePosition: choose)
        let id = try #require(first.state.presentation?.id)
        let finished = ReminderEngine.reduce(first.state, event: .effectFinished(id), at: time(6), chooseEyePosition: choose)
        #expect(finished.state.presentation == nil)
        #expect(choices == 1)
        let second = ReminderEngine.reduce(finished.state, event: .tick, at: time(10), chooseEyePosition: choose)
        #expect(second.state.presentation?.eyePosition == .leading)
        #expect(choices == 2)
    }

    @Test(arguments: EyePosition.fixedPositions)
    func fixedPositionsDoNotUseRandomSelection(position: EyePosition) {
        var settings = ReminderSettings.defaults
        settings.eyePosition = position
        let initial = ReminderEngine.initial(settings: settings, pause: .active, at: now)
        var choices = 0
        let result = ReminderEngine.reduce(initial, event: .preview, at: now, chooseEyePosition: {
            choices += 1
            return .center
        })
        #expect(result.state.presentation?.eyePosition == position)
        #expect(choices == 0)
    }

    @Test func dimmingDoesNotUseRandomSelection() {
        var settings = ReminderSettings.defaults
        settings.effect = .dim
        settings.eyePosition = .random
        let initial = ReminderEngine.initial(settings: settings, pause: .active, at: now)
        var choices = 0
        _ = ReminderEngine.reduce(initial, event: .preview, at: now, chooseEyePosition: {
            choices += 1
            return .center
        })
        #expect(choices == 0)
    }

    @Test func defaultRandomSelectionReturnsOnlyFixedPositions() {
        #expect(EyePosition.fixedPositions.count == 9)
        #expect(!EyePosition.fixedPositions.contains(.random))
        for _ in 0..<100 {
            #expect(EyePosition.fixedPositions.contains(EyePosition.random.resolved()))
        }
    }

    @Test func randomModeSurvivesStoreRecreation() throws {
        let random = try #require(EyePosition(rawValue: "random"))
        let name = "MataSehat.randomPosition.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        var settings = ReminderSettings.defaults
        settings.eyePosition = random
        let preferences = StoredPreferences(settings: settings, pause: .active)
        PreferencesStore(defaults: defaults).save(preferences)
        let restored = PreferencesStore(defaults: try #require(UserDefaults(suiteName: name))).load()
        #expect(restored == preferences)
    }

    private func time(_ seconds: Double) -> ClockSnapshot {
        ClockSnapshot(wall: now.wall.addingTimeInterval(seconds), monotonic: seconds)
    }
}
