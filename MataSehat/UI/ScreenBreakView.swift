import SwiftUI

struct ScreenBreakView: View {
    let phase: ScreenBreakPhase
    var duration: TimeInterval = 20
    let onAction: @MainActor (ReminderEvent) -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "binoculars").font(.largeTitle).foregroundStyle(.secondary).accessibilityHidden(true)
            Text(phase.isResting ? "Посмотри вдаль" : "Пора дать глазам отдых").font(.title2).fontWeight(.semibold)
            Text("Выбери объект примерно в 6 метрах или дальше.")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            if case .resting(let deadline) = phase {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    RestCountdownView(remaining: Int(ceil(min(duration,
                        max(0, deadline - ProcessInfo.processInfo.systemUptime)))))
                }
                Button("Завершить раньше") { onAction(.finishBreak) }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("endBreak")
            } else {
                Text("\(duration.formatted(.number.precision(.fractionLength(0)))) с без экрана").font(.headline)
                HStack(spacing: 12) {
                    Button("Отложить на 5 минут") { onAction(.snoozeBreak) }
                        .keyboardShortcut(.cancelAction)
                        .accessibilityIdentifier("snoozeBreak")
                    Button("Начать отдых") { onAction(.startBreak) }
                        .buttonStyle(.automatic)
                        .fontWeight(.semibold)
                        .accessibilityIdentifier("startBreak")
                }
            }
        }
        .padding(24)
        .frame(width: 420, height: 260)
    }
}

private struct RestCountdownView: View {
    let remaining: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Text("\(remaining) с").font(.largeTitle).monospacedDigit()
            .contentTransition(.numericText(countsDown: true))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: remaining)
            .accessibilityLabel("Осталось \(remaining) секунд")
            .accessibilityIdentifier("restCountdown")
    }
}

struct ScreenBreakSummaryView: View {
    let state: ReminderState
    @State private var visible = false
    var body: some View {
        Group {
            if visible, state.pause == .active, state.breakPhase == .waiting, state.nextBreakDue != nil {
                TimelineView(.periodic(from: .now, by: 1)) { _ in Text(title) }
            } else { Text(title) }
        }
        .font(.caption).foregroundStyle(.secondary)
        .onAppear { visible = true }.onDisappear { visible = false }
        .accessibilityIdentifier("breakStatus")
    }
    private var title: String {
        switch state.breakPhase {
        case .invitation: return "Пора посмотреть вдаль"
        case .resting: return "Отдых идёт · \(Int(state.breakDuration)) с"
        case .waiting:
            guard state.settings.screenBreaksEnabled else { return "Автоматический отдых выключен" }
            guard state.pause == .active, !state.suspended else { return "Отдых на паузе" }
            let period = "Отдых каждые \(Int(state.settings.screenBreakInterval / 60)) мин"
            guard let deadline = state.nextBreakDue else { return period }
            let minutes = ceil(max(0, deadline - ProcessInfo.processInfo.systemUptime) / 60)
            guard let value = Int(exactly: minutes) else { return period }
            return "До отдыха · \(value) мин"
        }
    }
}

#if DEBUG
#Preview("Напоминание об отдыхе") { ScreenBreakView(phase: .invitation, onAction: { _ in }) }
#Preview("Двадцать секунд") { ScreenBreakView(phase: .resting(until: ProcessInfo.processInfo.systemUptime + 20), onAction: { _ in }) }
#endif
