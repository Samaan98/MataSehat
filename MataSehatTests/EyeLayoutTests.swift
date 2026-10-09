import CoreGraphics
import Testing
@testable import MataSehat

@MainActor struct EyeLayoutTests {
    @Test func defaultSizeMatchesTheFormerTwoHundredPercentEye() {
        let frame = EyeLayout.frame(in: CGSize(width: 1_920, height: 1_080), position: .center,
                                    scale: ReminderSettings.defaults.eyeScale)
        #expect(abs(frame.width - 230.4) < 0.001)
        #expect(abs(frame.height - 136.8) < 0.001)
        #expect(ReminderSettings.eyeScaleRange == 0.5...2)
    }

    @Test(arguments: [
        (EyePosition.topLeading, 143.2, 120.4), (.top, 500.0, 120.4), (.topTrailing, 856.8, 120.4),
        (.leading, 143.2, 400.0), (.center, 500.0, 400.0), (.trailing, 856.8, 400.0),
        (.bottomLeading, 143.2, 703.6), (.bottom, 500.0, 703.6), (.bottomTrailing, 856.8, 703.6)
    ])
    func ninePositionsKeepTheEyeInsideScreen(position: EyePosition, x: Double, y: Double) {
        let frame = EyeLayout.frame(in: CGSize(width: 1_000, height: 800), position: position,
                                    scale: 1, topInset: 24)
        #expect(abs(frame.midX - x) < 0.001)
        #expect(abs(frame.midY - y) < 0.001)
        #expect(abs(frame.width - 230.4) < 0.001)
        #expect(abs(frame.height - 136.8) < 0.001)
    }

    @Test(arguments: [0.5, 1.0, 2.0])
    func previewShowsTheFullScaleRange(scale: Double) {
        let frame = EyeLayout.frame(in: CGSize(width: 1_440, height: 560), position: .center,
                                    scale: scale, maximumFraction: 0.5)
        #expect(abs(frame.width - 230.4 * scale) < 0.001)
        #expect(abs(frame.height - 136.8 * scale) < 0.001)
    }
    @Test(arguments: EyePosition.fixedPositions)
    func maximumScaleFitsASmallScreen(position: EyePosition) {
        let screen = CGRect(x: 0, y: 0, width: 240, height: 160)
        let frame = EyeLayout.frame(in: screen.size, position: position, scale: 2, topInset: 100)
        #expect(screen.contains(frame))
        #expect(frame.width <= 60.001)
        #expect(frame.height <= 40.001)
        #expect(abs(frame.width / frame.height - 64.0 / 38.0) < 0.001)
    }
}
