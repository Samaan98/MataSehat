import AppKit
import Testing
@testable import MataSehat

@MainActor
struct OverlayWindowTests {
    @Test func screenBreakCardAcceptsActionsWithoutAutomaticallyTakingFocus() {
        let presenter = ScreenBreakWindowController()
        #expect(!presenter.panel.ignoresMouseEvents)
        #expect(presenter.panel.canBecomeKey)
        #expect(!presenter.panel.canBecomeMain)
        #expect(presenter.panel.styleMask.contains(.nonactivatingPanel))
        #expect(presenter.panel.collectionBehavior.contains(.canJoinAllSpaces))
        let keyWindow = NSApp.keyWindow
        presenter.show(.invitation) { _ in }
        #expect(presenter.panel.isVisible)
        #expect(NSApp.keyWindow === keyWindow)
        let panel = presenter.panel
        presenter.show(.resting(until: ProcessInfo.processInfo.systemUptime + 20)) { _ in }
        #expect(presenter.panel === panel)
        presenter.hide()
        #expect(!presenter.panel.isVisible)
        #expect(presenter.panel.contentView == nil)
    }
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
