import SwiftUI

@main
struct MataSehatApp: App {
    @NSApplicationDelegateAdaptor(ApplicationDelegate.self) private var delegate
    @State private var controller: ReminderController
    init() {
        let configuration = AppConfiguration()
        let testing = configuration.isUITesting || configuration.isUnitTesting
        let overlay = OverlayWindowController()
        let breaks = ScreenBreakWindowController()
        let controller = ReminderController(clock: SystemReminderClock(),
            store: PreferencesStore(defaults: configuration.defaults), scheduler: ReminderScheduler(),
            overlay: overlay, login: testing ? InactiveLoginItemService() : LoginItemService(),
            activity: testing ? InactiveActivityMonitor() : SystemActivityMonitor(),
            automaticReminders: !testing, breakPresenter: breaks,
            soundPlayer: testing ? InactiveReminderSoundPlayer() : ReminderSoundPlayer())
        overlay.onError = { [weak controller] message in controller?.reportError(message) }
        breaks.onError = { [weak controller] message in controller?.reportError(message) }
        _controller = State(initialValue: controller)
        delegate.controller = controller
    }
    var body: some Scene {
        MenuBarExtra("MataSehat", systemImage: "eye") {
            QuickPanelView(controller: controller, showSettings: delegate.showSettings)
        }
            .menuBarExtraStyle(.window)
    }
}
