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
    @ObservationIgnored private let automaticReminders: Bool
    @ObservationIgnored private var started = false
    init(clock: any ReminderClock, store: any PreferencesStoring, scheduler: any ReminderScheduling, overlay: any OverlayPresenting, login: any LoginItemServicing, activity: any ActivityMonitoring, automaticReminders: Bool = true) {
        self.clock = clock; self.store = store; self.scheduler = scheduler
        self.overlay = overlay; self.login = login; self.activity = activity
        self.automaticReminders = automaticReminders
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
        guard started, automaticReminders, !state.suspended else { return }
        let now = clock.now()
        var delay: TimeInterval?
        if let nextDue = state.nextDue { delay = max(0, nextDue - now.monotonic) }
        if case .until(let deadline) = state.pause {
            // A bounded wake-up also notices clock changes even if their notification is missed.
            delay = min(60, max(0, deadline.timeIntervalSince(now.wall)))
        }
        if let delay {
            scheduler.schedule(after: delay) { [weak self] in self?.send(.tick) }
        }
    }
    func setLaunchAtLogin(_ enabled: Bool) {
        do { try login.setEnabled(enabled); errorMessage = nil }
        catch { errorMessage = "Не удалось изменить запуск при входе: \(error.localizedDescription)" }
        refreshLoginItemStatus()
    }
    func refreshLoginItemStatus() { loginItemStatus = login.status() }
    func reportError(_ message: String) { errorMessage = message }
    func stop() {
        guard started else { return }
        started = false
        scheduler.cancel(); overlay.hide(); activity.stop()
    }
}
