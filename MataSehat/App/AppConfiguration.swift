import Foundation

nonisolated struct AppConfiguration {
    let arguments: [String]
    init(arguments: [String] = ProcessInfo.processInfo.arguments) { self.arguments = arguments }
    var isUITesting: Bool { arguments.contains("--ui-testing") }
    var isUnitTesting: Bool {
        !isUITesting && (ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil || NSClassFromString("XCTestCase") != nil)
    }
    var showSettings: Bool { arguments.contains("--show-settings") }
    var defaults: UserDefaults {
        guard isUITesting else { return .standard }
        let requested = value(after: "--defaults-suite") ?? "MataSehat.ui.default"
        let name = requested.hasPrefix("MataSehat.ui.") ? requested : "MataSehat.ui.default"
        let suite = UserDefaults(suiteName: name)!
        if arguments.contains("--reset-defaults") { suite.removePersistentDomain(forName: name) }
        return suite
    }
    func value(after flag: String) -> String? {
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1) else { return nil }
        return arguments[index + 1]
    }
}
@MainActor final class InactiveLoginItemService: LoginItemServicing {
    func status() -> LoginItemStatus { .disabled }
    func setEnabled(_ enabled: Bool) throws { throw CocoaError(.featureUnsupported) }
}
@MainActor final class InactiveActivityMonitor: ActivityMonitoring {
    func start(onEvent: @escaping @MainActor (ActivityEvent) -> Void) {}
    func stop() {}
}
