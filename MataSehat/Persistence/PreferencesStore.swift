import Foundation
import CoreFoundation

nonisolated struct StoredPreferences: Equatable { var settings: ReminderSettings; var pause: PauseState }
@MainActor protocol PreferencesStoring { func load() -> StoredPreferences?; func save(_ value: StoredPreferences) }
@MainActor final class PreferencesStore: PreferencesStoring {
    private let defaults: UserDefaults
    init(defaults: UserDefaults) { self.defaults = defaults }
    func load() -> StoredPreferences? {
        guard number("schemaVersion") == 2 else { return nil }
        var settings = ReminderSettings.defaults
        if let raw = string("effect"), let effect = ReminderEffect(rawValue: raw) { settings.effect = effect }
        if let raw = string("eyePosition"), let position = EyePosition(rawValue: raw) { settings.eyePosition = position }
        if let raw = string("eyeStyle"), let style = EyeStyle(rawValue: raw) { settings.eyeStyle = style }
        settings.easterEggsEnabled = boolean("easterEggsEnabled") ?? true
        settings.easterEggTestMode = boolean("easterEggTestMode") ?? false
        if let value = number("eyeScale") { settings.eyeScale = value }
        if let interval = number("interval") { settings.interval = interval }
        settings.screenBreaksEnabled = boolean("screenBreaksEnabled") ?? true
        settings.screenBreakSoundsEnabled = boolean("screenBreakSoundsEnabled") ?? true
        if let value = number("screenBreakInterval") { settings.screenBreakInterval = value }
        if let value = number("screenBreakDuration") { settings.screenBreakDuration = value }
        if let raw = string("pauseOption") {
            settings.pauseOption = raw == "manual" ? .manual : .minutes(Int(raw) ?? 15)
        }
        for effect in ReminderEffect.allCases {
            settings.effects[effect] = EffectSettings(
                opacity: number("effects.\(effect.rawValue).opacity") ?? effect.defaults.opacity,
                duration: number("effects.\(effect.rawValue).duration") ?? effect.defaults.duration)
        }
        let pause: PauseState
        switch string("pauseState") {
        case "manual": pause = .manual
        case "until":
            if let timestamp = number("pauseDeadline"),
               (Date.distantPast.timeIntervalSince1970...Date.distantFuture.timeIntervalSince1970).contains(timestamp) {
                pause = .until(Date(timeIntervalSince1970: timestamp))
            }
            else { pause = .active }
        default: pause = .active
        }
        return StoredPreferences(settings: settings.validated(), pause: pause)
    }
    func save(_ value: StoredPreferences) {
        let settings = value.settings.validated()
        set(settings.effect.rawValue, "effect")
        set(settings.interval, "interval")
        set(settings.screenBreaksEnabled, "screenBreaksEnabled")
        set(settings.eyePosition.rawValue, "eyePosition")
        set(settings.eyeStyle.rawValue, "eyeStyle")
        set(settings.easterEggsEnabled, "easterEggsEnabled")
        set(settings.easterEggTestMode, "easterEggTestMode")
        set(settings.eyeScale, "eyeScale")
        set(settings.screenBreakInterval, "screenBreakInterval")
        set(settings.screenBreakDuration, "screenBreakDuration")
        set(settings.screenBreakSoundsEnabled, "screenBreakSoundsEnabled")
        switch settings.pauseOption {
        case .manual: set("manual", "pauseOption")
        case .minutes(let value): set(String(value), "pauseOption")
        }
        for effect in ReminderEffect.allCases {
            let parameters = settings.effects[effect] ?? effect.defaults
            set(parameters.opacity, "effects.\(effect.rawValue).opacity")
            set(parameters.duration, "effects.\(effect.rawValue).duration")
        }
        switch value.pause {
        case .active: set("active", "pauseState"); defaults.removeObject(forKey: key("pauseDeadline"))
        case .manual: set("manual", "pauseState"); defaults.removeObject(forKey: key("pauseDeadline"))
        case .until(let deadline): set("until", "pauseState"); set(deadline.timeIntervalSince1970, "pauseDeadline")
        }
        set(2, "schemaVersion")
    }
    private func key(_ field: String) -> String { "matasehat." + field }
    private func set(_ value: Any, _ field: String) { defaults.set(value, forKey: key(field)) }
    private func string(_ field: String) -> String? { defaults.object(forKey: key(field)) as? String }
    private func boolean(_ field: String) -> Bool? {
        guard let value = defaults.object(forKey: key(field)) as? NSNumber,
              CFGetTypeID(value) == CFBooleanGetTypeID() else { return nil }
        return value.boolValue
    }
    private func number(_ field: String) -> Double? {
        guard let number = defaults.object(forKey: key(field)) as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(), number.doubleValue.isFinite else { return nil }
        return number.doubleValue
    }
}
