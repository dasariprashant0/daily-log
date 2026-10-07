// Scenarios.swift - the app layer (AppModel + DayEditor + LogStore) driving the REAL editor in a WKWebView, against a
// temporary storage folder. Checks the data-loss rules from docs/EDITOR_CONTRACT.md end to end.
import AppKit
import WebKit

private let appRoot = URL(fileURLWithPath: ProcessInfo.processInfo.environment["EC_TMP"] ?? NSTemporaryDirectory()).appendingPathComponent("dl-editor-check-app")
private let logsDir = appRoot.appendingPathComponent("logs")
private let backupsDir = appRoot.appendingPathComponent("backups")

private func fileText(_ day: String) -> String? { try? String(contentsOf: logsDir.appendingPathComponent(day + ".md"), encoding: .utf8) }
private func exists(_ day: String) -> Bool { FileManager.default.fileExists(atPath: logsDir.appendingPathComponent(day + ".md").path) }
private func write(_ day: String, _ text: String) { try? text.write(to: logsDir.appendingPathComponent(day + ".md"), atomically: false, encoding: .utf8) }
private func mtime(_ day: String) -> Date? {
    (try? FileManager.default.attributesOfItem(atPath: logsDir.appendingPathComponent(day + ".md").path))?[.modificationDate] as? Date
}

func runAppScenarios() {
    print("9. app layer (AppModel + real editor + LogStore)")
    try? FileManager.default.removeItem(at: appRoot)
    try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
    try? FileManager.default.createDirectory(at: backupsDir, withIntermediateDirectories: true)

    let yesterday = "# 2026-10-05\n\n## 📝 What I did\nReviewed the pricing page and wrote the summary for the Friday sync with the whole team today.\n\n## 📌 To do next\n* Review the copy with Ana\n* Ship the webinar page\n"
    let older = "# 2026-10-02\n\n## What I did\n\nFriday notes: finished the quarterly report, answered customer emails, and planned the next sprint with the team.\n"
    write("2026-10-05", yesterday); write("2026-10-02", older)

    let cal = Calendar.current
    var fakeNow = cal.date(from: DateComponents(year: 2026, month: 10, day: 6, hour: 10, minute: 0))!
    let suite = UserDefaults(suiteName: "dailylog.editorcheck")!
    suite.removePersistentDomain(forName: "dailylog.editorcheck")
    var s = Settings(); s.storageFolder = logsDir; s.onboarded = true; s.minWords = 20
    s.save(to: suite)
    let model = AppModel(defaults: suite, backupDir: backupsDir, live: true, clock: { fakeNow })
    let today = "2026-10-06"
    check("model starts on today with the template (not read from disk)", model.editor.day == today && model.editor.initialBody == Settings.defaultTemplate)

    model.start()
    let appWin = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 700), styleMask: [.titled, .resizable], backing: .buffered, defer: false)
    appWin.contentView = model.bridge.webView
    appWin.orderFrontRegardless()

    /// Types like a user: caret at the end of the last editable block; under a heading Enter first (a heading line is not writing).
    func typeText(_ t: String, enter: Bool = true) -> Bool {
        let script = """
        (function (t) {
          var v = document.querySelector('.ProseMirror'); v.focus();
          var blocks = v.querySelectorAll('h1,h2,h3,h4,h5,h6,p,li,pre,blockquote');
          var last = blocks.length ? blocks[blocks.length - 1] : v;
          var r = document.createRange(); r.selectNodeContents(last); r.collapse(false);
          var sel = window.getSelection(); sel.removeAllRanges(); sel.addRange(r);
          if (\(enter ? "true" : "false") && /^H[1-6]$/.test(last.tagName)) document.execCommand('insertParagraph');
          if (document.execCommand('insertText', false, t)) return 'exec';
          last.appendChild(document.createTextNode(t)); return 'dom';
        })(\(JS.literal(t)))
        """
        let how = (blocking { done in model.bridge.webView.evaluateJavaScript(script) { r, _ in done(r as? String ?? "none") } } ?? "none")
        if how != "exec" { print("   (typing used: \(how))") }
        return how != "none"
    }
    func dump(_ label: String) {
        let e = model.editor!
        print("   [\(label)] day=\(e.day) loaded=\(e.loaded) failed=\(e.loadFailed) skipped=\(e.isSkipped) anyway=\(e.writingAnyway) edited=\(e.userEdited) unsaved=\(e.hasUnsavedEdits) err=\(String(describing: e.errorText)) words=\(e.words) ready=\(model.bridge.isReady) swaps=\(model.bridge.swapsInFlight) folder=\(String(describing: model.folderProblem))")
    }
    func editorText() -> String? { blocking { (done: @escaping (String?) -> Void) in model.bridge.read(token: model.editor.token) { done($0) } } ?? nil }
    func settle(_ s: TimeInterval = 1.6) { spin(s) }          // 300 ms page debounce + 600 ms autosave + slack

    // -- merely opening a day writes nothing
    check("editor loads today's page", wait(25) { model.editor.loaded })
    guard model.editor.loaded else { print("   editor never loaded; stopping app scenarios"); return }
    settle(2.0)
    check("a page that was only opened is NOT created on disk", !exists(today))
    check("nothing is unsaved after merely opening", !model.editor.hasUnsavedEdits)
    check("template words are not counted", model.editor.words == 0)

    // -- the template's headings get empty lines to type under (not an edit), and the caret starts in the first one
    func evalBool(_ script: String) -> Bool { (blocking { (done: @escaping (Bool) -> Void) in model.bridge.webView.evaluateJavaScript(script) { r, _ in done((r as? Bool) ?? false) } }) ?? false }
    check("every template heading got an empty paragraph under it", evalBool("document.querySelectorAll('.ProseMirror > h2 + p').length === 5"))
    check("the empty lines are not part of the markdown (page text == baseline)", editorText() == model.editor.baselineMarkdown && !model.editor.hasUnsavedEdits)
    let selInfo = blocking { (done: @escaping (String) -> Void) in model.bridge.webView.evaluateJavaScript("(function(){ var s = window.getSelection(); var a = s.anchorNode; return (a ? (a.nodeName + ' in ' + (a.parentNode ? a.parentNode.nodeName : '?') + ' off=' + s.anchorOffset + ' text=' + JSON.stringify((a.textContent || '').slice(0, 20))) : 'none') + ' | active=' + (document.activeElement ? document.activeElement.className : 'none') + ' | docHasFocus=' + document.hasFocus(); })()") { r, _ in done((r as? String) ?? "nil") } } ?? "nil"
    if !evalBool("(function(){ var p = document.querySelector('.ProseMirror > h2 + p'); var a = window.getSelection().anchorNode; return !!p && !!a && p.contains(a); })()") { print("   selection: \(selInfo)") }
    check("the caret starts in the first line under the first heading", evalBool("(function(){ var p = document.querySelector('.ProseMirror > h2 + p'); var a = window.getSelection().anchorNode; return !!p && !!a && p.contains(a); })()"))
    check("... and opening the page still wrote nothing", !exists(today))
    _ = evalBool("(function(){ var p = document.querySelector('.ProseMirror > h2 + p'); var r = document.createRange(); r.selectNodeContents(p); r.collapse(true); var s = window.getSelection(); s.removeAllRanges(); s.addRange(r); return document.execCommand('insertText', false, 'Typed straight under the first heading.'); })()")
    check("typing under the first heading becomes body text of that heading", wait(6) { exists(today) } && (fileText(today) ?? "").contains("## What I did\n\nTyped straight under the first heading.\n\n## Finished"), fileText(today) ?? "none")
    // reset: today's file goes away so the scenarios below start from the same state as before
    try? FileManager.default.removeItem(at: logsDir.appendingPathComponent(today + ".md"))
    model.reload(); model.openDay(today, force: true)
    check("today reopens as a fresh template page", wait(8) { model.editor.loaded && model.editor.initialBody == Settings.defaultTemplate })
    settle(1.0)

    // -- the first real edit creates the file, template included
    check("typing reaches the editor", typeText("Wrote the first notes of the day, covering standup, the review of the pricing page, two customer calls, and the sprint planning with the team."))
    check("the first edit creates today's file", wait(6) { exists(today) })
    let t1 = fileText(today) ?? ""
    check("file has the title, the template and the typed text", t1.hasPrefix("# 2026-10-06\n\n") && t1.contains("## What I did") && t1.contains("first notes"), t1)
    check("today is now logged by words (>= 20)", wait(3) { model.states[today] == .logged }, "\(String(describing: model.states[today])) words=\(model.editor.words)")
    check("sidebar/streak data updated without a full reload", model.streak.current >= 1)

    // -- switching days saves the old page and never writes the new one
    let yMtime = mtime("2026-10-05")
    let yBytes = fileText("2026-10-05")
    _ = typeText(" And a late addition typed right before switching.")
    model.openDay("2026-10-05")                          // immediately: inside the page's 300 ms debounce
    check("yesterday's page loads", wait(8) { model.editor.day == "2026-10-05" && model.editor.loaded })
    check("a late edit made just before the switch was saved to the OLD day", wait(4) { (fileText(today) ?? "").contains("late addition") }, fileText(today) ?? "")
    settle(2.0)
    check("opening yesterday did not rewrite its file (v0.2 formatting untouched)", fileText("2026-10-05") == yBytes && mtime("2026-10-05") == yMtime)
    check("the editor shows yesterday's text, not today's", (editorText() ?? "").contains("Review the copy with Ana") && !(editorText() ?? "").contains("late addition"))
    check("no cross-day leak: today's file has none of yesterday's words", !(fileText(today) ?? "").contains("Ship the webinar"))

    // -- a user edit on a past v0.2 page is saved to THAT day only
    check("typing on a past day", typeText(" Added a note afterwards."))
    check("the edit lands in that day's file (and a backup of the old text exists)", wait(6) { (fileText("2026-10-05") ?? "").contains("Added a note afterwards") })
    check("a safety copy of the previous text was made", model.store.listBackups(day: "2026-10-05").count >= 1 && (try? String(contentsOf: model.store.listBackups(day: "2026-10-05")[0].url, encoding: .utf8)) == yesterday)
    check("today's file did not change", !(fileText(today) ?? "").contains("afterwards"))

    // -- a page with no file and no net change is never created; touching only a heading is still an edit
    model.openDay("2026-10-04")
    check("an empty day opens with the template", wait(8) { model.editor.day == "2026-10-04" && model.editor.loaded } && model.editor.initialBody == Settings.defaultTemplate)
    let pristine = model.editor.baselineMarkdown
    model.editor.userChanged(pristine + "\nsomething typed")      // an edit event ...
    model.editor.userChanged(pristine)                              // ... and the user deletes it again before it is saved
    check("typed-then-deleted (no net change) is not an unsaved edit", !model.editor.hasUnsavedEdits)
    settle(1.5)
    check("... and creates no file", !exists("2026-10-04"))
    check("changing only a heading is a real edit and is saved", typeText(" (outline)", enter: false) && wait(6) { exists("2026-10-04") })
    check("the saved outline keeps the template", (fileText("2026-10-04") ?? "").contains("## What I did") && (fileText("2026-10-04") ?? "").contains("(outline)"))

    // -- emptying a page is allowed only as a user edit, and it is backed up first
    model.openDay("2026-10-02")
    check("older page loads", wait(8) { model.editor.day == "2026-10-02" && model.editor.loaded })
    settle(1.0)
    let beforeDelete = fileText("2026-10-02")
    _ = blocking { (done: @escaping (Bool) -> Void) in model.bridge.webView.evaluateJavaScript("(function(){ var v = document.querySelector('.ProseMirror'); v.focus(); document.execCommand('selectAll'); return document.execCommand('delete'); })()") { r, _ in done(r as? Bool ?? false) } }
    let removed = wait(6) { !exists("2026-10-02") }
    if !removed { dump("after select-all + delete"); print("   editor md: \(String(reflecting: editorText() ?? "nil"))") }
    check("user empties the page -> file removed", removed)
    check("the emptied page's text is in a backup", model.store.listBackups(day: "2026-10-02").contains { (try? String(contentsOf: $0.url, encoding: .utf8)) == beforeDelete })

    // -- external change: quiet reload when nothing is unsaved
    model.openDay("2026-10-05")
    check("reopen yesterday", wait(8) { model.editor.day == "2026-10-05" && model.editor.loaded })
    settle(0.5)
    write("2026-10-05", "# 2026-10-05\n\nChanged on another Mac with enough words to be a perfectly normal page of notes for the day.\n")
    model.editor.checkExternalChange()
    check("external change with no unsaved edits reloads quietly", wait(5) { (editorText() ?? "").contains("Changed on another Mac") })
    check("no notice was shown", !model.editor.externalNotice)
    // with unsaved edits: our version is kept, a notice is shown
    _ = typeText(" Local edit.")
    write("2026-10-05", "# 2026-10-05\n\nChanged AGAIN elsewhere, a second external version of the page for the same day.\n")
    spin(0.5)                                            // page debounce (300 ms) has fired: the edit is known, not yet saved
    model.editor.checkExternalChange()
    check("external change WITH unsaved edits keeps ours and shows a notice", model.editor.externalNotice && (editorText() ?? "").contains("Local edit"))
    check("our version wins at the next autosave", wait(6) { (fileText("2026-10-05") ?? "").contains("Local edit") })
    check("the other version was backed up", model.store.listBackups(day: "2026-10-05").contains { (try? String(contentsOf: $0.url, encoding: .utf8))?.contains("Changed AGAIN") == true })

    // -- carry-over (From yesterday) on today's page
    write("2026-10-05", yesterday)                       // restore a clean yesterday for the card
    model.openDay(today)
    check("today reopens with its saved text", wait(8) { model.editor.day == today && model.editor.loaded } && (editorText() ?? "").contains("first notes"))
    model.refreshCarry()
    check("From yesterday offers the two carry headings' lines", model.carryCard?.items == ["Review the copy with Ana", "Ship the webinar page"], "\(String(describing: model.carryCard?.items))")
    check("the strip is available before carrying", model.carryAvailable)
    let before = editorText()
    model.carryOver()
    check("carry-over inserts '## Carried over from' + tasks at the TOP", wait(5) { (editorText() ?? "").hasPrefix("## Carried over from Mon 5 Oct") })
    check("carried tasks are saved", wait(6) { (fileText(today) ?? "").contains("- [ ] Review the copy with Ana") })
    check("strip hides once applied, undo is offered", wait(2) { !model.carryAvailable } && model.carryUndoBody != nil)
    model.undoCarry()
    check("undo restores the previous text", wait(5) { editorText() == before })
    check("... and saves it", wait(6) { !(fileText(today) ?? "").contains("Carried over from") })

    // -- skip refuses a page with writing, accepts an empty day
    var skipResult: SkipFailure?? = .none
    model.skip(day: today, through: nil, reason: "Holiday") { skipResult = .some($0) }
    check("skip refuses a day that has writing", wait(5) { skipResult != nil } && skipResult! != nil)
    var skip2: SkipFailure?? = .none
    model.skip(day: "2026-10-03", through: nil, reason: "Weekend trip") { skip2 = .some($0) }
    check("skip accepts an empty day", wait(5) { skip2 != nil } && skip2! == nil && (fileText("2026-10-03") ?? "").contains("> Skipped: Weekend trip"))
    model.openDay("2026-10-03")
    check("skipped page shows no editor and does not load one", wait(5) { model.editor.day == "2026-10-03" } && model.editor.isSkipped && !model.editor.showsEditor)
    _ = typeText("must not land anywhere")
    spin(1.5)
    check("typing into the (hidden) editor while a skipped page is open writes nothing", (fileText("2026-10-03") ?? "").contains("> Skipped") && !(fileText("2026-10-03") ?? "").contains("must not land"))
    model.startWritingAnyway()
    check("'Write a log anyway' loads the template, still not written", wait(5) { model.editor.loaded } && (fileText("2026-10-03") ?? "").contains("> Skipped"))
    check("typing replaces the skip marker", typeText("Worked from the road after all, wrote up the notes from the customer visit in detail.") && wait(6) { !(fileText("2026-10-03") ?? "").contains("> Skipped") && (fileText("2026-10-03") ?? "").contains("customer visit") })

    // -- unwritable folder: nothing lost, retry works, quit asks
    model.openDay(today)
    let backOnToday = wait(8) { model.editor.day == today && model.editor.loaded }
    if !backOnToday { dump("back on today") }
    check("back on today", backOnToday)
    try? FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: logsDir.path)
    _ = typeText(" Unsaved while the folder is read-only.")
    check("save fails visibly, the text stays in the editor", wait(6) { model.editor.errorText != nil } && (editorText() ?? "").contains("read-only"))
    check("the page knows it has unsaved edits", model.editor.hasUnsavedEdits)
    var quitSaved: Bool?
    model.flushForQuit { quitSaved = $0 }
    check("quit flush reports the text is NOT saved (so the app can ask)", wait(5) { quitSaved != nil } && quitSaved == false)
    try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: logsDir.path)
    model.retryFolder()
    check("after the folder is back, retry writes the text", wait(6) { (fileText(today) ?? "").contains("read-only") } && model.editor.errorText == nil)

    // -- quit flush with a very recent edit
    _ = typeText(" Last words before quitting.")
    var quit2: Bool?
    model.flushForQuit { quit2 = $0 }
    check("quit flush saves an edit made a moment ago", wait(5) { quit2 != nil } && quit2 == true && (fileText(today) ?? "").contains("Last words before quitting"))

    // -- leaving a page whose text cannot be written must not throw that text away
    model.openDay(today)
    check("back on today again", wait(8) { model.editor.day == today && model.editor.loaded })
    try? FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: logsDir.path)
    _ = typeText(" Orphan text typed while the folder is read-only.")
    spin(0.5)
    model.openDay("2026-10-05")                                  // leave at once: the write on the way out fails
    spin(1.0)
    check("the page that could not be saved is kept (orphan) with its text", wait(8) { model.orphans.count == 1 && model.orphans[0].day == today && model.orphans[0].hasUnsavedEdits })
    var quitOrphan: Bool?
    model.flushForQuit { quitOrphan = $0 }
    check("quit would ask: an orphan is still unsaved", wait(5) { quitOrphan != nil } && quitOrphan == false)
    try? FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: logsDir.path)
    model.retryFolder()
    check("once the folder is back the orphan is written and released", wait(6) { (fileText(today) ?? "").contains("Orphan text typed") && model.orphans.isEmpty })

    // -- the template follows settings only while a page is untouched
    model.openDay("2026-10-01")
    check("a fresh day opens (template)", wait(8) { model.editor.day == "2026-10-01" && model.editor.loaded } && (editorText() ?? "").contains("## What I did"))
    var st = model.settings; st.template = TemplatePreset.standup.markdown; model.settings = st
    check("changing the template reloads an untouched page", wait(8) { (editorText() ?? "").contains("## Yesterday") && model.editor.loaded })
    model.openDay(today)
    check("today (with writing) reopens", wait(8) { model.editor.day == today && model.editor.loaded })
    st = model.settings; st.template = Settings.defaultTemplate; model.settings = st
    spin(1.2)
    check("changing the template never touches a page with writing", (editorText() ?? "").contains("Orphan text typed") && !(editorText() ?? "").contains("## Blockers"))

    // -- the words rule is read from settings
    check("today counts as logged at 20 words", model.status(of: today) == .logged)
    st = model.settings; st.minWords = 500; model.settings = st
    check("raising the rule to 500 words makes today partial (streak/heatmap/reminder follow)", wait(4) { model.status(of: today) == .partial })
    st = model.settings; st.minWords = 20; model.settings = st
    check("... and back", wait(4) { model.status(of: today) == .logged })

    // -- search opens the day and selects the match
    model.searchText = "customer visit"
    check("search finds a saved page", wait(6) { model.selection == .search && !model.searchHits.isEmpty && model.searchHits[0].day == "2026-10-03" }, "\(model.searchHits.map { $0.day })")
    if let hit = model.searchHits.first {
        model.open(hit: hit)
        check("opening a hit loads that day", wait(8) { model.editor.day == hit.day && model.editor.loaded })
        spin(0.8)
        let sel = (blocking { (done: @escaping (String) -> Void) in model.bridge.webView.evaluateJavaScript("window.getSelection().toString()") { r, _ in done((r as? String) ?? "") } } ?? "").lowercased()
        check("... and selects the matched text in the page", sel.contains("customer visit") || sel.contains("customer"), sel)
    }

    // -- the weekly review sees what was typed a moment ago
    model.openDay(today)
    check("today again", wait(8) { model.editor.day == today && model.editor.loaded })
    _ = typeText(" Weekly flush marker.")
    model.select(.week)
    check("the weekly review includes text typed just before opening it", wait(6) { (model.week?.days.contains { $0.doc?.body.contains("Weekly flush marker") == true }) == true })

    // -- a file created elsewhere for an untouched open page is picked up quietly
    model.openDay("2026-09-30")
    check("an untouched day is open", wait(8) { model.editor.day == "2026-09-30" && model.editor.loaded })
    write("2026-09-30", "# 2026-09-30\n\nWritten on another Mac while this page sat open and untouched, with plenty of words in it.\n")
    model.editor.checkExternalChange()
    check("the new file replaces the untouched template quietly", wait(6) { (editorText() ?? "").contains("another Mac") } && !model.editor.externalNotice)

    // -- restore a previous version
    model.openDay(today)
    check("today is open again before restoring", wait(8) { model.editor.day == today && model.editor.loaded })
    let versions = model.backups(for: today)
    check("today has previous versions", !versions.isEmpty)
    if let v = versions.last {
        var restored: String?? = .none
        model.restore(v, day: today) { restored = .some($0) }
        check("restore succeeds", wait(6) { restored != nil } && restored! == nil, "\(String(describing: restored))")
        check("restored page is shown and matches the restored file", wait(6) { model.editor.loaded && model.editor.day == today }
              && MarkdownBody.words(in: editorText() ?? "") == MarkdownBody.words(in: ((try? model.store.load(today)) ?? nil)?.body ?? ""))
    }

    print("   (app scenarios done)")
    _ = fakeNow; fakeNow = fakeNow.addingTimeInterval(1)
}
