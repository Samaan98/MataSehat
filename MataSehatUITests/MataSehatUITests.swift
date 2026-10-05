import XCTest

final class MataSehatUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    @MainActor private func launch(suite: String, reset: Bool = true, showSettings: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--defaults-suite", suite]
        if showSettings { app.launchArguments.append("--show-settings") }
        if reset { app.launchArguments.append("--reset-defaults") }
        app.launch()
        return app
    }
    @MainActor func testSettingsOpenWithoutClickingMenuBar() {
        let app = launch(suite: "MataSehat.ui.\(UUID().uuidString)", showSettings: false)
        XCTAssertTrue(app.buttons["preview"].waitForExistence(timeout: 6))
        XCTAssertEqual(app.windows.count, 1)
    }
    @MainActor func testEffectsParametersPauseAndPersistence() {
        let suite = "MataSehat.ui.\(UUID().uuidString)"
        let app = launch(suite: suite)
        XCTAssertTrue(app.buttons["preview"].waitForExistence(timeout: 6))
        app.radioButtons["Глаз в центре"].click()
        app.sliders["duration"].adjust(toNormalizedSliderPosition: 0.75)
        app.sliders["opacity"].adjust(toNormalizedSliderPosition: 0.5)
        let duration = app.sliders["duration"].value as? String
        app.buttons["preview"].click()
        app.radioButtons["Затемнение"].click()
        XCTAssertTrue(app.sliders["opacity"].exists)
        app.buttons["preview"].click()
        app.radioButtons["Глаз в углу"].click()
        app.buttons["preview"].click()
        app.radioButtons["Глаз в центре"].click()
        app.popUpButtons["pauseOption"].click()
        app.menuItems["До включения"].click()
        app.buttons["pauseResume"].click()
        XCTAssertTrue(app.staticTexts["Пауза до включения"].waitForExistence(timeout: 2))
        app.terminate()
        _ = launch(suite: suite, reset: false)
        XCTAssertTrue(app.buttons["preview"].waitForExistence(timeout: 6))
        XCTAssertEqual(app.sliders["duration"].value as? String, duration)
        XCTAssertTrue(app.staticTexts["Пауза до включения"].exists)
        app.buttons["pauseResume"].click()
        XCTAssertTrue(app.staticTexts["Работает"].waitForExistence(timeout: 2))
    }
    @MainActor func testAppearanceSnapshots() {
        for appearance in ["light", "dark"] {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-testing", "--show-settings", "--defaults-suite", "MataSehat.ui.snapshots.\(appearance)", "--reset-defaults", "--appearance", appearance]
            app.launch()
            XCTAssertTrue(app.buttons["preview"].waitForExistence(timeout: 6))
            app.activate()
            let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
            attachment.name = "Settings-\(appearance)"
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
    }

    @MainActor func testClosingSettingsKeepsMenuBarControlAndReopensSameWindow() {
        let app = launch(suite: "MataSehat.ui.\(UUID().uuidString)")
        XCTAssertTrue(app.buttons["preview"].waitForExistence(timeout: 6))
        app.activate()
        app.typeKey("w", modifierFlags: .command)
        XCTAssertTrue(app.statusItems.firstMatch.waitForExistence(timeout: 3))
        app.statusItems.firstMatch.click()
        XCTAssertTrue(app.buttons["Настройки…"].waitForExistence(timeout: 3))
        app.buttons["Настройки…"].click()
        XCTAssertTrue(app.buttons["preview"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.windows.containing(.button, identifier: "preview").count, 1)
        app.statusItems.firstMatch.click()
        XCTAssertTrue(app.buttons["Настройки…"].waitForExistence(timeout: 3))
        app.buttons["Настройки…"].click()
        XCTAssertEqual(app.windows.containing(.button, identifier: "preview").count, 1)
    }

}
