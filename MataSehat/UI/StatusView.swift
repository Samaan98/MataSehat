import SwiftUI

struct StatusView: View {
    let pause: PauseState
    @State private var visible = false
    var body: some View {
        Group {
            if visible, case .until = pause {
                TimelineView(.periodic(from: .now, by: 1)) { context in Text(Self.title(for: pause, at: context.date)) }
            } else { Text(Self.title(for: pause, at: .now)) }
        }
        .foregroundStyle(.secondary)
        .onAppear { visible = true }
        .onDisappear { visible = false }
        .accessibilityIdentifier("status")
    }
    static func title(for pause: PauseState, at date: Date) -> LocalizedStringResource {
        switch pause {
        case .active: return "Running"
        case .manual: return "Paused until resumed"
        case .until(let deadline):
            let remaining = ceil(max(0, deadline.timeIntervalSince(date)) / 60)
            guard let minutes = Int(exactly: remaining) else { return "Pause" }
            return "Paused · \(minutes) min left"
        }
    }
}
struct PauseControls: View {
    let controller: ReminderController
    var body: some View {
        HStack {
            Picker("Pause duration", selection: Binding(get: { controller.state.settings.pauseOption }, set: { option in
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
                Label {
                    if controller.state.pause == .active { Text("Pause reminders") }
                    else { Text("Resume now") }
                } icon: {
                    Image(systemName: controller.state.pause == .active ? "pause.fill" : "play.fill")
                }
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
            Picker("Blink interval", selection: Binding(get: { controller.state.settings.interval }, set: { interval in controller.updateSettings { $0.interval = interval } })) {
                ForEach(ReminderSettings.intervals, id: \.self) { interval in Text("\(Int(interval)) s").tag(interval) }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .accessibilityIdentifier("interval")
        }
    }
}
