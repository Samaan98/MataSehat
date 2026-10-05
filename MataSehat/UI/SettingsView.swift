import SwiftUI
import ServiceManagement

struct SettingsView: View {
    let controller: ReminderController
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var previewTrigger: UInt64 = 0
    private var effect: ReminderEffect { controller.state.settings.effect }
    private var parameters: EffectSettings { controller.state.settings.effects[effect] ?? effect.defaults }
    var body: some View {
        Form {
            Section {
                Picker("Напоминание", selection: Binding(get: { effect }, set: { effect in controller.updateSettings { $0.effect = effect } })) {
                    ForEach(ReminderEffect.allCases, id: \.self) { effect in Text(effect.title).tag(effect) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityIdentifier("effect")
                EffectPreviewView(effect: effect, settings: parameters, trigger: previewTrigger)
                IntervalPicker(controller: controller)
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text("Заметность"); Spacer(); Text(parameters.opacity, format: .percent.precision(.fractionLength(0))).foregroundStyle(.secondary).monospacedDigit() }
                    Slider(value: parameterBinding(\.opacity), in: effect.opacityRange)
                        .accessibilityLabel("Заметность")
                        .accessibilityIdentifier("opacity")
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text("Длительность"); Spacer(); Text("\(parameters.duration.formatted(.number.precision(.fractionLength(1)))) с").foregroundStyle(.secondary).monospacedDigit() }
                    Slider(value: parameterBinding(\.duration), in: 0.5...2, step: 0.1)
                        .accessibilityLabel("Длительность")
                        .accessibilityIdentifier("duration")
                }
                HStack {
                    Spacer()
                    Button("Попробовать сейчас", systemImage: "eye") {
                        previewTrigger &+= 1
                        controller.send(.preview)
                    }
                    .accessibilityIdentifier("preview")
                }
            } header: { Text("Напоминание") } footer: {
                Text("Наложение пропускает нажатия и не прерывает работу.")
            }
            Section("Пауза") {
                StatusView(pause: controller.state.pause)
                PauseControls(controller: controller)
            }
            Section("Система") {
                Toggle("Запускать при входе", isOn: Binding(get: { controller.loginItemStatus == .enabled || controller.loginItemStatus == .requiresApproval }, set: { controller.setLaunchAtLogin($0) }))
                    .accessibilityIdentifier("launchAtLogin")
                    .disabled(controller.loginItemStatus == .unavailable)
                if controller.loginItemStatus == .requiresApproval {
                    Text("Разрешите запуск в настройках macOS.").foregroundStyle(.secondary)
                    Button("Открыть настройки входа") { SMAppService.openSystemSettingsLoginItems() }
                } else if controller.loginItemStatus == .unavailable {
                    Text("Запуск при входе недоступен для этой копии приложения.").foregroundStyle(.secondary)
                }
                if let error = controller.errorMessage {
                    Text(error).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 480, idealWidth: 480, maxWidth: 600, minHeight: 650, idealHeight: 720)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: effect)
        .onAppear { controller.refreshLoginItemStatus() }
    }
    private func parameterBinding(_ path: WritableKeyPath<EffectSettings, Double>) -> Binding<Double> {
        Binding(get: { parameters[keyPath: path] }, set: { value in
            controller.updateSettings { settings in
                var parameters = settings.effects[settings.effect] ?? settings.effect.defaults
                parameters[keyPath: path] = value
                settings.effects[settings.effect] = parameters
            }
        })
    }
}
