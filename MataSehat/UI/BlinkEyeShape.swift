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
    var body: some View {
        let scale = width / 64
        ZStack {
            BlinkEyeShape(openness: openness).stroke(style: StrokeStyle(lineWidth: 3 * scale, lineCap: .round, lineJoin: .round))
            Circle().frame(width: 14 * scale, height: 14 * scale).scaleEffect(x: 1, y: max(0, openness))
        }
        .frame(width: width, height: 38 * scale)
        .accessibilityHidden(true)
    }
}
