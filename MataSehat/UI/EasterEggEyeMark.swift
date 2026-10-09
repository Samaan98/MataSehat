import SwiftUI

struct EasterEggEyeMark: View {
    let variant: EyeVariant
    let openness: Double
    let width: CGFloat
    var shadowRadius: CGFloat = 3

    var body: some View {
        Group {
            switch variant {
            case .standard: EmptyView()
            case .sauron: SauronEye(openness: openness)
            case .cipher: CipherEye(openness: openness)
            case .sharingan: SharinganEye(openness: openness)
            case .hal: HALEye(openness: openness)
            case .mike: MikeEye(openness: openness)
            case .sheikah: SheikahEye(openness: openness)
            case .horus: HorusEye(openness: openness)
            case .dragon: DragonEye(openness: openness)
            case .hypnotoad: HypnotoadEye(openness: openness)
            case .cacodemon: CacodemonEye(openness: openness)
            case .rinnegan: RinneganEye(openness: openness)
            case .cheshire: CheshireEye(openness: openness)
            }
        }
        .frame(width: 64, height: 38)
        .scaleEffect(width / 64)
        .frame(width: width, height: width * 38 / 64)
        .shadow(color: .white.opacity(0.25), radius: shadowRadius * 0.5)
        .shadow(color: .black.opacity(0.35), radius: shadowRadius)
        .accessibilityHidden(true)
    }
}

private struct SauronEye: View {
    let openness: Double
    var body: some View {
        ZStack {
            SauronFlames(openness: openness)
                .fill(LinearGradient(colors: [.red, .orange, .yellow, .orange, .red],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: 64, height: 38)
                .shadow(color: .orange.opacity(0.75), radius: 1.5)
            lens
        }.frame(width: 64, height: 38)
    }
    private var lens: some View {
        ZStack {
            BlinkEyeShape(openness: openness)
                .fill(LinearGradient(colors: [.red, .orange, .yellow, .orange, .red],
                                     startPoint: .leading, endPoint: .trailing))
            Ellipse()
                .fill(RadialGradient(colors: [.yellow, .orange, .red.opacity(0.2)],
                                     center: .center, startRadius: 2, endRadius: 15))
                .frame(width: 25, height: 30)
            Capsule().fill(.black).frame(width: 3.5, height: 27)
            Capsule().fill(.yellow.opacity(0.8)).frame(width: 0.8, height: 19).offset(x: 3)
        }
        .frame(width: 58, height: 24)
        .mask(BlinkEyeShape(openness: openness))
        .overlay {
            BlinkEyeShape(openness: openness)
                .stroke(LinearGradient(colors: [.red, .yellow, .orange],
                                       startPoint: .top, endPoint: .bottom), lineWidth: 1.2)
        }
        .shadow(color: .orange.opacity(0.85), radius: 2)
    }
}

private struct SauronFlames: Shape {
    var openness: Double
    var animatableData: Double { get { openness } set { openness = newValue } }
    func path(in rect: CGRect) -> Path {
        let openness = max(0, min(1, openness))
        var path = Path()
        for side in [-1.0, 1.0] {
            for index in 0..<9 {
                let x = 5.0 + Double(index) * 6.5
                let t = (x - 3) / 58
                let curve = 4 * t * (1 - t)
                let y = 19 + side * 12 * openness * curve
                let height = (1.5 + 4.5 * openness) * (index.isMultiple(of: 2) ? 1 : 0.65)
                let lean = index.isMultiple(of: 2) ? 2.0 : -2.0
                func point(_ x: Double, _ y: Double) -> CGPoint {
                    CGPoint(x: rect.minX + x / 64 * rect.width, y: rect.minY + y / 38 * rect.height)
                }
                path.move(to: point(x - 3.2, y - side))
                path.addQuadCurve(to: point(x + lean, y + side * height),
                                  control: point(x - 1, y + side * height * 0.7))
                path.addQuadCurve(to: point(x + 3.2, y - side),
                                  control: point(x + 1, y + side * height * 0.6))
                path.closeSubpath()
            }
        }
        return path
    }
}

private struct CipherEye: View {
    let openness: Double
    private var triangle: Path {
        Path { path in
            path.move(to: CGPoint(x: 32, y: 5))
            path.addLine(to: CGPoint(x: 13, y: 37))
            path.addLine(to: CGPoint(x: 51, y: 37))
            path.closeSubpath()
        }
    }
    var body: some View {
        ZStack {
            triangle.fill(LinearGradient(colors: [.yellow, Color(red: 1, green: 0.72, blue: 0.08)],
                                         startPoint: .top, endPoint: .bottom))
            triangle.stroke(Color(red: 0.35, green: 0.22, blue: 0), lineWidth: 0.8)
            Path { path in
                for y in [25.0, 31.0] {
                    path.move(to: CGPoint(x: 13, y: y))
                    path.addLine(to: CGPoint(x: 51, y: y))
                }
                for x in [23.0, 32.0, 41.0] {
                    path.move(to: CGPoint(x: x, y: 31))
                    path.addLine(to: CGPoint(x: x, y: 37))
                }
            }.stroke(.black.opacity(0.12), lineWidth: 0.5).clipShape(triangle)
            ZStack {
                BlinkEyeShape(openness: openness).fill(.white)
                BlinkEyeShape(openness: openness).stroke(.black, lineWidth: 1)
                Capsule().fill(.black).frame(width: 2.4, height: 10)
                    .scaleEffect(x: 1, y: max(0, openness))
            }.frame(width: 22, height: 13).position(x: 32, y: 21)
            Path { path in
                for x in [26.0, 32.0, 38.0] {
                    path.move(to: CGPoint(x: x, y: 15.5))
                    path.addLine(to: CGPoint(x: x, y: 12.5))
                }
            }.stroke(.black, style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .opacity(openness)
            Path { path in
                path.move(to: CGPoint(x: 26, y: 29))
                path.addLine(to: CGPoint(x: 38, y: 33))
                path.addLine(to: CGPoint(x: 38, y: 29))
                path.addLine(to: CGPoint(x: 26, y: 33))
                path.closeSubpath()
            }.fill(.black)
            Rectangle().fill(.black).frame(width: 6, height: 8).position(x: 32, y: 4)
            Capsule().fill(.black).frame(width: 12, height: 1.6).position(x: 32, y: 8)
        }.frame(width: 64, height: 38)
    }
}

private struct SharinganEye: View {
    let openness: Double
    var body: some View {
        ZStack {
            Color.white
            Circle().fill(RadialGradient(colors: [Color(red: 0.95, green: 0.2, blue: 0.22), .red, Color(red: 0.5, green: 0, blue: 0)],
                                         center: .center, startRadius: 1, endRadius: 14))
                .frame(width: 28, height: 28)
                .overlay { Circle().stroke(.black, lineWidth: 1.2) }
            Circle().stroke(.black.opacity(0.5), lineWidth: 0.5).frame(width: 19, height: 19)
            Circle().fill(.black).frame(width: 7, height: 7)
            ForEach(0..<3) { index in
                Tomoe().fill(.black).frame(width: 5, height: 7)
                    .offset(y: -9).rotationEffect(.degrees(Double(index) * 120))
            }
            Circle().fill(.white.opacity(0.65)).frame(width: 2, height: 2).offset(x: -5, y: -5)
        }
        .frame(width: 60, height: 30)
        .mask(BlinkEyeShape(openness: openness))
        .overlay { BlinkEyeShape(openness: openness).stroke(.black, lineWidth: 1.2) }
    }
}

private struct Tomoe: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width * 0.75, height: rect.height * 0.55))
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.35, y: rect.minY + rect.height * 0.25))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY),
                          control: CGPoint(x: rect.maxX + rect.width * 0.2, y: rect.minY + rect.height * 0.3))
        path.addQuadCurve(to: CGPoint(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.45),
                          control: CGPoint(x: rect.minX + rect.width * 0.6, y: rect.minY + rect.height * 0.7))
        path.closeSubpath()
        return path
    }
}

private struct HALEye: View {
    let openness: Double
    var body: some View {
        ZStack {
            Circle().fill(Color(white: 0.08)).frame(width: 34, height: 34)
            Circle().stroke(LinearGradient(colors: [.white, .gray, .white.opacity(0.6), .gray],
                                            startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
                .frame(width: 33, height: 33)
            Circle().fill(RadialGradient(colors: [Color(red: 1, green: 0.65, blue: 0.3), .red, Color(red: 0.2, green: 0, blue: 0)],
                                         center: .center, startRadius: 0, endRadius: 13))
                .frame(width: 26, height: 26)
                .scaleEffect(max(0, openness))
            ApertureLines(openness: openness).stroke(.gray.opacity(0.7), lineWidth: 0.5)
                .frame(width: 30, height: 30)
            Circle().fill(.white.opacity(0.7)).frame(width: 2.5, height: 2.5).offset(x: -6, y: -6)
                .opacity(openness)
        }.frame(width: 64, height: 38)
    }
}

private struct ApertureLines: Shape {
    var openness: Double
    var animatableData: Double { get { openness } set { openness = newValue } }
    func path(in rect: CGRect) -> Path {
        let radius = min(rect.width, rect.height) / 2
        let innerRadius = radius * max(0, min(1, openness)) * 0.9
        var path = Path()
        for index in 0..<6 {
            let angle = Double(index) * .pi / 3
            path.move(to: CGPoint(x: rect.midX + cos(angle + 0.4) * innerRadius,
                                 y: rect.midY + sin(angle + 0.4) * innerRadius))
            path.addLine(to: CGPoint(x: rect.midX + cos(angle) * radius,
                                    y: rect.midY + sin(angle) * radius))
        }
        return path
    }
}
