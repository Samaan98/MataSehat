import AppKit
import SwiftUI

@MainActor protocol ScreenBreakPresenting {
    func show(_ phase: ScreenBreakPhase, onAction: @escaping @MainActor (ReminderEvent) -> Void)
    func hide()
}
@MainActor final class ScreenBreakWindowController: ScreenBreakPresenting {
    private var storedPanel: NSPanel?
    var onError: ((String) -> Void)?
    var panel: NSPanel {
        if let storedPanel { return storedPanel }
        let panel = ScreenBreakPanel(contentRect: NSRect(x: 0, y: 0, width: 420, height: 260),
            styleMask: [.titled, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.title = "Отдых 20–20–20"
        panel.identifier = NSUserInterfaceItemIdentifier("screenBreak")
        panel.level = .statusBar
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        storedPanel = panel
        return panel
    }
    func show(_ phase: ScreenBreakPhase, onAction: @escaping @MainActor (ReminderEvent) -> Void) {
        guard phase != .waiting else { hide(); return }
        guard let screen = NSScreen.screens.first else {
            onError?("Не удалось найти экран для отдыха.")
            onAction(phase.isResting ? .finishBreak : .snoozeBreak)
            return
        }
        let panel = self.panel
        if !panel.isVisible {
            let visible = screen.visibleFrame
            panel.setFrameOrigin(NSPoint(x: visible.midX - panel.frame.width / 2, y: visible.midY - panel.frame.height / 2))
        }
        panel.contentView = NSHostingView(rootView: ScreenBreakView(phase: phase, onAction: onAction))
        panel.orderFrontRegardless()
    }
    func hide() {
        storedPanel?.orderOut(nil)
        storedPanel?.contentView = nil
    }
}
@MainActor private final class ScreenBreakPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
