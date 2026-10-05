import ServiceManagement

nonisolated enum LoginItemStatus: Equatable { case enabled, disabled, requiresApproval, unavailable }
@MainActor protocol LoginItemServicing {
    func status() -> LoginItemStatus
    func setEnabled(_ enabled: Bool) throws
}
@MainActor final class LoginItemService: LoginItemServicing {
    func status() -> LoginItemStatus {
        Self.status(for: SMAppService.mainApp.status)
    }
    static func status(for systemStatus: SMAppService.Status) -> LoginItemStatus {
        switch systemStatus {
        case .enabled: .enabled
        // A missing service may simply need registration. Let register() report any failure.
        case .notRegistered, .notFound: .disabled
        case .requiresApproval: .requiresApproval
        @unknown default: .unavailable
        }
    }
    func setEnabled(_ enabled: Bool) throws {
        if enabled { try SMAppService.mainApp.register() }
        else { try SMAppService.mainApp.unregister() }
    }
}
