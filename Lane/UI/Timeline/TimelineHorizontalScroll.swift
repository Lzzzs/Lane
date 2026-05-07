import SwiftUI
import AppKit

/// Custom NSScrollView wrapper for the timeline canvas. Two reasons to roll
/// our own here instead of using SwiftUI's ScrollView:
/// - Damps trackpad horizontal scroll by a constant factor so panning across
///   the year-wide canvas feels deliberate, not whiplash-fast.
/// - Exposes content offset bidirectionally so cursor-anchored zoom can
///   adjust scroll position to keep the date under the cursor stable.
struct TimelineHorizontalScroll<Content: View>: NSViewRepresentable {
    @Binding var offsetX: CGFloat
    let contentWidth: CGFloat
    let scrollFactor: CGFloat
    @ViewBuilder var content: () -> Content

    init(offsetX: Binding<CGFloat>,
         contentWidth: CGFloat,
         scrollFactor: CGFloat = 0.5,
         @ViewBuilder content: @escaping () -> Content) {
        self._offsetX = offsetX
        self.contentWidth = contentWidth
        self.scrollFactor = scrollFactor
        self.content = content
    }

    func makeNSView(context: Context) -> DampedScrollView {
        let scroll = DampedScrollView()
        scroll.scrollFactor = scrollFactor
        scroll.hasHorizontalScroller = false
        scroll.hasVerticalScroller = false
        scroll.borderType = .noBorder
        scroll.drawsBackground = false
        scroll.horizontalScrollElasticity = .allowed
        scroll.verticalScrollElasticity = .none

        let host = NSHostingView(rootView: content())
        host.translatesAutoresizingMaskIntoConstraints = true
        host.frame = NSRect(x: 0, y: 0, width: contentWidth, height: 1)
        scroll.documentView = host

        scroll.onScrollChanged = { x in
            if abs(x - offsetX) > 0.5 {
                Task { @MainActor in offsetX = x }
            }
        }
        return scroll
    }

    func updateNSView(_ scroll: DampedScrollView, context: Context) {
        scroll.scrollFactor = scrollFactor
        guard let host = scroll.documentView as? NSHostingView<Content> else { return }
        host.rootView = content()
        var frame = host.frame
        if abs(frame.size.width - contentWidth) > 0.5 || frame.size.height < 1 {
            frame.size.width = contentWidth
            frame.size.height = max(scroll.contentSize.height,
                                    host.intrinsicContentSize.height,
                                    host.fittingSize.height)
            host.frame = frame
        }

        // Programmatic scroll-offset application (e.g. cursor-anchored zoom).
        let current = scroll.contentView.bounds.origin.x
        if abs(current - offsetX) > 0.5 {
            scroll.contentView.scroll(to: NSPoint(x: offsetX, y: 0))
            scroll.reflectScrolledClipView(scroll.contentView)
        }
    }
}

/// NSScrollView that scales horizontal trackpad scroll deltas by `scrollFactor`
/// (1.0 = unchanged) and reports its content offset on every scroll.
final class DampedScrollView: NSScrollView {
    var scrollFactor: CGFloat = 0.5
    var onScrollChanged: ((CGFloat) -> Void)?

    override init(frame: NSRect) {
        super.init(frame: frame)
        contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self, selector: #selector(boundsChanged),
            name: NSView.boundsDidChangeNotification, object: contentView)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            self, selector: #selector(boundsChanged),
            name: NSView.boundsDidChangeNotification, object: contentView)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func boundsChanged() {
        onScrollChanged?(contentView.bounds.origin.x)
    }

    override func scrollWheel(with event: NSEvent) {
        // Only horizontal events get damped — let vertical scroll bubble up
        // unchanged so the outer SwiftUI scroll keeps its normal feel.
        if abs(event.deltaX) > abs(event.deltaY) {
            let scaled = scaledHorizontalEvent(event)
            super.scrollWheel(with: scaled)
        } else {
            // Pass vertical events to the next responder (outer SwiftUI scroll).
            nextResponder?.scrollWheel(with: event)
        }
    }

    private func scaledHorizontalEvent(_ event: NSEvent) -> NSEvent {
        if let cg = event.cgEvent?.copy() {
            let dx = event.scrollingDeltaX * scrollFactor
            cg.setDoubleValueField(.scrollWheelEventPointDeltaAxis2, value: Double(dx))
            cg.setDoubleValueField(.scrollWheelEventDeltaAxis2, value: Double(dx))
            if let ns = NSEvent(cgEvent: cg) {
                return ns
            }
        }
        return event
    }
}
