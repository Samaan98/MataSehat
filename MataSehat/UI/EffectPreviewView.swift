import SwiftUI

struct EffectPreviewView: View {
    let effect: ReminderEffect
    let settings: EffectSettings
    let trigger: UInt64
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var openness = 1.0
    var body: some View {
        ZStack(alignment: effect == .cornerEye ? .topTrailing : .center) {
            RoundedRectangle(cornerRadius: 8).fill(.quaternary)
            Image(systemName: "macwindow").font(.largeTitle).foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if effect == .dim { RoundedRectangle(cornerRadius: 8).fill(.black.opacity(settings.opacity)) }
            else {
                BlinkEyeMark(openness: openness)
                    .scaleEffect(effect == .cornerEye ? 0.45 : 0.8)
                    .opacity(settings.opacity)
                    .padding(effect == .cornerEye ? 4 : 0)
            }
        }
        .frame(height: 100)
        .accessibilityLabel("Миниатюра: " + effect.title)
        .task(id: "\(effect.rawValue).\(trigger)") {
            openness = 1
            guard !reduceMotion, effect != .dim else { return }
            do {
                try await Task.sleep(for: .milliseconds(150))
                withAnimation(.easeInOut(duration: 0.15)) { openness = 0 }
                try await Task.sleep(for: .milliseconds(180))
                withAnimation(.easeInOut(duration: 0.15)) { openness = 1 }
            } catch { return }
        }
    }
}
