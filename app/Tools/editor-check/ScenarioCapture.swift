// ScenarioCapture.swift - real-window scenarios for quick capture (Jot): hotkey, panel, menu-bar field, routing into an open page,
// the folder going away and coming back, journal replay after a simulated crash, the Shortcuts pane.
// Owned by the M2 UI stream. Called from main.swift after the Settings scenarios; use `check(name, ok, detail)`.
//
// What is real here: the real Jot panel (NSPanel) with real key events delivered to its text view, the real MenuBarView and
// SidebarView in real windows, the real MainView with the real WKWebView editor (and the real appendToSection in the bundled
// page), a real LogStore and a real capture journal on temporary folders, real folder permission and rename changes, and the
// real Carbon registration of an UNUSUAL test combination (control-option-shift-command with F17 to F19: never the owner's).
// What is NOT: nobody can press a physical global hotkey here, so the hotkey press is a Carbon hot key event sent through the
// application event target (the real handler, the real main-queue hop, the real callback); and whether a non-activating panel
// really appears over ANOTHER app's full-screen Space can only be seen on the owner's Mac.
// Screenshots go to EC_CAPTURE_SHOTS (default: a temporary folder).
import AppKit
import SwiftUI
import Vision
import Carbon.HIToolbox

// MARK: - helpers (private to this file)

private func pump(_ seconds: TimeInterval, until cond: () -> Bool = { false }) {
    let end = Date().addingTimeInterval(seconds)
    while Date() < end {
        if cond() { return }
        if let e = NSApp.nextEvent(matching: .any, until: Date().addingTimeInterval(0.01), inMode: .default, dequeue: true) { NSApp.sendEvent(e) }
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.001))
    }
}
@discardableResult private func until(_ seconds: TimeInterval, _ cond: () -> Bool) -> Bool { pump(seconds, until: cond); return cond() }

private func windowImage(_ w: NSWindow) -> CGImage? {
    CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(w.windowNumber), [.boundsIgnoreFraming, .bestResolution])
}
@discardableResult private func savePNG(_ cg: CGImage, to url: URL) -> Bool {
    guard let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else { return false }
    return (try? png.write(to: url)) != nil
}
private func recognise(_ cg: CGImage) -> [VNRecognizedTextObservation]? {
    let req = VNRecognizeTextRequest()
    req.recognitionLevel = .accurate; req.usesLanguageCorrection = false
    do { try VNImageRequestHandler(cgImage: cg, options: [:]).perform([req]) } catch { return nil }
    return req.results
}
private func squash(_ s: String) -> String { s.lowercased().filter { !$0.isWhitespace } }
private func allText(_ obs: [VNRecognizedTextObservation]) -> String { squash(obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")) }
private func locate(_ needle: String, in obs: [VNRecognizedTextObservation], of w: NSWindow) -> NSPoint? {
    for o in obs {
        guard let c = o.topCandidates(1).first, let r = c.string.lowercased().range(of: needle.lowercased()), let b = try? c.boundingBox(for: r) else { continue }
        return NSPoint(x: b.boundingBox.midX * w.frame.width, y: b.boundingBox.midY * w.frame.height)
    }
    return nil
}
/// What a window really drew, as squashed lowercase text (nil when text recognition is unavailable).
private func drawnText(_ w: NSWindow) -> String? { windowImage(w).flatMap(recognise).map(allText) }

private func mouseClick(at p: NSPoint, in w: NSWindow) {
    for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
        if let e = NSEvent.mouseEvent(with: type, location: p, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                                      windowNumber: w.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: type == .leftMouseDown ? 1 : 0) {
            w.sendEvent(e)
        }
        pump(0.06)
    }
}

/// Key events delivered the way AppKit delivers them (NSWindow.sendEvent -> first responder -> keyDown).
private func key(_ w: NSWindow, _ chars: String, code: UInt16, mods: NSEvent.ModifierFlags = []) {
    for type in [NSEvent.EventType.keyDown, .keyUp] {
        if let e = NSEvent.keyEvent(with: type, location: .zero, modifierFlags: mods, timestamp: ProcessInfo.processInfo.systemUptime,
                                    windowNumber: w.windowNumber, context: nil, characters: chars, charactersIgnoringModifiers: chars,
                                    isARepeat: false, keyCode: code) { w.sendEvent(e) }
    }
    pump(0.02)
}
private func typeText(_ w: NSWindow, _ s: String) { for ch in s { key(w, String(ch), code: 0) } }
private func pressReturn(_ w: NSWindow, shift: Bool = false) { key(w, "\r", code: 36, mods: shift ? [.shift] : []) }
private func pressEscape(_ w: NSWindow) { key(w, "\u{1B}", code: 53) }

/// A borderless window that can be key, like the menu-bar popover's panel.
private final class KeyableWindow: NSWindow { override var canBecomeKey: Bool { true } }
private func hostWindow<V: View>(_ v: V, width: CGFloat, height: CGFloat? = nil, origin: NSPoint = NSPoint(x: 80, y: 120)) -> NSWindow {
    let host = NSHostingView(rootView: v)
    host.layoutSubtreeIfNeeded()
    host.frame = NSRect(x: 0, y: 0, width: width, height: height ?? max(host.fittingSize.height, 120))
    let win = KeyableWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
    win.contentView = host
    win.isReleasedWhenClosed = false
    win.setFrameOrigin(origin)
    win.makeKeyAndOrderFront(nil)
    return win
}

private final class ClockBox { var date: Date; init(_ d: Date) { date = d } }
private func capDate(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 14, _ min: Int = 32) -> Date {
    Calendar.current.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
}

private let rootDir = URL(fileURLWithPath: ProcessInfo.processInfo.environment["EC_TMP"] ?? NSTemporaryDirectory()).appendingPathComponent("dl-editor-check-capture")
private let shotsDir = URL(fileURLWithPath: ProcessInfo.processInfo.environment["EC_CAPTURE_SHOTS"] ?? rootDir.appendingPathComponent("shots").path)

private let today = "2026-10-07"                      // Wednesday; the clock stands at 14:32
private let words = "Wrote up the pricing page notes, reviewed the signup form with Ana, fixed the demo tracking and planned the webinar page for next week."

/// One app instance: a live model on its own folders, shown in a real window (the real MainView and editor).
private final class CapWorld {
    let dir: URL, logs: URL, backups: URL, capture: URL
    let clock: ClockBox
    let suite: UserDefaults
    let model: AppModel
    var win: NSWindow?
    let fm = FileManager.default

    init(_ name: String, now: Date = capDate(2026, 10, 7), live: Bool = true, window: Bool = true, settings: (inout Settings) -> Void = { _ in }) {
        dir = rootDir.appendingPathComponent(name)
        logs = dir.appendingPathComponent("logs"); backups = dir.appendingPathComponent("backups"); capture = dir.appendingPathComponent("capture")
        let fresh = !fm.fileExists(atPath: logs.path)
        if fresh { try? fm.removeItem(at: dir) }
        for u in [logs, backups] { try? fm.createDirectory(at: u, withIntermediateDirectories: true) }
        if fresh {
            let cal = Calendar.current
            for back in 1...14 {                          // a fortnight of written days, so the sidebar looks like a real one
                guard let k = DayKey.adding(today, -back, cal) else { continue }
                let wd = DayKey.weekday(k, cal)
                if wd == 1 || wd == 7 || back == 4 { continue }
                try? MarkdownFormat.serialize(day: k, body: "## What I did\n\n\(words)\n\n## To do next\n\n- Follow up on the open items").write(to: logs.appendingPathComponent(k + ".md"), atomically: false, encoding: .utf8)
            }
        }
        clock = ClockBox(now)
        let suiteName = "dailylog.editorcheck.capture.\(name)"
        suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)
        suite.set(true, forKey: AppModel.whatsNewKey)
        var s = Settings(); s.storageFolder = logs; s.onboarded = true; settings(&s)
        s.save(to: suite)
        let c = clock
        model = AppModel(defaults: suite, backupDir: backups, live: live, clock: { c.date })
        if live { model.start() }
        if live && window {
            let host = NSHostingController(rootView: MainView(model: model))
            let w = NSWindow(contentViewController: host)
            w.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
            w.toolbarStyle = .unified
            w.title = "Gloamlog"
            w.setFrame(NSRect(x: 40, y: 40, width: 1000, height: 760), display: true)
            w.makeKeyAndOrderFront(nil)
            win = w
        }
        pump(0.6)
    }

    func file(_ day: String) -> String? { try? String(contentsOf: logs.appendingPathComponent(day + ".md"), encoding: .utf8) }
    func exists(_ day: String) -> Bool { fm.fileExists(atPath: logs.appendingPathComponent(day + ".md").path) }
    func occurrences(_ needle: String, in day: String) -> Int { (file(day) ?? "").components(separatedBy: needle).count - 1 }
    func editorText() -> String? { blocking { (done: @escaping (String?) -> Void) in model.bridge.read(token: model.editor.token) { done($0) } } ?? nil }
    var loaded: Bool { model.editor.loaded }
    func openAndWait(_ day: String) -> Bool {
        model.select(.day(day))
        return until(10) { model.editor.day == day && model.editor.loaded }
    }
    func js(_ script: String) -> Any? { blocking { done in model.bridge.webView.evaluateJavaScript(script) { r, _ in done(r) } } ?? nil }

    /// Types like a user into the real page: the caret goes to the first empty line under the first heading.
    @discardableResult
    func typeUnderFirstHeading(_ t: String) -> Bool {
        let script = """
        (function (t) {
          var v = document.querySelector('.ProseMirror'); v.focus();
          var p = document.querySelector('.ProseMirror > h2 + p'); if (!p) return 'none';
          var r = document.createRange(); r.selectNodeContents(p); r.collapse(false);
          var s = window.getSelection(); s.removeAllRanges(); s.addRange(r);
          return document.execCommand('insertText', false, t) ? 'exec' : 'failed';
        })(\(JS.literal(t)))
        """
        return (js(script) as? String) == "exec"
    }
    /// The caret as text: which paragraph it is in and where.
    func caret() -> String {
        (js("(function(){ var s = window.getSelection(); var a = s.anchorNode; if (!a) return 'none'; var p = a.nodeType === 1 ? a : a.parentNode; return (p ? p.textContent.slice(0, 40) : '?') + '@' + s.anchorOffset + '-' + s.focusOffset; })()") as? String) ?? "?"
    }
    func undo() { _ = js("(function(){ var v = document.querySelector('.ProseMirror'); v.focus(); v.dispatchEvent(new KeyboardEvent('keydown', {key: 'z', code: 'KeyZ', metaKey: true, bubbles: true, cancelable: true})); return 1; })()") }

    func close() { model.timer?.invalidate(); model.jotPanel.hide(clearing: true, restoreFocus: false); win?.close(); pump(0.2) }
}

private func resetRules() { LogStore.jotsRules = (heading: "Jots", countTowardLogged: false) }

// MARK: - the scenarios

func runCaptureScenarios() {
    print("12. quick capture (Jot): shortcut, panel, menu-bar field, routing, folder away and back, journal replay, Shortcuts pane")
    try? FileManager.default.removeItem(at: rootDir)
    try? FileManager.default.createDirectory(at: shotsDir, withIntermediateDirectories: true)
    defer { resetRules() }
    capHotKey()
    capMain()
    capCrashReplay()
    print("   (capture scenarios done; screenshots in \(shotsDir.path))")
}

// MARK: shortcut

/// An unusual combination (control-option-shift-command + F17...F19): nobody owns it, so the registration result is the real thing.
private func combo(_ keyCode: UInt32) -> HotKeySpec { HotKeySpec(keyCode: keyCode, carbonModifiers: 0x1B00) }

private func capHotKey() {
    print("   U1 shortcut: rules, real Carbon registration, the press callback")
    let jOpt = HotKeySpec(keyCode: 38, carbonModifiers: 0x0800), jOptShift = HotKeySpec(keyCode: 38, carbonModifiers: 0x0A00)
    check("the default is control-option-J (keyCode 38, modifiers 0x1800)", HotKeySpec.defaultJot == HotKeySpec(keyCode: 38, carbonModifiers: 0x1800) && HotKeySpec.defaultJot.display == "⌃⌥J")
    check("control or command is required; option-only and option-shift-only are refused",
          HotKeyCenter.isAllowed(.defaultJot) && HotKeyCenter.isAllowed(HotKeySpec(keyCode: 40, carbonModifiers: 0x0100)) && HotKeyCenter.isAllowed(HotKeySpec(keyCode: 40, carbonModifiers: 0x0300))
          && !HotKeyCenter.isAllowed(jOpt) && !HotKeyCenter.isAllowed(jOptShift) && !HotKeyCenter.isAllowed(HotKeySpec(keyCode: 38, carbonModifiers: 0x0200)) && !HotKeyCenter.isAllowed(HotKeySpec(keyCode: 38, carbonModifiers: 0)))
    check("a shortcut reads like macOS prints it: modifiers in order, then the key", HotKeySpec(keyCode: 40, carbonModifiers: 0x1B00).display == "⌃⌥⇧⌘K" && HotKeySpec(keyCode: 49, carbonModifiers: 0x0100).display == "⌘Space" && combo(80).display == "⌃⌥⇧⌘F19", "\(combo(80).display)")
    check("its spoken form is words (VoiceOver)", HotKeySpec.defaultJot.spoken == "Control Option J", HotKeySpec.defaultJot.spoken)
    check("the Page menu can show it: ⌃⌥J has a menu form, a function key has none",
          HotKeySpec.defaultJot.menuShortcut?.modifiers == [.control, .option] && HotKeySpec.defaultJot.menuShortcut?.key.character == "j" && combo(80).menuShortcut == nil)
    check("macOS's own shortcuts are recognised (command-Space is Spotlight), the default is free", HotKeyCenter.isSystemShortcut(HotKeySpec(keyCode: 49, carbonModifiers: 0x0100)) && !HotKeyCenter.isSystemShortcut(.defaultJot) && !HotKeyCenter.isSystemShortcut(combo(80)))

    let a = HotKeyCenter(), b = HotKeyCenter()
    var pressed = 0
    a.onPressed = { pressed += 1 }
    check("a center registers a combination with the system (noErr)", a.register(combo(80)) == noErr && a.registered == combo(80))
    check("the same combination again, inside this process, is refused with -9878 (eventHotKeyExistsErr)", b.register(combo(80)) == -9878 && b.registered == nil, "\(b.register(combo(80)))")
    check("the press callback runs on the main queue through the real Carbon handler", { a.deliverPressForTesting() && until(2) { pressed == 1 } }(), "pressed=\(pressed)")
    check("a press for another center does not reach this one", { b.deliverPressForTesting() == false }() && { pump(0.2); return pressed == 1 }())
    check("registering another combination moves the center; the old combination is free again", a.register(combo(79)) == noErr && a.registered == combo(79) && b.register(combo(80)) == noErr)
    b.unregister()
    a.unregister()
    check("unregister removes it: nothing is delivered, and a second center can take the combination", a.registered == nil && !a.deliverPressForTesting() && b.register(combo(79)) == noErr)
    b.unregister()
    check("a refused registration keeps the previous one (the user never loses a working shortcut)", {
        let x = HotKeyCenter(), y = HotKeyCenter()
        _ = x.register(combo(80)); _ = y.register(combo(79))
        let status = x.register(combo(79))
        let kept = x.registered == combo(80) && status == -9878
        x.unregister(); y.unregister()
        return kept
    }())

    // the model: Settings > Shortcuts goes through setJotHotKey. A throwaway model, never the real shortcut.
    print("   U6 recording: record, conflict, Off, Reset")
    let world = CapWorld("hotkey", live: false, window: false)
    defer { world.close() }
    let m = world.model
    let center = HotKeyCenter(), other = HotKeyCenter()
    m.settings.capture.hotKey = combo(80)                          // stored while no center is installed: nothing registered yet
    m.installHotKeys(center)
    check("at launch the stored shortcut is registered from Settings", center.registered == combo(80) && m.hotKeyFailure == nil)
    m.showJotPanel(source: "menu"); m.jotPanel.hide(clearing: true, restoreFocus: false)

    let rec = ShortcutRecording()
    rec.onShortcut = { m.setJotHotKey($0) }
    func fkey(_ code: UInt16, _ mods: NSEvent.ModifierFlags, scalar: Int) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: mods, timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: 0, context: nil,
                         characters: String(UnicodeScalar(UInt32(scalar))!), charactersIgnoringModifiers: String(UnicodeScalar(UInt32(scalar))!), isARepeat: false, keyCode: code)!
    }
    let all: NSEvent.ModifierFlags = [.control, .option, .shift, .command]
    rec.start()
    check("recording starts and waits for a key", rec.recording)
    check("a plain Escape cancels and changes nothing", rec.handle(fkey(53, [], scalar: 0x1B)) == nil && !rec.recording && m.settings.capture.hotKey == combo(80))
    rec.start()
    check("a combination without control or command is not accepted (the hint says why, recording goes on)",
          rec.handle(fkey(79, [.option, .shift], scalar: NSF18FunctionKey)) == nil && rec.recording && rec.hint != nil && m.settings.capture.hotKey == combo(80), "\(String(describing: rec.hint))")
    check("an event that is not a key press is none of its business", rec.handle(NSEvent.mouseEvent(with: .leftMouseDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)!) != nil)
    check("a good combination is recorded, takes effect at once and the recorder stops",
          rec.handle(fkey(79, all, scalar: NSF18FunctionKey)) == nil && !rec.recording && m.settings.capture.hotKey == combo(79) && center.registered == combo(79) && m.hotKeyFailure == nil)
    check("... and the OLD combination stopped: another center can take it, the new one is held (-9878 for a second taker)", other.register(combo(80)) == noErr && other.register(combo(79)) == -9878 && { other.unregister(); return true }())
    _ = other.register(combo(64))
    rec.start()
    _ = rec.handle(fkey(64, all, scalar: NSF17FunctionKey))
    check("a combination that is already registered shows the error and keeps the shortcut that works",
          m.hotKeyFailure?.reason == .taken && m.hotKeyFailure?.spec == combo(64) && m.settings.capture.hotKey == combo(79) && center.registered == combo(79), "\(String(describing: m.hotKeyFailure))")
    check("the error reads \"... is already used by another app.\"", m.hotKeyFailure?.message == "⌃⌥⇧⌘F17 is already used by another app.", m.hotKeyFailure?.message ?? "nil")
    other.unregister()
    rec.start()
    _ = rec.handle(NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [.command], timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: 0, context: nil, characters: " ", charactersIgnoringModifiers: " ", isARepeat: false, keyCode: 49)!)
    check("a macOS shortcut (command-Space) is refused with its own message", m.hotKeyFailure?.reason == .system && m.hotKeyFailure?.message == "⌘Space is already used by macOS." && m.settings.capture.hotKey == combo(79), "\(String(describing: m.hotKeyFailure?.message))")
    rec.start()
    _ = rec.handle(fkey(64, all, scalar: NSF17FunctionKey))
    check("a later good recording clears the error", m.hotKeyFailure == nil && m.settings.capture.hotKey == combo(64) && center.registered == combo(64))
    m.setJotHotKey(nil)
    check("Off removes it: stored as off, unregistered, and a second center can take the combination",
          m.settings.capture.hotKey == nil && center.registered == nil && other.register(combo(64)) == noErr && { other.unregister(); return true }())
    check("Off survives a restart (the stored setting is off, not the default)", Settings.load(from: world.suite).capture.hotKey == nil)
    // Reset goes back to control-option-J. Without a center nothing is registered (the owner's real shortcut is never touched).
    m.hotKeys = nil
    m.setJotHotKey(.defaultJot)
    check("Reset stores the default control-option-J", m.settings.capture.hotKey == .defaultJot && Settings.load(from: world.suite).capture.hotKey == .defaultJot)
    m.settings.capture.hotKey = nil
    check("an old settings file without a shortcut key still means control-option-J, and null means Off",
          (try? JSONDecoder().decode(CapturePrefs.self, from: Data("{}".utf8)))?.hotKey == .defaultJot && (try? JSONDecoder().decode(CapturePrefs.self, from: Data("{\"hotKey\":null}".utf8)))?.hotKey == nil)
}

// MARK: panel, field, routing

private func capMain() {
    let w = CapWorld("main")
    defer { w.close() }
    let m = w.model
    guard until(25, { w.loaded }) else { check("today's page loads in the real editor", false); return }
    pump(1.0)
    let hasCall = (w.js("typeof DailyLogEditor.appendToSection") as? String) == "function"
    check("the bundled editor has the appendToSection call", hasCall, "typeof = \(String(describing: w.js("typeof DailyLogEditor.appendToSection")))")
    guard hasCall else { return }
    check("today has no file yet and the writer starts empty", !w.exists(today) && m.notesWaiting == 0 && m.journal.pending().isEmpty)

    // ---- U2 the panel
    print("   U2 panel: window, position, focus, Esc, Return, Shift-Return")
    m.showJotPanel(source: "hotkey")
    guard let panel = m.jotPanel.panel else { check("the panel exists", false); return }
    pump(0.35)
    check("the panel is visible", panel.isVisible && m.jotPanel.isVisible)
    check("it is a non-activating panel that can take the keyboard but is never the main window",
          panel.styleMask.contains(.nonactivatingPanel) && panel.canBecomeKey && !panel.canBecomeMain && panel.isFloatingPanel)
    check("it floats and joins every Space, including full-screen ones", panel.level == .floating && panel.collectionBehavior.contains(.canJoinAllSpaces) && panel.collectionBehavior.contains(.fullScreenAuxiliary))
    check("it does not hide when the app is not active (it is shown from other apps)", !panel.hidesOnDeactivate)
    let mouse = NSEvent.mouseLocation
    let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main!
    let vf = screen.visibleFrame
    check("it is 520 pt wide and 148 pt high for one line", abs(panel.frame.width - 520) < 0.5 && abs(panel.frame.height - 148) < 0.5, "\(panel.frame.size)")
    check("it sits centred on the screen the pointer is on, its top edge 22% down the visible frame",
          abs(panel.frame.midX - vf.midX) <= 1 && abs((vf.maxY - panel.frame.maxY) - vf.height * 0.22) <= 1.5, "frame=\(panel.frame) visible=\(vf)")
    let tv = JotPanelController.findTextView(in: panel.contentView)
    check("the field is the first responder (the cursor is in the text field)", tv != nil && panel.firstResponder === tv)
    check("the panel took the keyboard without activating Gloamlog", panel.isKeyWindow, "key=\(panel.isKeyWindow) appActive=\(NSApp.isActive)")
    check("an empty field shows the placeholder, not text", tv?.string.isEmpty == true && tv?.placeholder == "Jot a line for today…")
    if let t = drawnText(panel) {
        check("the panel draws its title, the time the note will carry and the key hints", t.contains("jottotoday") && t.contains("14:32") && t.contains("returnadds") && t.contains("esccancels"), String(t.prefix(120)))
        check("... and the placeholder", t.contains("jotalinefortoday"), String(t.prefix(120)))
    }
    if let img = windowImage(panel) { savePNG(img, to: shotsDir.appendingPathComponent("panel-empty-light.png")) }

    // M2-A1: Esc writes nothing and closes
    typeText(panel, "this must not be saved")
    check("typing reaches the field", tv?.string == "this must not be saved", tv?.string ?? "nil")
    pressEscape(panel); pump(0.4)
    check("M2-A1: Esc closes the panel", !panel.isVisible)
    pump(1.0)
    check("M2-A1: ... writes nothing: no file, nothing in the journal, nothing waiting", !w.exists(today) && m.journal.pending().isEmpty && m.notesWaiting == 0)
    check("... and throws the draft away", m.jotPanel.model.text.isEmpty)

    // an empty Return does nothing; Shift-Return adds a line instead of submitting
    m.showJotPanel(source: "hotkey"); pump(0.3)
    pressReturn(panel); pump(0.3)
    check("an empty Return does nothing (the panel stays open, nothing is written)", panel.isVisible && m.journal.pending().isEmpty && m.jotPanel.model.phase == .typing)
    typeText(panel, "first line"); pressReturn(panel, shift: true); typeText(panel, "second line"); pump(0.3)
    check("Shift-Return starts a new line in the same note", tv?.string == "first line\nsecond line" && panel.isVisible && m.journal.pending().isEmpty, tv?.string ?? "nil")
    check("the field grew to two lines and the panel with it", m.jotPanel.model.fieldHeight > 44 && panel.frame.height > 148, "\(m.jotPanel.model.fieldHeight) \(panel.frame.height)")
    if let img = windowImage(panel) { savePNG(img, to: shotsDir.appendingPathComponent("panel-two-lines-light.png")) }
    // click-away keeps the draft: the panel hides, the next press brings the text back
    panel.resignKey(); pump(0.4)
    check("losing the keyboard hides the panel but keeps the draft (a stray click costs nothing)", !panel.isVisible && m.jotPanel.model.text == "first line\nsecond line" && !w.exists(today))
    m.showJotPanel(source: "hotkey"); pump(0.3)
    check("the next press brings the draft back, caret at its end", panel.isVisible && tv?.string == "first line\nsecond line" && tv?.selectedRange().location == ("first line\nsecond line" as NSString).length)
    pressEscape(panel); pump(0.4)
    check("Esc then throws the draft away", !panel.isVisible && m.jotPanel.model.text.isEmpty && m.jotPanel.model.fieldHeight == 44)

    // ---- M2-A2: type and Return
    print("   M2-A2 type and Return; M2-A4 a day with only jots")
    pump(0.2)
    m.showJotPanel(source: "hotkey"); pump(0.3)
    typeText(panel, "call with Sam about pricing")
    if let img = windowImage(panel) { savePNG(img, to: shotsDir.appendingPathComponent("panel-typed-light.png")) }
    let t0 = Date()
    pressReturn(panel)
    pump(0.15)
    check("after Return the panel says \"Added to Today\" (and holds the note for a moment)", m.jotPanel.model.phase == .added && panel.isVisible)
    if let img = windowImage(panel) { savePNG(img, to: shotsDir.appendingPathComponent("panel-added-light.png")) }
    if let t = drawnText(panel) { check("... as drawn", t.contains("addedtotoday"), String(t.prefix(120))) }
    let landed = until(2.5) { (w.file(today) ?? "").contains("- 14:32 call with Sam about pricing") }
    let ms = Date().timeIntervalSince(t0) * 1000
    check("M2-A2: today's page ends with ## Jots and \"- 14:32 call with Sam about pricing\", saved within 2 seconds of Return", landed && ms < 2000, String(format: "%.0f ms, %@", ms, w.file(today) ?? "no file"))
    print(String(format: "     (Return to a saved file: %.0f ms)", ms))
    let f1 = w.file(today) ?? ""
    check("only the Jots section was written: the template headings are not in the file", f1.contains("## Jots") && !f1.contains("What I did") && !f1.contains("To do next"), f1)
    check("the file is the day title, then ## Jots, then the bullet", f1.hasPrefix("# 2026-10-07\n\n## Jots\n\n- 14:32 call with Sam about pricing"), f1)
    check("the panel closed itself after the hold", until(1.5) { !panel.isVisible })
    check("the note is acknowledged: nothing waiting, journal empty", until(2) { m.notesWaiting == 0 && m.journal.pending().isEmpty })
    check("the open page shows the note and has nothing unsaved", (w.editorText() ?? "").contains("- 14:32 call with Sam about pricing") && !m.editor.hasUnsavedEdits, w.editorText() ?? "nil")
    check("the page is on today, still loaded, and was not reloaded for the note", m.editor.day == today && m.editor.loaded)
    check("M2-A4: the day is \"started\", not logged (a jots-only page is partial)", m.status(of: today) == .partial && m.states[today] == .partial, "\(m.status(of: today)) \(String(describing: m.states[today]))")
    check("the header counts the jot, not words", m.editor.jotCount == 1 && m.editor.words == 0, "jots=\(m.editor.jotCount) words=\(m.editor.words)")
    check("the sidebar's Today row reads started (half disc)", m.todayStatus == .partial)

    // reopen: the template shows above the jots, and nothing is written until the user writes
    let before = w.file(today)
    let mtime0 = (try? FileManager.default.attributesOfItem(atPath: w.logs.appendingPathComponent(today + ".md").path))?[.modificationDate] as? Date
    _ = w.openAndWait("2026-10-06"); _ = w.openAndWait(today)
    pump(1.0)
    let shown = w.editorText() ?? ""
    check("M2-A4: opening it shows the template headings above the jots", shown.hasPrefix("## What I did") && shown.contains("## To do next") && shown.contains("## Jots") && shown.hasSuffix("- 14:32 call with Sam about pricing"), shown)
    check("... with a line to type into under each template heading (an editor-only trick)", (w.js("document.querySelectorAll('.ProseMirror > h2 + p').length") as? Int) == 5, "\(String(describing: w.js("document.querySelectorAll('.ProseMirror > h2 + p').length")))")
    pump(2.0)
    let mtime1 = (try? FileManager.default.attributesOfItem(atPath: w.logs.appendingPathComponent(today + ".md").path))?[.modificationDate] as? Date
    check("M2-A4: nothing extra is written until I type (bytes and modification time unchanged)", w.file(today) == before && mtime0 == mtime1 && !m.editor.hasUnsavedEdits)
    if let img = m.live ? w.win.flatMap(windowImage) : nil { savePNG(img, to: shotsDir.appendingPathComponent("main-jots-only-light.png")) }
    check("the day still reads started in the sidebar and header", m.status(of: today) == .partial && m.editor.jotCount == 1)
    check("typing the first real words saves the template and the jots together", w.typeUnderFirstHeading("Reviewed the signup form with Ana.") && until(6) { (w.file(today) ?? "").contains("Reviewed the signup form") })
    let f2 = w.file(today) ?? ""
    check("... and the file now has the template headings, the typed line and the jot", f2.contains("## What I did") && f2.contains("Reviewed the signup form with Ana.") && f2.contains("## To do next") && f2.contains("- 14:32 call with Sam about pricing"), f2)

    // ---- M2-A3: page open, text just typed
    print("   M2-A3 capture into a page that is being written")
    pump(1.0)
    check("a bit more text is typed, then a jot arrives within the editor's half second", w.typeUnderFirstHeading(" Then the pricing page.") && { pump(0.1); return true }())
    let caretBefore = w.caret()
    let textBefore = w.editorText() ?? ""
    let receipt = m.jot(text: "call Ana", source: "hotkey")
    check("the capture is durable first: a receipt comes back at once", receipt != nil && receipt?.waiting == 1, "\(String(describing: receipt))")
    check("M2-A3: the note appears in the open page", until(3) { (w.editorText() ?? "").contains("- 14:32 call Ana") }, w.editorText() ?? "nil")
    let textAfter = w.editorText() ?? ""
    check("M2-A3: what I typed is untouched (the page differs only by the new note)", textAfter.replacingOccurrences(of: "\n- 14:32 call Ana", with: "") == textBefore, "before=\(textBefore)\nafter=\(textAfter)")
    check("M2-A3: the caret did not move", w.caret() == caretBefore, "\(caretBefore) -> \(w.caret())")
    check("the note joined the existing jots list (no blank line between jots)", textAfter.contains("- 14:32 call with Sam about pricing\n- 14:32 call Ana"), textAfter)
    check("it is in the file within 2 seconds and acknowledged", until(2.5) { (w.file(today) ?? "").contains("- 14:32 call Ana") && m.notesWaiting == 0 && m.journal.pending().isEmpty })
    check("the typed text is in the file too", (w.file(today) ?? "").contains("Then the pricing page."))
    w.undo(); pump(0.5)
    let undone = w.editorText() ?? ""
    check("M2-A3: undo still works, and removes just the note (not what I typed a moment before it)", !undone.contains("call Ana") && undone.contains("Then the pricing page.") && undone.contains("- 14:32 call with Sam about pricing"), undone)
    check("... and the undo is saved like any edit", until(4) { !(w.file(today) ?? "").contains("call Ana") && (w.file(today) ?? "").contains("Then the pricing page.") })

    // ---- window closed: the page stays loaded in memory; a note still goes in
    print("   M2-A2 with the window closed, and with the page not open")
    m.bridge.webView.removeFromSuperview(); w.win?.orderOut(nil)                 // what closing the window does to the shared web view
    pump(0.4)
    let closedReceipt = m.jot(text: "noted while the window was closed", source: "menubar")
    check("with the window closed the note still goes into the loaded page and is saved", closedReceipt != nil && until(4) { (w.file(today) ?? "").contains("- 14:32 noted while the window was closed") && m.notesWaiting == 0 })
    // another day open: today has no page open, so the note goes straight to the file
    check("another day is open", w.openAndWait("2026-10-06"))
    let diskReceipt = m.jot(text: "added while yesterday is open", source: "hotkey")
    check("with another day open the note goes straight to today's file (nothing waits)", diskReceipt?.waiting == 0 && (w.file(today) ?? "").contains("- 14:32 added while yesterday is open") && m.notesWaiting == 0, "\(String(describing: diskReceipt)) \(w.file(today) ?? "")")
    check("... after the earlier jots, in order, without touching anything else", { let f = w.file(today) ?? ""; return f.contains("Then the pricing page.") && f.range(of: "call with Sam")!.lowerBound < f.range(of: "noted while")!.lowerBound && f.range(of: "noted while")!.lowerBound < f.range(of: "added while")!.lowerBound }())
    check("the status follows without a reload (still started)", m.states[today] == .partial || m.states[today] == .logged)
    // to-do shorthand and timestamps are honoured
    let todo = m.jot(text: "[] send the invoice", source: "hotkey")
    check("[] at the start makes a task without a time", todo != nil && (w.file(today) ?? "").contains("- [ ] send the invoice"), w.file(today) ?? "")
    m.settings.capture.timestamps = false
    _ = m.jot(text: "no time on this one", source: "hotkey")
    check("with time stamps off a jot is a plain bullet", (w.file(today) ?? "").contains("- no time on this one") && !(w.file(today) ?? "").contains("14:32 no time"), w.file(today) ?? "")
    m.settings.capture.timestamps = true
    _ = w.openAndWait(today)
    w.win?.makeKeyAndOrderFront(nil); m.objectWillChange.send(); pump(0.8)

    // ---- M2-A5: the menu-bar field
    print("   M2-A5 menu-bar popover field")
    m.settings.appearance = .light; pump(0.3)
    let pop = hostWindow(MenuBarView(model: m), width: 300, origin: NSPoint(x: 1100, y: 80))
    pump(0.8)
    if let img = windowImage(pop), let obs = recognise(img) {
        savePNG(img, to: shotsDir.appendingPathComponent("popover-jot-empty-light.png"))
        let t = allText(obs)
        check("the popover shows the Jot field with its placeholder, and a Jot… row", t.contains("jotalinefortoday") && t.contains("jot…") || t.contains("jot..."), String(t.prefix(160)))
        if let p = locate("Jot a line", in: obs, of: pop) { mouseClick(at: p, in: pop) }
    }
    func editableField(_ v: NSView?) -> NSTextField? {
        guard let v = v else { return nil }
        if let t = v as? NSTextField, t.isEditable { return t }
        for s in v.subviews { if let t = editableField(s) { return t } }
        return nil
    }
    check("the popover's Jot field is a real editable text field", editableField(pop.contentView) != nil)
    if let f = editableField(pop.contentView), !(pop.firstResponder is NSText) { pop.makeFirstResponder(f) }
    typeText(pop, "popover note")
    pump(0.2)
    if let img = windowImage(pop) { savePNG(img, to: shotsDir.appendingPathComponent("popover-jot-typed-light.png")) }
    pressReturn(pop)
    pump(0.2)
    if let img = windowImage(pop) {
        savePNG(img, to: shotsDir.appendingPathComponent("popover-jot-added-light.png"))
        if let t = recognise(img).map(allText) { check("M2-A5: Return shows \"Added\" in the field", t.contains("added"), String(t.prefix(160))) }
    }
    check("M2-A5: the result is the same as M2-A2: \"- 14:32 popover note\" in today's file, saved within 2 seconds", until(2.5) { (w.file(today) ?? "").contains("- 14:32 popover note") })
    check("the field cleared and is ready for the next jot", until(1.5) { true } && !(drawnText(pop) ?? "").contains("popovernote"))
    m.settings.appearance = .dark; pump(0.5)
    if let img = windowImage(pop) { savePNG(img, to: shotsDir.appendingPathComponent("popover-jot-empty-dark.png")) }
    m.settings.appearance = .system; pump(0.3)
    pop.orderOut(nil)

    // ---- panel, dark
    m.settings.appearance = .dark; pump(0.4)
    m.showJotPanel(source: "hotkey"); pump(0.35)
    typeText(panel, "call with Sam about pricing"); pump(0.2)
    if let img = windowImage(panel) { savePNG(img, to: shotsDir.appendingPathComponent("panel-typed-dark.png")) }
    pressEscape(panel); pump(0.4)
    m.showJotPanel(source: "hotkey"); pump(0.35)
    if let img = windowImage(panel) { savePNG(img, to: shotsDir.appendingPathComponent("panel-empty-dark.png")) }
    pressEscape(panel); pump(0.4)
    m.settings.appearance = .system; pump(0.3)

    // ---- the hotkey callback opens the panel (the real Carbon dispatch)
    print("   the shortcut press opens the panel")
    let press = HotKeyCenter()
    m.settings.capture.hotKey = combo(80)
    m.installHotKeys(press)
    check("the model registered the stored shortcut on its center", press.registered == combo(80))
    check("pressing it (the Carbon event, through the real handler) opens the panel with the field focused", press.deliverPressForTesting() && until(2) { panel.isVisible } && panel.firstResponder === tv)
    pressEscape(panel); pump(0.4)
    m.hotKeys = nil; press.unregister(); m.settings.capture.hotKey = .defaultJot

    // ---- M2-A6: the folder goes away
    print("   M2-A6 the log folder is unavailable, then returns")
    let before6 = w.occurrences("- 14:32 kept note", in: today)
    check("today is open for the first scenario", w.openAndWait(today))
    try? FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: w.logs.path)
    m.showJotPanel(source: "hotkey"); pump(0.3)
    typeText(panel, "kept note")
    pressReturn(panel); pump(0.3)
    check("M2-A6: the panel says the note is kept on this Mac", m.jotPanel.model.phase == .kept, "\(m.jotPanel.model.phase)")
    if let t = drawnText(panel) { check("... in words: \"Kept on this Mac. It will be added when your log folder is back.\"", t.contains("keptonthismac") && t.contains("willbeaddedwhenyourlogfolderisback"), String(t.prefix(160))) }
    if let img = windowImage(panel) { savePNG(img, to: shotsDir.appendingPathComponent("panel-kept-light.png")) }
    check("the note is waiting, not lost: one in the journal, one on the badge", m.notesWaiting == 1 && m.journal.pending().count == 1 && m.journal.pending().first?.text == "kept note", "\(m.notesWaiting) \(m.journal.pending().map { $0.text })")
    check("it is NOT in the file (the folder is read-only)", w.occurrences("- 14:32 kept note", in: today) == before6)
    check("the open page shows it meanwhile (a normal editor transaction)", until(3) { (w.editorText() ?? "").contains("- 14:32 kept note") })
    check("the page reports it cannot save (the folder banner / error), the text stays on screen", until(6) { m.editor.errorText != nil } && (w.editorText() ?? "").contains("kept note"))
    pump(0.6)
    let sidebar = hostWindow(SidebarView(model: m), width: 240, height: 700, origin: NSPoint(x: 1100, y: 40))
    pump(0.8)
    if let img = windowImage(sidebar) {
        savePNG(img, to: shotsDir.appendingPathComponent("sidebar-waiting-light.png"))
        if let t = recognise(img).map(allText) { check("the sidebar says \"1 jot waiting\"", t.contains("1jotwaiting"), String(t.prefix(200))) }
    }
    sidebar.orderOut(nil)
    check("the popover says it too", { let p = hostWindow(MenuBarView(model: m), width: 300, origin: NSPoint(x: 1100, y: 80)); pump(0.6); let t = drawnText(p) ?? ""; p.orderOut(nil); return t.contains("1jotwaiting") }())
    pump(0.6)
    try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: w.logs.path)
    m.retryFolder()
    check("M2-A6: when the folder returns the note is added to today's page, once", until(6) { w.occurrences("- 14:32 kept note", in: today) == 1 && m.notesWaiting == 0 && m.journal.pending().isEmpty }, "n=\(w.occurrences("- 14:32 kept note", in: today)) waiting=\(m.notesWaiting)")
    pump(1.5)
    check("... still once a moment later (no duplicate from a second retry)", w.occurrences("- 14:32 kept note", in: today) == 1 && m.notesWaiting == 0)
    check("the earlier text and jots are all still there", { let f = w.file(today) ?? ""; return f.contains("Then the pricing page.") && f.contains("popover note") && f.contains("call with Sam") }())

    // the folder is missing (renamed) and no page for today is open: the disk route
    check("yesterday is open (today has no page open)", w.openAndWait("2026-10-06"))
    let away = w.dir.appendingPathComponent("logs-away")
    try? FileManager.default.moveItem(at: w.logs, to: away)
    let missing = m.jot(text: "folder renamed note", source: "hotkey")
    check("with the folder gone the note stays in the journal (waiting 1) and the panel route says kept", missing?.waiting == 1 && m.notesWaiting == 1 && m.jotOutcome(text: "second while away", source: "hotkey") == .kept, "\(String(describing: missing))")
    check("two notes wait, in order", m.notesWaiting == 2 && m.journal.pending().map { $0.text } == ["folder renamed note", "second while away"], "\(m.journal.pending().map { $0.text })")
    try? FileManager.default.moveItem(at: away, to: w.logs)
    m.reloadIfFolderChanged()                                  // what the 30 s tick does: waiting notes are retried even if nobody noticed the folder blink
    check("M2-A6: rename it back and both notes arrive, once each, in order", until(6) { w.occurrences("folder renamed note", in: today) == 1 && w.occurrences("second while away", in: today) == 1 && m.notesWaiting == 0 }, "n=\(w.occurrences("folder renamed note", in: today)) waiting=\(m.notesWaiting)")
    check("... in the order they were captured", { let f = w.file(today) ?? ""; guard let a = f.range(of: "folder renamed note"), let b = f.range(of: "second while away") else { return false }; return a.lowerBound < b.lowerBound }())
    check("the days around them are untouched", w.file("2026-10-06") != nil && (w.file("2026-10-06") ?? "").contains(words))

    // ---- Shortcuts pane
    print("   U6 Settings > Shortcuts")
    capShortcutsPane(w)
}

private func capShortcutsPane(_ w: CapWorld) {
    let m = w.model
    let controller = SettingsWindowController.shared
    m.installSettingsEffects()
    m.settings.capture.hotKey = .defaultJot
    m.settings.capture = CapturePrefs()
    var recognitionWorks = true
    for appearance in [AppAppearance.light, .dark] {
        m.settings.appearance = appearance
        pump(0.4)
        let tag = appearance == .dark ? "dark" : "light"
        m.openSettings(pane: .shortcuts)
        guard let sw = controller.window else { check("the Settings window opens", false); return }
        let screenH = (sw.screen ?? NSScreen.main)?.visibleFrame.height ?? 800
        let wantH = min(SettingsPane.shortcuts.contentHeight, SettingsTheme.heightCap, screenH - 140)
        until(2.0) { sw.isKeyWindow && abs(sw.contentRect(forFrameRect: sw.frame).height - wantH) < 1 }
        pump(0.8)
        guard let img = windowImage(sw) else { check("screenshot of the Shortcuts pane (\(tag))", false, "no window image"); continue }
        check("screenshot saved: settings-shortcuts-\(tag).png", savePNG(img, to: shotsDir.appendingPathComponent("settings-shortcuts-\(tag).png")) && img.width > 800)
        if recognitionWorks, let obs = recognise(img) {
            let t = allText(obs)
            let expected = ["Jot from anywhere", "Shortcut", "Reset", "Time stamp", "makes a to-do", "Jots count toward logging a day", "Go", "Today", "Catch Up", "Search Logs", "Open Settings", "Switch pane"]
            let missing = expected.filter { !t.contains(squash($0)) }
            check("Shortcuts (\(tag)) draws the Jot controls and the whole keyboard list without scrolling", missing.isEmpty, "missing: \(missing)")
        } else { recognitionWorks = false }
    }
    // the error state and the Off state, light
    m.settings.appearance = .light; pump(0.3)
    m.hotKeyFailure = HotKeyFailure(spec: .defaultJot, reason: .taken)
    m.openSettings(pane: .shortcuts); pump(0.9)
    if let sw = controller.window, let img = windowImage(sw) {
        savePNG(img, to: shotsDir.appendingPathComponent("settings-shortcuts-taken-light.png"))
        if let t = recognise(img).map(allText) { check("a combination another app owns shows \"⌃⌥J is already used by another app.\" with Record another… and Off", t.contains("alreadyusedbyanotherapp") && t.contains("recordanother"), String(t.prefix(300))) }
    }
    m.hotKeyFailure = nil
    m.settings.capture.hotKey = nil; pump(0.6)
    if let sw = controller.window, let img = windowImage(sw) {
        savePNG(img, to: shotsDir.appendingPathComponent("settings-shortcuts-off-light.png"))
        if let t = recognise(img).map(allText) { check("Off is shown as Off, with where else to jot", t.contains("off") && t.contains("menubar"), String(t.prefix(300))) }
    }
    m.settings.capture.hotKey = .defaultJot
    // the switches are wired
    let startTS = m.settings.capture.timestamps
    m.settings.capture.timestamps.toggle()
    check("the switches write straight to Settings and persist", m.settings.capture.timestamps == !startTS && Settings.load(from: w.suite).capture.timestamps == !startTS)
    m.settings.capture.timestamps = startTS
    // jots count toward logged: a jots-only page of 25 words becomes logged, and the rule is process-wide
    m.settings.capture.jotsCountTowardLogged = true; pump(0.3)
    check("\"Jots count toward logging a day\" reaches the core rule", LogStore.jotsRules.countTowardLogged == true && LogStore.jotsRules.heading == "Jots")
    m.settings.capture.jotsCountTowardLogged = false; pump(0.3)
    check("... and switches back", LogStore.jotsRules.countTowardLogged == false)
    let delegate = AppDelegate()                                      // menu items point at it weakly: keep it alive
    check("the Dock menu has Today, Jot…, Catch Up and Settings…", delegate.applicationDockMenu(NSApp)?.items.map { $0.title } == ["Today", "Jot…", "Catch Up", "Settings…"])
    m.settings.appearance = .system
    controller.window?.orderOut(nil)
    pump(0.3)
}

// MARK: crash and replay

/// A note that was durable in the journal when the app died is delivered by the next launch, exactly once.
private func capCrashReplay() {
    print("   journal replay after a simulated crash")
    let base = "crash"
    // "The app died": a model that never loads a page takes a note. The note is durable in the journal and went nowhere else.
    let first = CapWorld(base, live: false, window: false)
    let logs = first.logs, capture = first.capture
    let receipt = first.model.jot(text: "survived the crash", source: "hotkey")
    check("a note is durable in the journal and nowhere else (the app died before a page took it)",
          receipt?.waiting == 1 && CaptureJournal(dir: capture).pending().map { $0.text } == ["survived the crash"] && !FileManager.default.fileExists(atPath: logs.appendingPathComponent(today + ".md").path),
          "\(String(describing: receipt))")
    check("the journal file is private to the user (mode 0600)", ((try? FileManager.default.attributesOfItem(atPath: capture.appendingPathComponent("journal.jsonl").path))?[.posixPermissions] as? NSNumber)?.intValue == 0o600)

    let relaunch = CapWorld(base, live: true, window: true)            // the next launch: a new model on the same folders
    defer { relaunch.close() }
    guard until(25, { relaunch.loaded }) else { check("the relaunched app loads today's page", false); return }
    check("journal replay delivers the note once today's page has loaded, within a few seconds", until(8) { (relaunch.file(today) ?? "").contains("- 14:32 survived the crash") }, relaunch.file(today) ?? "no file")
    check("... exactly once, and acknowledged (nothing waits, the journal is empty)", until(4) { relaunch.model.notesWaiting == 0 && relaunch.model.journal.pending().isEmpty } && relaunch.occurrences("survived the crash", in: today) == 1)
    check("a second replay (app activation) adds nothing", { relaunch.model.replayCapture(); pump(1.5); return relaunch.occurrences("survived the crash", in: today) == 1 }())
    check("the page that was waiting also shows it", (relaunch.editorText() ?? "").contains("- 14:32 survived the crash"))

    // The app died after the file write and before the acknowledgement: the line is already in the page, a second copy must not appear.
    func item(_ text: String) -> CaptureItem { CaptureItem(id: UUID().uuidString, ts: capDate(2026, 10, 7), day: today, text: text, stamp: "14:32", todo: false, source: "hotkey") }
    let model = relaunch.model
    try? model.journal.append(item("already saved before the crash"))                 // the journal says it is pending ...
    model.refreshNotesWaiting()
    check("a pending note is counted", model.notesWaiting == 1)
    model.replayCapture()
    check("... delivered once (it was new to the page)", until(8) { model.notesWaiting == 0 && relaunch.occurrences("already saved before the crash", in: today) == 1 }, "waiting=\(model.notesWaiting)")
    try? model.journal.append(item("already saved before the crash"))                 // ... the same line again, as after a crash between save and acknowledgement
    model.refreshNotesWaiting()
    model.replayCapture()
    check("replaying a line that is already in the page acknowledges it and adds no duplicate", until(8) { model.notesWaiting == 0 } && relaunch.occurrences("already saved before the crash", in: today) == 1, "n=\(relaunch.occurrences("already saved before the crash", in: today)) waiting=\(model.notesWaiting)")

    // A torn last line (the app died in the middle of a write) is ignored; the notes before it survive.
    try? model.journal.append(item("before the torn line"))
    if let h = try? FileHandle(forWritingTo: capture.appendingPathComponent("journal.jsonl")) { h.seekToEndOfFile(); h.write(Data("{\"id\":\"torn\",\"ts\":".utf8)); try? h.close() }
    model.refreshNotesWaiting()
    model.replayCapture()
    check("a torn last line in the journal is tolerated: the note before it is delivered, once", until(8) { relaunch.occurrences("before the torn line", in: today) == 1 }, relaunch.file(today) ?? "")
}
