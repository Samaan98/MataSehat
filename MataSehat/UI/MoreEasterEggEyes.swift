import SwiftUI

struct MikeEye: View {
    let openness: Double
    private let green = Color(red: 0.48, green: 0.78, blue: 0.08)
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 18, y: 10))
                path.addQuadCurve(to: CGPoint(x: 20, y: 1), control: CGPoint(x: 15, y: 3))
                path.addLine(to: CGPoint(x: 25, y: 9))
                path.move(to: CGPoint(x: 39, y: 9))
                path.addLine(to: CGPoint(x: 44, y: 1))
                path.addQuadCurve(to: CGPoint(x: 46, y: 10), control: CGPoint(x: 49, y: 3))
            }.fill(Color(red: 0.92, green: 0.88, blue: 0.65))
            Circle().fill(RadialGradient(colors: [green, Color(red: 0.24, green: 0.46, blue: 0.02)],
                                         center: .topLeading, startRadius: 1, endRadius: 36))
                .frame(width: 35, height: 35).position(x: 32, y: 20)
            ZStack {
                Circle().fill(.white)
                Circle().fill(RadialGradient(colors: [.cyan, Color(red: 0.05, green: 0.33, blue: 0.28)],
                                             center: .center, startRadius: 1, endRadius: 6))
                    .frame(width: 13, height: 13)
                Circle().fill(.black).frame(width: 7, height: 7)
                Circle().fill(.white).frame(width: 2.5, height: 2.5).offset(x: -2, y: -3)
            }
            .frame(width: 25, height: 25)
            .mask(RoundEyeLid(openness: openness))
            .overlay {
                RoundEyeLid(openness: openness)
                    .stroke(Color(red: 0.13, green: 0.3, blue: 0.02), lineWidth: 0.8)
            }.position(x: 32, y: 19)
        }.frame(width: 64, height: 38)
    }
}

struct RoundEyeLid: Shape {
    var openness: Double
    var animatableData: Double { get { openness } set { openness = newValue } }
    func path(in rect: CGRect) -> Path {
        let height = rect.height * max(0.015, min(1, openness))
        return Path(ellipseIn: CGRect(x: rect.minX, y: rect.midY - height / 2,
                                      width: rect.width, height: height))
    }
}

struct SheikahEye: View {
    let openness: Double
    private let blue = Color(red: 0.2, green: 0.75, blue: 1)
    var body: some View {
        ZStack {
            Path { path in
                for x in [20.0, 32.0, 44.0] {
                    path.move(to: CGPoint(x: x - 3, y: 10))
                    path.addLine(to: CGPoint(x: x, y: 1))
                    path.addLine(to: CGPoint(x: x + 3, y: 10))
                    path.closeSubpath()
                }
                path.move(to: CGPoint(x: 29, y: 26))
                path.addLine(to: CGPoint(x: 32, y: 37))
                path.addLine(to: CGPoint(x: 35, y: 26))
                path.closeSubpath()
            }.fill(blue)
            BlinkEyeShape(openness: openness).stroke(blue, lineWidth: 1.8)
                .frame(width: 43, height: 19).position(x: 32, y: 19)
            Circle().stroke(blue, lineWidth: 1.5).frame(width: 10, height: 10)
                .overlay { Circle().fill(.white).frame(width: 3, height: 3) }
                .scaleEffect(x: 1, y: max(0, openness)).position(x: 32, y: 19)
        }
        .frame(width: 64, height: 38)
        .shadow(color: blue.opacity(0.7), radius: 1)
    }
}

struct HorusEye: View {
    let openness: Double
    private let gold = Color(red: 1, green: 0.74, blue: 0.19)
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 9, y: 10))
                path.addQuadCurve(to: CGPoint(x: 50, y: 11), control: CGPoint(x: 25, y: -3))
                path.addLine(to: CGPoint(x: 58, y: 17))
                path.move(to: CGPoint(x: 28, y: 25))
                path.addQuadCurve(to: CGPoint(x: 28, y: 36), control: CGPoint(x: 25, y: 32))
                path.move(to: CGPoint(x: 48, y: 23))
                path.addQuadCurve(to: CGPoint(x: 37, y: 32), control: CGPoint(x: 54, y: 34))
                path.addQuadCurve(to: CGPoint(x: 36, y: 28), control: CGPoint(x: 31, y: 33))
                path.move(to: CGPoint(x: 12, y: 23))
                path.addLine(to: CGPoint(x: 18, y: 31))
            }.stroke(gold, style: StrokeStyle(lineWidth: 1.7, lineCap: .round, lineJoin: .round))
            BlinkEyeShape(openness: openness).stroke(gold, lineWidth: 1.7)
                .frame(width: 46, height: 18).position(x: 32, y: 19)
            Circle().fill(gold).frame(width: 10, height: 10)
                .overlay { Circle().fill(Color(white: 0.08)).frame(width: 4, height: 4) }
                .scaleEffect(x: 1, y: max(0, openness)).position(x: 32, y: 19)
        }.frame(width: 64, height: 38)
    }
}

struct DragonEye: View {
    let openness: Double
    private let green = Color(red: 0.12, green: 0.65, blue: 0.3)
    var body: some View {
        ZStack {
            ForEach(0..<5) { index in
                Path { path in
                    let x = 12.0 + Double(index) * 10
                    for y in [2.0, 31.0] {
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x + 4, y: y + 2))
                        path.addLine(to: CGPoint(x: x, y: y + 5))
                        path.addLine(to: CGPoint(x: x - 4, y: y + 2))
                        path.closeSubpath()
                    }
                }.fill(index.isMultiple(of: 2) ? green : Color(red: 0.08, green: 0.36, blue: 0.2))
            }
            ZStack {
                LinearGradient(colors: [Color(red: 0.04, green: 0.2, blue: 0.1), green, .mint, green],
                               startPoint: .top, endPoint: .bottom)
                Ellipse().fill(RadialGradient(colors: [.yellow, .orange, green],
                                             center: .center, startRadius: 2, endRadius: 15))
                    .frame(width: 25, height: 29)
                Capsule().fill(.black).frame(width: 3, height: 25)
                Capsule().fill(.white.opacity(0.8)).frame(width: 0.8, height: 10).offset(x: -4, y: -5)
            }
            .frame(width: 58, height: 27)
            .mask(BlinkEyeShape(openness: openness))
            .overlay {
                BlinkEyeShape(openness: openness).stroke(Color(red: 0.02, green: 0.19, blue: 0.1), lineWidth: 1.4)
            }.position(x: 32, y: 19)
        }.frame(width: 64, height: 38)
    }
}
