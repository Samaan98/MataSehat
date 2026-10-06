import XCTest

final class MataSehatUITests: XCTestCase {
    @MainActor func testScreenBreakStartsManuallySnoozesAndCompletes() {
        let suite = "MataSehat.ui.\(UUID().uuidString)"
        let app = launch(suite: suite)
        XCTAssertTrue(app.buttons["preview"].waitForExistence(timeout: 6))
        app.radioButtons["5 с"].click()
        XCTAssertTrue(app.buttons["breakPreview"].waitForExistence(timeout: 3))
        app.buttons["breakPreview"].click()
        XCTAssertTrue(app.buttons["startBreak"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["restCountdown"].exists)
        app.buttons["snoozeBreak"].click()
        XCTAssertFalse(app.buttons["startBreak"].exists)
        app.buttons["breakPreview"].click()
        app.buttons["startBreak"].click()
        XCTAssertTrue(app.staticTexts["restCountdown"].waitForExistence(timeout: 3))
        let countdown = app.staticTexts["restCountdown"]
        let initialCountdown = countdown.value as? String
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            countdown.exists && (countdown.value as? String) != initialCountdown
        }, object: countdown)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 4), .completed)
        XCTAssertTrue(app.buttons["endBreak"].waitForNonExistence(timeout: 24))
        app.switches["screenBreaksEnabled"].click()
        app.terminate()
        _ = launch(suite: suite, reset: false)
        XCTAssertTrue(app.buttons["preview"].waitForExistence(timeout: 6))
        XCTAssertEqual(String(describing: app.radioButtons["5 с"].value ?? ""), "1")
        XCTAssertEqual(String(describing: app.switches["screenBreaksEnabled"].value ?? ""), "0")
        app.statusItems.firstMatch.click()
        XCTAssertTrue(app.buttons["restNow"].waitForExistence(timeout: 3))
        app.buttons["restNow"].click()
        XCTAssertTrue(app.staticTexts["restCountdown"].waitForExistence(timeout: 3))
        app.buttons["endBreak"].click()
        XCTAssertTrue(app.staticTexts["restCountdown"].waitForNonExistence(timeout: 3))
    }
    override func setUpWithError() throws { continueAfterFailure = false }
    @MainActor private func launch(suite: String, reset: Bool = true, showSettings: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU", "--ui-testing", "--defaults-suite", suite]
        if showSettings { app.launchArguments.append("--show-settings") }
        if reset { app.launchArguments.append("--reset-defaults") }
        app.launch()
        app.activate()
        if app.windows.firstMatch.waitForExistence(timeout: 3) {
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02)).click()
        }
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
        app.radioButtons["Глаз"].click()
        app.popUpButtons["eyePosition"].click()
        app.menuItems["В центре"].click()
        app.sliders["duration"].adjust(toNormalizedSliderPosition: 0.75)
        app.sliders["opacity"].adjust(toNormalizedSliderPosition: 0.5)
        let duration = app.sliders["duration"].value as? String
        app.buttons["preview"].click()
        app.radioButtons["Затемнение"].click()
        XCTAssertTrue(app.sliders["opacity"].exists)
        app.buttons["preview"].click()
        app.radioButtons["Глаз"].click()
        app.popUpButtons["eyePosition"].click()
        app.menuItems["Сверху справа"].click()
        app.buttons["preview"].click()
        app.popUpButtons["eyePosition"].click()
        app.menuItems["В центре"].click()
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
            app.launchArguments = ["-AppleLanguages", "(ru)", "-AppleLocale", "ru_RU", "--ui-testing", "--show-settings", "--defaults-suite", "MataSehat.ui.snapshots.\(appearance)", "--reset-defaults", "--appearance", appearance]
            app.launch()
            app.activate()
            XCTAssertTrue(app.buttons["preview"].waitForExistence(timeout: 6))
            app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.02)).click()
            let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
            attachment.name = "Settings-\(appearance)"
            attachment.lifetime = .keepAlways
            add(attachment)
            app.buttons["breakPreview"].click()
            XCTAssertTrue(app.buttons["startBreak"].waitForExistence(timeout: 3))
            let invitation = XCTAttachment(screenshot: app.dialogs["screenBreak"].screenshot())
            invitation.name = "Break-invitation-\(appearance)"
            invitation.lifetime = .keepAlways
            add(invitation)
            app.buttons["startBreak"].click()
            XCTAssertTrue(app.staticTexts["restCountdown"].waitForExistence(timeout: 3))
            let rest = XCTAttachment(screenshot: app.dialogs["screenBreak"].screenshot())
            rest.name = "Break-rest-\(appearance)"
            rest.lifetime = .keepAlways
            add(rest)
            app.buttons["endBreak"].click()
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
