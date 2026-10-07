// SettingsWindow.swift - the Settings window: an AppKit window (title follows the pane, toolbar tabs with icons and labels)
// hosting SettingsView. Every route to Settings ends in SettingsWindowController.show, via AppModel.openSettings(pane:).
//
// Why an AppKit window and not a SwiftUI `Settings`/`Window` scene: the harness (and any test) can open and inspect exactly
// the window the app uses, the window can never appear at launch (a secondary `Window` scene may), and the toolbar tabs are
// the real system ones. The scene opens nothing, so ⌘, and the sidebar gear are the only ways in, and both are ours.
import SwiftUI
import AppKit

/// Which pane is showing. Remembered in the model's defaults, so Settings reopens where it was.
/// `pane` announces itself to SwiftUI before it changes and tells the window after: the window resize runs a nested
/// event loop, which must see the new pane (a `@Published` sink fires before the value is stored and left the content
/// one pane behind).
final class SettingsNav: ObservableObject {
    static let paneKey = "dailylog.settingsPane"
    var onChange: ((SettingsPane) -> Void)?
    var pane: SettingsPane = .general {
        willSet { objectWillChange.send() }
        didSet { onChange?(pane) }
    }

    func restore(from defaults: UserDefaults) {
        pane = defaults.string(forKey: SettingsNav.paneKey).flatMap(SettingsPane.init(rawValue:)) ?? .general
    }
}

/// Left and right arrows change pane when nothing is being typed (UX_FLOWS 5.1: "Settings: ←→ change pane").
final class SettingsWindow: NSWindow {
    var stepPane: ((Int) -> Void)?
    override func keyDown(with event: NSEvent) {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask).subtracting([.numericPad, .function])
        if modifiers.isEmpty, !(firstResponder is NSText), let step = stepPane {
            if event.keyCode == 123 { step(-1); return }      // left arrow
            if event.keyCode == 124 { step(1); return }       // right arrow
        }
        super.keyDown(with: event)
    }
}

final class SettingsWindowController: NSObject, NSWindowDelegate, NSToolbarDelegate {
    static let shared = SettingsWindowController()
    static let windowID = "settings"

    let nav = SettingsNav()
    private(set) var window: SettingsWindow?
    private(set) weak var model: AppModel?
    private var host: NSHostingView<SettingsView>?

    /// Opens the window in front, on `pane` (nil = the last one). Reuses the one window; never opens a second.
    func show(model m: AppModel, pane: SettingsPane?) {
        let changedModel = model !== m
        model = m
        if changedModel && pane == nil { nav.restore(from: m.defaults) }
        if window == nil { makeWindow(model: m) }
        else if changedModel { host?.rootView = SettingsView(model: m, nav: nav) }
        if let p = pane { nav.pane = p }
        paneChanged(nav.pane)                       // title, tab and size are right even when the pane did not change
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    /// Builds the window without showing it, so the first open only has to show it (idle time after launch).
    func prewarm(model m: AppModel) {
        guard window == nil else { return }
        model = m
        nav.restore(from: m.defaults)
        makeWindow(model: m)
        window?.contentView?.layoutSubtreeIfNeeded()
    }

    /// For callers that still send `showSettingsWindow:`.
    func showCurrent() { show(model: model ?? AppModel.shared, pane: nil) }

    // MARK: window
    private func makeWindow(model m: AppModel) {
        // Title and close only: Settings windows have no minimise or zoom (HIG).
        let w = SettingsWindow(contentRect: NSRect(x: 0, y: 0, width: SettingsTheme.width, height: fitted(nav.pane.contentHeight)),
                               styleMask: [.titled, .closable], backing: .buffered, defer: false)
        w.identifier = NSUserInterfaceItemIdentifier(SettingsWindowController.windowID)
        w.isReleasedWhenClosed = false
        w.title = nav.pane.title
        w.toolbarStyle = .preference
        w.toolbar = makeToolbar()
        w.delegate = self
        w.stepPane = { [weak self] d in self?.step(d) }
        let h = NSHostingView(rootView: SettingsView(model: m, nav: nav))
        h.sizingOptions = []                              // the window is sized per pane here, not by the view's minimum size
        w.contentView = h
        host = h; window = w
        w.center()
        w.setFrameAutosaveName("GloamlogSettings")      // remembers where it was last put
        nav.onChange = { [weak self] p in self?.paneChanged(p) }
    }

    private func paneChanged(_ p: SettingsPane) {
        guard let w = window else { return }
        w.title = p.title
        w.toolbar?.selectedItemIdentifier = NSToolbarItem.Identifier(p.rawValue)
        model?.defaults.set(p.rawValue, forKey: SettingsNav.paneKey)
        resize(to: p, animated: w.isVisible)
    }

    /// Taller panes never exceed the screen; the form scrolls instead.
    private func fitted(_ h: CGFloat) -> CGFloat {
        let screenH = (window?.screen ?? NSScreen.main)?.visibleFrame.height ?? 800
        return min(h, SettingsTheme.heightCap, screenH - 140)
    }

    /// Resizes to the pane's height with the top edge fixed; instant when Reduce Motion is on.
    private func resize(to p: SettingsPane, animated: Bool) {
        guard let w = window else { return }
        let size = NSSize(width: SettingsTheme.width, height: fitted(p.contentHeight))
        guard w.contentRect(forFrameRect: w.frame).size != size else { return }
        var frame = w.frameRect(forContentRect: NSRect(origin: .zero, size: size))
        frame.origin = NSPoint(x: w.frame.minX, y: w.frame.maxY - frame.height)
        w.setFrame(frame, display: true, animate: animated && !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
    }

    private func step(_ d: Int) {
        let all = SettingsPane.allCases
        guard let i = all.firstIndex(of: nav.pane), all.indices.contains(i + d) else { return }
        nav.pane = all[i + d]
    }

    // MARK: toolbar tabs
    private func makeToolbar() -> NSToolbar {
        let t = NSToolbar(identifier: "GloamlogSettings")
        t.delegate = self
        t.allowsUserCustomization = false
        t.displayMode = .iconAndLabel
        t.selectedItemIdentifier = NSToolbarItem.Identifier(nav.pane.rawValue)
        return t
    }
    private var ids: [NSToolbarItem.Identifier] { SettingsPane.allCases.map { NSToolbarItem.Identifier($0.rawValue) } }
    func toolbarAllowedItemIdentifiers(_ t: NSToolbar) -> [NSToolbarItem.Identifier] { ids }
    func toolbarDefaultItemIdentifiers(_ t: NSToolbar) -> [NSToolbarItem.Identifier] { ids }
    func toolbarSelectableItemIdentifiers(_ t: NSToolbar) -> [NSToolbarItem.Identifier] { ids }
    func toolbar(_ t: NSToolbar, itemForItemIdentifier id: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        guard let p = SettingsPane(rawValue: id.rawValue) else { return nil }
        let item = NSToolbarItem(itemIdentifier: id)
        item.label = p.title; item.paletteLabel = p.title; item.toolTip = p.title
        item.image = NSImage(systemSymbolName: p.symbol, accessibilityDescription: p.title)
        item.target = self; item.action = #selector(pick(_:))
        return item
    }
    @objc private func pick(_ sender: NSToolbarItem) {
        if let p = SettingsPane(rawValue: sender.itemIdentifier.rawValue) { nav.pane = p }
    }
}

extension NSApplication {
    /// The selectors the system Settings scene answered to. Anything that still sends them reaches our window.
    @objc func showSettingsWindow(_ sender: Any?) { SettingsWindowController.shared.showCurrent() }
    @objc func showPreferencesWindow(_ sender: Any?) { SettingsWindowController.shared.showCurrent() }
}

/// ⌘, and "Settings…" in the Gloamlog menu.
struct SettingsCommands: Commands {
    @ObservedObject var model: AppModel
    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") { model.openSettings() }.keyboardShortcut(",")
        }
    }
}
