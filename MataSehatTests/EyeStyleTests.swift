import Foundation
import Testing
@testable import MataSehat

@MainActor struct EyeStyleTests {
    @Test(arguments: [
        (EyeStyle.light, false, EyeStyle.light), (.light, true, .light),
        (.dark, false, .dark), (.dark, true, .dark),
        (.system, false, .dark), (.system, true, .light)
    ])
    func systemStyleContrastsWithAppearance(style: EyeStyle, isDark: Bool, expected: EyeStyle) {
        #expect(style.resolved(isDarkAppearance: isDark) == expected)
    }

    @Test(arguments: EyeStyle.allCases)
    func changingStyleReachesPresentationAndSurvivesRestart(style: EyeStyle) throws {
        let fixture = ControllerFixture()
        let controller = fixture.make()
        controller.start()
        controller.updateSettings { $0.eyeStyle = style }
        controller.send(.preview)
        #expect(fixture.overlay.values.last?.eyeStyle == style)
        #expect(fixture.store.value?.settings.eyeStyle == style)
        controller.stop()
        let restored = fixture.make()
        restored.start()
        #expect(restored.state.settings.eyeStyle == style)
        fixture.clock.advance(10)
        fixture.scheduler.fire()
        #expect(fixture.overlay.values.last?.eyeStyle == style)
        #expect(fixture.overlay.values.last?.origin == .scheduled)
        restored.stop()
    }

    @Test(arguments: [Optional<String>.none, "unknown"])
    func missingOrInvalidStyleKeepsExistingSettings(rawStyle: String?) throws {
        let name = "MataSehat.eyeStyleFallback.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(2, forKey: "matasehat.schemaVersion")
        defaults.set(30, forKey: "matasehat.interval")
        defaults.set("random", forKey: "matasehat.eyePosition")
        if let rawStyle { defaults.set(rawStyle, forKey: "matasehat.eyeStyle") }
        let preferences = try #require(PreferencesStore(defaults: defaults).load())
        #expect(preferences.settings.eyeStyle == .light)
        #expect(preferences.settings.interval == 30)
        #expect(preferences.settings.eyePosition == .random)
        #expect(ReminderSettings.defaults.eyeStyle == .light)
    }

    @Test(arguments: ["light", "dark", "system"])
    func storedStyleSurvivesLoadingAndSaving(rawStyle: String) throws {
        let name = "MataSehat.eyeStyle.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(2, forKey: "matasehat.schemaVersion")
        defaults.set(rawStyle, forKey: "matasehat.eyeStyle")
        let preferences = try #require(PreferencesStore(defaults: defaults).load())
        defaults.removeObject(forKey: "matasehat.eyeStyle")
        PreferencesStore(defaults: defaults).save(preferences)
        #expect(defaults.string(forKey: "matasehat.eyeStyle") == rawStyle)
    }
}
