import Foundation
import Testing
@testable import MataSehat

@MainActor struct LocalizationTests {
    @Test(arguments: [("en", "Eye", "Settings…"), ("ru", "Глаз", "Настройки…")])
    func translationsArePackagedInTheApp(language: String, eye: String, settings: String) throws {
        let url = try #require(Bundle.main.url(forResource: language, withExtension: "lproj"))
        let bundle = try #require(Bundle(url: url))
        #expect(bundle.localizedString(forKey: "Eye", value: nil, table: nil) == eye)
        #expect(bundle.localizedString(forKey: "Settings…", value: nil, table: nil) == settings)
    }

    @Test(arguments: [("en", "15 min", "Until resumed"), ("ru", "15 мин", "До включения")])
    func dynamicPauseOptionsUseTheSelectedLanguage(language: String, timed: String, manual: String) throws {
        #expect(try localized(PauseOption.minutes(15).title, language: language) == timed)
        #expect(try localized(PauseOption.manual.title, language: language) == manual)
    }

    @Test(arguments: [("en", "Paused · 2 min left"), ("ru", "Пауза · осталось 2 мин")])
    func pauseStatusKeepsItsRoundedRemainingTime(language: String, expected: String) throws {
        let now = Date(timeIntervalSince1970: 100)
        let title = StatusView.title(for: .until(now.addingTimeInterval(61)), at: now)
        #expect(try localized(title, language: language) == expected)
    }

    @Test(arguments: [("en", "Next break · 2 min"), ("ru", "До отдыха · 2 мин")])
    func breakStatusUsesItsDeadlineInBothLanguages(language: String, expected: String) throws {
        var state = ReminderEngine.initial(settings: .defaults, pause: .active,
            at: ClockSnapshot(wall: Date(timeIntervalSince1970: 100), monotonic: 100))
        state.nextBreakDue = 161
        #expect(try localized(ScreenBreakSummaryView.title(for: state, now: 100), language: language) == expected)
    }

    @Test(arguments: [
        ("en", 1, "1 second remaining"), ("en", 2, "2 seconds remaining"),
        ("ru", 1, "Осталась 1 секунда"), ("ru", 2, "Осталось 2 секунды"),
        ("ru", 5, "Осталось 5 секунд"), ("ru", 21, "Осталась 21 секунда"),
        ("ru", 22, "Осталось 22 секунды"), ("ru", 11, "Осталось 11 секунд")
    ])
    func countdownAccessibilityUsesLanguageSpecificPluralForms(language: String, seconds: Int, expected: String) throws {
        #expect(try localized(RestCountdownView.accessibilityTitle(remaining: seconds), language: language) == expected)
    }

    @Test func languageSelectionRespectsPreferencesAndFallsBackToEnglish() {
        #expect(Bundle.preferredLocalizations(from: Bundle.main.localizations, forPreferences: ["ru-RU", "en"]).first == "ru")
        #expect(Bundle.preferredLocalizations(from: Bundle.main.localizations, forPreferences: ["en-GB", "ru"]).first == "en")
        #expect(Bundle.preferredLocalizations(from: Bundle.main.localizations, forPreferences: ["ja"]).first == "en")
    }

    private func localized(_ resource: LocalizedStringResource, language: String) throws -> String {
        let url = try #require(Bundle.main.url(forResource: language, withExtension: "lproj"))
        let localized = LocalizedStringResource(resource.defaultValue, table: resource.table,
            locale: Locale(identifier: language), bundle: .atURL(url))
        return String(localized: localized)
    }
}
