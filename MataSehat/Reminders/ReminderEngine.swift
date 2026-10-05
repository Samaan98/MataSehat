import Foundation

nonisolated enum PauseState: Equatable, Sendable { case active, until(Date), manual }
nonisolated enum PresentationOrigin: Equatable, Sendable { case scheduled, preview }
nonisolated enum ScreenBreakPhase: Equatable, Sendable {
    case waiting, invitation, resting(until: TimeInterval)
    var isResting: Bool { if case .resting = self { true } else { false } }
}
nonisolated enum ScreenBreakTiming {
    static let interval: TimeInterval = 1_200
    static let duration: TimeInterval = 20
    static let snooze: TimeInterval = 300
}
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
    var breakPhase: ScreenBreakPhase = .waiting
    var nextBreakDue: TimeInterval?
}
nonisolated enum ReminderEvent: Sendable {
    case tick, pause(PauseOption), resume, settingsChanged(ReminderSettings), preview, suspend, wake, effectFinished(UInt64)
    case requestBreak, startBreak, snoozeBreak, finishBreak
}
nonisolated enum EffectCommand: Equatable, Sendable { case show(EffectPresentation), hide, showBreak, hideBreak }
nonisolated struct EngineResult: Sendable { let state: ReminderState; let commands: [EffectCommand] }
nonisolated enum ReminderEngine {
    static func initial(settings: ReminderSettings, pause: PauseState, at time: ClockSnapshot) -> ReminderState {
        var state = ReminderState(settings: settings.validated(), pause: pause)
        expirePause(&state, at: time)
        resetInterval(&state, at: time)
        resetBreakCycle(&state, at: time)
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
        func hideBreak() {
            if state.breakPhase != .waiting { commands.append(.hideBreak) }
            state.breakPhase = .waiting
        }
        func finishBreak() {
            hideBreak()
            resetInterval(&state, at: time)
            resetBreakCycle(&state, at: time)
        }
        switch event {
        case .requestBreak:
            guard !state.suspended, !state.breakPhase.isResting else { break }
            hide()
            state.breakPhase = .invitation
            state.nextBreakDue = nil
            resetInterval(&state, at: time)
            commands.append(.showBreak)
        case .startBreak:
            guard !state.suspended, !state.breakPhase.isResting else { break }
            hide()
            state.breakPhase = .resting(until: time.monotonic + ScreenBreakTiming.duration)
            state.nextDue = nil
            state.nextBreakDue = nil
            commands.append(.showBreak)
        case .snoozeBreak:
            guard state.breakPhase == .invitation else { break }
            hideBreak()
            resetInterval(&state, at: time)
            resetBreakCycle(&state, at: time, delay: ScreenBreakTiming.snooze)
        case .finishBreak:
            guard state.breakPhase.isResting else { break }
            finishBreak()
        case .tick:
            guard !state.suspended else { break }
            if expirePause(&state, at: time) {
                resetInterval(&state, at: time)
                if state.breakPhase == .waiting { resetBreakCycle(&state, at: time) }
            }
            if case .resting(let deadline) = state.breakPhase {
                if time.monotonic >= deadline { finishBreak() }
                break
            }
            if state.pause == .active, let due = state.nextBreakDue, time.monotonic >= due {
                hide()
                state.breakPhase = .invitation
                state.nextBreakDue = nil
                resetInterval(&state, at: time)
                commands.append(.showBreak)
            } else if state.pause == .active, let due = state.nextDue, time.monotonic >= due {
                state.nextDue = time.monotonic + state.settings.interval
                if state.presentation == nil { show(.scheduled) }
            }
        case .pause(let option):
            hide()
            hideBreak()
            let valid = PauseOption.all.contains(option) ? option : .minutes(15)
            state.settings.pauseOption = valid
            switch valid {
            case .manual: state.pause = .manual
            case .minutes(let minutes): state.pause = .until(time.wall.addingTimeInterval(Double(minutes * 60)))
            }
            state.nextDue = nil
            state.nextBreakDue = nil
        case .resume:
            hide()
            hideBreak()
            state.pause = .active
            resetInterval(&state, at: time)
            resetBreakCycle(&state, at: time)
        case .settingsChanged(let settings):
            hide()
            let breakEnabledChanged = state.settings.screenBreaksEnabled != settings.screenBreaksEnabled
            state.settings = settings.validated()
            let pauseExpired = expirePause(&state, at: time)
            if breakEnabledChanged, !state.breakPhase.isResting {
                hideBreak()
                resetBreakCycle(&state, at: time)
            } else if pauseExpired, state.breakPhase == .waiting {
                resetBreakCycle(&state, at: time)
            }
            resetInterval(&state, at: time)
        case .preview:
            guard !state.suspended, !state.breakPhase.isResting else { break }
            show(.preview)
            state.nextDue = nil
        case .suspend:
            hide()
            hideBreak()
            state.suspended = true
            state.nextDue = nil
            state.nextBreakDue = nil
        case .wake:
            hide()
            hideBreak()
            state.suspended = false
            expirePause(&state, at: time)
            resetInterval(&state, at: time)
            resetBreakCycle(&state, at: time)
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
        state.nextDue = state.pause == .active && !state.suspended && !state.breakPhase.isResting ? time.monotonic + state.settings.interval : nil
    }
    private static func resetBreakCycle(_ state: inout ReminderState, at time: ClockSnapshot, delay: TimeInterval = ScreenBreakTiming.interval) {
        state.nextBreakDue = state.settings.screenBreaksEnabled && state.pause == .active && !state.suspended
            ? time.monotonic + delay : nil
    }
}
