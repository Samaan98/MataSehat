import SwiftUI

struct StatusView: View {
    let pause: PauseState
    @State private var visible = false
    var body: some View {
        Group {
            if visible, case .until = pause {
                TimelineView(.periodic(from: .now, by: 1)) { context in Text(title(at: context.date)) }
            } else { Text(title(at: .now)) }
        }
        .foregroundStyle(.secondary)
        .onAppear { visible = true }
        .onDisappear { visible = false }
        .accessibilityIdentifier("status")
    }
    private func title(at date: Date) -> String {
        switch pause {
        case .active: return "Работает"
        case .manual: return "Пауза до включения"
        case .until(let deadline):
            let remaining = ceil(max(0, deadline.timeIntervalSince(date)) / 60)
            guard let minutes = Int(exactly: remaining) else { return "Пауза" }
            return "Пауза · осталось \(minutes) мин"
        }
    }
}
struct PauseControls: View {
    let controller: ReminderController
    var body: some View {
        HStack {
            Picker("Длительность паузы", selection: Binding(get: { controller.state.settings.pauseOption }, set: { option in
                if controller.state.pause == .active { controller.updateSettings { $0.pauseOption = option } }
                else { controller.send(.pause(option)) }
            })) {
                ForEach(PauseOption.all, id: \.self) { option in Text(option.title).tag(option) }
            }
            .labelsHidden()
            .accessibilityIdentifier("pauseOption")
            Button {
                if controller.state.pause == .active { controller.send(.pause(controller.state.settings.pauseOption)) }
                else { controller.send(.resume) }
            } label: {
                Label(controller.state.pause == .active ? "Приостановить" : "Продолжить сейчас", systemImage: controller.state.pause == .active ? "pause.fill" : "play.fill")
            }
            .buttonStyle(.glassProminent)
            .accessibilityIdentifier("pauseResume")
        }
    }
}
struct IntervalPicker: View {
    let controller: ReminderController
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HelpHeading(topic: .interval)
            Picker("Интервал морганий", selection: Binding(get: { controller.state.settings.interval }, set: { interval in controller.updateSettings { $0.interval = interval } })) {
                ForEach(ReminderSettings.intervals, id: \.self) { interval in Text("\(Int(interval)) с").tag(interval) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityIdentifier("interval")
        }
    }
}
