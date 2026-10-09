import SwiftUI

struct RinneganEye: View {
    let openness: Double
    var body: some View {
        ZStack {
            Color(red: 0.92, green: 0.88, blue: 0.97)
            Circle().fill(RadialGradient(colors: [Color(red: 0.8, green: 0.65, blue: 0.95),
                                                  Color(red: 0.57, green: 0.4, blue: 0.73)],
                                         center: .topLeading, startRadius: 0, endRadius: 30))
                .frame(width: 30, height: 30)
            ForEach([29.0, 24.0, 19.0, 14.0, 9.0], id: \.self) { diameter in
                Circle().stroke(Color(red: 0.18, green: 0.09, blue: 0.25), lineWidth: 0.65)
                    .frame(width: diameter, height: diameter)
            }
            Circle().fill(Color(red: 0.1, green: 0.03, blue: 0.17)).frame(width: 4, height: 4)
            Circle().fill(.white.opacity(0.65)).frame(width: 2, height: 2).offset(x: -6, y: -7)
        }
        .frame(width: 59, height: 30)
        .mask(BlinkEyeShape(openness: openness))
        .overlay {
            BlinkEyeShape(openness: openness)
                .stroke(Color(red: 0.14, green: 0.07, blue: 0.19), lineWidth: 1.4)
        }
        .frame(width: 64, height: 38)
    }
}

struct CheshireEye: View {
    let openness: Double
    private let rim = Color(red: 0.01, green: 0.12, blue: 0.12)

    var body: some View {
        ZStack {
            Circle().fill(AngularGradient(colors: [Color(red: 0.06, green: 0.68, blue: 0.38),
                                                    Color(red: 0.07, green: 0.88, blue: 0.85),
                                                    Color(red: 0.02, green: 0.53, blue: 0.64),
                                                    Color(red: 0.12, green: 0.8, blue: 0.42),
                                                    Color(red: 0.06, green: 0.68, blue: 0.38)],
                                         center: .center))
            Circle().fill(RadialGradient(colors: [.clear, .clear, rim.opacity(0.85)],
                                         center: .center, startRadius: 4, endRadius: 18))
            irisFibres(bright: true).stroke(.mint.opacity(0.55), lineWidth: 0.4)
            irisFibres(bright: false).stroke(rim.opacity(0.45), lineWidth: 0.35)
            Path { path in
                path.move(to: CGPoint(x: 18, y: 3))
                path.addQuadCurve(to: CGPoint(x: 18, y: 33), control: CGPoint(x: 27, y: 18))
                path.addQuadCurve(to: CGPoint(x: 18, y: 3), control: CGPoint(x: 9, y: 18))
                path.closeSubpath()
            }.fill(Color(white: 0.015))
            Ellipse().fill(.white.opacity(0.95)).frame(width: 3, height: 5).offset(x: -6, y: -7)
            Circle().fill(.white.opacity(0.55)).frame(width: 1.5, height: 1.5).offset(x: 5, y: 8)
        }
        .frame(width: 36, height: 36)
        .mask(RoundEyeLid(openness: openness))
        .overlay { RoundEyeLid(openness: openness).stroke(rim, lineWidth: 1.1) }
        .shadow(color: .cyan.opacity(0.3), radius: 1)
        .frame(width: 64, height: 38)
    }

    private func irisFibres(bright: Bool) -> Path {
        Path { path in
            for index in stride(from: bright ? 0 : 1, to: 48, by: 2) {
                let angle = Double(index) * .pi / 24
                let inner = 5.5 + Double(index % 5)
                path.move(to: CGPoint(x: 18 + cos(angle) * inner, y: 18 + sin(angle) * inner))
                path.addQuadCurve(to: CGPoint(x: 18 + cos(angle + 0.04) * 17, y: 18 + sin(angle + 0.04) * 17),
                                  control: CGPoint(x: 18 + cos(angle - 0.06) * 12, y: 18 + sin(angle - 0.06) * 12))
            }
        }
    }
}
