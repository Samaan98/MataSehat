import Foundation
import Testing
@testable import MataSehat

@MainActor
struct PreferencesStoreTests {
    @Test func screenBreakPreferenceRoundTripsAndMissingOrCorruptFlagUsesDefault() throws {
        try withStore { store, defaults in
            defaults.set(2, forKey: "matasehat.schemaVersion")
            defaults.set(30, forKey: "matasehat.interval")
            #expect(store.load()?.settings.screenBreaksEnabled == true)
            var settings = ReminderSettings.defaults
            settings.screenBreaksEnabled = false
            settings.interval = 5
            store.save(StoredPreferences(settings: settings, pause: .manual))
            #expect(store.load()?.settings.screenBreaksEnabled == false)
            #expect(store.load()?.settings.interval == 5)
            #expect(store.load()?.pause == .manual)
            defaults.set("invalid", forKey: "matasehat.screenBreaksEnabled")
            #expect(store.load()?.settings.screenBreaksEnabled == true)
        }
    }
    private func withStore(_ body: (PreferencesStore, UserDefaults) throws -> Void) throws {
        let name = "MataSehat.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        try body(PreferencesStore(defaults: defaults), defaults)
    }
    @Test func emptyStoreMeansFirstLaunch() throws {
        try withStore { store, _ in #expect(store.load() == nil) }
    }
    @Test(arguments: [1, 3]) func unsupportedSchemaUsesFreshSettings(version: Int) throws {
        try withStore { store, defaults in
            defaults.set(version, forKey: "matasehat.schemaVersion")
            defaults.set(30, forKey: "matasehat.interval")
            #expect(store.load() == nil)
            store.save(StoredPreferences(settings: .defaults, pause: .active))
            #expect(store.load() == StoredPreferences(settings: .defaults, pause: .active))
        }
    }
    @Test(arguments: [PauseState.active, .manual, .until(Date(timeIntervalSince1970: 12_345))])
    func roundTripKeepsAllEffectSettingsAndPause(pause: PauseState) throws {
        try withStore { store, _ in
            var settings = ReminderSettings.defaults
            settings.effect = .eye
            settings.interval = 20
            settings.pauseOption = .manual
            settings.effects[.eye] = EffectSettings(opacity: 0.9, duration: 1.5)
            settings.effects[.dim] = EffectSettings(opacity: 0.12, duration: 2)
            let value = StoredPreferences(settings: settings, pause: pause)
            store.save(value)
            #expect(store.load() == value)
        }
    }
    @Test func corruptFieldsDoNotDestroyValidValues() throws {
        try withStore { store, defaults in
            defaults.set(2, forKey: "matasehat.schemaVersion")
            defaults.set("unknown", forKey: "matasehat.effect")
            defaults.set(30, forKey: "matasehat.interval")
            defaults.set("manual", forKey: "matasehat.pauseOption")
            defaults.set("until", forKey: "matasehat.pauseState")
            defaults.set("bad date", forKey: "matasehat.pauseDeadline")
            defaults.set(0.1, forKey: "matasehat.effects.dim.opacity")
            defaults.set(true, forKey: "matasehat.effects.eye.opacity")
            defaults.set(-2, forKey: "matasehat.effects.eye.duration")
            let value = try #require(store.load())
            #expect(value.settings.effect == .eye)
            #expect(value.settings.interval == 30)
            #expect(value.settings.pauseOption == .manual)
            #expect(value.pause == .active)
            #expect(value.settings.effects[.dim]?.opacity == 0.1)
            #expect(value.settings.effects[.eye]?.opacity == 1)
            #expect(value.settings.effects[.eye]?.duration == 1)
        }
    }
    @Test func leavingTimedPauseRemovesDeadline() throws {
        try withStore { store, defaults in
            store.save(StoredPreferences(settings: .defaults, pause: .until(Date())))
            store.save(StoredPreferences(settings: .defaults, pause: .manual))
            #expect(defaults.object(forKey: "matasehat.pauseDeadline") == nil)
            #expect(store.load()?.pause == .manual)
        }
    }
    @Test func enormousFiniteDeadlineIsRepairedWithoutLosingSettings() throws {
        try withStore { store, defaults in
            defaults.set(2, forKey: "matasehat.schemaVersion")
            defaults.set("until", forKey: "matasehat.pauseState")
            defaults.set(1e300, forKey: "matasehat.pauseDeadline")
            defaults.set(20, forKey: "matasehat.interval")
            let value = try #require(store.load())
            #expect(value.pause == .active)
            #expect(value.settings.interval == 20)
        }
    }

}
