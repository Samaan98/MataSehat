import Foundation

nonisolated enum ReminderEffect: String, CaseIterable, Sendable {
    case cornerEye, centerEye, dim
    var title: String {
        switch self { case .cornerEye: "Глаз в углу"; case .centerEye: "Глаз в центре"; case .dim: "Затемнение" }
    }
    var opacityRange: ClosedRange<Double> { self == .dim ? 0.02...0.2 : 0.4...1 }
    var defaults: EffectSettings { EffectSettings(opacity: self == .dim ? 0.06 : 0.8, duration: 1) }
}
nonisolated struct EffectSettings: Equatable, Sendable {
    var opacity: Double
    var duration: TimeInterval
}
nonisolated enum PauseOption: Equatable, Hashable, Sendable {
    case minutes(Int), manual
    static let all: [Self] = [.minutes(5), .minutes(15), .minutes(30), .minutes(60), .manual]
    var title: String { switch self { case .minutes(let value): "\(value) мин"; case .manual: "До включения" } }
}
nonisolated struct ReminderSettings: Equatable, Sendable {
    var effect: ReminderEffect
    var interval: TimeInterval
    var effects: [ReminderEffect: EffectSettings]
    var pauseOption: PauseOption
    var screenBreaksEnabled = true
    static let intervals: [TimeInterval] = [5, 10, 15, 20, 30]
    static var defaults: Self {
        Self(effect: .cornerEye, interval: 10, effects: Dictionary(uniqueKeysWithValues: ReminderEffect.allCases.map { ($0, $0.defaults) }), pauseOption: .minutes(15))
    }
    func validated() -> Self {
        var value = self
        if !Self.intervals.contains(value.interval) { value.interval = Self.defaults.interval }
        if !PauseOption.all.contains(value.pauseOption) { value.pauseOption = Self.defaults.pauseOption }
        for effect in ReminderEffect.allCases {
            var parameters = value.effects[effect] ?? effect.defaults
            if !parameters.opacity.isFinite || !effect.opacityRange.contains(parameters.opacity) {
                parameters.opacity = effect.defaults.opacity
            }
            if !parameters.duration.isFinite || !(0.5...2).contains(parameters.duration) {
                parameters.duration = effect.defaults.duration
            }
            value.effects[effect] = parameters
        }
        return value
    }
}
