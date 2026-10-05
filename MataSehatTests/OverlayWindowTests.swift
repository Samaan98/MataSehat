import AppKit
import Testing
@testable import MataSehat

@MainActor
struct OverlayWindowTests {
    @Test func effectWindowAllowsInputToPassWithoutBecomingKey() {
        let overlay = OverlayWindowController()
        #expect(overlay.panel.ignoresMouseEvents)
        #expect(!overlay.panel.canBecomeKey)
        #expect(!overlay.panel.canBecomeMain)
        #expect(!overlay.panel.isOpaque)
        #expect(overlay.panel.styleMask.contains(.nonactivatingPanel))
        #expect(overlay.panel.collectionBehavior.contains(.canJoinAllSpaces))
        #expect(overlay.panel.collectionBehavior.contains(.fullScreenAuxiliary))
    }
    @Test func overlappingSuspensionReasonsDoNotResumeEarly() {
        var state = ActivitySuspension()
        #expect(state.update(.sleep, suspended: true) == .suspended)
        #expect(state.update(.locked, suspended: true) == nil)
        #expect(state.update(.sleep, suspended: false) == nil)
        #expect(state.update(.locked, suspended: false) == .resumed)
    }
}
