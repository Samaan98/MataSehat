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
    var body: some View {
        ZStack {
            BlinkEyeShape(openness: openness).stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            Circle().frame(width: 14, height: 14).scaleEffect(x: 1, y: max(0, openness))
        }
        .frame(width: 64, height: 38)
        .accessibilityHidden(true)
    }
}
