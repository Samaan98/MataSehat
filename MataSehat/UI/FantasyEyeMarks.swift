import SwiftUI

struct HypnotoadEye: View {
    let openness: Double
    var body: some View {
        ZStack {
            Ellipse().fill(LinearGradient(colors: [Color(red: 0.6, green: 0.72, blue: 0.2),
                                                   Color(red: 0.22, green: 0.35, blue: 0.08)],
                                         startPoint: .top, endPoint: .bottom))
                .frame(width: 47, height: 34)
            ForEach([-20.0, 20.0], id: \.self) { x in
                Circle().fill(Color(red: 0.37, green: 0.49, blue: 0.12))
                    .frame(width: 4, height: 4).offset(x: x, y: 4)
            }
            ZStack {
                Ellipse().fill(Color(red: 1, green: 0.77, blue: 0.23))
                Circle().fill(Color(red: 0.9, green: 0.18, blue: 0.2)).frame(width: 25, height: 25)
                Circle().fill(Color(red: 1, green: 0.65, blue: 0.15)).frame(width: 19, height: 19)
                Circle().fill(Color(red: 0.9, green: 0.14, blue: 0.3)).frame(width: 13, height: 13)
                Circle().fill(.yellow).frame(width: 7, height: 7)
                Capsule().fill(.black).frame(width: 13, height: 3.2)
                Capsule().fill(.white.opacity(0.6)).frame(width: 4, height: 1).offset(x: -6, y: -6)
            }
            .frame(width: 34, height: 28)
            .mask(RoundEyeLid(openness: openness))
            .overlay {
                RoundEyeLid(openness: openness)
                    .stroke(Color(red: 0.18, green: 0.23, blue: 0.06), lineWidth: 1.3)
            }
        }.frame(width: 64, height: 38)
    }
}
