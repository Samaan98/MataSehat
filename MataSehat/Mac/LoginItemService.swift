import ServiceManagement

nonisolated enum LoginItemStatus: Equatable { case enabled, disabled, requiresApproval, unavailable }
@MainActor protocol LoginItemServicing {
    func status() -> LoginItemStatus
    func setEnabled(_ enabled: Bool) throws
}
@MainActor final class LoginItemService: LoginItemServicing {
    func status() -> LoginItemStatus {
        switch SMAppService.mainApp.status {
        case .enabled: .enabled
        case .notRegistered: .disabled
        case .requiresApproval: .requiresApproval
        case .notFound: .unavailable
        @unknown default: .unavailable
        }
    }
    func setEnabled(_ enabled: Bool) throws {
        if enabled { try SMAppService.mainApp.register() }
        else { try SMAppService.mainApp.unregister() }
    }
}
