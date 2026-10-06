import AppKit
import SwiftUI

@MainActor protocol OverlayPresenting {
    func show(_ value: EffectPresentation, reduceMotion: Bool, completion: @escaping @MainActor (UInt64) -> Void)
    func hide()
}
@MainActor private final class ReminderPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
@MainActor final class OverlayWindowController: OverlayPresenting {
    let panel: NSPanel
    private var completionTask: Task<Void, Never>?
    var onError: ((String) -> Void)?
    init() {
        panel = ReminderPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.hidesOnDeactivate = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
    }
    func show(_ value: EffectPresentation, reduceMotion: Bool, completion: @escaping @MainActor (UInt64) -> Void) {
        hide()
        guard let screen = NSScreen.screens.first else {
            onError?(String(localized: "Could not find a screen for the blink reminder."))
            completion(value.id)
            return
        }
        panel.setFrame(screen.frame, display: false)
        let topInset = screen.frame.maxY - screen.visibleFrame.maxY
        panel.contentView = NSHostingView(rootView: ReminderOverlayView(presentation: value, reduceMotion: reduceMotion, topInset: topInset))
        panel.orderFrontRegardless()
        completionTask = Task { @MainActor in
            do { try await Task.sleep(for: .seconds(value.settings.duration)) }
            catch { return }
            guard !Task.isCancelled else { return }
            completion(value.id)
        }
    }
    func hide() {
        completionTask?.cancel()
        completionTask = nil
        panel.orderOut(nil)
        panel.contentView = nil
    }
}
