import Foundation

nonisolated enum ReminderEffect: String, CaseIterable, Sendable {
    case eye, dim
    var title: LocalizedStringResource {
        switch self { case .eye: "Eye"; case .dim: "Dim" }
    }
    var opacityRange: ClosedRange<Double> { self == .dim ? 0.02...0.5 : 0.4...1 }
    var durationRange: ClosedRange<Double> { self == .dim ? 0.1...2 : 0.5...2 }
    var defaults: EffectSettings { EffectSettings(opacity: self == .dim ? 0.2 : 1, duration: self == .dim ? 0.3 : 1) }
}
nonisolated struct EffectSettings: Equatable, Sendable {
    var opacity: Double
    var duration: TimeInterval
}
nonisolated enum PauseOption: Equatable, Hashable, Sendable {
    case minutes(Int), manual
    static let all: [Self] = [.minutes(5), .minutes(15), .minutes(30), .minutes(60), .manual]
    var title: LocalizedStringResource { switch self { case .minutes(let value): "\(value) min"; case .manual: "Until resumed" } }
}
nonisolated struct ReminderSettings: Equatable, Sendable {
    var effect: ReminderEffect
    var interval: TimeInterval
    var effects: [ReminderEffect: EffectSettings]
    var pauseOption: PauseOption
    var screenBreaksEnabled = true
    var eyePosition: EyePosition = .center
    var eyeScale = 1.0
    var screenBreakInterval: TimeInterval = 1_200
    var screenBreakDuration: TimeInterval = 20
    var screenBreakSoundsEnabled = true
    static let intervals: [TimeInterval] = [3, 4, 5, 10, 20, 30]
    static let eyeScaleRange = 0.5...2.0
    static let screenBreakIntervalRange: ClosedRange<TimeInterval> = 60...7_200
    static let screenBreakDurationRange: ClosedRange<TimeInterval> = 5...300
    static var defaults: Self {
        Self(effect: .eye, interval: 5, effects: Dictionary(uniqueKeysWithValues: ReminderEffect.allCases.map { ($0, $0.defaults) }), pauseOption: .minutes(15))
    }
    func validated() -> Self {
        var value = self
        if !Self.intervals.contains(value.interval) { value.interval = Self.defaults.interval }
        if !PauseOption.all.contains(value.pauseOption) { value.pauseOption = Self.defaults.pauseOption }
        if !value.eyeScale.isFinite || !Self.eyeScaleRange.contains(value.eyeScale) { value.eyeScale = 1 }
        if !value.screenBreakInterval.isFinite || !Self.screenBreakIntervalRange.contains(value.screenBreakInterval) {
            value.screenBreakInterval = 1_200
        } else {
            value.screenBreakInterval = (value.screenBreakInterval / 60).rounded() * 60
        }
        if !value.screenBreakDuration.isFinite || !Self.screenBreakDurationRange.contains(value.screenBreakDuration) {
            value.screenBreakDuration = 20
        } else {
            value.screenBreakDuration = value.screenBreakDuration.rounded()
        }
        for effect in ReminderEffect.allCases {
            var parameters = value.effects[effect] ?? effect.defaults
            if !parameters.opacity.isFinite || !effect.opacityRange.contains(parameters.opacity) {
                parameters.opacity = effect.defaults.opacity
            }
            if !parameters.duration.isFinite || !effect.durationRange.contains(parameters.duration) {
                parameters.duration = effect.defaults.duration
            }
            value.effects[effect] = parameters
        }
        return value
    }
}
