import ServiceManagement
import Testing
@testable import MataSehat

@MainActor struct LoginItemServiceTests {
    @Test(arguments: [
        (SMAppService.Status.notFound, LoginItemStatus.disabled),
        (.notRegistered, .disabled),
        (.enabled, .enabled),
        (.requiresApproval, .requiresApproval)
    ])
    func systemStatusAllowsRegistrationAndPreservesApproval(
        systemStatus: SMAppService.Status, expected: LoginItemStatus
    ) {
        #expect(LoginItemService.status(for: systemStatus) == expected)
    }
}
