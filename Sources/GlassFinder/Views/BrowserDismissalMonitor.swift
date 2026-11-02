import SwiftUI
import AppKit

/// Marks the native folder hit surface so dismissal never races a folder's own mouseDown.
protocol FolderInteractionRegion: AnyObject {}

@MainActor
struct BrowserDismissalMonitor: NSViewRepresentable {
    var dismiss: () -> Void
    func makeNSView(context: Context) -> MonitorView { MonitorView() }
    func updateNSView(_ view: MonitorView, context: Context) { view.dismiss = dismiss }
    static func dismantleNSView(_ view: MonitorView, coordinator: ()) { view.stop() }

    final class MonitorView: NSView {
        var dismiss: (() -> Void)?
        private var monitor: Any?
        private var observers: [NSObjectProtocol] = []
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stop()
            guard let window else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self, weak window] event in
                guard let self, let window else { return event }
                if event.window === window, let content = window.contentView {
                    let point = content.superview?.convert(event.locationInWindow, from: nil) ?? event.locationInWindow
                    var hit = content.hitTest(point)
                    while let view = hit {
                        if view is FolderInteractionRegion { return event }
                        hit = view.superview
                    }
                }
                self.dismiss?()
                return event // Observe only: preserve clicks, native double-click timing and drag sessions.
            }
            let center = NotificationCenter.default
            for name in [NSWindow.didResignKeyNotification, NSWindow.willCloseNotification] {
                observers.append(center.addObserver(forName: name, object: window, queue: .main) { [weak self] _ in
                    Task { @MainActor in
                        self?.dismiss?()
                        if name == NSWindow.willCloseNotification { self?.stop() }
                    }
                })
            }
        }
        func stop() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
            for observer in observers { NotificationCenter.default.removeObserver(observer) }
            observers.removeAll()
        }
    }
}
