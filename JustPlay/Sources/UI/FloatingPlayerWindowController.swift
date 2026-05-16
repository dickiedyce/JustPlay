import AppKit
import SwiftUI

final class FloatingPlayerWindowController: NSObject, NSWindowDelegate {
    static let shared = FloatingPlayerWindowController()

    private var windows: [NSWindow] = []
    private var currentOpacity: Double = 1.0
    private var isFloating = false

    private override init() {
        super.init()
    }

    func show(model: AppModel) {
        let contentView = NSHostingView(rootView: FloatingPlayerView(model: model))
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 140),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = ""
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        if let front = NSApp.keyWindow {
            let origin = NSPoint(x: front.frame.origin.x + 24, y: front.frame.origin.y - 24)
            window.setFrameOrigin(origin)
        } else {
            window.center()
        }
        window.contentView = contentView
        window.isReleasedWhenClosed = true
        window.delegate = self
        window.level = isFloating ? .floating : .normal
        window.alphaValue = currentOpacity
        window.makeKeyAndOrderFront(nil)

        windows.append(window)
    }

    func hide() {
        windows.forEach { $0.orderOut(nil) }
        windows.removeAll()
    }

    func toggle(model: AppModel) {
        if windows.isEmpty {
            show(model: model)
        } else {
            hide()
        }
    }

    func setFloating(_ enabled: Bool) {
        isFloating = enabled
        windows.forEach { $0.level = enabled ? .floating : .normal }
    }

    func setOpacity(_ value: Double) {
        currentOpacity = max(0.35, min(1.0, value))
        windows.forEach { $0.alphaValue = currentOpacity }
    }

    func windowWillClose(_ notification: Notification) {
        guard let closedWindow = notification.object as? NSWindow else { return }
        windows.removeAll { $0 == closedWindow }
    }
}
