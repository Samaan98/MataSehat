import Foundation

nonisolated enum PauseState: Equatable, Sendable { case active, until(Date), manual }
nonisolated enum PresentationOrigin: Equatable, Sendable { case scheduled, preview }
nonisolated struct EffectPresentation: Equatable, Sendable {
    let id: UInt64
    let effect: ReminderEffect
    let settings: EffectSettings
    let origin: PresentationOrigin
}
nonisolated struct ReminderState: Equatable, Sendable {
    var settings: ReminderSettings
    var pause: PauseState
    var suspended: Bool = false
    var nextDue: TimeInterval?
    var generation: UInt64 = 0
    var presentation: EffectPresentation?
}
nonisolated enum ReminderEvent: Sendable {
    case tick, pause(PauseOption), resume, settingsChanged(ReminderSettings), preview, suspend, wake, effectFinished(UInt64)
}
nonisolated enum EffectCommand: Equatable, Sendable { case show(EffectPresentation), hide }
nonisolated struct EngineResult: Sendable { let state: ReminderState; let commands: [EffectCommand] }
nonisolated enum ReminderEngine {
    static func initial(settings: ReminderSettings, pause: PauseState, at time: ClockSnapshot) -> ReminderState {
        var state = ReminderState(settings: settings.validated(), pause: pause)
        expirePause(&state, at: time)
        resetInterval(&state, at: time)
        return state
    }
    static func reduce(_ original: ReminderState, event: ReminderEvent, at time: ClockSnapshot) -> EngineResult {
        var state = original
        var commands: [EffectCommand] = []
        func hide() {
            state.presentation = nil
            commands.append(.hide)
        }
        func show(_ origin: PresentationOrigin) {
            state.generation &+= 1
            let value = EffectPresentation(id: state.generation, effect: state.settings.effect,
                settings: state.settings.effects[state.settings.effect] ?? state.settings.effect.defaults, origin: origin)
            state.presentation = value
            commands.append(.show(value))
        }
        switch event {
        case .tick:
            guard !state.suspended else { break }
            if expirePause(&state, at: time) {
                resetInterval(&state, at: time)
            } else if state.pause == .active, let due = state.nextDue, time.monotonic >= due {
                state.nextDue = time.monotonic + state.settings.interval
                if state.presentation == nil { show(.scheduled) }
            }
        case .pause(let option):
            hide()
            let valid = PauseOption.all.contains(option) ? option : .minutes(15)
            state.settings.pauseOption = valid
            switch valid {
            case .manual: state.pause = .manual
            case .minutes(let minutes): state.pause = .until(time.wall.addingTimeInterval(Double(minutes * 60)))
            }
            state.nextDue = nil
        case .resume:
            hide()
            state.pause = .active
            resetInterval(&state, at: time)
        case .settingsChanged(let settings):
            hide()
            state.settings = settings.validated()
            expirePause(&state, at: time)
            resetInterval(&state, at: time)
        case .preview:
            guard !state.suspended else { break }
            show(.preview)
            state.nextDue = nil
        case .suspend:
            hide()
            state.suspended = true
            state.nextDue = nil
        case .wake:
            hide()
            state.suspended = false
            expirePause(&state, at: time)
            resetInterval(&state, at: time)
        case .effectFinished(let id):
            guard let presentation = state.presentation, presentation.id == id else { break }
            hide()
            if presentation.origin == .preview { resetInterval(&state, at: time) }
        }
        return EngineResult(state: state, commands: commands)
    }
    @discardableResult private static func expirePause(_ state: inout ReminderState, at time: ClockSnapshot) -> Bool {
        if case .until(let deadline) = state.pause, deadline <= time.wall {
            state.pause = .active
            return true
        }
        return false
    }
    private static func resetInterval(_ state: inout ReminderState, at time: ClockSnapshot) {
        state.nextDue = state.pause == .active && !state.suspended ? time.monotonic + state.settings.interval : nil
    }
}
