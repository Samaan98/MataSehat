import SwiftUI

struct ReminderOverlayView: View {
    let presentation: EffectPresentation
    let reduceMotion: Bool
    let topInset: CGFloat
    @State private var opacity = 0.0
    @State private var openness = 1.0
    var body: some View {
        ZStack(alignment: presentation.effect == .cornerEye ? .topTrailing : .center) {
            Color.clear
            if presentation.effect == .dim {
                Color.black.opacity(presentation.settings.opacity * opacity)
            } else {
                BlinkEyeMark(openness: openness)
                    .scaleEffect(presentation.effect == .centerEye ? 1.8 : 1)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.65), radius: 3)
                    .opacity(presentation.settings.opacity * opacity)
                    .padding(.top, presentation.effect == .cornerEye ? topInset + 24 : 0)
                    .padding(.trailing, presentation.effect == .cornerEye ? 28 : 0)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: presentation.id) {
            let unit = presentation.settings.duration / 5
            withAnimation(.easeInOut(duration: unit)) { opacity = 1 }
            do {
                try await Task.sleep(for: .seconds(unit))
                if !reduceMotion { withAnimation(.easeInOut(duration: unit)) { openness = 0 } }
                try await Task.sleep(for: .seconds(unit * 2))
                if !reduceMotion { withAnimation(.easeInOut(duration: unit)) { openness = 1 } }
                try await Task.sleep(for: .seconds(unit))
                withAnimation(.easeInOut(duration: unit)) { opacity = 0 }
            } catch { return }
        }
    }
}
