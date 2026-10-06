import CoreGraphics
import Testing
@testable import MataSehat

@MainActor struct EyeLayoutTests {
    @Test(arguments: [
        (EyePosition.topLeading, 85.6, 86.2), (.top, 500.0, 86.2), (.topTrailing, 914.4, 86.2),
        (.leading, 85.6, 400.0), (.center, 500.0, 400.0), (.trailing, 914.4, 400.0),
        (.bottomLeading, 85.6, 737.8), (.bottom, 500.0, 737.8), (.bottomTrailing, 914.4, 737.8)
    ])
    func ninePositionsKeepTheEyeInsideScreen(position: EyePosition, x: Double, y: Double) {
        let frame = EyeLayout.frame(in: CGSize(width: 1_000, height: 800), position: position,
                                    scale: 1, topInset: 24)
        #expect(abs(frame.midX - x) < 0.001)
        #expect(abs(frame.midY - y) < 0.001)
        #expect(abs(frame.width - 115.2) < 0.001)
        #expect(abs(frame.height - 68.4) < 0.001)
    }
    @Test(arguments: EyePosition.allCases)
    func maximumScaleFitsASmallScreen(position: EyePosition) {
        let screen = CGRect(x: 0, y: 0, width: 240, height: 160)
        let frame = EyeLayout.frame(in: screen.size, position: position, scale: 2, topInset: 100)
        #expect(screen.contains(frame))
        #expect(frame.width <= 60.001)
        #expect(frame.height <= 40.001)
        #expect(abs(frame.width / frame.height - 64.0 / 38.0) < 0.001)
    }
}
