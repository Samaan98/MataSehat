import SwiftUI

@Animatable
struct CacodemonEye: View, Animatable {
    var openness: Double

    // Each cell is a vector rectangle on a two-point grid, preserving the sprite's hard edges.
    private static let sprite = [
        "     T            T     ",
        "     TT          TT     ",
        "  T  TBB   KK   BBT  T  ",
        "  TB  KRRKKHHKKRRK  BT  ",
        "   TBKRHHHHHHHRRRKBT    ",
        "   KRRHHHHHHHRRRRRRK    ",
        "  KRRHHHHHHHRRRRRRDK    ",
        "  KRHHHHHHHRRRRRRDDK    ",
        "  KRRHHHHHRRRRRRDDDK    ",
        "  KRRHHHRRRRRRDDDDDK    ",
        "  KRRHRRRRRRRDDDDDDK    ",
        "   KRRRRRRDDDDDDDDK     ",
        "   KRRRKKMMMMMMKKDK     ",
        "   KRRKMBMMBMMBMKDK     ",
        "    KRKMMMMMMMMMKDK     ",
        "    KRKMBMMBMMBMKDK     ",
        "     KDDKKMMMMKKDK      ",
        "      KDDDDDDDDKK       ",
        "       KKKKKKKK         "
    ]
    private static let eye = [
        "  gggg  ",
        " gGGGGg ",
        "gGlNNlGg",
        "gGlNNlGg",
        " gGllGg ",
        "  gggg  "
    ]
    private static let palette: [Character: Color] = [
        "K": Color(red: 0.16, green: 0.02, blue: 0.06),
        "D": Color(red: 0.36, green: 0.03, blue: 0.1),
        "R": Color(red: 0.7, green: 0.08, blue: 0.12),
        "H": Color(red: 0.93, green: 0.24, blue: 0.22),
        "T": Color(red: 0.46, green: 0.39, blue: 0.28),
        "B": Color(red: 0.96, green: 0.84, blue: 0.61),
        "M": Color(red: 0.03, green: 0.14, blue: 0.26),
        "g": Color(red: 0.03, green: 0.29, blue: 0.12),
        "G": Color(red: 0.21, green: 0.76, blue: 0.17),
        "l": Color(red: 0.8, green: 0.97, blue: 0.38),
        "N": Color(white: 0.02)
    ]

    var body: some View {
        Canvas { context, _ in
            func pixel(_ value: Character, x: Int, y: Int) {
                guard let colour = Self.palette[value] else { return }
                let cell = CGRect(x: (x + 4) * 2, y: y * 2, width: 2, height: 2)
                context.fill(Path(cell), with: .color(colour), style: FillStyle(antialiased: false))
            }
            for (y, row) in Self.sprite.enumerated() {
                for (x, value) in row.enumerated() { pixel(value, x: x, y: y) }
            }
            let halfHeight = Int((max(0, min(1, openness)) * 3).rounded(.up))
            if halfHeight == 0 {
                for x in 8..<16 { pixel("K", x: x, y: 8) }
            } else {
                for (y, row) in Self.eye.enumerated() where y >= 3 - halfHeight && y < 3 + halfHeight {
                    for (x, value) in row.enumerated() { pixel(value, x: x + 8, y: y + 5) }
                }
            }
        }.frame(width: 64, height: 38)
    }
}
