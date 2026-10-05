# MataSehat

Нативная утилита строки меню для macOS 26.5 и новее: мягкие напоминания о моргании во время работы.

- Глаз в правом верхнем углу, глаз по центру или лёгкое затемнение.
- Интервал 5, 10, 15, 20 или 30 секунд; длительность эффекта 0,5–2 секунды.
- Отдельная настройка заметности и длительности каждого эффекта.
- Паузы 5, 15, 30, 60 минут или до ручного включения.
- Предпросмотр работает на паузе и сохраняет её.
- Настройки и пауза сохраняются между запусками.
- Отдых по правилу 20–20–20: каждые 20 минут появляется предложение посмотреть вдаль примерно на 6 метров. Отсчёт 20 секунд начинается по кнопке «Начать отдых»; предложение можно отложить на 5 минут.
- Во время отдыха сигналы моргания приостанавливаются. В панели строки меню можно начать отдых сразу; автоматические предложения отдельно выключаются в настройках.
- Системное оформление SwiftUI, светлая/тёмная тема и Liquid Glass для основного действия.

Откройте `MataSehat.xcodeproj` в Xcode 26.5 и выберите общую схему **MataSehat**. При первом запуске открываются настройки. После закрытия окна управление остаётся под значком глаза в строке меню. Команда «Выход» завершает приложение.

## Разработка

Внешние зависимости и база данных не нужны. SwiftUI отвечает за управление и настройки, AppKit — за прозрачное окно эффекта, ServiceManagement — за запуск при входе. Настройки хранятся в UserDefaults. Логика времени отделена от системных интеграций; unit-тесты используют Swift Testing, UI-тесты — XCTest.

После отдыха, продолжения общей паузы и возвращения из сна начинается новый цикл 20 минут. Изменение интервала морганий не отодвигает отдых. Выключение автоматических предложений сохраняет уже начатый отсчёт; для его отмены есть «Завершить раньше». Экран остаётся доступен, появление окна отдыха не переводит на него фокус.

```sh
xcodebuild -project MataSehat.xcodeproj -scheme MataSehat \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /private/tmp/matasehat-native-dd \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual \
  -parallel-testing-enabled NO \
  -only-testing:MataSehatTests \
  -skip-testing:MataSehatTests/OverlayWindowTests test

xcodebuild -project MataSehat.xcodeproj -scheme MataSehat \
  -configuration Release -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /private/tmp/matasehat-native-dd \
  CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual build
```

Обычная проверка запускает тесты логики без управления экраном. `MataSehatUITests` и `OverlayWindowTests` взаимодействуют с рабочим столом или показывают реальные окна: их запускаем только для затронутых сценариев интерфейса и окон. После коммита, push или fast-forward объединения уже проверенного кода повторять UI-прогон не нужно. Правила для агента сохранены в [AGENTS.md](AGENTS.md).

Локальная сборка использует ad-hoc подпись, не меняя ваши настройки подписи в Xcode. Собранное приложение для экспериментов: [build/MataSehat.app](build/MataSehat.app). Исходный продукт Release-сборки: `/private/tmp/matasehat-native-dd/Build/Products/Release/MataSehat.app`. Для распространения потребуются отдельные подпись Developer ID и notarization.

Запуск при входе регистрируется только через пользовательский переключатель. Отсутствие службы не блокирует попытку регистрации: после неё приложение показывает фактический статус macOS, необходимость системного разрешения или ошибку регистрации.

Результаты проверки и ограничения: [manual-verification.md](docs/manual-verification.md).

## Платформенные ориентиры

- [Apple Human Interface Guidelines: macOS](https://developer.apple.com/design/human-interface-guidelines/designing-for-macos/)
- [Adopting Liquid Glass](https://developer.apple.com/documentation/technologyoverviews/adopting-liquid-glass)
- [NSHostingSceneRepresentation](https://developer.apple.com/documentation/swiftui/nshostingscenerepresentation): регистрация нативной сцены настроек и доступ к публичному openSettings из жизненного цикла приложения.

Камера, статистика, определение звонков и запись экрана в эту версию не входят.
