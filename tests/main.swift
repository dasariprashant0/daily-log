// Tiny assert-based runner (no XCTest). Run with tests/run-tests.sh.
import Foundation

var passed = 0, failed = 0
var currentTest = ""
func test(_ name: String, _ body: () throws -> Void) {
    currentTest = name
    do { try body() } catch { failed += 1; print("FAIL [\(name)] threw \(error)") }
}
func expect(_ cond: @autoclosure () throws -> Bool, _ msg: String = "", line: Int = #line) rethrows {
    if try cond() { passed += 1 } else { failed += 1; print("FAIL [\(currentTest)] line \(line) \(msg)") }
}

// MARK: helpers
var cal = Calendar(identifier: .gregorian)
cal.timeZone = TimeZone(identifier: "America/New_York")!
cal.firstWeekday = 2
func mk(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ mi: Int = 0) -> Date {
    cal.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: mi))!
}
let tmpBase = URL(fileURLWithPath: ProcessInfo.processInfo.environment["TMPDIR"] ?? NSTemporaryDirectory(), isDirectory: true)
let root = tmpBase.appendingPathComponent("dl-tests-\(UUID().uuidString)")
try! FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
func freshDir(_ name: String) -> URL {
    let u = root.appendingPathComponent(name); try! FileManager.default.createDirectory(at: u, withIntermediateDirectories: true); return u
}
func full(_ day: String, _ fill: String = "did stuff") -> DayEntry {
    var e = DayEntry(date: day)
    for s in DefaultSections.all { e.texts[s.id] = fill }
    e.refreshStatus(sections: DefaultSections.all); return e
}
let workdays: Set<Int> = [2, 3, 4, 5, 6]
// 2026-10-05 is a Monday.

// MARK: models / markdown
test("v0.1 file loads and round-trips byte-for-byte") {
    let dir = freshDir("v01"); let store = LogStore(dir: dir)
    var v01 = "# 2026-10-05\n\n"
    let bodies = ["did": "Wrote code", "finished": "Shipped it", "started": "Docs", "pending": "Waiting on Ana", "todo": "Review PR"]
    for s in DefaultSections.all { v01 += "## \(s.title)\n\(bodies[s.id]!)\n\n" }
    try v01.write(to: dir.appendingPathComponent("2026-10-05.md"), atomically: true, encoding: .utf8)
    let e = try store.load("2026-10-05")!
    expect(e.texts["did"] == "Wrote code" && e.texts["todo"] == "Review PR" && e.texts.count == 5)
    expect(e.status == .logged && e.extras.isEmpty)
    try store.save(e)
    try expect(try String(contentsOf: dir.appendingPathComponent("2026-10-05.md")) == v01, "round trip identical")
    expect(DefaultSections.all.map { $0.title } == ["📝 What I did", "✅ Finished", "🚀 Started", "⏳ Pending / blocked", "📌 To do next"])
}
test("'## ' lines in user text are escaped and never split a section") {
    let dir = freshDir("esc"); let store = LogStore(dir: dir)
    var e = full("2026-10-05")
    let nasty = "intro\n## Fake heading\n\\## already slashed\n\\\\## two\n  ## indented ok"
    e.texts["did"] = nasty
    try store.save(e)
    let raw = try String(contentsOf: dir.appendingPathComponent("2026-10-05.md"))
    let headings = raw.components(separatedBy: "\n").filter { $0.hasPrefix("## ") }
    expect(headings.count == 5, "only real headings, got \(headings.count)")
    let back = try store.load("2026-10-05")!
    expect(back.texts["did"] == nasty, "unescaped on load")
    expect(back.extras.isEmpty && back.texts["finished"] == "did stuff")
    expect(MarkdownFormat.unescape(MarkdownFormat.escape("## a\n\\## b")) == "## a\n\\## b")
}
test("unknown headings preserved; CRLF tolerated") {
    let dir = freshDir("unk"); let store = LogStore(dir: dir)
    try "# 2026-10-05\r\n\r\n## ✅ Finished\r\nA\r\n\r\n## Random notes\r\nkeep me\r\n".write(to: dir.appendingPathComponent("2026-10-05.md"), atomically: true, encoding: .utf8)
    var e = try store.load("2026-10-05")!
    expect(e.texts["finished"] == "A" && e.extras == [ExtraSection(title: "Random notes", text: "keep me")])
    expect(e.status == .logged, "sections absent from file do not un-log")
    e.texts["finished"] = "B"; try store.save(e)
    let raw = try String(contentsOf: dir.appendingPathComponent("2026-10-05.md"))
    expect(raw.contains("## Random notes\nkeep me") && raw.contains("## ✅ Finished\nB"))
}
test("status: logged / partial / non-required empty") {
    var e = full("2026-10-05"); expect(e.status == .logged)
    e.texts["started"] = ""; e.refreshStatus(sections: DefaultSections.all); expect(e.status == .partial)
    var secs = DefaultSections.all; secs[2].required = false
    e.refreshStatus(sections: secs); expect(e.status == .logged, "optional empty tolerated")
    expect(DayEntry(date: "2026-10-05").status == .partial)
}
test("section validation") {
    expect(SectionDef.validationError(DefaultSections.all) == nil)
    expect(SectionDef.validationError([]) != nil)
    expect(SectionDef.validationError([SectionDef(title: "a"), SectionDef(title: "A")]) != nil, "dupe case-insens")
    expect(SectionDef.validationError([SectionDef(title: "#x")]) != nil)
    expect(SectionDef.validationError([SectionDef(title: String(repeating: "x", count: 41))]) != nil)
    expect(SectionDef.validationError((0..<11).map { SectionDef(title: "s\($0)") }) != nil)
}
test("custom sections keep stable ids across rename") {
    let dir = freshDir("custom")
    let a = SectionDef(id: "A", title: "Wins"), b = SectionDef(id: "B", title: "Blockers")
    let store = LogStore(dir: dir, sections: [a, b])
    var e = DayEntry(date: "2026-10-05", texts: ["A": "w", "B": "b"]); e.refreshStatus(sections: store.sections)
    try store.save(e)
    try expect(try store.load("2026-10-05")!.texts["B"] == "b")
    store.sections = [a, SectionDef(id: "B", title: "Stuck")]
    let l = try store.load("2026-10-05")!
    expect(l.texts["A"] == "w" && l.extras.map { $0.title } == ["Blockers"], "old title kept as unknown heading, not lost")
}

// MARK: store: skip, folder errors
test("skip / unskip / skip range") {
    let dir = freshDir("skip"); let store = LogStore(dir: dir)
    try store.skip("2026-10-06", reason: "Holiday")
    let raw = try String(contentsOf: dir.appendingPathComponent("2026-10-06.md"))
    expect(raw.contains("> Skipped: Holiday"))
    let e = try store.load("2026-10-06")!
    expect(e.isSkipped && e.skipReason == "Holiday" && e.status == .skipped)
    try store.skip("2026-10-07")
    try expect(try String(contentsOf: dir.appendingPathComponent("2026-10-07.md")).contains("> Skipped\n"))
    try expect(try store.load("2026-10-07")!.skipReason == "")
    try expect(try store.unskip("2026-10-06") && (try store.load("2026-10-06")) == nil)
    try expect(try store.unskip("2026-10-06") == false)
    // logged day is protected
    try store.save(full("2026-10-08"))
    do { try store.skip("2026-10-08"); expect(false, "should throw") } catch { expect(error as? LogError == .hasContent("2026-10-08")) }
    try expect(try store.unskip("2026-10-08") == false, "unskip never deletes a log")
    // range: Mon 12 .. Sun 18 Oct, one file per scheduled day
    let w = try store.skipRange(from: "2026-10-12", to: "2026-10-18", reason: "Leave", weekdays: workdays, calendar: cal)
    expect(w == ["2026-10-12", "2026-10-13", "2026-10-14", "2026-10-15", "2026-10-16"], "\(w)")
    try expect(try store.load("2026-10-17") == nil)
    // range skips days that already have a log
    try store.save(full("2026-10-21"))
    let w2 = try store.skipRange(from: "2026-10-20", to: "2026-10-22", weekdays: workdays, calendar: cal)
    expect(w2 == ["2026-10-20", "2026-10-22"])
    // "write a log anyway" replaces the marker
    try store.save(full("2026-10-20")); try expect(try store.load("2026-10-20")!.status == .logged)
}
test("missing and unwritable folders give typed errors; atomic write leaves no temp files") {
    let missing = LogStore(dir: root.appendingPathComponent("nope"))
    do { try missing.save(full("2026-10-05")); expect(false) } catch { expect(error as? LogError == .folderMissing(missing.dir.path)) }
    do { _ = try missing.listDays(); expect(false) } catch { expect(error as? LogError == .folderMissing(missing.dir.path)) }
    try missing.ensureFolder()
    try missing.save(full("2026-10-05"))
    try expect(try FileManager.default.contentsOfDirectory(atPath: missing.dir.path) == ["2026-10-05.md"])
    let ro = freshDir("ro"); let rs = LogStore(dir: ro)
    try rs.save(full("2026-10-05"))
    try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: ro.path)
    do { try rs.save(full("2026-10-06")); expect(false, "should throw") } catch { expect(error as? LogError == .folderNotWritable(ro.path), "\(error)") }
    do { try rs.skip("2026-10-07"); expect(false) } catch { expect(error as? LogError == .folderNotWritable(ro.path)) }
    try expect(try rs.load("2026-10-05") != nil, "still readable")
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: ro.path)
    do { try rs.save(full("../evil")); expect(false) } catch { expect(error as? LogError == .badDay("../evil")) }
}
test("listDays, folderSummary ignore foreign files") {
    let dir = freshDir("list"); let store = LogStore(dir: dir)
    try store.save(full("2026-10-05")); try store.skip("2026-10-06", reason: "x")
    try "hi".write(to: dir.appendingPathComponent("notes.md"), atomically: true, encoding: .utf8)
    try "hi".write(to: dir.appendingPathComponent("2026-10-0x.md"), atomically: true, encoding: .utf8)
    try expect(try store.listDays() == ["2026-10-06", "2026-10-05"])
    try expect(try store.folderSummary() == FolderSummary(logs: 1, skipped: 1, unrecognized: 2))
    try expect(try store.fileStates() == ["2026-10-05": .logged, "2026-10-06": .skipped])
}

// MARK: settings
test("settings round trip, tolerant decode, normalize") {
    let ms = MemoryStore()
    expect(Settings.load(from: ms) == Settings(), "defaults when empty")
    var s = Settings()
    s.mode = .gentle; s.reminderMinutes = 17 * 60; s.weekdays = [2, 4]; s.snoozeMinutes = 30
    s.storageFolder = URL(fileURLWithPath: "/tmp/x"); s.onboarded = true; s.launchAtLogin = false
    s.sections = [SectionDef(id: "z", title: "Z")]; s.carryOverSectionID = "z"
    s.save(to: ms)
    expect(Settings.load(from: ms) == s)
    ms.setData("{\"mode\":\"gentle\"}".data(using: .utf8), forKey: Settings.storageKey)
    let t = Settings.load(from: ms)
    expect(t.mode == .gentle && t.reminderMinutes == 16 * 60 + 55 && t.weekdays == workdays && t.sections == DefaultSections.all)
    ms.setData("garbage".data(using: .utf8), forKey: Settings.storageKey)
    expect(Settings.load(from: ms) == Settings())
    var bad = Settings(); bad.weekdays = []; bad.snoozeMinutes = 7; bad.reminderMinutes = 5000; bad.sections = []
    let n = bad.normalized()
    expect(n.weekdays == workdays && n.snoozeMinutes == 15 && n.reminderMinutes == 1439 && n.sections == DefaultSections.all)
    let ud = UserDefaults(suiteName: "dailylog.tests.\(UUID().uuidString)")!
    s.save(to: ud); expect(Settings.load(from: ud) == s, "UserDefaults conforms")
    expect(Settings().mode == .strict, "Strict is default")
}

// MARK: drafts
test("drafts save/load/clear, stored apart from logs") {
    let dd = freshDir("drafts"); let ds = DraftStore(dir: dd.appendingPathComponent("sub/drafts"))
    let t = mk(2026, 10, 5, 16, 0)
    expect(ds.load("2026-10-05") == nil)
    try ds.save(day: "2026-10-05", texts: ["did": "half a thou", "todo": ""], now: t)
    let d = ds.load("2026-10-05")!
    expect(d.texts["did"] == "half a thou" && d.savedAt == t && d.day == "2026-10-05")
    try ds.save(day: "2026-10-06", texts: ["did": "x"], now: t)
    expect(ds.days() == ["2026-10-06", "2026-10-05"])
    try ds.save(day: "2026-10-05", texts: ["did": "  "], now: t); expect(ds.load("2026-10-05") == nil, "all-empty clears")
    ds.clear("2026-10-06"); expect(ds.days().isEmpty)
    do { try ds.save(day: "../x", texts: ["a": "b"], now: t); expect(false) } catch { expect(error as? LogError == .badDay("../x")) }
    // unwritable drafts folder does not crash and reports an error
    expect(DraftStore.defaultDir.path.hasSuffix("Library/Application Support/Daily Log/drafts"))
}

// MARK: streak + heatmap
func states(_ pairs: [(String, DayStatus)]) -> [String: DayStatus] { Dictionary(uniqueKeysWithValues: pairs) }
test("streak across weekend, skip and miss") {
    let mon12 = mk(2026, 10, 12, 9)  // Monday, nothing logged yet today
    let l: DayStatus = .logged
    var s = states([("2026-10-05", l), ("2026-10-06", l), ("2026-10-07", l), ("2026-10-08", l), ("2026-10-09", l)])
    expect(Streak.compute(states: s, now: mon12, calendar: cal, weekdays: workdays) == StreakResult(current: 5, best: 5), "weekend neutral, today not yet")
    s["2026-10-12"] = l
    expect(Streak.compute(states: s, now: mon12, calendar: cal, weekdays: workdays).current == 6, "today logged +1")
    s["2026-10-12"] = nil; s["2026-10-07"] = .skipped
    expect(Streak.compute(states: s, now: mon12, calendar: cal, weekdays: workdays).current == 4, "skip neutral")
    s["2026-10-07"] = nil
    expect(Streak.compute(states: s, now: mon12, calendar: cal, weekdays: workdays) == StreakResult(current: 2, best: 2), "miss breaks")
    s["2026-10-07"] = .partial
    expect(Streak.compute(states: s, now: mon12, calendar: cal, weekdays: workdays).current == 2, "partial past day breaks")
    s["2026-10-07"] = l; s["2026-10-10"] = l  // Saturday extra effort
    expect(Streak.compute(states: s, now: mon12, calendar: cal, weekdays: workdays).current == 6, "non-scheduled log +1")
    // today is Tuesday unlogged, Monday missed -> broken
    s["2026-10-12"] = nil
    expect(Streak.compute(states: s, now: mk(2026, 10, 13, 9), calendar: cal, weekdays: workdays).current == 0, "yesterday missed")
    expect(Streak.compute(states: [:], now: mon12, calendar: cal, weekdays: workdays) == StreakResult(current: 0, best: 0))
    // schedule change re-evaluates: Friday off
    let noFri: Set<Int> = [2, 3, 4, 5]
    let t = states([("2026-10-05", l), ("2026-10-06", l), ("2026-10-07", l), ("2026-10-08", l)])
    expect(Streak.compute(states: t, now: mon12, calendar: cal, weekdays: noFri).current == 4)
    expect(Streak.compute(states: t, now: mon12, calendar: cal, weekdays: workdays).current == 0, "Fri 9 missed under Mon-Fri")
    // best survives a later break
    let b = states([("2026-10-05", l), ("2026-10-06", l), ("2026-10-07", l), ("2026-10-09", l)])
    expect(Streak.compute(states: b, now: mon12, calendar: cal, weekdays: workdays) == StreakResult(current: 1, best: 3))
}
test("heatmap: 12 weeks, statuses, today ring") {
    let now = mk(2026, 10, 7, 10)  // Wed
    let st = states([("2026-10-05", .logged), ("2026-10-06", .skipped), ("2026-09-30", .partial)])
    let hm = Heatmap.weeks(states: st, now: now, calendar: cal, weekdays: workdays)
    expect(hm.count == 12 && hm.allSatisfy { $0.count == 7 })
    let last = hm.last!
    expect(last.map { $0.day } == ["2026-10-05", "2026-10-06", "2026-10-07", "2026-10-08", "2026-10-09", "2026-10-10", "2026-10-11"], "week starts Monday")
    expect(last.map { $0.status } == [.logged, .skipped, .missed, .future, .future, .future, .future])
    expect(last.map { $0.isToday } == [false, false, true, false, false, false, false])
    expect(hm[10][2].status == .partial && hm[10][5].status == .off, "Saturday off")
    expect(hm[0][0].status == .off, "before first entry is not 'missed'")
    expect(hm[10][3].status == .missed || hm[10][3].day == "2026-10-01", "after first entry, empty workday is missed")
    expect(hm[10][3].status == .missed)
}
test("DST: day keys, heatmap and streak across fall-back and spring-forward") {
    // Fall back 2026-11-01 (25h day), spring forward 2026-03-08 (23h day) in New York.
    expect(DayKey.string(mk(2026, 11, 1, 23, 30), cal) == "2026-11-01")
    expect(DayKey.adding("2026-11-01", 1, cal) == "2026-11-02" && DayKey.adding("2026-03-08", 1, cal) == "2026-03-09")
    expect(DayKey.adding("2026-11-02", -1, cal) == "2026-11-01" && DayKey.adding("2026-03-09", -1, cal) == "2026-03-08")
    expect(DayKey.date("2026-02-30", cal) == nil && DayKey.date("2026-03-08", cal) != nil)
    for now in [mk(2026, 11, 3, 10), mk(2026, 3, 10, 10)] {
        let hm = Heatmap.weeks(states: ["2026-10-01": .logged], now: now, calendar: cal, weekdays: workdays).flatMap { $0 }
        expect(hm.count == 84 && Set(hm.map { $0.day }).count == 84, "unique days")
        var ok = true
        for i in 1..<hm.count where DayKey.adding(hm[i - 1].day, 1, cal) != hm[i].day { ok = false }
        expect(ok, "consecutive across DST")
    }
    let every: Set<Int> = Set(1...7)
    let s = states([("2026-10-30", .logged), ("2026-10-31", .logged), ("2026-11-01", .logged), ("2026-11-02", .logged)])
    expect(Streak.compute(states: s, now: mk(2026, 11, 2, 18), calendar: cal, weekdays: every).current == 4, "streak over the 25h day")
    let s2 = states([("2026-03-07", .logged), ("2026-03-08", .logged), ("2026-03-09", .logged)])
    expect(Streak.compute(states: s2, now: mk(2026, 3, 9, 18), calendar: cal, weekdays: every).current == 3, "streak over the 23h day")
    // reminder uses wall-clock minutes on the DST day
    var st = Settings(); st.weekdays = every
    let r = ReminderPlanner.decide(now: mk(2026, 11, 1, 17, 0), calendar: cal, settings: st, todayStatus: .missed,
                                   state: PlannerState(day: "2026-11-01"), windowVisible: true)
    expect(r.0 == .bringToFront(notify: true), "17:00 wall clock on fall-back day")
}

// MARK: reminder planner
let monDay = "2026-10-05"
func at(_ h: Int, _ m: Int, day: Int = 5) -> Date { mk(2026, 10, day, h, m) }
func D(_ now: Date, _ s: Settings, _ st: DayStatus, _ state: PlannerState, win: Bool = true) -> (ReminderAction, PlannerState) {
    ReminderPlanner.decide(now: now, calendar: cal, settings: s, todayStatus: st, state: state, windowVisible: win)
}
test("planner: not due / ineligible days") {
    let s = Settings()
    let fresh = PlannerState(day: monDay)
    expect(D(at(16, 54), s, .missed, fresh).0 == .none, "before reminder")
    expect(D(at(17, 0), s, .logged, fresh).0 == .none, "already logged")
    expect(D(at(17, 0), s, .skipped, fresh).0 == .none, "skipped today")
    expect(D(at(17, 0, day: 10), s, .off, PlannerState(day: "2026-10-10")).0 == .none, "Saturday")
    expect(D(at(17, 0, day: 10), s, .missed, PlannerState(day: "2026-10-10")).0 == .none, "Saturday even if status says unlogged")
    expect(D(at(17, 0), s, .future, fresh).0 == .none)
    expect(D(at(17, 0), s, .partial, fresh).0 == .bringToFront(notify: true), "partial still nags")
    var tue = s; tue.weekdays = [3]
    expect(D(at(17, 0), tue, .missed, fresh).0 == .none, "Monday not scheduled")
}
test("planner: strict first fire, re-open every 5 min, skip hint, 23:00 cutoff") {
    let s = Settings()
    var (a, st) = D(at(16, 55), s, .missed, PlannerState(day: monDay))
    expect(a == .bringToFront(notify: true) && st.firstFired)
    (a, st) = D(at(16, 56), s, .missed, st, win: true); expect(a == .none, "visible: leave alone")
    (a, st) = D(at(17, 0), s, .missed, st, win: false); expect(a == .none, "just closed: start 5 min wait")
    (a, st) = D(at(17, 4), s, .missed, st, win: false); expect(a == .none)
    (a, st) = D(at(17, 5), s, .missed, st, win: false); expect(a == .reopen && st.reopenCount == 1)
    (a, st) = D(at(17, 6), s, .missed, st, win: false); expect(a == .none, "closed again, wait")
    (a, st) = D(at(17, 11), s, .missed, st, win: false); expect(a == .reopen && st.reopenCount == 2 && !st.showSkipHint)
    (a, st) = D(at(17, 12), s, .missed, st, win: false)
    (a, st) = D(at(17, 17), s, .missed, st, win: false); expect(a == .reopen && st.reopenCount == 3 && st.showSkipHint)
    (a, st) = D(at(22, 59), s, .missed, st, win: false); (a, st) = D(at(23, 0), s, .missed, st, win: false)
    expect(a == .none, "23:00 cutoff")
    (a, _) = D(at(23, 30), s, .missed, st, win: false); expect(a == .none)
    expect(D(at(23, 5), s, .missed, PlannerState(day: monDay)).0 == .none, "woke after cutoff: no first fire")
    expect(D(at(22, 59), s, .missed, PlannerState(day: monDay)).0 == .bringToFront(notify: true), "woke at 22:59 fires")
}
test("planner: strict snooze (max 2) then re-fire without second notification") {
    let s = Settings()
    var (_, st) = D(at(16, 55), s, .missed, PlannerState(day: monDay))
    expect(ReminderPlanner.snoozesLeft(state: st, settings: s) == 2)
    st = ReminderPlanner.snooze(state: st, now: at(17, 0), settings: s, calendar: cal)!
    expect(st.snoozedUntil == at(17, 15) && ReminderPlanner.snoozesLeft(state: st, settings: s) == 1)
    var a = D(at(17, 10), s, .missed, st, win: false).0; expect(a == .none, "silent during snooze, even with window closed")
    (a, st) = D(at(17, 15), s, .missed, st, win: false); expect(a == .bringToFront(notify: false), "re-fire quietly")
    st = ReminderPlanner.snooze(state: st, now: at(17, 16), settings: s, calendar: cal)!
    expect(ReminderPlanner.snoozesLeft(state: st, settings: s) == 0)
    expect(ReminderPlanner.snooze(state: st, now: at(17, 40), settings: s, calendar: cal) == nil, "third snooze refused")
    (a, st) = D(at(17, 31), s, .missed, st, win: true); expect(a == .bringToFront(notify: false))
    // snooze runs past 23:00 -> nothing
    var late = PlannerState(day: monDay); late.firstFired = true; late.snoozedUntil = at(23, 10)
    expect(D(at(23, 11), s, .missed, late).0 == .none)
    // snooze length follows settings
    var s30 = s; s30.snoozeMinutes = 30
    expect(ReminderPlanner.snooze(state: PlannerState(day: monDay), now: at(17, 0), settings: s30, calendar: cal)!.snoozedUntil == at(17, 30))
}
test("planner: gentle never forces, notifies once, unlimited snooze") {
    var g = Settings(); g.mode = .gentle
    var (a, st) = D(at(16, 55), g, .missed, PlannerState(day: monDay), win: false)
    expect(a == .notify)
    for m in [0, 5, 30, 59] { expect(D(at(17, m), g, .missed, st, win: false).0 == .none, "no repeats / re-opens") }
    expect(ReminderPlanner.snoozesLeft(state: st, settings: g) == nil)
    for i in 0..<5 { st = ReminderPlanner.snooze(state: st, now: at(17, i), settings: g, calendar: cal)! }
    expect(st.snoozesUsed == 0, "no counter in gentle")
    (a, st) = D(at(17, 20), g, .missed, st); expect(a == .notify, "notification again after snooze")
    expect(D(at(17, 21), g, .missed, st).0 == .none)
}
test("planner: launched after reminder time, laptop asleep, settings/undo grace, day rollover") {
    let s = Settings()
    var st = PlannerState.atLaunch(previous: nil, now: at(18, 0), calendar: cal)
    var a = D(at(18, 0), s, .missed, st).0; expect(a == .none, "2 min grace after launch")
    a = D(at(18, 1), s, .missed, st).0; expect(a == .none)
    (a, st) = D(at(18, 2), s, .missed, st); expect(a == .bringToFront(notify: true), "fires once grace is over")
    // asleep through 16:55, wakes 20:10
    expect(D(at(20, 10), s, .missed, PlannerState(day: monDay)).0 == .bringToFront(notify: true))
    // wakes after a snooze elapsed during sleep
    var sn = PlannerState(day: monDay); sn.firstFired = true; sn.snoozedUntil = at(17, 15)
    expect(D(at(19, 0), s, .missed, sn).0 == .bringToFront(notify: false))
    // settings change / undo skip suppress
    let sup = PlannerState(day: monDay).suppressed(until: at(17, 1).addingTimeInterval(ReminderPlanner.graceAfterSettingsChange - 60 + 60))
    expect(D(at(17, 0), s, .missed, sup).0 == .none && D(at(17, 2), s, .missed, sup).0 != .none)
    // snooze count survives relaunch the same day, not the next
    var used = PlannerState(day: monDay); used.snoozesUsed = 2
    expect(PlannerState.atLaunch(previous: used, now: at(18, 0), calendar: cal).snoozesUsed == 2)
    expect(PlannerState.atLaunch(previous: used, now: at(9, 0, day: 6), calendar: cal).snoozesUsed == 0)
    // yesterday's state resets on a new day
    var old = PlannerState(day: monDay); old.firstFired = true; old.snoozesUsed = 2; old.reopenCount = 5
    let (a2, n) = D(at(17, 0, day: 6), s, .missed, old)
    expect(a2 == .bringToFront(notify: true) && n.snoozesUsed == 0 && n.reopenCount == 0 && n.day == "2026-10-06")
}
test("planner: isPending and state is Codable") {
    let s = Settings()
    expect(ReminderPlanner.isPending(now: at(17, 0), calendar: cal, settings: s, todayStatus: .missed))
    expect(!ReminderPlanner.isPending(now: at(10, 0), calendar: cal, settings: s, todayStatus: .missed))
    expect(!ReminderPlanner.isPending(now: at(17, 0), calendar: cal, settings: s, todayStatus: .logged))
    expect(!ReminderPlanner.isPending(now: at(17, 0, day: 10), calendar: cal, settings: s, todayStatus: .off))
    var st = PlannerState(day: monDay); st.snoozedUntil = at(17, 15); st.reopenCount = 2
    try expect(try JSONDecoder().decode(PlannerState.self, from: JSONEncoder().encode(st)) == st)
}

// MARK: weekly review
func weekFixture() throws -> (WeekSummary, LogStore) {
    let dir = freshDir("week-\(UUID().uuidString)"); let store = LogStore(dir: dir)
    var mon = full("2026-10-05", "mon work"); mon.texts["finished"] = "Shipped A\nand B"; mon.texts["todo"] = "Plan Q4"
    var tue = full("2026-10-06", "tue work"); tue.texts["finished"] = "Shipped C"; tue.texts["pending"] = "Waiting on legal"
    try store.save(mon); try store.save(tue)
    try store.skip("2026-10-07", reason: "Holiday")
    try store.save(full("2026-10-08", "thu")); try store.save(full("2026-10-09", "fri"))
    try store.save(full("2026-09-30", "outside week"))
    let ent = try store.entries(from: "2026-10-05", to: "2026-10-11")
    let w = WeeklyReview.summary(weekContaining: mk(2026, 10, 7), entries: ent, states: try store.fileStates(),
                                 settings: Settings(), calendar: cal, now: mk(2026, 10, 11, 20))
    return (w, store)
}
test("weekly review aggregate") {
    let (w, _) = try weekFixture()
    expect(w.weekStart == "2026-10-05" && w.weekEnd == "2026-10-11" && w.days.count == 7)
    expect(w.loggedCount == 4 && w.workdayCount == 5 && w.skippedCount == 1)
    expect(w.items(forSection: "finished").map { $0.day } == ["2026-10-05", "2026-10-06", "2026-10-08", "2026-10-09"])
    expect(w.items(forSection: "pending").map { $0.text } == ["mon work", "Waiting on legal", "thu", "fri"])
    expect(w.items(forSection: "todo").first?.text == "Plan Q4")
    expect(w.days[2].status == .skipped && w.days[5].status == .off)
    let mid = WeeklyReview.summary(weekContaining: mk(2026, 10, 6), entries: [:], states: ["2026-10-05": .logged],
                                   settings: Settings(), calendar: cal, now: mk(2026, 10, 6, 9))
    expect(mid.workdayCount == 2, "future days are not workdays yet")
    expect(WeeklyReview.shift(mk(2026, 10, 7), weeks: -1, calendar: cal) == mk(2026, 9, 30))
}
test("weekly review markdown (day + section grouping)") {
    let (w, _) = try weekFixture()
    let day = WeeklyReview.markdown(for: w, grouping: .day, sections: DefaultSections.all, calendar: cal)
    expect(day.hasPrefix("# Week of 5 Oct – 11 Oct 2026\n\nLogged 4 of 5 workdays · 1 skipped\n"), day)
    expect(day.contains("## Mon 5 Oct\n\n### 📝 What I did\nmon work"))
    expect(day.contains("## Wed 7 Oct\n_Skipped: Holiday_"))
    expect(day.contains("### ✅ Finished\nShipped A\nand B"))
    expect(!day.contains("Sat 10 Oct") && !day.contains("outside week"))
    let sec = WeeklyReview.markdown(for: w, grouping: .section, sections: DefaultSections.all, calendar: cal)
    expect(sec.contains("## ✅ Finished\n\n- **Mon 5 Oct**: Shipped A\n  and B\n- **Tue 6 Oct**: Shipped C"), sec)
    expect(sec.contains("- **Tue 6 Oct**: Waiting on legal\n- **Thu 8 Oct**: thu"))
    expect(!sec.contains("Skipped"))
    let empty = WeeklyReview.summary(weekContaining: mk(2026, 10, 7), entries: [:], states: [:], settings: Settings(), calendar: cal, now: mk(2026, 10, 7))
    let em = WeeklyReview.markdown(for: empty, grouping: .day, sections: DefaultSections.all, calendar: cal)
    expect(em.contains("Logged 0 of 3 workdays") && !em.contains("##"), em)
}

// MARK: carry-over
test("carry-over card, prefill, dedupe, targets") {
    let dir = freshDir("carry"); let store = LogStore(dir: dir)
    var fri = full("2026-10-02", "x"); fri.texts["todo"] = "Call Ana\nFix build"; fri.texts["pending"] = "- Legal review"
    try store.save(fri)
    try store.skip("2026-10-05", reason: "Holiday")
    let load: (String) -> DayEntry? = { (try? store.load($0)) ?? nil }
    let card = CarryOver.card(before: "2026-10-06", calendar: cal, load: load)
    expect(card?.sourceDay == "2026-10-02", "skips the skipped day, finds Friday")
    expect(card?.sourceLabel == "Fri 2 Oct" && card?.todo == "Call Ana\nFix build" && card?.pending == "- Legal review")
    expect(CarryOver.heading(for: card!, today: "2026-10-06", calendar: cal) == "Friday")
    expect(CarryOver.heading(for: card!, today: "2026-10-03", calendar: cal) == "Yesterday")
    expect(CarryOver.heading(for: card!, today: "2026-10-12", calendar: cal) == "2 Oct 2026")
    let pre = CarryOver.prefill(card!)
    expect(pre == "(from Fri 2 Oct)\n- Call Ana\n- Fix build\n- Legal review", pre)
    let added = CarryOver.apply(card!, to: "- Call Ana\nmy own line")
    expect(added == "- Call Ana\nmy own line\n\n(from Fri 2 Oct)\n- Fix build\n- Legal review", added)
    expect(CarryOver.apply(card!, to: pre) == pre, "idempotent")
    expect(CarryOver.card(before: "2026-10-02", calendar: cal, load: load) == nil, "nothing logged before")
    var st = Settings()
    expect(CarryOver.targetSectionID(st) == "pending", "default Pending")
    st.carryOverSectionID = "todo"; expect(CarryOver.targetSectionID(st) == "todo")
    st.carryOverSectionID = "gone"; expect(CarryOver.targetSectionID(st) == "did", "falls back to first section")
    var empty = full("2026-10-07", "x"); empty.texts["todo"] = ""; empty.texts["pending"] = " "
    store.sections = DefaultSections.all.map { var d = $0; if d.id == "todo" || d.id == "pending" { d.required = false }; return d }
    try store.save(empty)
    try expect(try store.load("2026-10-07")?.status == .logged)
    expect(CarryOver.card(before: "2026-10-08", calendar: cal, load: load) == nil, "no card when nothing to carry")
}

// MARK: search
test("search: case/diacritic-insensitive, AND words, section filter, snippet") {
    let dir = freshDir("search"); let store = LogStore(dir: dir)
    var a = full("2026-10-05", "nothing"); a.texts["did"] = "Drafted the Pricing page copy at the Café with Ana"; a.texts["todo"] = "review PRICING page with Ana"
    var b = full("2026-10-06", "nothing"); b.texts["finished"] = "Pricing only"
    try store.save(a); try store.save(b); try store.skip("2026-10-07", reason: "pricing holiday")
    var hits = try store.search("pricing")
    expect(hits.count == 3, "\(hits.count)")
    expect(hits.map { $0.day } == ["2026-10-06", "2026-10-05", "2026-10-05"], "newest day first")
    expect(hits[1].sectionID == "did" && hits[1].sectionTitle == "📝 What I did" && hits[2].sectionID == "todo")
    let h = hits[1]
    expect(h.matchRange.map { String(h.snippet[$0]) } == "Pricing", "matchRange points at the match")
    try expect(try store.search("CAFE ana").count == 1, "diacritic-insensitive, AND")
    try expect(try store.search("pricing zebra").isEmpty)
    try expect(try store.search("   ").isEmpty)
    hits = try store.search("pricing", sectionID: "todo"); expect(hits.count == 1 && hits[0].sectionID == "todo")
    var long = full("2026-10-08", "n"); long.texts["did"] = String(repeating: "word ", count: 60) + "needle" + String(repeating: " tail", count: 60)
    try store.save(long)
    let lh = try store.search("needle")[0]
    expect(lh.snippet.hasPrefix("…") && lh.snippet.hasSuffix("…") && lh.snippet.count < 140 && lh.snippet.contains("needle"))
    try "# 2026-10-09\n\n## Misc\nneedle in unknown heading\n".write(to: dir.appendingPathComponent("2026-10-09.md"), atomically: true, encoding: .utf8)
    try expect(try store.search("needle").contains { $0.day == "2026-10-09" && $0.sectionID == nil && $0.sectionTitle == "Misc" })
}

// MARK: end to end through real files
test("store -> fileStates -> streak/heatmap/status agree") {
    let dir = freshDir("e2e"); let store = LogStore(dir: dir)
    for d in ["2026-10-05", "2026-10-06", "2026-10-08", "2026-10-09"] { try store.save(full(d)) }
    try store.skip("2026-10-07", reason: "x")
    var part = full("2026-10-12"); part.texts["did"] = ""; try store.save(part)
    let st = try store.fileStates()
    let now = mk(2026, 10, 12, 18)
    expect(st["2026-10-12"] == .partial)
    expect(Streak.compute(states: st, now: now, calendar: cal, weekdays: workdays) == StreakResult(current: 4, best: 4), "partial today is 'not yet'")
    expect(Status.resolve(day: "2026-10-12", fileState: st["2026-10-12"], now: now, calendar: cal, weekdays: workdays, since: "2026-10-05") == .partial)
    expect(Status.resolve(day: "2026-10-13", fileState: nil, now: now, calendar: cal, weekdays: workdays, since: "2026-10-05") == .future)
    expect(Status.resolve(day: "2026-10-10", fileState: nil, now: now, calendar: cal, weekdays: workdays, since: "2026-10-05") == .off)
    expect(Status.resolve(day: "2026-10-02", fileState: nil, now: now, calendar: cal, weekdays: workdays, since: "2026-10-05") == .off)
}

try? FileManager.default.removeItem(at: root)
print("\(passed) passed, \(failed) failed")
exit(failed == 0 ? 0 : 1)
