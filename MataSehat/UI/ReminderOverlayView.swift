import SwiftUI

struct ReminderOverlayView: View {
    let presentation: EffectPresentation
    let reduceMotion: Bool
    let topInset: CGFloat
    @State private var opacity = 0.0
    @State private var openness = 1.0
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.clear
                if presentation.effect == .dim {
                    Color.black.opacity(presentation.settings.opacity * opacity)
                } else {
                    let frame = EyeLayout.frame(in: geometry.size, position: presentation.eyePosition,
                                                scale: presentation.eyeScale, topInset: topInset)
                    BlinkEyeMark(openness: openness, width: frame.width, style: presentation.eyeStyle,
                                 variant: presentation.eyeVariant)
                        .opacity(presentation.settings.opacity * opacity)
                        .position(x: frame.midX, y: frame.midY)
                }
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
