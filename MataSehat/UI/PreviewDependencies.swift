#if DEBUG
import SwiftUI

@MainActor enum PreviewDependencies {
    static func make(pause: PauseState = .active) -> ReminderController {
        let controller = ReminderController(clock: SystemReminderClock(),
            store: PreviewStore(pause: pause), scheduler: PreviewScheduler(),
            overlay: PreviewOverlay(), login: PreviewLogin(),
            activity: InactiveActivityMonitor(), automaticReminders: false)
        controller.start()
        return controller
    }
}

@MainActor private final class PreviewStore: PreferencesStoring {
    var value: StoredPreferences
    init(pause: PauseState) { value = StoredPreferences(settings: .defaults, pause: pause) }
    func load() -> StoredPreferences? { value }
    func save(_ value: StoredPreferences) { self.value = value }
}

@MainActor private final class PreviewScheduler: ReminderScheduling {
    func schedule(after delay: TimeInterval, action: @escaping @MainActor () -> Void) {}
    func cancel() {}
}

@MainActor private final class PreviewOverlay: OverlayPresenting {
    func show(_ value: EffectPresentation, reduceMotion: Bool, completion: @escaping @MainActor (UInt64) -> Void) { completion(value.id) }
    func hide() {}
}

@MainActor private final class PreviewLogin: LoginItemServicing {
    private var current: LoginItemStatus = .disabled
    func status() -> LoginItemStatus { current }
    func setEnabled(_ enabled: Bool) throws { current = enabled ? .enabled : .disabled }
}

#Preview("Settings") {
    SettingsView(controller: PreviewDependencies.make())
}

#Preview("Paused panel") {
    QuickPanelView(controller: PreviewDependencies.make(pause: .manual), showSettings: {})
}
#endif
