import SwiftUI

struct BlinkEyeShape: Shape {
    var openness: Double
    var animatableData: Double { get { openness } set { openness = newValue } }
    func path(in rect: CGRect) -> Path {
        let rise = rect.height * max(0.02, min(openness, 1)) * 0.5
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.midY - rise * 2))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.midY), control: CGPoint(x: rect.midX, y: rect.midY + rise * 2))
        return path
    }
}
struct BlinkEyeMark: View {
    var openness: Double = 1
    var width: CGFloat = 64
    var style: EyeStyle = .light
    var variant: EyeVariant = .standard
    var shadowRadius: CGFloat = 3
    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { style.resolved(isDarkAppearance: colorScheme == .dark) == .dark }
    var body: some View {
        if variant == .standard {
            standardEye
        } else {
            EasterEggEyeMark(variant: variant, openness: openness, width: width, shadowRadius: shadowRadius)
        }
    }
    private var standardEye: some View {
        let scale = width / 64
        return ZStack {
            BlinkEyeShape(openness: openness).stroke(style: StrokeStyle(lineWidth: 3 * scale, lineCap: .round, lineJoin: .round))
            Circle().frame(width: 14 * scale, height: 14 * scale).scaleEffect(x: 1, y: max(0, openness))
        }
        .frame(width: width, height: 38 * scale)
        .foregroundStyle(isDark ? Color.black : Color.white)
        .shadow(color: (isDark ? Color.white : Color.black).opacity(0.65), radius: shadowRadius)
        .accessibilityHidden(true)
    }
}
