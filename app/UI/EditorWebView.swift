// EditorWebView.swift - SwiftUI host for the shared editor web view. The WKWebView outlives any one SwiftUI view (it keeps
// its page, undo state and readiness while the user looks at the weekly review), so the representable only parents it
// into a plain container and hands it back on teardown.
import SwiftUI
import WebKit

final class EditorContainerView: NSView {
    let bridge: EditorBridge
    init(bridge: EditorBridge) {
        self.bridge = bridge
        super.init(frame: .zero)
        attach()
    }
    required init?(coder: NSCoder) { fatalError("not used") }

    func attach() {
        let w = bridge.webView
        guard w.superview !== self else { return }
        w.removeFromSuperview()
        w.translatesAutoresizingMaskIntoConstraints = false
        addSubview(w)
        NSLayoutConstraint.activate([
            w.leadingAnchor.constraint(equalTo: leadingAnchor), w.trailingAnchor.constraint(equalTo: trailingAnchor),
            w.topAnchor.constraint(equalTo: topAnchor), w.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    func detach() { if bridge.webView.superview === self { bridge.webView.removeFromSuperview() } }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let w = window else { return }
        bridge.pushTheme()                                   // the appearance may have changed while the view was away
        if bridge.pendingFocus { bridge.pendingFocus = false; w.makeFirstResponder(bridge.webView) }
    }
}

struct EditorWebView: NSViewRepresentable {
    let bridge: EditorBridge
    func makeNSView(context: Context) -> EditorContainerView { EditorContainerView(bridge: bridge) }
    func updateNSView(_ view: EditorContainerView, context: Context) { view.attach() }
    static func dismantleNSView(_ view: EditorContainerView, coordinator: ()) { view.detach() }
}
