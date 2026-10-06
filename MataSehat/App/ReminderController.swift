import AppKit
import Observation

@MainActor @Observable final class ReminderController {
    private(set) var state: ReminderState
    private(set) var loginItemStatus: LoginItemStatus
    private(set) var errorMessage: String?
    let isFirstLaunch: Bool
    @ObservationIgnored private let clock: any ReminderClock
    @ObservationIgnored private let store: any PreferencesStoring
    @ObservationIgnored private let scheduler: any ReminderScheduling
    @ObservationIgnored private let overlay: any OverlayPresenting
    @ObservationIgnored private let login: any LoginItemServicing
    @ObservationIgnored private let activity: any ActivityMonitoring
    @ObservationIgnored private let breakPresenter: any ScreenBreakPresenting
    @ObservationIgnored private let automaticReminders: Bool
    @ObservationIgnored private let soundPlayer: any ReminderSoundPlaying
    @ObservationIgnored private var started = false
    init(clock: any ReminderClock, store: any PreferencesStoring, scheduler: any ReminderScheduling, overlay: any OverlayPresenting, login: any LoginItemServicing, activity: any ActivityMonitoring, automaticReminders: Bool = true, breakPresenter: (any ScreenBreakPresenting)? = nil, soundPlayer: (any ReminderSoundPlaying)? = nil) {
        self.clock = clock; self.store = store; self.scheduler = scheduler
        self.overlay = overlay; self.login = login; self.activity = activity
        self.automaticReminders = automaticReminders
        self.breakPresenter = breakPresenter ?? InactiveScreenBreakPresenter()
        self.soundPlayer = soundPlayer ?? InactiveReminderSoundPlayer()
        let saved = store.load()
        isFirstLaunch = saved == nil
        state = ReminderEngine.initial(settings: saved?.settings ?? .defaults, pause: saved?.pause ?? .active, at: clock.now())
        loginItemStatus = login.status()
    }
    func start() {
        guard !started else { return }
        started = true
        activity.start { [weak self] event in
            guard let self else { return }
            switch event {
            case .suspended: self.send(.suspend)
            case .resumed: self.send(.wake); self.refreshLoginItemStatus()
            case .clockChanged: self.send(.tick)
            case .screenConfigurationChanged, .accessibilityChanged: self.send(.settingsChanged(self.state.settings))
            }
        }
        send(.wake)
        store.save(StoredPreferences(settings: state.settings, pause: state.pause))
    }
    func send(_ event: ReminderEvent) {
        guard started else { return }
        let previous = state
        let result = ReminderEngine.reduce(state, event: event, at: clock.now())
        if state != result.state { state = result.state }
        if previous.settings != state.settings || previous.pause != state.pause {
            store.save(StoredPreferences(settings: state.settings, pause: state.pause))
        }
        for command in result.commands {
            switch command {
            case .showBreak:
                breakPresenter.show(state.breakPhase, duration: state.breakDuration) { [weak self] event in self?.send(event) }
            case .playSound(let sound): soundPlayer.play(sound)
            case .hideBreak: breakPresenter.hide()
            case .hide: overlay.hide()
            case .show(let value):
                overlay.show(value, reduceMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion) { [weak self] id in
                    self?.send(.effectFinished(id))
                }
            }
        }
        scheduleNext()
    }
    func updateSettings(_ update: (inout ReminderSettings) -> Void) {
        var settings = state.settings
        update(&settings)
        send(.settingsChanged(settings))
    }
    private func scheduleNext() {
        scheduler.cancel()
        guard started, !state.suspended else { return }
        let now = clock.now()
        var delays: [TimeInterval] = []
        if case .resting(let deadline) = state.breakPhase {
            delays.append(max(0, deadline - now.monotonic))
        }
        if automaticReminders {
            for due in [state.nextDue, state.nextBreakDue].compactMap({ $0 }) {
                delays.append(max(0, due - now.monotonic))
            }
        }
        if automaticReminders, case .until(let deadline) = state.pause {
            // A bounded wake-up also notices clock changes even if their notification is missed.
            delays.append(min(60, max(0, deadline.timeIntervalSince(now.wall))))
        }
        if let delay = delays.min() {
            scheduler.schedule(after: delay) { [weak self] in self?.send(.tick) }
        }
    }
    func setLaunchAtLogin(_ enabled: Bool) {
        do { try login.setEnabled(enabled); errorMessage = nil }
        catch { errorMessage = String(localized: "Could not change launch at login: \(error.localizedDescription)") }
        refreshLoginItemStatus()
    }
    func refreshLoginItemStatus() { loginItemStatus = login.status() }
    func reportError(_ message: String) { errorMessage = message }
    func stop() {
        guard started else { return }
        started = false
        scheduler.cancel(); overlay.hide(); breakPresenter.hide(); activity.stop()
    }
}
