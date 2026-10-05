import AppKit

nonisolated enum ActivityEvent: Equatable, Sendable {
    case suspended, resumed, screenConfigurationChanged, clockChanged, accessibilityChanged
}
nonisolated enum SuspensionReason: Hashable { case sleep, display, session, locked }
nonisolated struct ActivitySuspension {
    private(set) var reasons: Set<SuspensionReason> = []
    mutating func update(_ reason: SuspensionReason, suspended: Bool) -> ActivityEvent? {
        let wasSuspended = !reasons.isEmpty
        if suspended { reasons.insert(reason) } else { reasons.remove(reason) }
        let isSuspended = !reasons.isEmpty
        guard wasSuspended != isSuspended else { return nil }
        return isSuspended ? .suspended : .resumed
    }
}
@MainActor protocol ActivityMonitoring {
    func start(onEvent: @escaping @MainActor (ActivityEvent) -> Void)
    func stop()
}

@MainActor final class SystemActivityMonitor: ActivityMonitoring {
    private var tokens: [(NotificationCenter, NSObjectProtocol)] = []
    private var distributedTokens: [NSObjectProtocol] = []
    private var suspension = ActivitySuspension()
    private var handler: (@MainActor (ActivityEvent) -> Void)?
    func start(onEvent: @escaping @MainActor (ActivityEvent) -> Void) {
        stop()
        handler = onEvent
        let workspace = NSWorkspace.shared.notificationCenter
        observe(workspace, NSWorkspace.willSleepNotification, reason: .sleep, suspended: true)
        observe(workspace, NSWorkspace.didWakeNotification, reason: .sleep, suspended: false)
        observe(workspace, NSWorkspace.screensDidSleepNotification, reason: .display, suspended: true)
        observe(workspace, NSWorkspace.screensDidWakeNotification, reason: .display, suspended: false)
        observe(workspace, NSWorkspace.sessionDidResignActiveNotification, reason: .session, suspended: true)
        observe(workspace, NSWorkspace.sessionDidBecomeActiveNotification, reason: .session, suspended: false)
        observe(.default, NSApplication.didChangeScreenParametersNotification, event: .screenConfigurationChanged)
        observe(.default, .NSSystemClockDidChange, event: .clockChanged)
        observe(workspace, NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, event: .accessibilityChanged)
        for (name, locked) in [("com.apple.screenIsLocked", true), ("com.apple.screenIsUnlocked", false)] {
            let token = DistributedNotificationCenter.default().addObserver(forName: Notification.Name(name), object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor [weak self] in self?.update(.locked, suspended: locked) }
            }
            distributedTokens.append(token)
        }
    }
    private func observe(_ center: NotificationCenter, _ name: Notification.Name, reason: SuspensionReason, suspended: Bool) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.update(reason, suspended: suspended) }
        }
        tokens.append((center, token))
    }
    private func observe(_ center: NotificationCenter, _ name: Notification.Name, event: ActivityEvent) {
        let token = center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.handler?(event) }
        }
        tokens.append((center, token))
    }
    private func update(_ reason: SuspensionReason, suspended: Bool) {
        if let event = suspension.update(reason, suspended: suspended) { handler?(event) }
    }
    func stop() {
        tokens.forEach { $0.0.removeObserver($0.1) }
        tokens.removeAll()
        distributedTokens.forEach { DistributedNotificationCenter.default().removeObserver($0) }
        distributedTokens.removeAll()
        handler = nil
        suspension = ActivitySuspension()
    }
}
