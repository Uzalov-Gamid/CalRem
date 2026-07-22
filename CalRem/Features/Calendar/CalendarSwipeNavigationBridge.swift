import AppKit
import SwiftUI

struct CalendarSwipeNavigationBridge: NSViewRepresentable {
    var isEnabled: Bool
    let onNavigate: (Int) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(isEnabled: isEnabled, onNavigate: onNavigate)
    }

    func makeNSView(context: Context) -> NSView {
        context.coordinator.installMonitor()
        return NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.isEnabled = isEnabled
        context.coordinator.onNavigate = onNavigate
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.removeMonitor()
    }

    final class Coordinator {
        var isEnabled: Bool
        var onNavigate: (Int) -> Void
        private var monitor: Any?
        private var lastNavigationDate = Date.distantPast

        init(isEnabled: Bool, onNavigate: @escaping (Int) -> Void) {
            self.isEnabled = isEnabled
            self.onNavigate = onNavigate
        }

        func installMonitor() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.handle(event)
                return event
            }
        }

        func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
            monitor = nil
        }

        private func handle(_ event: NSEvent) {
            guard isEnabled else { return }

            let horizontal = event.scrollingDeltaX
            let vertical = event.scrollingDeltaY
            guard abs(horizontal) > max(22, abs(vertical) * 1.35) else { return }

            let now = Date()
            guard now.timeIntervalSince(lastNavigationDate) > 0.36 else { return }
            lastNavigationDate = now

            onNavigate(horizontal > 0 ? 1 : -1)
        }
    }
}
