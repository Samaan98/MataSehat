import SwiftUI

struct EffectPreviewView: View {
    let effect: ReminderEffect
    let settings: EffectSettings
    let trigger: UInt64
    var eyePosition: EyePosition = .center
    var eyeScale = 1.0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var openness = 1.0
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(.quaternary)
                Image(systemName: "macwindow").font(.largeTitle).foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if effect == .dim { RoundedRectangle(cornerRadius: 8).fill(.black.opacity(settings.opacity)) }
                else {
                    let frame = EyeLayout.frame(in: CGSize(width: geometry.size.width * 4, height: geometry.size.height * 4),
                                                position: eyePosition, scale: eyeScale)
                    BlinkEyeMark(openness: openness, width: frame.width / 4)
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.65), radius: 1)
                        .opacity(settings.opacity)
                        .position(x: frame.midX / 4, y: frame.midY / 4)
                }
            }
        }
        .frame(height: 140)
        .accessibilityLabel("Миниатюра: " + effect.title + (effect == .eye ? ", " + eyePosition.title : ""))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: eyePosition)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: eyeScale)
        .task(id: "\(effect.rawValue).\(trigger).\(eyePosition.rawValue)") {
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
