import SwiftUI

struct ScreenBreakView: View {
    let phase: ScreenBreakPhase
    var duration: TimeInterval = 20
    let onAction: @MainActor (ReminderEvent) -> Void
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "binoculars").font(.largeTitle).foregroundStyle(.secondary).accessibilityHidden(true)
            Group {
                if phase.isResting { Text("Look into the distance") }
                else { Text("Time for an eye break") }
            }.font(.title2).fontWeight(.semibold)
            Text("Look at something at least 20 feet (about 6 metres) away.")
                .foregroundStyle(.secondary).multilineTextAlignment(.center)
            if case .resting(let deadline) = phase {
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    RestCountdownView(remaining: Int(ceil(min(duration,
                        max(0, deadline - ProcessInfo.processInfo.systemUptime)))))
                }
                Button("End break early") { onAction(.finishBreak) }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("endBreak")
            } else {
                Text("\(duration, format: .number.precision(.fractionLength(0))) s away from the screen").font(.headline)
                HStack(spacing: 12) {
                    Button("Snooze for 5 minutes") { onAction(.snoozeBreak) }
                        .keyboardShortcut(.cancelAction)
                        .accessibilityIdentifier("snoozeBreak")
                    Button("Start break") { onAction(.startBreak) }
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

struct RestCountdownView: View {
    let remaining: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        Text("\(remaining) s").font(.largeTitle).monospacedDigit()
            .contentTransition(.numericText(countsDown: true))
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: remaining)
            .accessibilityLabel(Text(Self.accessibilityTitle(remaining: remaining)))
            .accessibilityIdentifier("restCountdown")
    }
    static func accessibilityTitle(remaining: Int) -> LocalizedStringResource {
        "\(remaining) seconds remaining"
    }
}

struct ScreenBreakSummaryView: View {
    let state: ReminderState
    @State private var visible = false
    var body: some View {
        Group {
            if visible, state.pause == .active, state.breakPhase == .waiting, state.nextBreakDue != nil {
                TimelineView(.periodic(from: .now, by: 1)) { _ in Text(Self.title(for: state, now: ProcessInfo.processInfo.systemUptime)) }
            } else { Text(Self.title(for: state, now: ProcessInfo.processInfo.systemUptime)) }
        }
        .font(.caption).foregroundStyle(.secondary)
        .onAppear { visible = true }.onDisappear { visible = false }
        .accessibilityIdentifier("breakStatus")
    }
    static func title(for state: ReminderState, now: TimeInterval) -> LocalizedStringResource {
        switch state.breakPhase {
        case .invitation: return "Time to look into the distance"
        case .resting: return "Break in progress · \(Int(state.breakDuration)) s"
        case .waiting:
            guard state.settings.screenBreaksEnabled else { return "Automatic breaks are off" }
            guard state.pause == .active, !state.suspended else { return "Break reminders are paused" }
            let period: LocalizedStringResource = "Break every \(Int(state.settings.screenBreakInterval / 60)) min"
            guard let deadline = state.nextBreakDue else { return period }
            let minutes = ceil(max(0, deadline - now) / 60)
            guard let value = Int(exactly: minutes) else { return period }
            return "Next break · \(value) min"
        }
    }
}

#if DEBUG
#Preview("Break invitation") { ScreenBreakView(phase: .invitation, onAction: { _ in }) }
#Preview("Twenty seconds") { ScreenBreakView(phase: .resting(until: ProcessInfo.processInfo.systemUptime + 20), onAction: { _ in }) }
#endif
