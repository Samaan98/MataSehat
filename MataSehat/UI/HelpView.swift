import SwiftUI

nonisolated enum HelpTopic: String, CaseIterable, Sendable {
    case interval, screenBreak, pause

    var title: LocalizedStringResource {
        switch self {
        case .interval: "Blink interval"
        case .screenBreak: "20–20–20 breaks"
        case .pause: "Pause"
        }
    }

    var tooltip: LocalizedStringResource {
        switch self {
        case .interval: "How to choose an interval and remember to blink between reminders. Click to learn more."
        case .screenBreak: "Every 20 minutes, look into the distance for at least 20 seconds. Click to learn more."
        case .pause: "Temporarily pause reminders when you need uninterrupted time. Click to learn more."
        }
    }

    var explanation: LocalizedStringResource {
        switch self {
        case .interval:
            """
            People usually blink about 15–20 times a minute — roughly every 3–4 seconds. We often blink less while using a screen; the rate varies by person and activity.

            If you find it comfortable to blink with every reminder, try an interval of 3–4 seconds. With less frequent reminders, remember to blink between them too.
            """
        case .screenBreak:
            """
            Every 20 minutes, look away from the screen for at least 20 seconds. Focus on an object at least 20 feet — about 6 metres — away.

            You can change the reminder interval and break duration in settings. The countdown begins when you select “Start break”.
            """
        case .pause:
            """
            Temporarily pause reminders when you do not want distractions. This pauses blink reminders and automatic break invitations.

            Choose a duration and select “Pause reminders”. Reminders resume automatically; “Until resumed” keeps them paused until you resume them yourself.
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
        .help(Text(topic.tooltip))
        .accessibilityLabel(Text("About \(Text(topic.title))"))
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
