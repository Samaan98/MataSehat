import SwiftUI

nonisolated enum HelpTopic: String, CaseIterable, Sendable {
    case interval, screenBreak, pause

    var title: String {
        switch self {
        case .interval: "Интервал морганий"
        case .screenBreak: "Отдых 20–20–20"
        case .pause: "Пауза"
        }
    }

    var summary: String {
        switch self {
        case .interval: "Как выбрать интервал и не забывать моргать между сигналами."
        case .screenBreak: "Каждые 20 минут смотрите вдаль не менее 20 секунд."
        case .pause: "Поставьте напоминания временно на паузу, если не хотите отвлекаться."
        }
    }

    var explanation: String {
        switch self {
        case .interval:
            """
            Обычно человек моргает около 15–20 раз в минуту — примерно раз в 3–4 секунды. При работе за экраном мы часто моргаем реже; частота зависит от человека и занятия.

            Если удобно моргать с каждым сигналом, попробуйте интервал 3–4 секунды. При более редких напоминаниях старайтесь моргать и между сигналами.
            """
        case .screenBreak:
            """
            Раз в 20 минут отводите взгляд от экрана минимум на 20 секунд и смотрите на объект не ближе 20 футов — примерно 6 метров.

            Период напоминания и длительность отдыха можно изменить в настройках. Отсчёт начинается после нажатия «Начать отдых».
            """
        case .pause:
            """
            Поставьте напоминания временно на паузу, если не хотите отвлекаться. Она приостанавливает сигналы моргания и автоматические предложения отдыха.

            Выберите длительность и нажмите «Приостановить». Напоминания возобновятся автоматически, а вариант «До включения» действует до ручного продолжения.
            """
        }
    }
}

struct HelpHeading: View {
    let topic: HelpTopic
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(topic.title)
            HelpButton(topic: topic)
        }
    }
}

struct HelpButton: View {
    let topic: HelpTopic
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(systemName: "info.circle")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .help(topic.summary + " Нажмите, чтобы узнать больше.")
        .accessibilityLabel("Подробнее: " + topic.title)
        .accessibilityIdentifier("help-" + topic.rawValue)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            HelpContentView(topic: topic)
        }
    }
}

struct HelpContentView: View {
    let topic: HelpTopic
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(topic.title).font(.headline).fontWeight(.semibold)
            Text(topic.explanation)
                .fixedSize(horizontal: false, vertical: true)
                .textSelection(.enabled)
        }
        .font(.body)
        .fontWeight(.regular)
        .foregroundStyle(Color.primary)
        .controlSize(.regular)
        .frame(width: 320, alignment: .leading)
        .padding(16)
    }
}
