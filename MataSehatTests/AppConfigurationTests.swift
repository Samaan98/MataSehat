import Foundation
import Testing
@testable import MataSehat

@MainActor struct AppConfigurationTests {
    @Test func invalidTestSuiteDoesNotUseUserPreferences() {
        let configuration = AppConfiguration(arguments: ["--ui-testing", "--defaults-suite", "unrelated.preferences"])
        #expect(configuration.defaults !== UserDefaults.standard)
    }
}
