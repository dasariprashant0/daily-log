// ScenarioSettings.swift - real-window scenarios for the Settings window and its entry points.
// Owned by the Settings stream. Called from main.swift after the app scenarios; use `check(name, ok, detail)`.
//
// This opens the REAL Settings window (the one the app uses, SettingsWindowController), drives it with real mouse and key
// events, reads what it drew back with on-device text recognition, and saves real screenshots of every pane in light and dark
// (set EC_SETTINGS_SHOTS=<dir>; default: a temporary folder). It never touches the user's logs, defaults or login item:
// every model is `live: false` over a throwaway defaults suite and a temporary log folder.
// What it cannot do: run the SwiftUI `App` lifecycle (GloamlogApp.swift is not compiled here), so the ⌘, menu command and the
// real menu bar item are not exercised; their code paths end in the same AppModel.openSettings(pane:).
import AppKit
import SwiftUI
import Vision

// MARK: - helpers (private to this file)

/// Runs the AppKit event loop (not just the run loop), which is what lets this process become the active app and makes a
/// window key, and delivers events posted to windows.
private func pumpEvents(_ seconds: TimeInterval, until cond: () -> Bool = { false }) {
    let end = Date().addingTimeInterval(seconds)
    while Date() < end {
        if cond() { return }
        if let e = NSApp.nextEvent(matching: .any, until: Date().addingTimeInterval(0.01), inMode: .default, dequeue: true) { NSApp.sendEvent(e) }
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.001))
    }
}
@discardableResult
private func waitEvents(_ seconds: TimeInterval, until cond: () -> Bool) -> Bool { pumpEvents(seconds, until: cond); return cond() }

private func windowImage(_ w: NSWindow) -> CGImage? {
    CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(w.windowNumber), [.boundsIgnoreFraming, .bestResolution])
}
@discardableResult
private func savePNG(_ cg: CGImage, to url: URL) -> Bool {
    guard let png = NSBitmapImageRep(cgImage: cg).representation(using: .png, properties: [:]) else { return false }
    return (try? png.write(to: url)) != nil
}

/// Text recognition (Vision, on device) of what a window really drew. nil when recognition is unavailable.
private func recognise(_ cg: CGImage) -> [VNRecognizedTextObservation]? {
    let req = VNRecognizeTextRequest()
    req.recognitionLevel = .accurate; req.usesLanguageCorrection = false
    do { try VNImageRequestHandler(cgImage: cg, options: [:]).perform([req]) } catch { return nil }
    return req.results
}
private func squash(_ s: String) -> String { s.lowercased().filter { !$0.isWhitespace } }
private func allText(_ obs: [VNRecognizedTextObservation]) -> String { squash(obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")) }
/// Where `needle` (case sensitive) sits in the recognised text, in window coordinates (points, origin bottom left).
private func locate(_ needle: String, in obs: [VNRecognizedTextObservation], of w: NSWindow) -> NSPoint? {
    for o in obs {
        guard let c = o.topCandidates(1).first, let r = c.string.range(of: needle), let b = try? c.boundingBox(for: r) else { continue }
        return NSPoint(x: b.boundingBox.midX * w.frame.width, y: b.boundingBox.midY * w.frame.height)
    }
    return nil
}

private func mouseClick(at p: NSPoint, in w: NSWindow) {
    for type in [NSEvent.EventType.leftMouseDown, .leftMouseUp] {
        if let e = NSEvent.mouseEvent(with: type, location: p, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                                      windowNumber: w.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: type == .leftMouseDown ? 1 : 0) {
            w.sendEvent(e)
        }
        pumpEvents(0.06)
    }
}
private func arrowKey(_ code: UInt16, in w: NSWindow) {
    let f = code == 123 ? NSLeftArrowFunctionKey : NSRightArrowFunctionKey
    let s = String(UnicodeScalar(UInt32(f))!)
    if let e = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: [.numericPad, .function], timestamp: ProcessInfo.processInfo.systemUptime,
                                windowNumber: w.windowNumber, context: nil, characters: s, charactersIgnoringModifiers: s, isARepeat: false, keyCode: code) {
        w.sendEvent(e)
    }
    pumpEvents(0.05)
}

/// The outermost scroll view under `view` (a pane's form), not the text editor's own.
private func firstScrollView(in view: NSView) -> NSScrollView? {
    if let s = view as? NSScrollView, s.documentView != nil { return s }
    for sub in view.subviews { if let f = firstScrollView(in: sub) { return f } }
    return nil
}

/// A borderless window that can be key, like the menu-bar popover's panel.
private final class KeyableWindow: NSWindow { override var canBecomeKey: Bool { true } }
private func hostWindow<V: View>(_ v: V, width: CGFloat, height: CGFloat? = nil) -> NSWindow {
    let host = NSHostingView(rootView: v)
    host.layoutSubtreeIfNeeded()
    host.frame = NSRect(x: 0, y: 0, width: width, height: height ?? max(host.fittingSize.height, 120))
    let win = KeyableWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
    win.contentView = host
    win.isReleasedWhenClosed = false
    win.setFrameOrigin(NSPoint(x: 80, y: 120))
    win.makeKeyAndOrderFront(nil)
    return win
}

// MARK: - the scenarios

func runSettingsScenarios() {
    print("11. Settings window, entry points, effects (real NSWindow, real events)")
    let env = ProcessInfo.processInfo.environment
    let base = URL(fileURLWithPath: env["EC_TMP"] ?? NSTemporaryDirectory()).appendingPathComponent("dl-editor-check-settings")
    let logs = base.appendingPathComponent("logs"), backups = base.appendingPathComponent("backups")
    let otherDir = base.appendingPathComponent("other-folder"), emptyDir = base.appendingPathComponent("empty-folder")
    let shots = URL(fileURLWithPath: env["EC_SETTINGS_SHOTS"] ?? base.appendingPathComponent("shots").path)
    try? FileManager.default.removeItem(at: base)
    for u in [logs, backups, otherDir, emptyDir, shots] { try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true) }

    // Fixture: 60 days before Wed 7 Oct 2026 with writing, a few holidays and a few unwritten workdays.
    let cal = Calendar.current
    func put(_ day: String, _ text: String, in dir: URL = logs) { try? text.write(to: dir.appendingPathComponent(day + ".md"), atomically: false, encoding: .utf8) }
    let words = "Wrote up the pricing page notes, reviewed the signup form with Ana, fixed the demo tracking and planned the webinar page for next week."
    for back in 1...60 {
        guard let k = DayKey.adding("2026-10-07", -back, cal) else { continue }
        let wd = DayKey.weekday(k, cal)
        if wd == 1 || wd == 7 || back % 11 == 4 { continue }
        if back % 9 == 3 { put(k, MarkdownFormat.serializeSkip(day: k, reason: "Holiday")); continue }
        put(k, MarkdownFormat.serialize(day: k, body: "## What I did\n\n\(words)"))
    }
    var now = cal.date(from: DateComponents(year: 2026, month: 10, day: 7, hour: 10, minute: 0))!        // Wednesday
    let suiteName = "dailylog.editorcheck.settings"
    let suite = UserDefaults(suiteName: suiteName)!
    suite.removePersistentDomain(forName: suiteName)
    var s0 = Settings(); s0.storageFolder = logs; s0.onboarded = true
    s0.save(to: suite)
    func makeModel() -> AppModel { AppModel(defaults: suite, backupDir: backups, live: false, clock: { now }) }
    let model = makeModel()
    model.installSettingsEffects()
    let controller = SettingsWindowController.shared
    func settingsWindows() -> [NSWindow] { NSApp.windows.filter { $0.identifier?.rawValue == SettingsWindowController.windowID && $0.isVisible } }
    func expectedHeight(_ p: SettingsPane) -> CGFloat {
        let screenH = (controller.window?.screen ?? NSScreen.main)?.visibleFrame.height ?? 800
        return min(p.contentHeight, SettingsTheme.heightCap, screenH - 140)
    }
    func contentSize(_ w: NSWindow) -> NSSize { w.contentRect(forFrameRect: w.frame).size }

    // ---- S1: one door, opens in front within a second
    print("   S1 window and entry points")
    // Cold: nothing prepared, SwiftUI not yet warmed in this process (a second controller, so the shared one stays untouched).
    let cold = SettingsWindowController()
    let tc = Date()
    cold.show(model: model, pane: .reminders)
    let coldKey = waitEvents(3.0) { cold.window?.isKeyWindow == true }
    let coldMs = Date().timeIntervalSince(tc) * 1000
    check("cold open (window built on demand) is key within 3 s", coldKey && coldMs < 3000, String(format: "%.0f ms", coldMs))
    print(String(format: "     (cold build and show: key after %.0f ms)", coldMs))
    cold.window?.close()
    // What the app does: build the window hidden after launch (prewarm), then show it on demand.
    controller.prewarm(model: model)
    pumpEvents(0.3)
    check("prewarm builds the window but does not show it", controller.window != nil && controller.window?.isVisible == false)
    let t0 = Date()
    model.openSettings(pane: .reminders)
    let returned = Date().timeIntervalSince(t0) * 1000
    let keyed = waitEvents(1.0) { controller.window?.isKeyWindow == true }
    let elapsed = Date().timeIntervalSince(t0) * 1000
    guard let w = controller.window else { check("openSettings creates the Settings window", false); return }
    check("openSettings(pane: .reminders) opens the window and it is key within 1 s", keyed && w.isVisible && elapsed < 1000, String(format: "%.0f ms, key=%@ visible=%@", elapsed, "\(keyed)", "\(w.isVisible)"))
    print(String(format: "     (prewarmed: openSettings returned after %.0f ms, key after %.0f ms)", returned, elapsed))
    check("it is on the Reminders pane: title, selected tab and state agree",
          w.title == "Reminders" && w.toolbar?.selectedItemIdentifier?.rawValue == "reminders" && controller.nav.pane == .reminders)
    check("it is the front window of the app", NSApp.orderedWindows.first === w)
    check("window chrome: titled and closable, no minimise or zoom", w.styleMask.contains(.titled) && w.styleMask.contains(.closable) && !w.styleMask.contains(.miniaturizable) && !w.styleMask.contains(.resizable))
    check("window is 680 pt wide with the pane's height", abs(contentSize(w).width - SettingsTheme.width) < 1 && abs(contentSize(w).height - expectedHeight(.reminders)) < 1, "\(contentSize(w))")
    check("the six tabs exist in order, each with a title and an icon",
          (w.toolbar?.items.map { $0.itemIdentifier.rawValue }) == SettingsPane.allCases.map { $0.rawValue }
          && (w.toolbar?.items.allSatisfy { $0.image != nil && !$0.label.isEmpty }) == true)

    model.openSettings(pane: .page)
    check("a second openSettings reuses the one window and switches pane", settingsWindows().count == 1 && w.title == "Page" && controller.nav.pane == .page)
    check("the window follows the pane's height", waitEvents(1.0) { abs(contentSize(w).height - expectedHeight(.page)) < 1 }, "\(contentSize(w))")
    model.openSettings()
    check("openSettings() with no pane keeps the pane it was on", w.title == "Page" && settingsWindows().count == 1)

    w.performClose(nil); pumpEvents(0.3)
    check("closing the window (⌘W) hides it", !w.isVisible)
    let t1 = Date(); model.openSettings(pane: .general)
    let again = waitEvents(1.0) { w.isKeyWindow }
    check("reopening is just as fast and shows the pane asked for", again && w.title == "General" && Date().timeIntervalSince(t1) < 1.0 && settingsWindows().count == 1)

    w.orderOut(nil)
    let sent = NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    check("the old showSettingsWindow: selector (What's new, older callers) still opens our window", sent && waitEvents(1.0) { w.isKeyWindow })

    // keyboard: arrows move between panes, never past the ends, and never steal arrows from a text field
    model.openSettings(pane: .storage)
    arrowKey(124, in: w); let r1 = controller.nav.pane
    arrowKey(124, in: w); let r2 = controller.nav.pane
    arrowKey(124, in: w); let r3 = controller.nav.pane
    arrowKey(123, in: w); let l1 = controller.nav.pane
    check("→ and ← change pane and stop at the ends", r1 == .shortcuts && r2 == .about && r3 == .about && l1 == .shortcuts, "\(r1) \(r2) \(r3) \(l1)")
    check("the title and tab followed the arrows", w.title == "Shortcuts" && w.toolbar?.selectedItemIdentifier?.rawValue == "shortcuts")

    // the pane is remembered (in the model's defaults) and a new model reopens on it
    check("the last pane is stored in the defaults", suite.string(forKey: SettingsNav.paneKey) == "shortcuts")
    let model2 = makeModel(); model2.installSettingsEffects()
    controller.nav.pane = .general                      // (stores "general" too, so put the remembered pane back by hand)
    suite.set("shortcuts", forKey: SettingsNav.paneKey)
    model2.openSettings()
    check("a fresh model reopens Settings on the pane it was last on", controller.nav.pane == .shortcuts && w.title == "Shortcuts")
    model.openSettings(pane: .general)

    // ---- S2/S5: every pane, light and dark, as drawn (screenshots + text recognised in the picture)
    print("   S2/S5 panes: screenshots and what they drew")
    let expected: [SettingsPane: [String]] = [
        .general: ["Appearance", "Week starts on", "Open Gloamlog at login", "Show in the menu bar", "Reset to defaults"],
        .reminders: ["Remind me at", "On these days", "When it fires", "Snooze for", "Next reminder", "Notifications"],
        .page: ["A day counts as logged after", "Log start date", "Catch-up window", "New day template"],
        .storage: ["Folder", "Show in Finder", "Change", "Use default", "Safety copies", "Restore Previous Version"],
        .shortcuts: ["Today", "Catch Up", "Go to Date", "Search Logs", "Open Settings"],
        .about: ["Gloamlog", "No network requests", "Run setup again", "MIT licence"],
    ]
    var recognitionWorks = true
    for appearance in [AppAppearance.light, .dark] {
        model.settings.appearance = appearance
        pumpEvents(0.4)
        let tag = appearance == .dark ? "dark" : "light"
        for pane in SettingsPane.allCases {
            model.openSettings(pane: pane)
            waitEvents(1.5) { w.isKeyWindow && abs(contentSize(w).height - expectedHeight(pane)) < 1 }
            pumpEvents(0.7)                                  // the form lays out, the toolbar tab settles
            if pane == .page, let doc = w.contentView, let sc = firstScrollView(in: doc) {
                waitEvents(1.0) { sc.contentView.bounds.origin.y == 0 }
                check("Page (\(tag)) opens scrolled to its top, with no text field grabbing focus",
                      sc.contentView.bounds.origin.y == 0 && !(w.firstResponder is NSText), "scrollY=\(sc.contentView.bounds.origin.y) firstResponder=\(String(describing: w.firstResponder))")
            }
            guard let img = windowImage(w) else { check("screenshot \(pane.rawValue) \(tag)", false, "no window image"); continue }
            let file = shots.appendingPathComponent("settings-\(pane.rawValue)-\(tag).png")
            check("screenshot saved: settings-\(pane.rawValue)-\(tag).png", savePNG(img, to: file) && img.width > 800)
            if pane == .page, let doc = w.contentView, let scroll = firstScrollView(in: doc) {
                // the Page form is longer than the window: also show its end (template, carried-over headings)
                scroll.contentView.scroll(to: NSPoint(x: 0, y: max(0, (scroll.documentView?.bounds.height ?? 0) - scroll.contentView.bounds.height)))
                scroll.reflectScrolledClipView(scroll.contentView)
                pumpEvents(0.5)
                if let end = windowImage(w) {
                    savePNG(end, to: shots.appendingPathComponent("settings-page-end-\(tag).png"))
                    if recognitionWorks, let obs = recognise(end) {
                        let text = allText(obs)
                        check("Page (\(tag)), scrolled to its end, shows the template and the carried-over headings", text.contains("carriedoverfromyesterday") && text.contains("addheading"), String(text.suffix(160)))
                    }
                }
                scroll.contentView.scroll(to: .zero); scroll.reflectScrolledClipView(scroll.contentView)
            }
            if recognitionWorks, let obs = recognise(img) {
                let text = allText(obs)
                let missing = (expected[pane] ?? []).filter { !text.contains(squash($0)) }
                check("\(pane.title) (\(tag)) drew its controls and help text", missing.isEmpty, "missing: \(missing)")
                if pane == .reminders || pane == .general { check("\(pane.title) (\(tag)): the selected tab and window title read '\(pane.title)'", text.contains(squash(pane.title))) }
            } else { recognitionWorks = false }
        }
    }
    if !recognitionWorks { print("     (text recognition unavailable here: pane text was not checked, screenshots were saved)") }
    model.settings.appearance = .system
    pumpEvents(0.3)

    // ---- S3: real clicks reach the model (the controls are wired), changes apply at once
    print("   S3 controls, effects and persistence")
    model.openSettings(pane: .general)
    waitEvents(1.5) { w.isKeyWindow }; pumpEvents(0.6)
    if recognitionWorks, let img = windowImage(w), let obs = recognise(img), let p = locate("Dark", in: obs, of: w) {
        mouseClick(at: p, in: w)
        check("clicking 'Dark' in the Appearance control sets Dark, and the whole app turns dark at once",
              model.settings.appearance == .dark && NSApp.appearance?.name == .darkAqua && w.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua)
    } else { check("clicking 'Dark' in the Appearance control", false, "could not find the control in the picture") }
    model.settings.appearance = .light; pumpEvents(0.2)
    check("Light pins the app light", NSApp.appearance?.name == .aqua)
    model.settings.appearance = .system; pumpEvents(0.2)
    check("System follows macOS again (no override)", NSApp.appearance == nil)

    model.openSettings(pane: .reminders)
    waitEvents(1.5) { abs(contentSize(w).height - expectedHeight(.reminders)) < 1 }; pumpEvents(0.6)
    if recognitionWorks, let img = windowImage(w), let obs = recognise(img), let p = locate("Gentle", in: obs, of: w) {
        mouseClick(at: p, in: w)
        check("clicking 'Gentle' sets the reminder style", model.settings.mode == .gentle)
    } else { check("clicking 'Gentle' sets the reminder style", false, "could not find the control in the picture") }
    model.settings.mode = .strict

    model.openSettings(pane: .page)
    waitEvents(1.5) { abs(contentSize(w).height - expectedHeight(.page)) < 1 }; pumpEvents(0.6)
    if recognitionWorks, let img = windowImage(w), let obs = recognise(img), let p = locate("Start from today", in: obs, of: w) {
        mouseClick(at: p, in: w)
        check("'Start from today' sets the log start to today", model.settings.logStartDate == "2026-10-07", String(describing: model.settings.logStartDate))
        pumpEvents(0.3)
        if let img2 = windowImage(w), let obs2 = recognise(img2), let q = locate("Use first log", in: obs2, of: w) {
            mouseClick(at: q, in: w)
            check("'Use first log' returns to following the first page", model.settings.logStartDate == nil, String(describing: model.settings.logStartDate))
        } else { check("'Use first log' returns to following the first page", false, "button not found") }
    } else { check("'Start from today' sets the log start to today", false, "could not find the button in the picture") }

    model.openSettings(pane: .about)
    waitEvents(1.5) { abs(contentSize(w).height - expectedHeight(.about)) < 1 }; pumpEvents(0.6)
    if recognitionWorks, let img = windowImage(w), let obs = recognise(img), let p = locate("Run setup again", in: obs, of: w) {
        mouseClick(at: p, in: w)
        check("'Run setup again…' opens the setup sheet", waitEvents(1.0) { model.sheet == .onboarding })
        model.sheet = nil
    } else { check("'Run setup again…' opens the setup sheet", false, "could not find the button in the picture") }

    // a real click on a toolbar tab (the way a person changes pane)
    model.openSettings(pane: .general)
    waitEvents(1.5) { abs(contentSize(w).height - expectedHeight(.general)) < 1 }; pumpEvents(0.6)
    if recognitionWorks, let img = windowImage(w), let obs = recognise(img), let p = locate("Storage and backups", in: obs, of: w) {
        mouseClick(at: p, in: w)
        check("clicking the 'Storage and backups' tab opens that pane (title, tab, height)",
              waitEvents(1.0) { controller.nav.pane == .storage } && w.title == "Storage and backups" && w.toolbar?.selectedItemIdentifier?.rawValue == "storage")
    } else { check("clicking a toolbar tab", false, "could not find the tab in the picture") }
    if let item = w.toolbar?.items.first(where: { $0.itemIdentifier.rawValue == "reminders" }), let action = item.action {
        NSApp.sendAction(action, to: item.target, from: item)
        check("a tab's action selects its pane", controller.nav.pane == .reminders && w.title == "Reminders")
    }

    // reminder effects
    model.planner.firstFired = true; model.planner.snoozedUntil = now.addingTimeInterval(600)
    var st = model.settings; st.reminderMinutes = 17 * 60 + 10; model.settings = st
    pumpEvents(0.3)
    let clock = Fmt.clock(minutes: 17 * 60 + 10, calendar: model.cal, now: now)
    check("a new reminder time re-plans: today's reminder can fire again at it", model.planner.firstFired == false && model.planner.snoozedUntil == nil)
    check("'Next reminder' shows the new time", model.nextReminderLabel == "Today, \(clock)", model.nextReminderLabel)
    st = model.settings; st.mode = .gentle; st.snoozeMinutes = 20; st.weekdays = [2, 6]; model.settings = st      // Monday and Friday only
    pumpEvents(0.2)
    check("with Monday and Friday only, the next reminder is Friday", model.nextReminderLabel == "Fri 9 Oct, \(clock)", model.nextReminderLabel)
    check("the popover's reminder line carries the new time and style", model.menuReminderLine == "Next reminder: Fri 9 Oct, \(clock) · Gentle", model.menuReminderLine)

    // pure schedule table
    func label(_ nowDate: Date, _ days: Set<Int>, _ minutes: Int, done: Bool = false) -> String {
        ReminderSchedule.next(now: nowDate, calendar: cal, weekdays: days, reminderMinutes: minutes, todayDone: done)
            .map { ReminderSchedule.label(for: $0, now: nowDate, calendar: cal) } ?? "none"
    }
    func at(_ d: Int, _ h: Int, _ m: Int = 0) -> Date { cal.date(from: DateComponents(year: 2026, month: 10, day: d, hour: h, minute: m))! }
    let weekdaysMF: Set<Int> = [2, 3, 4, 5, 6]
    let c1655 = Fmt.clock(minutes: 16 * 60 + 55, calendar: cal, now: at(7, 10))
    check("schedule: Wednesday morning -> today", label(at(7, 10), weekdaysMF, 16 * 60 + 55) == "Today, \(c1655)")
    check("schedule: Wednesday evening, past the time -> tomorrow", label(at(7, 17), weekdaysMF, 16 * 60 + 55) == "Tomorrow, \(c1655)")
    check("schedule: today already logged -> tomorrow", label(at(7, 10), weekdaysMF, 16 * 60 + 55, done: true) == "Tomorrow, \(c1655)")
    check("schedule: Friday evening -> Monday 12 Oct", label(at(9, 17), weekdaysMF, 16 * 60 + 55) == "Mon 12 Oct, \(c1655)")
    check("schedule: Saturday -> Monday 12 Oct", label(at(10, 9), weekdaysMF, 16 * 60 + 55) == "Mon 12 Oct, \(c1655)")
    check("schedule: Mondays only, on a Wednesday -> next Monday", label(at(7, 10), [2], 16 * 60 + 55) == "Mon 12 Oct, \(c1655)")

    // week start, log start, catch-up window apply without Save
    st = model.settings; st.weekStart = 1; model.settings = st; pumpEvents(0.3)
    check("week start Sunday: the calendar is rebuilt from makeCalendar (cal.firstWeekday == 1)", model.cal.firstWeekday == 1 && AppModel.makeCalendar(weekStart: 1).firstWeekday == 1)
    check("... and the heatmap's weeks begin on Sunday", (model.heat.first?.first).map { DayKey.weekday($0.day, model.cal) == 1 } ?? false)
    st = model.settings; st.weekStart = 2; model.settings = st; pumpEvents(0.3)
    check("week start Monday: cal.firstWeekday == 2 and the heatmap's weeks begin on Monday", model.cal.firstWeekday == 2 && (model.heat.first?.first).map { DayKey.weekday($0.day, model.cal) == 2 } ?? false)
    st = model.settings; st.weekStart = nil; model.settings = st; pumpEvents(0.3)
    check("week start System: follows the system calendar", model.cal.firstWeekday == Calendar.current.firstWeekday && AppModel.makeCalendar(weekStart: nil).firstWeekday == Calendar.current.firstWeekday)
    check("makeCalendar clamps nonsense to the system calendar", AppModel.makeCalendar(weekStart: 9).firstWeekday == Calendar.current.firstWeekday)

    let missed = model.heat.flatMap { $0 }.first { $0.status == .missed }
    check("fixture: the heatmap shows an unlogged workday", missed != nil)
    if let m = missed, let next = DayKey.adding(m.day, 1, model.cal) {
        let hadInCatchUp = model.catchUpDays.contains(m.day)
        st = model.settings; st.logStartDate = next; model.settings = st; pumpEvents(0.3)
        let status = model.heat.flatMap { $0 }.first { $0.day == m.day }?.status
        check("setting the log start after an unlogged day stops counting it (heatmap), at once", status == .off, "\(String(describing: status))")
        if hadInCatchUp { check("... and Catch up no longer lists it", !model.catchUpDays.contains(m.day)) }
        st = model.settings; st.logStartDate = nil; model.settings = st; pumpEvents(0.3)
        check("clearing the log start counts it again", model.heat.flatMap { $0 }.first { $0.day == m.day }?.status == .missed)
    }
    st = model.settings; st.catchUpWindowDays = 14; model.settings = st; pumpEvents(0.2)
    let narrow = model.catchUpDays.count
    st = model.settings; st.catchUpWindowDays = 90; model.settings = st; pumpEvents(0.2)
    check("a wider catch-up window never lists fewer days", model.catchUpDays.count >= narrow, "\(narrow) -> \(model.catchUpDays.count)")

    // everything survives a new model over the same defaults
    print("   S3 persistence")
    model.openSettings(pane: .general)
    st = model.settings
    st.appearance = .dark; st.weekStart = 1; st.reminderMinutes = 17 * 60 + 10; st.mode = .gentle; st.snoozeMinutes = 20
    st.weekdays = [2, 4, 6]; st.minWords = 35; st.catchUpWindowDays = 60; st.logStartDate = "2026-09-14"
    st.template = TemplatePreset.standup.markdown; st.carryOverHeadings = ["Today", "Blockers"]
    model.settings = st
    model.showMenuBarItem = false
    pumpEvents(0.3)
    let fresh = makeModel()
    let f = fresh.settings
    check("appearance, week start, reminder time, style, snooze and weekdays persist", f.appearance == .dark && f.weekStart == 1 && f.reminderMinutes == 17 * 60 + 10 && f.mode == .gentle && f.snoozeMinutes == 20 && f.weekdays == [2, 4, 6])
    check("words rule, catch-up window, log start, template and carry-over headings persist", f.minWords == 35 && f.catchUpWindowDays == 60 && f.logStartDate == "2026-09-14" && f.template == TemplatePreset.standup.markdown && f.carryOverHeadings == ["Today", "Blockers"])
    check("a new model builds its calendar from the saved week start", fresh.cal.firstWeekday == 1)
    check("the new model's popover line shows the saved time", fresh.menuReminderLine.contains(clock) && fresh.menuReminderLine.hasSuffix("Gentle"), fresh.menuReminderLine)
    check("the menu-bar item preference persists (and is off)", fresh.showMenuBarItem == false && model.showMenuBarItem == false)
    check("changes were saved without any Save step (the stored JSON has them)", Settings.load(from: suite).reminderMinutes == 17 * 60 + 10 && Settings.load(from: suite).appearance == .dark)

    // popover: the real MenuBarView, drawn, shows the new time; its Settings row opens the window
    print("   S4 menu-bar popover, onboarding")
    model.settings.appearance = .light; pumpEvents(0.3)
    let popover = hostWindow(MenuBarView(model: model), width: 300)
    pumpEvents(0.8)
    if let img = windowImage(popover) {
        savePNG(img, to: shots.appendingPathComponent("menubar-popover-light.png"))
        if recognitionWorks, let obs = recognise(img) {
            let text = allText(obs)
            check("the popover (as drawn) shows the next reminder with the new time", text.contains("nextreminder") && text.contains(squash(clock)), String(text.prefix(200)))
            check("the popover offers Settings", text.contains("settings"))
            w.orderOut(nil)
            if let p = locate("Settings", in: obs, of: popover) {
                mouseClick(at: p, in: popover)
                check("clicking Settings… in the popover opens the Settings window in front (key within 1 s)", waitEvents(1.0) { w.isKeyWindow })
            } else { check("clicking Settings… in the popover", false, "row not found") }
        }
    }
    model.settings.appearance = .dark; pumpEvents(0.5)
    if let img = windowImage(popover) { savePNG(img, to: shots.appendingPathComponent("menubar-popover-dark.png")) }
    popover.orderOut(nil)

    // reset to defaults, per pane
    model.settings = { var d = Settings(); d.storageFolder = logs; d.onboarded = true; return d }()      // back to a known start
    st = model.settings
    st.appearance = .dark; st.weekStart = 1; st.reminderMinutes = 8 * 60; st.mode = .gentle; st.snoozeMinutes = 5; st.weekdays = [2]
    st.minWords = 99; st.template = "x"; st.carryOverHeadings = ["x"]; st.catchUpWindowDays = 365; st.logStartDate = "2026-01-01"
    model.settings = st; model.showMenuBarItem = false; pumpEvents(0.2)
    model.resetSettings(.reminders); pumpEvents(0.2)
    let d = Settings()
    check("Reset Reminders restores time, days, style and snooze and nothing else", model.settings.reminderMinutes == d.reminderMinutes && model.settings.weekdays == d.weekdays && model.settings.mode == d.mode && model.settings.snoozeMinutes == d.snoozeMinutes && model.settings.appearance == .dark && model.settings.minWords == 99)
    model.resetSettings(.page)
    check("Reset Page restores the words rule, template, headings, window and log start", model.settings.minWords == d.minWords && model.settings.template == d.template && model.settings.carryOverHeadings == d.carryOverHeadings && model.settings.catchUpWindowDays == d.catchUpWindowDays && model.settings.logStartDate == nil && model.settings.weekStart == 1)
    model.resetSettings(.general); pumpEvents(0.2)
    check("Reset General restores appearance, week start and the menu bar item (and the app stops being dark)", model.settings.appearance == .system && model.settings.weekStart == nil && model.showMenuBarItem && NSApp.appearance == nil)
    let before = model.settings
    model.resetSettings(.storage); model.resetSettings(.shortcuts); model.resetSettings(.about)
    check("Storage, Shortcuts and About have nothing to reset (the folder is never touched)", model.settings == before && model.settings.storageFolder == logs)

    // folder change keeps working (the empty-to-empty path needs no dialog; copy/move/conflict dialogs are unchanged code)
    let folderModel = AppModel(defaults: suite, backupDir: backups, live: false, clock: { now })
    var fs = folderModel.settings; fs.storageFolder = emptyDir; folderModel.settings = fs; folderModel.store = AppModel.makeStore(dir: emptyDir, backupDir: backups)
    folderModel.changeFolder(to: otherDir)
    check("changing to another folder switches the log folder and keeps it in the defaults",
          waitEvents(2.0) { folderModel.settings.storageFolder.standardizedFileURL.path == otherDir.standardizedFileURL.path }
          && AppModel(defaults: suite, backupDir: backups, live: false, clock: { now }).settings.storageFolder.standardizedFileURL.path == otherDir.standardizedFileURL.path)
    check("... and the logs in the old folder are untouched", ((try? FileManager.default.contentsOfDirectory(atPath: logs.path)) ?? []).filter { $0.hasSuffix(".md") }.count > 30)
    model.settings = { var d2 = Settings(); d2.storageFolder = logs; d2.onboarded = true; return d2 }()

    // ---- S4: onboarding: where Settings lives, log start for existing logs, run setup again changes nothing by itself
    func dayFiles(_ n: Int, in dir: URL) { for i in 0..<n { put("2026-09-\(String(format: "%02d", i + 10))", "# x\n\n\(words)\n", in: dir) } }
    let freshDir = base.appendingPathComponent("found-folder"); try? FileManager.default.createDirectory(at: freshDir, withIntermediateDirectories: true)
    dayFiles(3, in: freshDir); try? "not a day".write(to: freshDir.appendingPathComponent("notes.md"), atomically: false, encoding: .utf8)
    let probe = OnboardingState(Settings()); probe.choice = .custom; probe.customURL = freshDir; probe.refreshFound()
    check("onboarding finds existing day pages in a chosen folder (names only, others ignored)", probe.found == OnboardingState.FoundLogs(count: 3, first: "2026-09-10", last: "2026-09-12"), String(describing: probe.found))
    probe.customURL = emptyDir; probe.refreshFound()
    check("... and offers nothing for an empty folder", probe.found == nil && probe.logStart == nil)

    let first = OnboardingState(Settings())
    first.template = .standup; first.templateTouched = true; first.minutes = 18 * 60; first.mode = .gentle; first.minWords = 30
    first.choice = .custom; first.customURL = otherDir; first.found = .init(count: 3, first: "2026-09-10", last: "2026-09-12"); first.logStart = cal.date(from: DateComponents(year: 2026, month: 9, day: 11))
    let a = first.applied(to: Settings(), useDefaults: false, calendar: cal)
    check("first run: every answer applies (template, reminder, words, folder, log start) and setup is done",
          a.template == TemplatePreset.standup.markdown && a.reminderMinutes == 18 * 60 && a.mode == .gentle && a.minWords == 30 && a.storageFolder == otherDir && a.logStartDate == "2026-09-11" && a.onboarded)
    let skipped = first.applied(to: Settings(), useDefaults: true, calendar: cal)
    check("first run, Skip setup: only the template card and 'done' apply", skipped.reminderMinutes == Settings().reminderMinutes && skipped.storageFolder == Settings().storageFolder && skipped.logStartDate == nil && skipped.onboarded)

    var mine = Settings(); mine.onboarded = true; mine.template = "## My own\n\n## Template"; mine.carryOverHeadings = ["Mine"]
    mine.storageFolder = otherDir; mine.reminderMinutes = 17 * 60; mine.logStartDate = "2026-09-01"
    let again2 = OnboardingState(mine); again2.configure(from: mine, loginEnabled: false)
    check("run setup again: starts from the current settings (own template, current folder)", again2.rerun && again2.template == nil && again2.choice == .custom && again2.customURL == otherDir && again2.minutes == 17 * 60)
    check("run setup again, nothing edited: no setting changes at all", again2.applied(to: mine, useDefaults: false, calendar: cal) == mine && again2.applied(to: mine, useDefaults: true, calendar: cal) == mine)
    again2.minutes = 18 * 60
    let edited = again2.applied(to: mine, useDefaults: false, calendar: cal)
    check("run setup again, time edited: only the time changes (template, headings, folder, log start stay)", edited.reminderMinutes == 18 * 60 && edited.template == mine.template && edited.carryOverHeadings == mine.carryOverHeadings && edited.storageFolder == otherDir && edited.logStartDate == "2026-09-01")
    again2.template = .blank; again2.templateTouched = true
    check("... and a template card that is picked does apply", again2.applied(to: mine, useDefaults: false, calendar: cal).template == "")
    let preset = OnboardingState(Settings()); var withPreset = Settings(); withPreset.onboarded = true; withPreset.template = TemplatePreset.standup.markdown
    preset.configure(from: withPreset, loginEnabled: false)
    check("run setup again with a preset template: that card starts selected", preset.template == .standup)

    model.runSetupAgain()
    check("Settings > About 'Run setup again' puts the setup sheet up", model.sheet == .onboarding)
    model.sheet = nil

    // onboarding screenshots (first run with existing logs; run again)
    for dark in [false, true] {
        model.settings.appearance = dark ? .dark : .light; pumpEvents(0.4)
        let tag = dark ? "dark" : "light"
        let firstModel = AppModel(defaults: UserDefaults(suiteName: suiteName + ".first")!, backupDir: backups, live: false, clock: { now })
        let prepared = OnboardingState(Settings()); prepared.choice = .custom; prepared.customURL = freshDir; prepared.step = 3
        let firstWin = hostWindow(OnboardingView(model: firstModel, startStep: 3, state: prepared), width: 600, height: 520)
        pumpEvents(0.8)
        if let img = windowImage(firstWin) { savePNG(img, to: shots.appendingPathComponent("onboarding-existing-logs-\(tag).png")) }
        if !dark, recognitionWorks, let img = windowImage(firstWin), let obs = recognise(img) {
            let text = allText(obs)
            check("onboarding step 3 (as drawn) says where Settings lives and offers 'Log starts' for existing logs", text.contains("livesinsettings") && text.contains("logstarts") && text.contains("found3logs"), String(text.suffix(260)))
        }
        firstWin.orderOut(nil)
        let rerunWin = hostWindow(OnboardingView(model: model, startStep: 1), width: 600, height: 520)
        pumpEvents(0.8)
        if let img = windowImage(rerunWin) { savePNG(img, to: shots.appendingPathComponent("onboarding-run-again-\(tag).png")) }
        rerunWin.orderOut(nil)
    }

    // ---- wrap up: leave the process as the next scenario expects it
    model.settings.appearance = .system; pumpEvents(0.2)
    check("the app is left on the system appearance", NSApp.appearance == nil)
    w.orderOut(nil)
    for name in [suiteName, suiteName + ".first"] { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }
    print("   (settings scenarios done; screenshots in \(shots.path))")
    _ = now; now = now.addingTimeInterval(1)
}
