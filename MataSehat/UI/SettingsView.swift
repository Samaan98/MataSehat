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
                Picker("Reminder", selection: Binding(get: { effect }, set: { effect in controller.updateSettings { $0.effect = effect } })) {
                    ForEach(ReminderEffect.allCases, id: \.self) { effect in Text(effect.title).tag(effect) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityIdentifier("effect")
                IntervalPicker(controller: controller)
                if effect == .eye {
                    Picker("Position", selection: settingsBinding(\.eyePosition)) {
                        ForEach(EyePosition.allCases, id: \.self) { position in
                            Text(position.title).tag(position)
                        }
                    }
                    .accessibilityIdentifier("eyePosition")
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Eye size")
                            Spacer()
                            Text(controller.state.settings.eyeScale, format: .percent.precision(.fractionLength(0)))
                                .foregroundStyle(.secondary).monospacedDigit()
                        }
                        Slider(value: settingsBinding(\.eyeScale), in: ReminderSettings.eyeScaleRange, step: 0.05)
                            .accessibilityLabel("Eye size")
                            .accessibilityIdentifier("eyeScale")
                    }
                }
                EffectPreviewView(effect: effect, settings: parameters, trigger: previewTrigger,
                                  eyePosition: controller.state.settings.eyePosition,
                                  eyeScale: controller.state.settings.eyeScale)
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text("Visibility"); Spacer(); Text(parameters.opacity, format: .percent.precision(.fractionLength(0))).foregroundStyle(.secondary).monospacedDigit() }
                    Slider(value: parameterBinding(\.opacity), in: effect.opacityRange)
                        .accessibilityLabel("Visibility")
                        .accessibilityIdentifier("opacity")
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack { Text("Duration"); Spacer(); Text("\(parameters.duration, format: .number.precision(.fractionLength(1))) s").foregroundStyle(.secondary).monospacedDigit() }
                    Slider(value: parameterBinding(\.duration), in: effect.durationRange, step: 0.1)
                        .accessibilityLabel("Duration")
                        .accessibilityIdentifier("duration")
                }
                HStack {
                    Spacer()
                    Button("Preview now", systemImage: "eye") {
                        previewTrigger &+= 1
                        controller.send(.preview)
                    }
                    .accessibilityIdentifier("preview")
                    .disabled(controller.state.breakPhase.isResting)
                }
            } header: { Text("Reminder") } footer: {
                Text("The overlay lets clicks through and keeps your work in focus.")
            }
            Section {
                Toggle("Remind me to take breaks", isOn: settingsBinding(\.screenBreaksEnabled))
                    .accessibilityIdentifier("screenBreaksEnabled")
                TimeSettingRow(title: "Reminder interval", unit: "min", value: Binding(
                    get: { controller.state.settings.screenBreakInterval / 60 },
                    set: { value in controller.updateSettings { $0.screenBreakInterval = value * 60 } }),
                    range: 1...120, identifier: "screenBreakInterval")
                TimeSettingRow(title: "Break duration", unit: "s", value: settingsBinding(\.screenBreakDuration),
                               range: ReminderSettings.screenBreakDurationRange, identifier: "screenBreakDuration")
                Toggle("Play sounds when a break is offered and ends", isOn: settingsBinding(\.screenBreakSoundsEnabled))
                    .accessibilityIdentifier("screenBreakSoundsEnabled")
                HStack {
                    Text("Look into the distance · about 20 feet (6 m)").foregroundStyle(.secondary)
                    Spacer()
                    Button("Show reminder") { controller.send(.requestBreak) }
                        .disabled(controller.state.breakPhase.isResting)
                        .accessibilityIdentifier("breakPreview")
                }
            } header: { HelpHeading(topic: .screenBreak) } footer: {
                Text("Start the break from the reminder card, or snooze it for 5 minutes.")
            }
            Section {
                StatusView(pause: controller.state.pause)
                PauseControls(controller: controller)
            } header: { HelpHeading(topic: .pause) }
            Section("System") {
                Toggle("Launch at login", isOn: Binding(get: { controller.loginItemStatus == .enabled || controller.loginItemStatus == .requiresApproval }, set: { controller.setLaunchAtLogin($0) }))
                    .accessibilityIdentifier("launchAtLogin")
                    .disabled(controller.loginItemStatus == .unavailable)
                if controller.loginItemStatus == .requiresApproval {
                    Text("Allow launch at login in macOS settings.").foregroundStyle(.secondary)
                    Button("Open Login Items settings") { SMAppService.openSystemSettingsLoginItems() }
                } else if controller.loginItemStatus == .unavailable {
                    Text("Launch at login is unavailable for this copy of the app.").foregroundStyle(.secondary)
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
    private func settingsBinding<Value>(_ path: WritableKeyPath<ReminderSettings, Value>) -> Binding<Value> {
        Binding(get: { controller.state.settings[keyPath: path] }, set: { value in
            controller.updateSettings { $0[keyPath: path] = value }
        })
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

private struct TimeSettingRow: View {
    let title: LocalizedStringKey
    let unit: LocalizedStringKey
    @Binding var value: Double
    let range: ClosedRange<Double>
    let identifier: String

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, value: boundedValue, format: .number.precision(.fractionLength(0)))
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .frame(width: 54)
                .help(Text("Allowed range: \(Int(range.lowerBound))–\(Int(range.upperBound)) \(Text(unit))"))
                .accessibilityIdentifier(identifier)
            Text(unit).foregroundStyle(.secondary)
            Stepper(title, value: $value, in: range, step: 1)
                .labelsHidden().fixedSize()
                .accessibilityIdentifier(identifier + "Stepper")
        }
    }
    private var boundedValue: Binding<Double> {
        Binding(get: { value }, set: { newValue in
            guard newValue.isFinite else { return }
            value = min(range.upperBound, max(range.lowerBound, newValue.rounded()))
        })
    }
}
