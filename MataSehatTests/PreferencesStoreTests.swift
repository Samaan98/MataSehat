import Foundation
import Testing
@testable import MataSehat

@MainActor
struct PreferencesStoreTests {
    private func withStore(_ body: (PreferencesStore, UserDefaults) throws -> Void) throws {
        let name = "MataSehat.tests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        try body(PreferencesStore(defaults: defaults), defaults)
    }
    @Test func emptyStoreMeansFirstLaunch() throws {
        try withStore { store, _ in #expect(store.load() == nil) }
    }
    @Test(arguments: [PauseState.active, .manual, .until(Date(timeIntervalSince1970: 12_345))])
    func roundTripKeepsAllEffectSettingsAndPause(pause: PauseState) throws {
        try withStore { store, _ in
            var settings = ReminderSettings.defaults
            settings.effect = .centerEye
            settings.interval = 20
            settings.pauseOption = .manual
            settings.effects[.cornerEye] = EffectSettings(opacity: 0.5, duration: 0.6)
            settings.effects[.centerEye] = EffectSettings(opacity: 0.9, duration: 1.5)
            settings.effects[.dim] = EffectSettings(opacity: 0.12, duration: 2)
            let value = StoredPreferences(settings: settings, pause: pause)
            store.save(value)
            #expect(store.load() == value)
        }
    }
    @Test func corruptFieldsDoNotDestroyValidValues() throws {
        try withStore { store, defaults in
            defaults.set(1, forKey: "matasehat.schemaVersion")
            defaults.set("unknown", forKey: "matasehat.effect")
            defaults.set(30, forKey: "matasehat.interval")
            defaults.set("manual", forKey: "matasehat.pauseOption")
            defaults.set("until", forKey: "matasehat.pauseState")
            defaults.set("bad date", forKey: "matasehat.pauseDeadline")
            defaults.set(0.1, forKey: "matasehat.effects.dim.opacity")
            defaults.set(true, forKey: "matasehat.effects.cornerEye.opacity")
            defaults.set(-2, forKey: "matasehat.effects.centerEye.duration")
            let value = try #require(store.load())
            #expect(value.settings.effect == .cornerEye)
            #expect(value.settings.interval == 30)
            #expect(value.settings.pauseOption == .manual)
            #expect(value.pause == .active)
            #expect(value.settings.effects[.dim]?.opacity == 0.1)
            #expect(value.settings.effects[.cornerEye]?.opacity == 0.8)
            #expect(value.settings.effects[.centerEye]?.duration == 1)
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
            defaults.set(1, forKey: "matasehat.schemaVersion")
            defaults.set("until", forKey: "matasehat.pauseState")
            defaults.set(1e300, forKey: "matasehat.pauseDeadline")
            defaults.set(20, forKey: "matasehat.interval")
            let value = try #require(store.load())
            #expect(value.pause == .active)
            #expect(value.settings.interval == 20)
        }
    }

}
