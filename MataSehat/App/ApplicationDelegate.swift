import AppKit
import SwiftUI

@MainActor final class ApplicationDelegate: NSObject, NSApplicationDelegate {
    var controller: ReminderController?
    private var settingsScene: NSHostingSceneRepresentation<Settings<AnyView>>?
    func applicationWillFinishLaunching(_ notification: Notification) {
        guard !AppConfiguration().isUnitTesting, let controller else { return }
        let scene = NSHostingSceneRepresentation {
            Settings {
                AnyView(SettingsView(controller: controller).preferredColorScheme(testAppearance))
            }
        }
        settingsScene = scene
        NSApp.addSceneRepresentation(scene)
    }
    func applicationDidFinishLaunching(_ notification: Notification) {
        let configuration = AppConfiguration()
        guard !configuration.isUnitTesting, let controller else { return }
        if !configuration.isUITesting, let bundleID = Bundle.main.bundleIdentifier {
            let existing = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
                .first { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier && !$0.isTerminated }
            if let existing { existing.activate(options: []); NSApp.terminate(nil); return }
        }
        controller.start()
        if controller.isFirstLaunch || configuration.showSettings {
            showSettings()
        }
    }
    func showSettings() {
        NSApp.activate()
        settingsScene?.environment.openSettings()
    }
    private var testAppearance: ColorScheme? {
        let configuration = AppConfiguration()
        guard configuration.isUITesting else { return nil }
        switch configuration.value(after: "--appearance") { case "light": return .light; case "dark": return .dark; default: return nil }
    }
    func applicationDidBecomeActive(_ notification: Notification) { controller?.refreshLoginItemStatus() }
    func applicationWillTerminate(_ notification: Notification) { controller?.stop() }
}
