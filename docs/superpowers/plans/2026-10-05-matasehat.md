# MataSehat Native macOS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans or superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking. No delegation until the user selects it.

**Goal:** Создать нативную утилиту macOS с тремя напоминаниями о моргании, выбираемой паузой и минималистичным интерфейсом SwiftUI по рекомендациям Apple, с уместным Liquid Glass и мягкими анимациями.

**Architecture:** Чистая Swift-машина состояний определяет расписание; контроллер на MainActor владеет состоянием интерфейса, планировщиком и UserDefaults. SwiftUI рисует панель строки меню, настройки и эффекты, а AppKit предоставляет неактивирующее окно поверх других приложений и системные события. ServiceManagement управляет запуском при входе.

**Tech Stack:** Существующий Xcode-проект, Swift, SwiftUI, Observation, AppKit, Foundation/UserDefaults, ServiceManagement, Swift Testing, XCTest UI Tests. Внешние библиотеки не требуются.

**Spec:** [2026-10-05-matasehat-design.md](../specs/2026-10-05-matasehat-design.md)

## Global Constraints

- Только macOS, основной дисплей — `NSScreen.screens.first`.
- Сохраняем `MataSehat.xcodeproj` и targets `MataSehat`, `MataSehatTests`, `MataSehatUITests`.
- Bundle identifier приложения: существующий `id.aleks-singaraja.MataSehat`.
- Минимум — macOS 26.5 для приложения и тестов; текущий deployment target сохраняем. Используем установленный SDK 26.5, проверяем доступность новых API по macOS, а не по iOS-примерам навыков.
- Сохраняем существующий Swift language mode и approachable concurrency. UI/AppKit изолированы явным `@MainActor`; состояние UI — Observation (`@Observable`, корневое владение через `@State`).
- Эффекты: глаз в углу, глаз в центре, затемнение. Начальный эффект — глаз в углу.
- Интервалы: 10, 15, 20, 30 секунд; стартовый — 10 секунд.
- Длительность: 0,5–2 секунды; стартовая — 1 секунда.
- Непрозрачность глаза: 40–100%, стартовая — 80%; затемнения: 2–20%, стартовая — 6%.
- Пауза: 5, 15, 30, 60 минут или до ручного включения; начальный выбор — 15 минут.
- Настройки каждого эффекта и состояние паузы сохраняются между запусками; runtime-отсчёт при запуске начинается заново.
- Один видимый эффект; клики, прокрутка и клавиатурный фокус остаются у текущего приложения.
- После возобновления, сна и изменения интервала/эффекта начинается полный интервал. После окончания предпросмотра также начинается полный интервал; пропущенные сигналы не накапливаются.
- Следуем Apple HIG: стандартные SwiftUI-контролы, системные цвета, SF Symbols, светлая/тёмная тема. Liquid Glass применяем точечно к управлению; основное содержимое настроек — читаемая форма. Анимации короткие и мягкие, с поддержкой сокращения движения и прозрачности.
- Камера, статистика, отдельные перерывы, звонки, запись экрана, горячие клавиши и App Store вне объёма.

## Baseline Review — 5 октября 2026

- В репозитории есть нативная SwiftUI-точка входа и обычный WindowGroup с шаблонным ContentView. Это корректная основа; режим строки меню ещё предстоит реализовать.
- Unit target использует `import Testing`, UI target — `import XCTest`; зависимости обоих targets на приложение настроены.
- SwiftData/Core Data, Kotlin, Compose и сторонних package dependencies в новом проекте нет.
- Xcode 26.5, Swift compiler 6.3.2; установленная macOS 26.5.2, arm64. Значение `SWIFT_VERSION = 5.0` относится к language mode, не означает старый установленный компилятор.
- `plutil -lint MataSehat.xcodeproj/project.pbxproj` — OK.
- `xcodebuild ... build-for-testing` с локальной ad-hoc подписью успешно собрал приложение и оба тестовых targets.
- Шаблонный unit-тест запущен: 1 passed, 0 failed. Он проверяет подключение Swift Testing, но не поведение будущего приложения. Один шаблонный XCTest UI launch-тест также прошёл: 1 passed, 0 failed; performance-тест не запускался.
- Minimum deployment target 26.5 соответствует последнему решению пользователя и сохраняется. Ассеты и тесты шаблонные, `LSUIElement` ещё не задан; это задачи первой версии.
- Есть Git с Initial Commit; документация пока не отслеживается. Личный `xcuserdata` уже попал в первоначальный коммит, общей схемы и `.gitignore` пока нет. План добавляет общую схему и ignore-правила; существующие личные файлы не удаляются автоматически.

## Review Focus

1. Скачки системных часов: интервалы используют монотонное время, срок паузы — Date; после изменения часов нет серии сигналов (Task 2).
2. Некорректные defaults: валидные поля сохраняются, остальные получают стартовые значения; отсутствие срока у временной паузы не оставляет её вечной (Task 3).
3. Быстрые переключения, повторный Preview и Preview на паузе: один слой, пауза сохраняется, устаревший completion не влияет на новый показ (Tasks 2, 4, 5, 7).
4. Fullscreen, Spaces, дисплеи, сон и блокировка: сохраняется ввод текущего приложения, перед показом обновляется геометрия, возврат не запускает очередь старых сигналов (Tasks 4, 7).
5. Автозапуск отключён системой или недоступен: UI показывает реальный статус ServiceManagement; ошибка не выглядит успешным включением (Tasks 4, 7).

## File Structure

- `MataSehat/Reminders/ReminderSettings.swift`: эффекты, параметры, допустимые значения.
- `MataSehat/Reminders/ReminderEngine.swift`: чистые состояния, события и команды эффекта.
- `MataSehat/Reminders/ReminderClock.swift`: real/monotonic time и production clock.
- `MataSehat/Persistence/PreferencesStore.swift`: UserDefaults и нормализация.
- `MataSehat/App/ReminderController.swift`: Observation, scheduling, действия UI.
- `MataSehat/App/ReminderScheduler.swift`: отменяемый планировщик и test seam.
- `MataSehat/Mac/OverlayWindowController.swift`: non-key NSPanel и SwiftUI hosting.
- `MataSehat/Mac/SystemActivityMonitor.swift`: sleep/wake, session/display/lock notifications.
- `MataSehat/Mac/LoginItemService.swift`: ServiceManagement и фактический статус.
- `MataSehat/UI/QuickPanelView.swift`, `SettingsView.swift`, `EffectPreviewView.swift`: системные элементы управления и миниатюра выбранного эффекта.
- `MataSehat/UI/BlinkEyeShape.swift`, `ReminderOverlayView.swift`: общий рисунок для миниатюр и overlay.
- `MataSehat/MataSehatApp.swift`: MenuBarExtra, Settings и время жизни приложения.
- `MataSehatTests/ReminderEngineTests.swift`, `PreferencesStoreTests.swift`, `ReminderControllerTests.swift`: Swift Testing.
- `MataSehatUITests/MataSehatUITests.swift`: осмысленные UI-сценарии вместо шаблона.
- `MataSehat.xcodeproj/xcshareddata/xcschemes/MataSehat.xcscheme`: общая схема build/test/archive.
- `.gitignore`, `README.md`, `docs/manual-verification.md`: воспроизводимость и результаты проверки.

## Task 1: Согласовать настройки нативного проекта

**Files:** изменить `MataSehat.xcodeproj/project.pbxproj`; создать общую схему и `.gitignore`.

- [x] Проверить, что `MACOSX_DEPLOYMENT_TARGET = 26.5` остаётся для проекта и явно заданных тестовых конфигураций; targets с наследуемым значением также используют 26.5. Сохранить bundle identifiers, sandbox, автоматическую подпись в проекте и личные настройки разработчика. Для локальных команд допускается ad-hoc override без изменения project signing.
- [x] Создать общую схему MataSehat с build target приложения и test targets Swift Testing/XCTest. Использовать существующие target IDs из pbxproj; не создавать дубли targets.
- [x] Добавить ignore-правила для `.DS_Store`, `.idea/`, `build/`, `DerivedData/`, `*.xcuserstate`, `xcuserdata/`. Не удалять и не снимать с отслеживания уже закоммиченный личный файл без отдельной необходимости.
- [x] Выполнить `plutil -lint MataSehat.xcodeproj/project.pbxproj` и `xcodebuild -list -json -project MataSehat.xcodeproj`: валидный проект, одна общая схема, три прежних targets.
- [x] Выполнить `xcodebuild -project MataSehat.xcodeproj -scheme MataSehat -destination 'platform=macOS' -derivedDataPath /private/tmp/matasehat-native-dd CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual build-for-testing`: exit 0, отсутствие ошибок availability. Deployment target остаётся 26.5; текущий Mac подходит для последующих ручных проверок.

## Task 2: Расписание, пауза и предпросмотр

**Files:** создать `MataSehat/Reminders/*`, `MataSehatTests/ReminderEngineTests.swift`.

**Interfaces:**
- `enum ReminderEffect: String, CaseIterable { case cornerEye, centerEye, dim }`.
- `struct EffectSettings: Equatable { var opacity: Double; var duration: TimeInterval }`.
- `enum PauseOption: Equatable { case minutes(Int); case manual }`; допустимые minutes — 5/15/30/60.
- `struct ReminderSettings: Equatable` с `effect`, `interval: TimeInterval`, `effects: [ReminderEffect: EffectSettings]`, `pauseOption`; `static var defaults`, `func validated() -> Self`.
- `struct ClockSnapshot { let wall: Date; let monotonic: TimeInterval }`; `protocol ReminderClock { func now() -> ClockSnapshot }`.
- `enum PauseState: Equatable { case active; case until(Date); case manual }`.
- `struct EffectPresentation: Equatable` с `id: UInt64`, `effect`, `settings`, `origin: PresentationOrigin`; `enum PresentationOrigin { case scheduled, preview }`.
- `struct ReminderState: Equatable` с settings, pause, suspended, nextDue, generation и optional presentation.
- `enum ReminderEvent`: tick, pause(PauseOption), resume, settingsChanged(ReminderSettings), preview, suspend, wake, effectFinished(UInt64).
- `enum EffectCommand`: show(EffectPresentation), hide.
- `struct EngineResult { let state: ReminderState; let commands: [EffectCommand] }`.
- `ReminderEngine.initial(settings:pause:at:) -> ReminderState` и `ReminderEngine.reduce(_:event:at:) -> EngineResult`.

- [x] Написать Swift Testing-тесты с явными ClockSnapshot: сигнал при monotonic 10.0; следующий плановый старт при 20.0; интервал не включает добавочное время анимации. Для паузы 15 минут deadline = wall + 900; повторный выбор 5 минут заменяет deadline на now + 300; manual не истекает.
- [x] Проверить resume/wake/settingsChanged: nextDue = monotonic now + interval; большое пропущенное время выдаёт только одну Show. Скачок wall time не меняет активный монотонный отсчёт, но пересчитывает истечение временной паузы.
- [x] Проверить Preview на обеих паузах: pause не меняется; второй Preview заменяет ID; completion старого ID не скрывает новый; после завершения Preview nextDue = now + interval. Suspend скрывает эффект; Tick не рисует во время suspension.
- [x] Запустить unit target и увидеть падение новых тестов из-за отсутствующей реализации. Затем реализовать чистые модели/reducer без реальных таймеров и AppKit.
- [x] Повторить `xcodebuild ... test -only-testing:MataSehatTests`: новые тесты проходят. Удалить пустой `MataSehatTests.example` после появления содержательных тестов.

## Task 3: Сохранение настроек

**Files:** создать `MataSehat/Persistence/PreferencesStore.swift`, `MataSehatTests/PreferencesStoreTests.swift`.

**Interfaces:**
- `struct StoredPreferences: Equatable { var settings: ReminderSettings; var pause: PauseState }`.
- `protocol PreferencesStoring { func load() -> StoredPreferences?; func save(_ value: StoredPreferences) }`.
- `final class PreferencesStore: PreferencesStoring { init(defaults: UserDefaults) }`.
- Ключи с префиксом `matasehat.`: schemaVersion, effect, interval, pauseOption, pauseState, pauseDeadline и `effects.<rawValue>.opacity` / `.duration`. Схема = 1; deadline — timestamp Date. Отсутствие schemaVersion означает первый запуск. Unknown keys игнорируются.

- [x] Написать тесты с отдельным уникальным suiteName и очисткой домена в defer: roundtrip трёх эффектов и двух видов паузы, первый запуск, неизвестный effect, неверные типы/диапазоны, отсутствующий deadline и частичные настройки. Проверить, что валидные поля не теряются из-за одного ошибочного значения.
- [x] Запустить unit target: новые тесты падают. Реализовать нормализацию каждого поля через значения спецификации; неправильную временную паузу восстановить как active.
- [x] Сохранять settings и pause; не сохранять runtime nextDue, presentation и suspension. UserDefaults обновляет значения синхронно в памяти, но не предоставляет гарантированного подтверждения flush на диск; не использовать `synchronize()` и не обещать атомарную транзакцию всех ключей.
- [x] Запустить unit target: все тесты проходят. Изолированные suites не должны изменять реальные настройки пользователя.

## Task 4: Нативное окно эффекта и системные события

**Files:** создать `MataSehat/Mac/*`, `MataSehat/UI/BlinkEyeShape.swift`, `ReminderOverlayView.swift`.

**Interfaces:** все платформенные контроллеры — `@MainActor`.
- `protocol OverlayPresenting { func show(_ value: EffectPresentation, reduceMotion: Bool, completion: @escaping (UInt64) -> Void); func hide() }`.
- `final class OverlayWindowController: OverlayPresenting`.
- `enum ActivityEvent { case suspended; case resumed; case screenConfigurationChanged; case clockChanged }`.
- `final class SystemActivityMonitor` с `start(onEvent: @escaping (ActivityEvent) -> Void)` и `stop()`.
- `enum LoginItemStatus: Equatable { case enabled, disabled, requiresApproval, unavailable }`.
- `protocol LoginItemServicing { func status() -> LoginItemStatus; func setEnabled(_ enabled: Bool) throws }`; `LoginItemService` использует `SMAppService.mainApp`.
- `BlinkEyeShape: Shape` с openness 0...1; `ReminderOverlayView` принимает presentation и reduceMotion. Один рисунок глаза используется в overlay и миниатюре настроек.

- [x] Создать NSPanel с borderless/nonactivating style, прозрачным фоном, `ignoresMouseEvents=true`, `canBecomeKey=false`, `canBecomeMain=false`, уровнем statusBar и поведением canJoinAllSpaces/fullScreenAuxiliary. Показ через orderFrontRegardless не активирует приложение. Frame рассчитывать заново по primary screen перед каждым показом.
- [x] Разместить SwiftUI-контент через NSHostingView. Corner eye находится ниже menu bar в visibleFrame, center eye — в центре frame, dim — на всём frame. Fade и закрытие/открытие глаза укладываются в выбранную общую длительность; непрозрачность не выходит за выбранные границы. Новый показ отменяет старую анимацию/completion; Hide идемпотентен.
- [x] Сокращение движения получить из SwiftUI environment / NSWorkspace accessibility setting; для overlay отключить пространственную анимацию, оставить мягкий fade. Наблюдать изменение настройки во время работы.
- [x] Подключить NSWorkspace sleep/wake, display sleep/wake, session activity; изменение геометрии экрана и системных часов. Сигналы блокировки/разблокировки loginwindow из DistributedNotificationCenter изолированы внутри SystemActivityMonitor. Их строковые имена не являются документированным контрактом AppKit; реальная блокировка остаётся ручной проверкой и не заявляется проверенной.
- [x] Реализовать статус login item и регистрацию/отмену; не хранить желаемый enabled как доказательство фактического включения. Ошибку и requiresApproval отдавать UI. Проверку регистрации проводить только действием пользователя в переключателе и восстанавливать исходное состояние после проверки.
- [ ] Выполнить сборку. Проверить на Mac все три эффекта, печать/клики/скролл, fullscreen, Spaces, sleep и lock. В `docs/manual-verification.md` записать фактический результат каждого сценария; для эффектов вне обычных окон unit-тесты не заменяют проверку настоящего NSPanel.

## Task 5: Контроллер приложения и отменяемое расписание

**Files:** создать `MataSehat/App/*`, `MataSehatTests/ReminderControllerTests.swift`.

**Interfaces:**
- `@MainActor protocol ReminderScheduling { func schedule(after delay: TimeInterval, action: @escaping @MainActor () -> Void); func cancel() }`.
- Production ReminderScheduler владеет одним отменяемым Task с sleep; fake scheduler исполняет callback вручную. Не создавать постоянно работающий animation/frame timer для расписания.
- `@MainActor @Observable final class ReminderController` с `private(set) var state: ReminderState`, `private(set) var loginItemStatus: LoginItemStatus`, `private(set) var errorMessage: String?`; зависимости clock/store/scheduler/overlay/login/activity помечены `@ObservationIgnored`, если не являются отображаемым состоянием. Корневое приложение владеет контроллером через `@State`; дочерние представления не создают его заново.
- Действия: `start()`, `send(_ event: ReminderEvent)`, `setLaunchAtLogin(_ enabled: Bool)`, `stop()`. Действия UI проходят через controller и reducer; controller исполняет EffectCommand и сохраняет settings/pause при их изменении.

- [x] Написать controller-тесты: восстановление активной/истёкшей/ручной паузы, отображение ошибки login без ложного enabled, Wake сбрасывает интервал, stale completion игнорируется, stop отменяет scheduler и скрывает overlay, повторный start не создаёт второй scheduler. Использовать fakes без ожидания и без AppKit.
- [x] Запустить unit target и подтвердить падение новых тестов. Реализовать controller и одно отменяемое scheduling-задание на ближайший сигнал/истечение паузы. После clockChanged пересчитать время временной паузы, после wake начать полный интервал. Не публиковать одинаковое состояние каждый кадр; прекратить задачи и observers при stop.
- [x] Повторить unit target: все новые controller-тесты проходят, тесты не ждут реальные интервалы и не включают реальный автозапуск.

## Task 6: Нативный SwiftUI-интерфейс и материалы Apple

**Files:** создать остальные `MataSehat/UI/*`; обновить assets и заменить шаблонный `MataSehat/ContentView.swift` по необходимости. Отдельная кастомная тема не требуется.

**Interfaces:**
- `QuickPanelView(controller: ReminderController, showSettings: () -> Void)` и `SettingsView(controller: ReminderController)`.
- `EffectPreviewView(effect:settings:reduceMotion:)`; переиспользует BlinkEyeShape. Доступные имена и идентификаторы стабильны.
- Представления читают переданный контроллер, изменения отправляют через его действия. Binding для Picker/Slider/Toggle вызывает эти действия и сохраняет настройки; локальная копия состояния не расходится с controller.
- Окно настроек создаётся сценой `Settings`, зарегистрированной через NSHostingSceneRepresentation; управление открытием — через публичный `environment.openSettings` этой сцены. Панель передаёт действие делегату приложения.

- [x] Использовать Form с секциями, системные Picker/Slider/Toggle/Button, шрифты и primary/secondary/accentColor. Подписи на русском; иконки SF Symbols с доступными названиями. Компактная панель — примерно 320 pt шириной; настройки подстраиваются под содержимое и размер текста, при необходимости прокручиваются. Проверить размещение по доступной области экрана.
- [x] Добавить системный выбор трёх эффектов, небольшую миниатюру выбранного, sliders заметности и длительности, Preview и автозапуск. Заметность — в процентах; длительность — в секундах. Диапазон dim отличается от глаз. Выбранное состояние показывает системный Picker.
- [x] Сохранить системное оформление macOS 26.5. Для главного действия панели оценить системный `.glass` / `.glassProminent`; использовать только если действие остаётся ясным. Не покрывать форму собственным стеклянным фоном. При необходимости собственного glassEffect проверить macOS availability по SDK и правила Apple для группировки материалов; не накладывать стекло на стекло. Семантический цвет ошибки не заменять декоративным акцентом.
- [x] Добавить короткие плавные переходы при смене параметров и состояния Pause/Resume; системные hover/pressed/focus реакции сохранять. Миниатюра моргает только при выборе/предпросмотре. При accessibilityReduceMotion убрать масштаб/смещения и декоративное моргание. Напоминания продолжают работать.
- [ ] Проверить системные accessibilityReduceMotion, accessibilityReduceTransparency и increased contrast в обеих темах на реальном Mac.
- [x] Показать активную/временную/ручную паузу, выбор 5/15/30/60/manual, запомнить последний выбор и дать Resume Now. Остаток округлять вверх до минут; обновлять этот текст только пока панель видима.
- [ ] Проверить keyboard focus, Space/Return, VoiceOver labels, обе темы, длинную ошибку login item и доступность. Добавить previews с подставным состоянием, без таймеров и системной регистрации.
- [x] Собрать проект и проверить интерфейс на Mac. Сохранить снимки обеих тем для просмотра пользователем. Оценить читаемость формы и панели на разных фонах; убрать лишний материал или анимацию, если они мешают быстрому управлению.

## Task 7: Жизненный цикл, UI-тесты и поставка

**Files:** создать README и manual verification; изменить `MataSehatApp.swift`, pbxproj и UI-тесты.

**Interfaces:** использует ReminderController из Task 5 и QuickPanelView/SettingsView из Task 6; сценой настроек управляет SwiftUI, новых доменных типов не вводит.

- [x] Заменить обычный WindowGroup точкой входа MenuBarExtra с `.window` style и QuickPanelView, добавить сцену `Settings` с SettingsView. Добавить `INFOPLIST_KEY_LSUIElement = YES`. Панель открывает настройки через действие делегата и публичный environment.openSettings зарегистрированной сцены. Реализовать и проверить автоматическое открытие настроек именно при первом запуске процесса, без необходимости сначала нажать значок в строке меню; повторное открытие поднимает существующее окно. Закрытие настроек сохраняет menu bar app; Quit останавливает controller и завершает NSApp. Lifecycle-связь со сценой проверить на реальном Mac до завершения этой задачи; не использовать приватные selectors открытия настроек.
- [x] Проверить повторный запуск: обычное открытие `.app` использует существующий экземпляр; при обнаружении второго процесса того же bundle identifier активировать существующий и завершить новый без второго таймера. Тестовые запуски изолировать от этой логики.
- [x] Добавить UI launch arguments `--ui-testing`, `--show-settings` и отдельный defaults suite для тестов. В test mode отключить автоматические напоминания/автозапуск; автоматическое открытие первого запуска остаётся для отдельного UI-теста; Preview запускается явно. Заменить шаблонные launch/performance-тесты сценариями: три эффекта, изменение opacity/duration, сохранение после relaunch, выбор manual pause и Resume. UI-тесты проверяют управление; mouse passthrough/focus проверяются вручную.
- [x] Выполнить `xcodebuild -project MataSehat.xcodeproj -scheme MataSehat -destination 'platform=macOS' -derivedDataPath /private/tmp/matasehat-native-dd CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual test`: 0 failures в unit и UI suites. Повторный полный запуск нужен только после новых изменений/ошибок.
- [x] Выполнить Release build через ту же схему с `-configuration Release build`. Продукт — `/private/tmp/matasehat-native-dd/Build/Products/Release/MataSehat.app`; никакие jpackage/JVM/нативные dylib bridges не нужны. Показать этот файл пользователю; публикация и notarization вне локального этапа.
- [ ] Проверить релизный `.app`: menu bar без постоянного Dock icon, первый запуск/повторный запуск, все эффекты, pause/preview, сохранение, sleep/lock/fullscreen/Spaces, выход. Подписывание Developer ID требуется только на отдельном этапе распространения; не менять личные signing credentials в рамках этого плана.
- [x] Добавить README с открытием в Xcode, build/test, возможностями и ограничениями. Заполнить `docs/manual-verification.md` версиями ОС/Xcode, результатами, снимками и непроверенными сценариями. Не заявлять, что smoke-тест шаблона проверяет реализованное приложение.

## Installed Skills

По запросу пользователя установлены глобально в `/Users/aakorolev/.codex/skills`:

- [SwiftUI Expert](https://github.com/AvdLee/SwiftUI-Agent-Skill), каталог `swiftui-expert-skill`: состояние, системный SwiftUI-интерфейс, анимации, доступность и Liquid Glass.
- [Swift Concurrency](https://github.com/AvdLee/Swift-Concurrency-Agent-Skill), каталог `swift-concurrency`: MainActor, владение задачами и отмена расписания.
- [Swift Testing](https://github.com/AvdLee/Swift-Testing-Agent-Skill), каталог `swift-testing-expert`: содержательные unit-тесты с подставным временем и зависимостями. UI-тесты остаются XCTest.

Навыки не добавляют зависимости в приложение. Их инструкции применяются с учётом macOS 26.5 и пользовательского выбора дизайна. Примеры iOS и SDK новее установленного проверяются по документации Apple; они не являются основанием для повышения или снижения deployment target.

## Execution Review

Этот план полностью заменяет прежний Kotlin/Compose-план. Три эффекта, выбираемая пауза и сохранение остаются в объёме. По последнему решению пользователя визуальная концепция обновлена на минималистичный системный дизайн Apple с уместным Liquid Glass; минимум — macOS 26.5. Удалены JNA, Objective-C C ABI, Kotlin Toolchain, Gradle/Compose зависимости и jpackage. Рекомендован последовательный запуск в этом чате после просмотра обновлённого плана; делегирование не выбрано.

## Implementation status — 5 октября 2026

Нативная реализация добавлена. Завершённые шаги отмечены; составные ручные проверки остаются открытыми, если хотя бы один сценарий ещё не подтверждён. Их фактические результаты и ограничения перечислены в [manual-verification.md](../../manual-verification.md). Настройки и панель имеют Xcode previews с зависимостями в памяти без системной регистрации и расписания; проверка отображения canvas отдельно не выполнялась.
