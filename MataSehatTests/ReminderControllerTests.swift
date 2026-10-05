import Foundation
import Testing
@testable import MataSehat

nonisolated final class TestClock: ReminderClock {
    var wall = Date(timeIntervalSince1970: 1_000)
    var mono = 0.0
    func now() -> ClockSnapshot { ClockSnapshot(wall: wall, monotonic: mono) }
    func advance(_ seconds: Double) { wall.addTimeInterval(seconds); mono += seconds }
}
@MainActor final class TestStore: PreferencesStoring {
    var value: StoredPreferences?
    var saves = 0
    func load() -> StoredPreferences? { value }
    func save(_ value: StoredPreferences) { self.value = value; saves += 1 }
}
@MainActor final class TestScheduler: ReminderScheduling {
    var action: (@MainActor () -> Void)?
    var delay: TimeInterval?
    var schedules = 0
    func schedule(after delay: TimeInterval, action: @escaping @MainActor () -> Void) { self.delay = delay; self.action = action; schedules += 1 }
    func cancel() { action = nil; delay = nil }
    func fire() { let action = action; self.action = nil; action?() }
}
@MainActor final class TestOverlay: OverlayPresenting {
    var values: [EffectPresentation] = []
    var completions: [UInt64: @MainActor (UInt64) -> Void] = [:]
    var hides = 0
    func show(_ value: EffectPresentation, reduceMotion: Bool, completion: @escaping @MainActor (UInt64) -> Void) { values.append(value); completions[value.id] = completion }
    func hide() { hides += 1 }
}
@MainActor final class TestLogin: LoginItemServicing {
    var current: LoginItemStatus = .disabled
    var fails = false
    func status() -> LoginItemStatus { current }
    func setEnabled(_ enabled: Bool) throws {
        if fails { throw CocoaError(.fileWriteNoPermission) }
        current = enabled ? .requiresApproval : .disabled
    }
}
@MainActor final class TestActivity: ActivityMonitoring {
    var handler: (@MainActor (ActivityEvent) -> Void)?
    var starts = 0
    func start(onEvent: @escaping @MainActor (ActivityEvent) -> Void) { handler = onEvent; starts += 1 }
    func stop() { handler = nil }
}
@MainActor struct ControllerFixture {
    let clock = TestClock()
    let store = TestStore()
    let scheduler = TestScheduler()
    let overlay = TestOverlay()
    let login = TestLogin()
    let activity = TestActivity()
    let breaks = TestBreakPresenter()
    func make() -> ReminderController {
        ReminderController(clock: clock, store: store, scheduler: scheduler, overlay: overlay, login: login, activity: activity, breakPresenter: breaks)
    }
}
@MainActor final class TestBreakPresenter: ScreenBreakPresenting {
    var values: [ScreenBreakPhase] = []
    var hides = 0
    var action: (@MainActor (ReminderEvent) -> Void)?
    func show(_ phase: ScreenBreakPhase, onAction: @escaping @MainActor (ReminderEvent) -> Void) { values.append(phase); action = onAction }
    func hide() { hides += 1; action = nil }
}
@MainActor struct ReminderControllerTests {
    @Test func breakCardActionsUseSchedulerAndStopReleasesPresentation() {
        let f = ControllerFixture(); let controller = f.make(); controller.start()
        f.clock.advance(1_200); f.scheduler.fire()
        #expect(controller.state.breakPhase == .invitation)
        #expect(f.breaks.values == [.invitation])
        f.breaks.action?(.startBreak)
        #expect(controller.state.breakPhase == .resting(until: 1_220))
        #expect(f.scheduler.delay == 20)
        let effectsBeforeRest = f.overlay.values.count
        f.clock.advance(19)
        controller.send(.tick)
        #expect(f.overlay.values.count == effectsBeforeRest)
        f.clock.advance(1); f.scheduler.fire()
        #expect(controller.state.breakPhase == .waiting)
        #expect(f.breaks.action == nil)
        #expect(f.scheduler.delay == 10)
        controller.send(.startBreak)
        controller.stop()
        #expect(f.breaks.action == nil)
        #expect(f.scheduler.action == nil)
    }
    @Test func explicitRestFinishesEvenWhenAutomaticRemindersAreDisabled() {
        let f = ControllerFixture()
        let controller = ReminderController(clock: f.clock, store: f.store, scheduler: f.scheduler,
            overlay: f.overlay, login: f.login, activity: f.activity,
            automaticReminders: false, breakPresenter: f.breaks)
        controller.start(); controller.send(.pause(.manual)); controller.send(.startBreak)
        #expect(f.scheduler.delay == 20)
        f.clock.advance(20); f.scheduler.fire()
        #expect(controller.state.breakPhase == .waiting)
        #expect(controller.state.pause == .manual)
        #expect(f.scheduler.action == nil)
    }
    @Test func startIsIdempotentAndStopCancelsEverything() {
        let f = ControllerFixture(); let controller = f.make()
        controller.start(); controller.start()
        #expect(f.activity.starts == 1)
        #expect(f.scheduler.delay == 10)
        #expect(f.scheduler.schedules == 1)
        controller.stop()
        #expect(f.scheduler.action == nil)
        #expect(f.activity.handler == nil)
        #expect(f.overlay.hides > 0)
    }
    @Test(arguments: [PauseState.active, .manual, .until(Date(timeIntervalSince1970: 900))])
    func restorationDoesNotLosePause(pause: PauseState) {
        let f = ControllerFixture()
        f.store.value = StoredPreferences(settings: .defaults, pause: pause)
        let controller = f.make(); controller.start()
        #expect(controller.state.pause == (pause == .manual ? .manual : .active))
        #expect(f.scheduler.delay == (pause == .manual ? nil : 10))
    }
    @Test func previewCompletionCannotHideNewerPreviewAndPausePersists() throws {
        let f = ControllerFixture(); let controller = f.make(); controller.start()
        controller.send(.pause(.manual))
        controller.send(.preview)
        let first = try #require(f.overlay.values.last)
        controller.send(.preview)
        let second = try #require(f.overlay.values.last)
        f.overlay.completions[first.id]?(first.id)
        #expect(controller.state.presentation?.id == second.id)
        f.overlay.completions[second.id]?(second.id)
        #expect(controller.state.presentation == nil)
        #expect(controller.state.pause == .manual)
        #expect(f.store.value?.pause == .manual)
        #expect(f.scheduler.action == nil)
    }
    @Test func loginErrorsAndApprovalReflectActualStatus() {
        let f = ControllerFixture(); let controller = f.make()
        f.login.fails = true
        controller.setLaunchAtLogin(true)
        #expect(controller.loginItemStatus == .disabled)
        #expect(controller.errorMessage != nil)
        f.login.fails = false
        controller.setLaunchAtLogin(true)
        #expect(controller.loginItemStatus == .requiresApproval)
        #expect(controller.errorMessage == nil)
    }
    @Test func wakeResetsTimerAndScheduledEffectsUseCurrentSettings() {
        let f = ControllerFixture(); let controller = f.make(); controller.start()
        f.clock.advance(10); f.scheduler.fire()
        #expect(f.overlay.values.count == 1)
        f.activity.handler?(.suspended)
        #expect(f.scheduler.action == nil)
        f.clock.advance(500); f.activity.handler?(.resumed)
        #expect(f.scheduler.delay == 10)
        #expect(controller.state.presentation == nil)
    }
    @Test func previewAfterStopIsIgnored() {
        let f = ControllerFixture(); let controller = f.make(); controller.start(); controller.stop()
        controller.send(.preview)
        #expect(f.overlay.values.isEmpty)
    }
}
