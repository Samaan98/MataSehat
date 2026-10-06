import SwiftUI
import AppKit

struct QuickPanelView: View {
    let controller: ReminderController
    let showSettings: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "eye").font(.title2).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text("MataSehat").font(.headline)
                    StatusView(pause: controller.state.pause).font(.caption)
                }
            }
            IntervalPicker(controller: controller).controlSize(.small)
            VStack(alignment: .leading, spacing: 6) {
                HelpHeading(topic: .pause)
                PauseControls(controller: controller)
            }
            Divider()
            VStack(alignment: .leading, spacing: 8) {
                HelpHeading(topic: .screenBreak).font(.headline)
                ScreenBreakSummaryView(state: controller.state)
                Button("Отдохнуть сейчас", systemImage: "binoculars") {
                    dismiss()
                    controller.send(.startBreak)
                }
                .disabled(controller.state.breakPhase.isResting || controller.state.suspended)
                .accessibilityIdentifier("restNow")
            }
            if let error = controller.errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
            }
            Divider()
            HStack {
                Button("Настройки…", systemImage: "gearshape") { dismiss(); showSettings() }
                    .keyboardShortcut(",")
                Spacer()
                Button("Выход") { controller.stop(); NSApp.terminate(nil) }
                    .keyboardShortcut("q")
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
        .frame(width: 320)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: controller.state.pause)
        .onAppear { controller.refreshLoginItemStatus() }
    }
}
