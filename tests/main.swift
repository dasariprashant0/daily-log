// Tiny assert-based runner (no XCTest). Run with tests/run-tests.sh (outside the Bash sandbox: atomic writes need the system temp dir).
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
    let u = root.appendingPathComponent(name + "-" + UUID().uuidString.prefix(6))
    try! FileManager.default.createDirectory(at: u, withIntermediateDirectories: true); return u
}
func freshStore(_ name: String) -> LogStore { LogStore(dir: freshDir(name)) }
/// n words: "w1 w2 ... wn" ("" for 0)
func lorem(_ n: Int, _ prefix: String = "w") -> String { n <= 0 ? "" : (1...n).map { "\(prefix)\($0)" }.joined(separator: " ") }
func raw(_ s: String, in dir: URL, day: String) throws { try s.write(to: dir.appendingPathComponent(day + ".md"), atomically: true, encoding: .utf8) }
func fileText(_ dir: URL, _ day: String) throws -> String { try String(contentsOf: dir.appendingPathComponent(day + ".md"), encoding: .utf8) }
let workdays: Set<Int> = [2, 3, 4, 5, 6]
let pngBytes = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 1, 2, 3, 4])
// 2026-10-05 is a Monday.
func W(_ s: String) -> Int { MarkdownBody.words(in: s) }

// MARK: word counting
test("words: basics, headings, list/task markers, quotes") {
    expect(W("") == 0 && W("  \n\n ") == 0)
    expect(W("Hello world") == 2)
    expect(W("# Title\n## What I did\nwrote code") == 2, "heading lines are ignored")
    expect(W("#tag stays") == 2, "#tag is not a heading")
    expect(W("####### seven") == 1, "7 hashes is not a heading; the hashes are not a word")
    expect(W("## Done ##\n###### six\nreal words") == 2, "closing hashes, level 6")
    expect(W("   ### three spaces\ntext") == 1, "up to 3 leading spaces is still a heading")
    expect(W("    ### four spaces is not a heading") == 6)
    expect(W("-\n- \n* [ ]\n- [x]\n1.\n- [ ] \n+ [X]\n2) [ ]\n[ ]") == 0, "empty list/task markers")
    expect(W("- [ ] Call Ana") == 2 && W("- [x] done thing") == 2 && W("  - [ ] sub task") == 2)
    expect(W("1. First thing\n2) second thing") == 4 && W("* star item") == 2)
    expect(W("**bold** text") == 2 && W("-5 degrees") == 2, "not list markers")
    expect(W("> quoted words here") == 3 && W("> - [ ] task") == 1 && W(">> nested quote") == 2)
    expect(W("a\u{00A0}b\tc") == 3 && W("one two\r\nthree") == 3, "NBSP, tab, CRLF")
    expect(W("don't can't") == 2 && W("https://example.com/a/b") == 1 && W("v1.2.3 shipped") == 2 && W("2026-10-06") == 1)
    expect(W("---\n***\n___\n— – -") == 0, "rules and dashes are not words")
    expect(W("| a | b |\n|---|---|\n| c | d |") == 4, "tables")
    expect(W("[two words](http://x.com)") == 2 && W("<https://example.com>") == 1)
}
test("words: code fences") {
    expect(W("```swift\nlet x = 1\n```") == 3, "fence lines ignored, code between them counts")
    expect(W("~~~\ncode here\n~~~\nafter") == 3)
    expect(W("```\n# not heading\n```") == 2, "headings do not exist inside code")
    expect(W("````\n```\ntext\n````") == 1, "a shorter fence does not close a longer one")
    expect(W("```\none two") == 2, "unclosed fence runs to the end")
    expect(W("`a b`") == 2 && W("```\n```") == 0)
}
test("words: images, html, comments") {
    expect(W("![diagram](assets/2026-10-06-1a2b3c4d.png)") == 0)
    expect(W("see ![a b](x.png) here") == 2 && W("![a](x.png \"title text\")") == 0)
    expect(W("![ref image][r1] words") == 1 && W("- ![](a.png)") == 0)
    expect(W("<img src=\"a.png\" alt=\"x y\">") == 0 && W("<br>") == 0 && W("text<br>more") == 2)
    expect(W("<!-- hidden words here -->") == 0 && W("visible <!-- hidden --> text") == 2)
    expect(W("start\n<!--\nsecret one two\n-->\nend") == 2, "multi-line comment")
    expect(W("a b <!-- c d") == 2, "unterminated comment hides the rest")
    expect(W("<!-- a\nb --> tail words") == 2 && W("## Title <!-- note -->\nbody") == 1)
    expect(W("```\n<!-- x y -->\n```") == 2, "comments are literal inside code")
}
test("words: emoji and non-Latin text") {
    expect(W("Done ✅ 🎉") == 1 && W("🎉🎉🎉") == 0 && W("✅") == 0 && W("Shipped🚀") == 1 && W("👍 great job 👍") == 2)
    expect(W("👨‍👩‍👧") == 0, "ZWJ sequence is not a word")
    expect(W("Сегодня я закончил отчёт") == 4, "Cyrillic")
    expect(W("اليوم أنهيت التقرير") == 3 && W("היום סיימתי את הדוח") == 4, "Arabic, Hebrew")
    expect(W("आज मैंने रिपोर्ट पूरी की") == 5, "Devanagari")
    expect(W("오늘 보고서를 완료했다") == 3, "Hangul uses spaces")
    expect(W("今天完成了报告") == 4, "CJK run of 7 chars = 4 words (ceil(n/2))")
    expect(W("完成 报告") == 2 && W("Q4完成") == 2 && W("hello世界") == 2 && W("完成，报告。") == 2)
    expect(W("ありがとう") == 3 && W("コーヒーを飲んだ") == 4)
    expect(W("วันนี้ทำงานเสร็จ") == 1, "Thai: one word per space-delimited chunk (documented limit)")
}
test("hasContent / DayDocument.status boundaries") {
    expect(!MarkdownBody.hasContent("") && !MarkdownBody.hasContent("## A\n\n## B") && !MarkdownBody.hasContent("- [ ]\n"))
    expect(!MarkdownBody.hasContent("<!-- c -->") && !MarkdownBody.hasContent("```\n```"))
    expect(MarkdownBody.hasContent("![](assets/x.png)"), "an image alone is content")
    expect(MarkdownBody.hasContent("- [ ] x") && MarkdownBody.hasContent("---"))
    expect(DayDocument(day: "2026-10-05", body: lorem(19)).status(minWords: 20) == .partial)
    expect(DayDocument(day: "2026-10-05", body: lorem(20)).status(minWords: 20) == .logged)
    expect(DayDocument(day: "2026-10-05", body: Settings.defaultTemplate).status(minWords: 20) == .missed, "template alone is no log")
    expect(DayDocument(day: "2026-10-05", body: Settings.defaultTemplate + "\n\n" + lorem(3)).words == 3)
    expect(DayDocument(day: "2026-10-05", body: "![](a.png)").status(minWords: 1) == .missed)
    expect(DayDocument(day: "2026-10-05", isSkipped: true, skipReason: "x").status(minWords: 1) == .skipped)
    expect(DayDocument(day: "2026-10-05", body: lorem(1)).status(minWords: 0) == .logged, "minWords below 1 behaves as 1")
}

// MARK: headings and sections
test("normalizeHeading") {
    let n = MarkdownBody.normalizeHeading
    expect(n("📝 What I did") == "what i did" && n("⏳ Pending / blocked") == "pending blocked")
    expect(n("Pending / blocked") == n("⏳ Pending / blocked") && n("📌 To do next") == n("To do next"))
    expect(n("  To-Do   Next!! ") == "to do next" && n("Pending/blocked") == "pending blocked")
    expect(n("Q&A") == "q a" && n("Café ☕") == "café" && n("Привет, мир!") == "привет мир")
    expect(n("1️⃣ First") == "1 first" && n("हिंदी") == "हिंदी" && n("🙂") == "" && n("") == "")
}
test("sections(of:) levels, nesting, fences, edge headings") {
    let body = "intro line\n\n## 📝 What I did\ntext A\n#tag line\n\n### Sub\nsub text\n\n```\n## not heading\n```\n\n## Finished\n"
    let s = MarkdownBody.sections(of: body)
    expect(s.map { $0.level } == [0, 2, 3, 2])
    expect(s.map { $0.title } == ["", "📝 What I did", "Sub", "Finished"])
    expect(s.map { $0.normalizedTitle } == ["", "what i did", "sub", "finished"])
    expect(s[0].text == "intro line" && s[1].text == "text A\n#tag line")
    expect(s[2].text == "sub text\n\n```\n## not heading\n```" && s[3].text == "")
    let e = MarkdownBody.sections(of: "## Title ##\n##\n   ## three\n    ## four spaces\n## C#\n####### x\nSetext\n======")
    expect(e.map { $0.title } == ["Title", "", "three", "C#"], "\(e.map { $0.title })")
    expect(e[2].text == "## four spaces", "4 leading spaces is text, not a heading")
    expect(e[3].text == "####### x\nSetext\n======", "7 hashes and setext underlines are plain text")
    expect(MarkdownBody.sections(of: "").isEmpty && MarkdownBody.sections(of: "\n\n").isEmpty)
    expect(MarkdownBody.headings(inTemplate: Settings.defaultTemplate) == ["What I did", "Finished", "Started", "Pending / blocked", "To do next"])
    expect(MarkdownBody.headings(inTemplate: "## A\n### a\n# 🅰 A\n## B") == ["A", "B"], "de-duplicated by normalised title")
}
test("trimBody, shiftHeadings, pruneEmptySections, partition") {
    expect(MarkdownBody.trimBody("\n\n  indented\nline  \n\n") == "  indented\nline" && MarkdownBody.trimBody("a\r\nb\r\n") == "a\nb")
    expect(MarkdownBody.shiftHeadings(in: "# Big\n## Small\ntext", minLevel: 3) == "### Big\n#### Small\ntext")
    expect(MarkdownBody.shiftHeadings(in: "### a\n#### b", minLevel: 3) == "### a\n#### b")
    expect(MarkdownBody.shiftHeadings(in: "# a\n###### b", minLevel: 3) == "### a\n###### b", "capped at 6")
    expect(MarkdownBody.shiftHeadings(in: "no headings <!-- c -->", minLevel: 3) == "no headings")
    expect(MarkdownBody.pruneEmptySections("## A\n\n## B\ntext\n\n## C\n- [ ]\n\n## D\n### E\n### F\nstuff") == "## B\ntext\n\n## D\n### F\nstuff")
    expect(MarkdownBody.pruneEmptySections(Settings.defaultTemplate) == "")
    let body = "pre text\n## Finished\nA\n### Sub\nB\n## Misc\nC\n## finished\nD\n#### Deep\nE"
    let p = MarkdownBody.partition(body, headings: ["finished"])
    expect(p.matched.map { $0.index } == [0, 0] && p.matched[0].text == "A\n\n**Sub**\nB" && p.matched[1].text == "D\n\n**Deep**\nE")
    expect(p.other == "pre text\n\n**Misc**\nC", p.other)
    expect(MarkdownBody.partition(body, headings: ["finished"], subheadings: .drop).matched[0].text == "A\n\nB")
}

// MARK: day file format and old files
test("v0.1/v0.2 files load as plain markdown; re-save is stable") {
    let store = freshStore("old")
    var v02 = "# 2026-10-05\n\n"
    for (t, b) in [("📝 What I did", "Wrote code"), ("✅ Finished", "Shipped it"), ("🚀 Started", "Docs"),
                   ("⏳ Pending / blocked", "Waiting on Ana"), ("📌 To do next", "Review PR")] { v02 += "## \(t)\n\(b)\n\n" }
    try raw(v02, in: store.dir, day: "2026-10-05")
    let d = try store.load("2026-10-05")!
    expect(d.body.hasPrefix("## 📝 What I did\nWrote code\n\n## ✅ Finished") && d.body.hasSuffix("## 📌 To do next\nReview PR"))
    expect(!d.body.contains("# 2026-10-05") && !d.isSkipped)
    expect(d.words == 10 && d.status(minWords: 20) == .partial && d.status(minWords: 10) == .logged)
    try store.save(day: "2026-10-05", body: d.body)
    let once = try fileText(store.dir, "2026-10-05")
    expect(once.hasPrefix("# 2026-10-05\n\n## 📝 What I did\nWrote code") && once.hasSuffix("Review PR\n"))
    try store.save(day: "2026-10-05", body: try store.load("2026-10-05")!.body)
    try expect(try fileText(store.dir, "2026-10-05") == once, "save(load(x)) is a fixed point")
    expect(MarkdownBody.sections(of: d.body).map { $0.normalizedTitle } == ["what i did", "finished", "started", "pending blocked", "to do next"])
}
test("old '\\## ' escapes unescape on load, outside code") {
    let store = freshStore("esc")
    try raw("# 2026-10-05\n\n## 📝 What I did\nline\n\\## fake\n\\\\## two\n  \\## indented stays\n\n```\n\\## code stays\n```\n", in: store.dir, day: "2026-10-05")
    let d = try store.load("2026-10-05")!
    let lines = d.body.components(separatedBy: "\n")
    expect(lines.contains("## fake") && lines.contains("\\## two") && lines.contains("  \\## indented stays") && lines.contains("\\## code stays"), "\(lines)")
}
test("file format: title, BOM, CRLF, skip markers, serialize") {
    let store = freshStore("fmt")
    func load(_ s: String) throws -> DayDocument { try raw(s, in: store.dir, day: "2026-10-05"); return try store.load("2026-10-05")! }
    try expect(try load("# 2026-10-05\n\nbody").body == "body")
    try expect(try load("body only").body == "body only" && (try load("\n\n# 2026-10-05\n\n\nbody\n\n\n").body == "body"))
    try expect(try load("# 2026-01-01\n\nbody").body == "body", "any date title is stripped")
    try expect(try load("# 2026-10-05 retro\n\nbody").body == "# 2026-10-05 retro\n\nbody", "a title with text is content")
    try expect(try load("# My plan\n\nbody").body == "# My plan\n\nbody")
    try expect(try load("\u{FEFF}# 2026-10-05\r\n\r\nline one\r\nline two\r\n").body == "line one\nline two")
    try expect(try load("# 2026-10-05\n\n> Skipped: Holiday\n").isSkipped && (try load("# 2026-10-05\n\n> Skipped: Holiday\n").skipReason == "Holiday"))
    try expect(try load("# 2026-10-05\n\n> Skipped\n\n\n").skipReason == "" && (try load("# 2026-10-05\n\n> Skipped\n").isSkipped))
    try expect(try load("# 2026-10-05\n\n> Skipped the meeting\n").isSkipped == false, "no colon: ordinary quote")
    try expect(try load("# 2026-10-05\n\n> Skipped: x\nmore text\n").isSkipped == false, "marker must be the only content")
    try expect(try load("# 2026-10-05\n\n> Skipped: Holiday\n").body == "", "skipped day has no body")
    expect(MarkdownFormat.serialize(day: "2026-10-05", body: "\n\nhello\n\n") == "# 2026-10-05\n\nhello\n")
    expect(MarkdownFormat.serializeSkip(day: "2026-10-05", reason: " a\nb ") == "# 2026-10-05\n\n> Skipped: a b\n")
    expect(MarkdownFormat.serializeSkip(day: "2026-10-05", reason: "") == "# 2026-10-05\n\n> Skipped\n")
}

// MARK: store
test("save/load: no escaping, unicode, images, idempotent, date-like first line") {
    let store = freshStore("rt")
    let body = "intro\n## Real heading\ntext\n\\## literal slash stays\n\n![](assets/2026-10-05-1a2b3c4d.png)\n\n- [ ] 今天完成 ✅ café"
    try store.save(day: "2026-10-05", body: body)
    try expect(try fileText(store.dir, "2026-10-05") == "# 2026-10-05\n\n" + body + "\n", "written verbatim, nothing is escaped")
    try expect(try store.load("2026-10-05")!.body.contains("\n## literal slash stays\n"), "documented trade-off: old-style escapes are undone on load")
    let b2 = "intro\n## Real heading\ntext\n\n![](assets/2026-10-05-1a2b3c4d.png)\n\n- [ ] 今天完成 ✅ café"
    try store.save(day: "2026-10-06", body: b2)
    try expect(try store.load("2026-10-06")!.body == b2)
    try expect(try fileText(store.dir, "2026-10-06").contains("\n## Real heading\n"), "headings are not escaped")
    try store.save(day: "2026-10-07", body: "# 2026-10-07\ntext under a date heading")
    try expect(try store.load("2026-10-07")!.body == "# 2026-10-07\ntext under a date heading", "only the first title line is stripped")
    for b in ["\n\nlead blank", "trail  \n\n", "  indented first", "a\r\nb"] {
        try store.save(day: "2026-10-08", body: b)
        let l = try store.load("2026-10-08")!.body
        expect(l == MarkdownBody.trimBody(b))
        try store.save(day: "2026-10-08", body: l)
        try expect(try store.load("2026-10-08")!.body == l)
    }
}
test("an emptied page is no log; empty save never creates a file or touches a skip marker") {
    let store = freshStore("empty")
    try store.save(day: "2026-10-05", body: "  \n \n")
    try expect(try store.listDays().isEmpty && (try store.load("2026-10-05")) == nil, "no file for an empty page")
    try store.save(day: "2026-10-05", body: "hello there")
    try expect(try store.listDays() == ["2026-10-05"])
    try store.save(day: "2026-10-05", body: "\n")
    try expect(try store.listDays().isEmpty, "emptied page removes the file")
    try store.skip("2026-10-06", reason: "Holiday")
    try store.save(day: "2026-10-06", body: "")
    try expect(try store.load("2026-10-06")!.isSkipped, "empty save keeps the skip marker")
    try store.save(day: "2026-10-06", body: "I worked anyway today")
    let d = try store.load("2026-10-06")!
    expect(!d.isSkipped && d.body == "I worked anyway today", "write a log anyway replaces the marker")
}
test("skip / unskip / skip range") {
    let store = freshStore("skip"); let dir = store.dir
    try store.skip("2026-10-06", reason: "Holiday")
    try expect(try fileText(dir, "2026-10-06").contains("> Skipped: Holiday"))
    let e = try store.load("2026-10-06")!
    expect(e.isSkipped && e.skipReason == "Holiday" && e.status(minWords: 20) == .skipped)
    try store.skip("2026-10-07")
    try expect(try fileText(dir, "2026-10-07").contains("> Skipped\n") && (try store.load("2026-10-07")!.skipReason == ""))
    try store.skip("2026-10-06", reason: "Leave")
    try expect(try store.load("2026-10-06")!.skipReason == "Leave", "re-skipping updates the reason")
    try expect(try store.unskip("2026-10-06") && (try store.load("2026-10-06")) == nil)
    try expect(try store.unskip("2026-10-06") == false)
    try store.save(day: "2026-10-08", body: lorem(30))
    do { try store.skip("2026-10-08"); expect(false, "should throw") } catch { expect(error as? LogError == .hasContent("2026-10-08")) }
    try expect(try store.unskip("2026-10-08") == false, "unskip never deletes a log")
    try store.save(day: "2026-10-09", body: "## What I did\n\n## Finished")
    try store.skip("2026-10-09", reason: "headings only")
    try expect(try store.load("2026-10-09")!.isSkipped, "a heading-only page may be skipped")
    try store.save(day: "2026-10-10", body: "![](assets/x.png)")
    do { try store.skip("2026-10-10"); expect(false, "an image is content") } catch { expect(error as? LogError == .hasContent("2026-10-10")) }
    let w = try store.skipRange(from: "2026-10-12", to: "2026-10-18", reason: "Leave", weekdays: workdays, calendar: cal)
    expect(w == ["2026-10-12", "2026-10-13", "2026-10-14", "2026-10-15", "2026-10-16"], "\(w)")
    try expect(try store.load("2026-10-17") == nil)
    try store.save(day: "2026-10-21", body: lorem(30))
    let w2 = try store.skipRange(from: "2026-10-20", to: "2026-10-22", weekdays: workdays, calendar: cal)
    expect(w2 == ["2026-10-20", "2026-10-22"], "days with writing are left alone")
    try store.save(day: "2026-10-20", body: lorem(25))
    try expect(try store.load("2026-10-20")!.status(minWords: 20) == .logged)
}
test("fileStates(minWords:) follows the words rule; listDays/folderSummary ignore assets and foreign files") {
    let store = freshStore("states"); let dir = store.dir
    try store.save(day: "2026-10-05", body: lorem(25))
    try store.save(day: "2026-10-06", body: lorem(5))
    try store.save(day: "2026-10-07", body: Settings.defaultTemplate)
    try store.skip("2026-10-08", reason: "x")
    try expect(try store.listDays() == ["2026-10-08", "2026-10-07", "2026-10-06", "2026-10-05"])
    try expect(try store.fileStates(minWords: 20) == ["2026-10-05": .logged, "2026-10-06": .partial, "2026-10-08": .skipped], "template-only page is omitted")
    try expect(try store.fileStates(minWords: 5) == ["2026-10-05": .logged, "2026-10-06": .logged, "2026-10-08": .skipped])
    try expect(try store.fileStates(minWords: 30) == ["2026-10-05": .partial, "2026-10-06": .partial, "2026-10-08": .skipped])
    try FileManager.default.createDirectory(at: dir.appendingPathComponent("assets"), withIntermediateDirectories: true)
    try "hi".write(to: dir.appendingPathComponent("notes.md"), atomically: true, encoding: .utf8)
    try "hi".write(to: dir.appendingPathComponent("2026-10-0x.md"), atomically: true, encoding: .utf8)
    try "hi".write(to: dir.appendingPathComponent(".hidden"), atomically: true, encoding: .utf8)
    try expect(try store.listDays().count == 4)
    try expect(try store.folderSummary() == FolderSummary(logs: 2, skipped: 1, unrecognized: 2))
    let docs = try store.documents(from: "2026-10-06", to: "2026-10-07")
    try expect(Set(docs.keys) == ["2026-10-06", "2026-10-07"] && (try store.allDocuments().count) == 4)
}
test("missing and unwritable folders give typed errors; atomic writes leave no temp files; bad days") {
    let missing = LogStore(dir: root.appendingPathComponent("nope-\(UUID().uuidString)"))
    do { try missing.save(day: "2026-10-05", body: "hello"); expect(false) } catch { expect(error as? LogError == .folderMissing(missing.dir.path)) }
    do { _ = try missing.listDays(); expect(false) } catch { expect(error as? LogError == .folderMissing(missing.dir.path)) }
    do { _ = try missing.load("2026-10-05"); expect(false) } catch { expect(error as? LogError == .folderMissing(missing.dir.path)) }
    do { try missing.skip("2026-10-05"); expect(false) } catch { expect(error as? LogError == .folderMissing(missing.dir.path)) }
    try missing.ensureFolder()
    try missing.save(day: "2026-10-05", body: "hello")
    try expect(try FileManager.default.contentsOfDirectory(atPath: missing.dir.path) == ["2026-10-05.md"])
    let rs = freshStore("ro"); let ro = rs.dir
    try rs.save(day: "2026-10-05", body: "hello there")
    try FileManager.default.setAttributes([.posixPermissions: 0o555], ofItemAtPath: ro.path)
    do { try rs.save(day: "2026-10-06", body: "x y z"); expect(false, "should throw") } catch { expect(error as? LogError == .folderNotWritable(ro.path), "\(error)") }
    do { try rs.skip("2026-10-07"); expect(false) } catch { expect(error as? LogError == .folderNotWritable(ro.path)) }
    do { _ = try rs.assets.save(data: pngBytes, ext: "png", day: "2026-10-05"); expect(false) } catch { expect(error as? LogError == .folderNotWritable(ro.path), "\(error)") }
    try expect(try rs.load("2026-10-05") != nil, "still readable")
    try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: ro.path)
    for bad in ["../evil", "2026-10-5", "x", "2026-10-05.md", ""] {
        do { try rs.save(day: bad, body: "x"); expect(false, bad) } catch { expect(error as? LogError == .badDay(bad), bad) }
    }
    do { _ = try rs.load("../x"); expect(false) } catch { expect(error as? LogError == .badDay("../x")) }
}

// MARK: backups
var fakeNow = mk(2026, 10, 6, 12, 0)   // 16:00:00 UTC (New York is on EDT)
func backupStore(_ name: String, interval: TimeInterval = 0) -> (store: LogStore, bdir: URL) {
    let bdir = freshDir(name + "-backups")
    return (LogStore(dir: freshDir(name), backupDir: bdir, minBackupInterval: interval, clock: { fakeNow }), bdir)
}
func bkNames(_ bdir: URL, _ day: String) -> [String] {
    ((try? FileManager.default.contentsOfDirectory(atPath: bdir.appendingPathComponent(day).path)) ?? []).sorted()
}
func bkText(_ b: BackupInfo) throws -> String { try String(contentsOf: b.url, encoding: .utf8) }
func isIO(_ e: Error) -> Bool { if case LogError.io = e { return true } else { return false } }
/// Safe accessor: a missing backup becomes a placeholder that makes the next call throw instead of trapping the test run.
func bk(_ l: [BackupInfo], _ i: Int) -> BackupInfo { (i >= 0 && i < l.count) ? l[i] : fakeBackup("00000000-000000.md") }
func fakeBackup(_ name: String = "20260101-000000.md") -> BackupInfo {
    BackupInfo(date: Date(), url: URL(fileURLWithPath: "/tmp/" + name), words: 0)
}

test("backup: overwrite copies the previous file first") {
    fakeNow = mk(2026, 10, 6, 12, 0)
    let (store, bdir) = backupStore("bk-over"); let day = "2026-10-06"
    var o = try store.save(day: day, body: "first version " + lorem(25))
    expect(o == SaveOutcome() && store.listBackups(day: day).isEmpty, "nothing existed, nothing to back up")
    expect(!FileManager.default.fileExists(atPath: bdir.appendingPathComponent(day).path), "no backup folder before the first backup")
    let v1 = try fileText(store.dir, day)
    fakeNow = fakeNow.addingTimeInterval(30)
    o = try store.save(day: day, body: "second version " + lorem(30))
    expect(o.backedUp && o.backupWarning == nil && store.lastBackupWarning == nil)
    var list = store.listBackups(day: day)
    expect(list.count == 1 && bk(list, 0).words == 27 && bk(list, 0).date == fakeNow)
    try expect(try bkText(bk(list, 0)) == v1, "byte-for-byte copy of the replaced file")
    expect(bkNames(bdir, day) == ["20261006-160030.md"], "UTC time stamp: \(bkNames(bdir, day))")
    try expect(try fileText(store.dir, day).contains("second version"))
    fakeNow = fakeNow.addingTimeInterval(60)
    let v2 = try fileText(store.dir, day)
    try store.save(day: day, body: "third " + lorem(5))
    list = store.listBackups(day: day)
    try expect(list.map { $0.words } == [32, 27] && (try bkText(bk(list, 0))) == v2 && bk(list, 0).date > bk(list, 1).date, "newest first")
    try store.save(day: "2026-10-07", body: "a b c"); try store.save(day: "2026-10-07", body: "a b c d")
    expect(store.listBackups(day: "2026-10-07").count == 1 && store.listBackups(day: day).count == 2, "one folder per day")
    try expect(Set(try FileManager.default.contentsOfDirectory(atPath: bdir.path)) == ["2026-10-06", "2026-10-07"])
}
test("backup: deleting a page (empty body) keeps a copy; nothing worth keeping means no copy") {
    fakeNow = mk(2026, 10, 6, 12, 0)
    let (store, bdir) = backupStore("bk-del"); let day = "2026-10-06"
    try store.save(day: day, body: "keep me " + lorem(25))
    let before = try fileText(store.dir, day)
    var o = try store.save(day: day, body: " \n\n ")
    try expect(o.backedUp && o.backupWarning == nil && (try store.load(day)) == nil, "file deleted")
    let list = store.listBackups(day: day)
    try expect(list.count == 1 && (try bkText(bk(list, 0))) == before && bk(list, 0).words == 27)
    try raw("# 2026-10-08\n", in: store.dir, day: "2026-10-08")
    o = try store.save(day: "2026-10-08", body: "")
    try expect(!o.backedUp && (try store.load("2026-10-08")) == nil && store.listBackups(day: "2026-10-08").isEmpty, "title-only file: nothing to keep")
    try store.skip("2026-10-09", reason: "x")
    o = try store.save(day: "2026-10-09", body: "")
    try expect(!o.backedUp && (try store.load("2026-10-09"))!.isSkipped && store.listBackups(day: "2026-10-09").isEmpty, "skip marker is neither copied nor deleted")
    o = try store.save(day: "2026-10-10", body: "")
    expect(!o.backedUp && store.listBackups(day: "2026-10-10").isEmpty, "no file at all")
    try expect(Set(try FileManager.default.contentsOfDirectory(atPath: bdir.path)) == ["2026-10-06"])
}
test("backup: only the newest 10 per day are kept (names keep increasing on a frozen clock)") {
    fakeNow = mk(2026, 10, 6, 12, 0)
    let (store, bdir) = backupStore("bk-prune"); let day = "2026-10-06"
    expect(LogStore.maxBackupsPerDay == 10)
    try store.save(day: "2026-10-07", body: "other day v1"); try store.save(day: "2026-10-07", body: "other day v2")
    for i in 1...15 { try store.save(day: day, body: "version \(i) " + lorem(25)) }   // the clock never moves
    let list = store.listBackups(day: day)
    expect(list.count == 10 && bkNames(bdir, day).count == 10, "\(list.count)")
    try expect(try bkText(bk(list, 0)).contains("version 14 ") && (try bkText(bk(list, list.count - 1))).contains("version 5 "), "versions 5...14 survive")
    expect(zip(list, list.dropFirst()).allSatisfy { $0.date > $1.date }, "strictly newest first")
    try expect(try fileText(store.dir, day).contains("version 15 "))
    expect(store.listBackups(day: "2026-10-07").count == 1, "pruning is per day")
}
test("backup: identical content is a no-op; skip markers and title-only files are not copied") {
    fakeNow = mk(2026, 10, 6, 12, 0)
    let (store, _) = backupStore("bk-same"); let day = "2026-10-06"
    try store.save(day: day, body: "same text " + lorem(25))
    func mtime() throws -> Date { try FileManager.default.attributesOfItem(atPath: store.url(for: day).path)[.modificationDate] as! Date }
    let m0 = try mtime()
    Thread.sleep(forTimeInterval: 0.05)
    for b in ["same text " + lorem(25), "same text " + lorem(25) + "\n\n  ", "\n\nsame text " + lorem(25)] {
        let o = try store.save(day: day, body: b)
        expect(o == SaveOutcome(), "identical after normalisation: \(o)")
    }
    try expect(store.listBackups(day: day).isEmpty && (try mtime()) == m0, "no copy and the file was not rewritten")
    try store.save(day: day, body: "changed " + lorem(25))
    expect(store.listBackups(day: day).count == 1)
    try store.save(day: day, body: "changed " + lorem(25))
    expect(store.listBackups(day: day).count == 1, "saving the same thing again adds nothing")
    try store.skip("2026-10-07", reason: "Holiday")
    let o = try store.save(day: "2026-10-07", body: "worked anyway " + lorem(25))
    try expect(!o.backedUp && store.listBackups(day: "2026-10-07").isEmpty && !(try store.load("2026-10-07")!.isSkipped), "a skip marker is not worth a copy")
    try raw("# 2026-10-08\n\n", in: store.dir, day: "2026-10-08")
    try expect(!(try store.save(day: "2026-10-08", body: "now text")).backedUp && store.listBackups(day: "2026-10-08").isEmpty, "title-only file")
    let legacy = "# 2026-10-09\n\n## 📝 What I did\nWrote code\n\n## ✅ Finished\nShipped it\n\n"
    try raw(legacy, in: store.dir, day: "2026-10-09")
    let o2 = try store.save(day: "2026-10-09", body: try store.load("2026-10-09")!.body)
    try expect(o2.backedUp && (try bkText(bk(store.listBackups(day: "2026-10-09"), 0))) == legacy, "re-normalising an old file keeps its original bytes")
}
test("backup: failures never fail the save; unwritable backup dir; restore refuses without its safety copy") {
    fakeNow = mk(2026, 10, 6, 12, 0)
    let day = "2026-10-06"
    let blocker = root.appendingPathComponent("blocker-\(UUID().uuidString)")
    try "i am a file".write(to: blocker, atomically: true, encoding: .utf8)
    let a = LogStore(dir: freshDir("bk-a"), backupDir: blocker, clock: { fakeNow })
    try a.save(day: day, body: "v1 " + lorem(25))
    let oa = try a.save(day: day, body: "v2 " + lorem(25))
    expect(!oa.backedUp && oa.backupWarning != nil && a.lastBackupWarning == oa.backupWarning, "\(oa)")
    try expect(try fileText(a.dir, day).contains("v2 ") && a.listBackups(day: day).isEmpty, "backup dir that is a file: the save still happened")

    let (b, bdir) = backupStore("bk-b")
    try b.save(day: day, body: "v1 " + lorem(25))
    let fm = FileManager.default
    try fm.setAttributes([.posixPermissions: 0o555], ofItemAtPath: bdir.path)
    let o2 = try b.save(day: day, body: "v2 " + lorem(25))
    expect(!o2.backedUp && o2.backupWarning != nil && b.lastBackupWarning == o2.backupWarning)
    try expect(try fileText(b.dir, day).contains("v2 "), "unwritable backup dir: the save itself went through")
    let o3 = try b.save(day: day, body: "")
    try expect(!o3.backedUp && o3.backupWarning != nil && (try b.load(day)) == nil, "deleting is also never blocked by a failed backup")
    try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: bdir.path)
    try b.save(day: day, body: "v3 " + lorem(25))
    let o4 = try b.save(day: day, body: "v4 " + lorem(25))
    expect(o4.backedUp && o4.backupWarning == nil && b.lastBackupWarning == nil && b.listBackups(day: day).count == 1, "recovers on its own and clears the warning")
    let v4 = try fileText(b.dir, day)
    let old = bk(b.listBackups(day: day), 0)
    let dayDir = bdir.appendingPathComponent(day)
    try fm.setAttributes([.posixPermissions: 0o555], ofItemAtPath: dayDir.path)
    do { _ = try b.restoreBackup(day: day, backup: old); expect(false, "restore needs its safety copy") }
    catch { if case LogError.backupFailed = error { expect(true) } else { expect(false, "\(error)") } }
    try expect(try fileText(b.dir, day) == v4 && b.lastBackupWarning != nil, "nothing was changed")
    try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: dayDir.path)
    try b.restoreBackup(day: day, backup: old)
    try expect(try fileText(b.dir, day).contains("v3 ") && b.lastBackupWarning == nil, "works again once the folder is writable")
}
test("backup: restore round trip (restore backs up the current file first)") {
    fakeNow = mk(2026, 10, 6, 12, 0)
    let (store, _) = backupStore("bk-restore"); let day = "2026-10-06"
    var raws = [String]()
    for i in 1...3 {
        fakeNow = fakeNow.addingTimeInterval(10)
        try store.save(day: day, body: "v\(i) " + lorem(25)); raws.append(try fileText(store.dir, day))
    }
    var list = store.listBackups(day: day)   // [v2, v1]
    try expect(list.count == 2 && (try bkText(bk(list, 0))) == raws[1] && (try bkText(bk(list, 1))) == raws[0])
    fakeNow = fakeNow.addingTimeInterval(10)
    let doc = try store.restoreBackup(day: day, backup: bk(list, 1))   // back to v1
    try expect(doc.day == day && doc.body.hasPrefix("v1 ") && (try fileText(store.dir, day)) == raws[0] && (try store.load(day)) == doc)
    list = store.listBackups(day: day)   // [v3 (the safety copy), v2, v1]
    try expect(list.count == 3 && (try bkText(bk(list, 0))) == raws[2], "the current file was copied first")
    fakeNow = fakeNow.addingTimeInterval(10)
    try store.restoreBackup(day: day, backup: bk(list, 0))   // undo the restore
    try expect(try fileText(store.dir, day) == raws[2])
    list = store.listBackups(day: day)   // [v1 (safety copy), v3, v2, v1]
    try expect(list.count == 4 && (try bkText(bk(list, 0))) == raws[0])
    try store.restoreBackup(day: day, backup: bk(list, 1))   // identical to the current file
    try expect(store.listBackups(day: day).count == 4 && (try fileText(store.dir, day)) == raws[2], "identical: no write, no copy")
    // over a deleted page and over a skip marker
    try store.save(day: day, body: "")
    try expect(try store.load(day) == nil)
    list = store.listBackups(day: day)
    try store.restoreBackup(day: day, backup: bk(list, 0))
    try expect(try fileText(store.dir, day) == raws[2], "a deleted page comes back")
    try store.save(day: "2026-10-07", body: "s1 " + lorem(25)); try store.save(day: "2026-10-07", body: "s2 " + lorem(25))
    let s2 = try fileText(store.dir, "2026-10-07")
    try store.save(day: "2026-10-07", body: ""); try store.skip("2026-10-07", reason: "x")
    let sl = store.listBackups(day: "2026-10-07")   // [s2, s1]
    try store.restoreBackup(day: "2026-10-07", backup: bk(sl, 0))
    try expect(try fileText(store.dir, "2026-10-07") == s2 && store.listBackups(day: "2026-10-07").count == 2, "a skip marker is replaced without a copy")
    // forged or foreign backups
    for bad in [fakeBackup("passwd"), fakeBackup(), fakeBackup("../x.md"), BackupInfo(date: Date(), url: bk(list, 0).url.deletingLastPathComponent(), words: 0)] {
        do { _ = try store.restoreBackup(day: day, backup: bad); expect(false, bad.url.path) } catch { expect(isIO(error), "\(error)") }
    }
    do { _ = try store.restoreBackup(day: "2026-10-09", backup: bk(list, 0)); expect(false) } catch { expect(isIO(error), "a name is only looked up inside the given day's folder") }
    do { _ = try store.restoreBackup(day: "../x", backup: bk(list, 0)); expect(false) } catch { expect(error as? LogError == .badDay("../x")) }
    let plain = freshStore("bk-plain")
    do { _ = try plain.restoreBackup(day: day, backup: bk(list, 0)); expect(false) } catch { expect(error as? LogError == .backupsDisabled) }
}
test("backup: backups are never listed, searched or counted") {
    fakeNow = mk(2026, 10, 6, 12, 0)
    for nested in [false, true] {
        let dir = freshDir("bk-ex")
        let bdir = nested ? dir.appendingPathComponent("backups") : freshDir("bk-ex-out")
        let store = LogStore(dir: dir, backupDir: bdir, clock: { fakeNow })
        try store.save(day: "2026-10-06", body: "zebra " + lorem(25))
        try store.save(day: "2026-10-06", body: "giraffe " + lorem(25))
        try store.save(day: "2026-10-07", body: "zebra again " + lorem(25))
        try store.save(day: "2026-10-07", body: "okapi " + lorem(25))
        expect(store.listBackups(day: "2026-10-06").count == 1 && FileManager.default.fileExists(atPath: bdir.path))
        try expect(try store.listDays() == ["2026-10-07", "2026-10-06"], "nested=\(nested)")
        try expect(try store.fileStates(minWords: 20) == ["2026-10-06": .logged, "2026-10-07": .logged])
        try expect(try store.search("zebra").isEmpty && (try store.search("giraffe").map { $0.day }) == ["2026-10-06"] && (try store.search("okapi")).count == 1, "old text lives only in backups")
        try expect(try store.allDocuments().count == 2 && (try store.documents(from: "2000-01-01", to: "2100-01-01").count) == 2)
        try expect(try store.folderSummary() == FolderSummary(logs: 2, skipped: 0, unrecognized: 0), "nested=\(nested)")
        try expect(try store.load("2026-10-06")!.body.hasPrefix("giraffe"))
    }
}
test("backup: UTC names, junk ignored, clock set back, throttle, off by default") {
    var utc = Calendar(identifier: .gregorian); utc.timeZone = TimeZone(identifier: "GMT")!
    let fm = FileManager.default
    // DST fall-back: 01:30 happens twice in New York; the UTC names stay distinct and ordered
    let t1 = utc.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 5, minute: 30))!
    let t2 = t1.addingTimeInterval(3600)
    expect(cal.component(.hour, from: t1) == 1 && cal.component(.hour, from: t2) == 1 && cal.component(.minute, from: t2) == 30, "same wall-clock time twice")
    let (store, bdir) = backupStore("bk-names"); let day = "2026-11-01"
    fakeNow = t1.addingTimeInterval(-60)
    try store.save(day: day, body: "a " + lorem(25))
    fakeNow = t1; try store.save(day: day, body: "b " + lorem(25))
    fakeNow = t2; try store.save(day: day, body: "c " + lorem(25))
    expect(bkNames(bdir, day) == ["20261101-053000.md", "20261101-063000.md"], "\(bkNames(bdir, day))")
    expect(store.listBackups(day: day).map { $0.date } == [t2, t1])
    // junk next to real backups; a valid name holding non-UTF-8 bytes lists with 0 words
    let dayDir = bdir.appendingPathComponent(day)
    for junk in ["notes.txt", ".DS_Store", "20261101-053000.md.tmp", "bad-name.md", "20261301-160000.md", "2026110-0530000.md", "20261101_053000.md"] {
        try "x".write(to: dayDir.appendingPathComponent(junk), atomically: true, encoding: .utf8)
    }
    try Data([0xFF, 0xFE, 0xFD]).write(to: dayDir.appendingPathComponent("20260101-000000.md"))
    let l0 = store.listBackups(day: day)
    expect(l0.count == 3 && bk(l0, 2).words == 0 && bk(l0, 2).date == utc.date(from: DateComponents(year: 2026, month: 1, day: 1)), "\(l0.count)")
    expect(store.listBackups(day: "../x").isEmpty && store.listBackups(day: "nope").isEmpty && store.listBackups(day: "2026-12-31").isEmpty)
    do { _ = try store.restoreBackup(day: day, backup: bk(l0, 2)); expect(false) } catch { expect(isIO(error), "non-UTF-8 backup") }
    // a clock set back never makes a new copy sort older (and so prunable)
    fakeNow = t2.addingTimeInterval(-86400 * 3)
    try store.save(day: day, body: "d " + lorem(25))
    let l1 = store.listBackups(day: day)
    try expect(l1.count == 4 && bk(l1, 0).date == t2.addingTimeInterval(1) && (try bkText(bk(l1, 0))).contains("c "), "newest copy is still first: \(l1.map { $0.date })")
    // throttle: overwrites skip the copy inside the interval; deletes and restores always copy
    fakeNow = mk(2026, 10, 6, 12, 0)
    let (ts, _) = backupStore("bk-throttle", interval: 60); let d2 = "2026-10-06"
    try ts.save(day: d2, body: "v1 " + lorem(25))
    fakeNow = fakeNow.addingTimeInterval(5); try ts.save(day: d2, body: "v2 " + lorem(25))
    fakeNow = fakeNow.addingTimeInterval(5); let skipped = try ts.save(day: d2, body: "v3 " + lorem(25))
    try expect(!skipped.backedUp && skipped.backupWarning == nil && ts.listBackups(day: d2).count == 1 && (try bkText(bk(ts.listBackups(day: d2), 0))).contains("v1 "), "inside the interval")
    fakeNow = fakeNow.addingTimeInterval(120); try ts.save(day: d2, body: "v4 " + lorem(25))
    try expect(ts.listBackups(day: d2).count == 2 && (try bkText(bk(ts.listBackups(day: d2), 0))).contains("v3 "), "interval over: copy of v3")
    fakeNow = fakeNow.addingTimeInterval(1); try ts.save(day: d2, body: "")
    try expect(ts.listBackups(day: d2).count == 3 && (try bkText(bk(ts.listBackups(day: d2), 0))).contains("v4 "), "delete ignores the interval")
    fakeNow = fakeNow.addingTimeInterval(1); try ts.restoreBackup(day: d2, backup: bk(ts.listBackups(day: d2), 0))
    fakeNow = fakeNow.addingTimeInterval(1); try ts.restoreBackup(day: d2, backup: bk(ts.listBackups(day: d2), 2))
    expect(ts.listBackups(day: d2).count == 4, "restore ignores the interval: the current page was copied before the oldest backup came back")
    // off by default: nothing is created, nothing breaks
    let off = freshStore("bk-off")
    try off.save(day: "2026-10-06", body: "a " + lorem(25))
    try expect(try off.save(day: "2026-10-06", body: "b " + lorem(25)) == SaveOutcome() && off.listBackups(day: "2026-10-06").isEmpty && off.lastBackupWarning == nil && off.backupDir == nil)
    try off.save(day: "2026-10-06", body: "")
    try expect(try off.load("2026-10-06") == nil && (try fm.contentsOfDirectory(atPath: off.dir.path)).isEmpty)
    do { _ = try off.restoreBackup(day: "2026-10-06", backup: fakeBackup()); expect(false) } catch { expect(error as? LogError == .backupsDisabled) }
}

// MARK: settings
test("settings defaults, round trip, tolerant decode, normalize") {
    let d = Settings()
    expect(d.mode == .strict && d.minWords == 20 && d.carryOverHeadings == ["To do next", "Pending / blocked"] && d.reminderMinutes == 16 * 60 + 55)
    expect(d.template == "## What I did\n\n## Finished\n\n## Started\n\n## Pending / blocked\n\n## To do next")
    let ms = MemoryStore()
    expect(Settings.load(from: ms) == Settings(), "defaults when empty")
    var s = Settings()
    s.mode = .gentle; s.reminderMinutes = 17 * 60; s.weekdays = [2, 4]; s.snoozeMinutes = 30
    s.storageFolder = URL(fileURLWithPath: "/tmp/x"); s.onboarded = true; s.launchAtLogin = false
    s.template = "## Wins\n\n## Next"; s.carryOverHeadings = ["Next"]; s.minWords = 50
    s.save(to: ms)
    expect(Settings.load(from: ms) == s)
    ms.setData("{\"mode\":\"gentle\"}".data(using: .utf8), forKey: Settings.storageKey)
    let t = Settings.load(from: ms)
    expect(t.mode == .gentle && t.reminderMinutes == 16 * 60 + 55 && t.weekdays == workdays && t.template == Settings.defaultTemplate && t.minWords == 20)
    ms.setData("garbage".data(using: .utf8), forKey: Settings.storageKey)
    expect(Settings.load(from: ms) == Settings())
    var bad = Settings(); bad.weekdays = []; bad.snoozeMinutes = 7; bad.reminderMinutes = 5000; bad.minWords = 0
    bad.carryOverHeadings = ["  Next  ", "", "   "]
    let n = bad.normalized()
    expect(n.weekdays == workdays && n.snoozeMinutes == 15 && n.reminderMinutes == 1439 && n.minWords == 1 && n.carryOverHeadings == ["Next"])
    bad.minWords = 9999; expect(bad.normalized().minWords == 500)
    bad.minWords = -3; expect(bad.normalized().minWords == 1)
    var empty = Settings(); empty.template = ""; empty.carryOverHeadings = []
    empty.save(to: ms); let e = Settings.load(from: ms)
    expect(e.template == "" && e.carryOverHeadings.isEmpty, "an empty template / no carry-over headings are allowed")
    let ud = UserDefaults(suiteName: "dailylog.tests.\(UUID().uuidString)")!
    s.save(to: ud); expect(Settings.load(from: ud) == s, "UserDefaults conforms")
}
test("settings migration from v0.2 JSON") {
    let ms = MemoryStore()
    let old = """
    {"mode":"gentle","reminderMinutes":1020,"weekdays":[2,3],"snoozeMinutes":20,"launchAtLogin":false,"onboarded":true,
     "storageFolder":"file:///tmp/old-logs/","carryOverSectionID":"pending",
     "sections":[{"id":"did","title":"📝 What I did","hint":"h","required":true},{"id":"x","title":"  Wins  ","hint":"","required":false},
                 {"id":"y","title":"   ","hint":"","required":true},{"id":"todo","title":"📌 To do next","hint":"","required":true}]}
    """
    ms.setData(old.data(using: .utf8), forKey: Settings.storageKey)
    let s = Settings.load(from: ms)
    expect(s.template == "## 📝 What I did\n\n## Wins\n\n## 📌 To do next", "\(s.template)")
    expect(s.mode == .gentle && s.reminderMinutes == 1020 && s.weekdays == [2, 3] && s.snoozeMinutes == 20 && s.onboarded && !s.launchAtLogin)
    expect(s.storageFolder.path == "/tmp/old-logs" && s.minWords == 20 && s.carryOverHeadings == Settings.defaultCarryOverHeadings)
    expect(MarkdownBody.headings(inTemplate: s.template).map { MarkdownBody.normalizeHeading($0) } == ["what i did", "wins", "to do next"])
    s.save(to: ms)
    let json = String(data: ms.data(forKey: Settings.storageKey)!, encoding: .utf8)!
    expect(!json.contains("\"sections\"") && !json.contains("carryOverSectionID") && json.contains("\"template\""), "re-saved in the new shape")
    expect(Settings.load(from: ms) == s)
    // an explicit template wins over old sections; empty/blank sections fall back to the default
    ms.setData("{\"template\":\"## Mine\",\"sections\":[{\"id\":\"a\",\"title\":\"Old\"}]}".data(using: .utf8), forKey: Settings.storageKey)
    expect(Settings.load(from: ms).template == "## Mine")
    ms.setData("{\"sections\":[]}".data(using: .utf8), forKey: Settings.storageKey)
    expect(Settings.load(from: ms).template == Settings.defaultTemplate)
    ms.setData("{\"sections\":[{\"id\":\"a\",\"title\":\"  \"}]}".data(using: .utf8), forKey: Settings.storageKey)
    expect(Settings.load(from: ms).template == Settings.defaultTemplate)
    ms.setData("{\"sections\":\"nonsense\"}".data(using: .utf8), forKey: Settings.storageKey)
    expect(Settings.load(from: ms).template == Settings.defaultTemplate, "unreadable old sections are ignored")
}

// MARK: assets
test("AssetStore.save: names, dedupe, ext allowlist, size cap") {
    let store = freshStore("assets-save"); let a = store.assets
    let p = try a.save(data: Data("hello".utf8), ext: "png", day: "2026-10-06")
    expect(p == "assets/2026-10-06-2cf24dba.png", "SHA-256 prefix of the bytes: \(p)")
    expect(FileManager.default.fileExists(atPath: store.dir.appendingPathComponent(p).path))
    try expect(try a.save(data: Data("hello".utf8), ext: "png", day: "2026-10-06") == p, "same bytes, same day, same path")
    try expect(try FileManager.default.contentsOfDirectory(atPath: store.dir.appendingPathComponent("assets").path).count == 1)
    try expect(try a.save(data: Data("hello".utf8), ext: "png", day: "2026-10-07") == "assets/2026-10-07-2cf24dba.png")
    let q = try a.save(data: pngBytes, ext: "png", day: "2026-10-06")
    expect(q != p && q.range(of: "^assets/2026-10-06-[0-9a-f]{8}\\.png$", options: .regularExpression) != nil, q)
    for (ext, want) in [("PNG", "png"), (".jpg", "jpg"), ("jpeg", "jpeg"), ("GIF", "gif"), (" webp ", "webp")] {
        let r = try a.save(data: Data("x-\(ext)".utf8), ext: ext, day: "2026-10-06")
        expect(r.hasSuffix("." + want) && r.hasPrefix("assets/2026-10-06-"), r)
    }
    for ext in ["svg", "exe", "png/../x", "", "md", "heic", "png.exe", "../png"] {
        do { _ = try a.save(data: pngBytes, ext: ext, day: "2026-10-06"); expect(false, ext) } catch { expect(error as? LogError == .unsupportedAsset(ext), "\(ext) \(error)") }
    }
    do { _ = try a.save(data: Data(), ext: "png", day: "2026-10-06"); expect(false) } catch { expect(error as? LogError == .emptyAsset) }
    for bad in ["../x", "2026-10-6", "assets"] {
        do { _ = try a.save(data: pngBytes, ext: "png", day: bad); expect(false, bad) } catch { expect(error as? LogError == .badDay(bad)) }
    }
    let big = Data(count: AssetStore.maxBytes + 1)
    do { _ = try a.save(data: big, ext: "png", day: "2026-10-06"); expect(false) } catch { expect(error as? LogError == .assetTooLarge(AssetStore.maxBytes + 1)) }
    let exact = Data(count: AssetStore.maxBytes)
    try expect(AssetStore.maxBytes == 20 * 1024 * 1024 && (try a.save(data: exact, ext: "png", day: "2026-10-06")).hasPrefix("assets/"), "exactly 20 MB is accepted")
    let nofolder = AssetStore(dir: root.appendingPathComponent("no-such-\(UUID().uuidString)"))
    do { _ = try nofolder.save(data: pngBytes, ext: "png", day: "2026-10-06"); expect(false) } catch { expect(error as? LogError == .folderMissing(nofolder.dir.path)) }
}
test("AssetStore.fileExtension(mime:name:)") {
    let f = AssetStore.fileExtension
    expect(f("image/png", nil) == "png" && f("IMAGE/JPEG; charset=binary", "x.png") == "jpg" && f("image/jpg", nil) == "jpg")
    expect(f("image/gif", "a.png") == "gif" && f("image/webp", nil) == "webp" && f(" image/png ", "") == "png")
    expect(f("application/octet-stream", "Photo.JPEG") == "jpeg" && f(nil, "pic.webp") == "webp" && f("", "pic.gif") == "gif")
    expect(f("image/svg+xml", "a.svg") == nil && f(nil, nil) == nil && f("text/plain", "notes.md") == nil && f("image/heic", "a.heic") == nil)
}
test("AssetStore.resolve: inside the folder only") {
    let store = freshStore("assets-resolve"); let a = store.assets; let dir = store.dir
    let p = try a.save(data: pngBytes, ext: "png", day: "2026-10-06")
    let real = AssetStore.realPath(dir.appendingPathComponent(p))!
    expect(a.resolve(p)?.path == real && FileManager.default.fileExists(atPath: real))
    expect(a.resolve("./" + p)?.path == real && a.resolve("assets//" + String(p.dropFirst(7)))?.path == real, "normalised")
    expect(a.resolve("") == nil && a.resolve("assets/") == nil && a.resolve("assets") == nil)
    for bad in ["../outside.png", "assets/../../outside.png", "assets/../" + String(p.dropFirst(7)), "assets/..", "..", "a/b/../../../x.png"] {
        expect(a.resolve(bad) == nil, bad)
    }
    expect(a.resolve("/etc/passwd.png") == nil && a.resolve("/" + p) == nil && a.resolve(real) == nil, "absolute paths")
    expect(a.resolve("file:///etc/hosts.png") == nil && a.resolve("https://example.com/a.png") == nil)
    expect(a.resolve("%2e%2e/x.png") == nil && a.resolve("assets/nope.png") == nil, "missing file")
    try "notes".write(to: dir.appendingPathComponent("notes.md"), atomically: true, encoding: .utf8)
    try "x".write(to: dir.appendingPathComponent("assets/a.svg"), atomically: true, encoding: .utf8)
    try "x".write(to: dir.appendingPathComponent("assets/noext"), atomically: true, encoding: .utf8)
    expect(a.resolve("notes.md") == nil && a.resolve("assets/a.svg") == nil && a.resolve("assets/noext") == nil, "non-image extensions")
    try FileManager.default.createDirectory(at: dir.appendingPathComponent("assets/dir.png"), withIntermediateDirectories: true)
    expect(a.resolve("assets/dir.png") == nil, "a directory named like an image")
    try pngBytes.write(to: dir.appendingPathComponent("loose.JPG"))
    expect(a.resolve("loose.JPG") != nil, "images elsewhere in the folder are fine, ext case-insensitive")
    // dlasset:// URLs
    expect(a.resolve(assetURL: URL(string: "dlasset://local/" + p)!)?.path == real)
    expect(a.resolve(assetURL: URL(string: "https://local/" + p)!) == nil && a.resolve(assetURL: URL(string: "dlasset://local/assets/%2e%2e/%2e%2e/x.png")!) == nil)
    expect(a.resolve(assetURL: URL(string: "dlasset://local/")!) == nil)
}
test("AssetStore: symlinks cannot escape the storage folder") {
    let store = freshStore("assets-link"); let dir = store.dir; let a = store.assets
    let outside = freshDir("outside")
    try pngBytes.write(to: outside.appendingPathComponent("secret.png"))
    try "top secret".write(to: outside.appendingPathComponent("passwords.txt"), atomically: true, encoding: .utf8)
    let assets = dir.appendingPathComponent("assets")
    try FileManager.default.createDirectory(at: assets, withIntermediateDirectories: true)
    let fm = FileManager.default
    try fm.createSymbolicLink(at: assets.appendingPathComponent("evil.png"), withDestinationURL: outside.appendingPathComponent("secret.png"))
    try fm.createSymbolicLink(at: assets.appendingPathComponent("linkdir"), withDestinationURL: outside)
    try fm.createSymbolicLink(at: assets.appendingPathComponent("txt.png"), withDestinationURL: outside.appendingPathComponent("passwords.txt"))
    try fm.createSymbolicLink(atPath: assets.appendingPathComponent("rel.png").path, withDestinationPath: "../../" + outside.lastPathComponent + "/secret.png")
    expect(a.resolve("assets/evil.png") == nil, "file symlink leaving the folder")
    expect(a.resolve("assets/linkdir/secret.png") == nil, "directory symlink leaving the folder")
    expect(a.resolve("assets/txt.png") == nil && a.resolve("assets/rel.png") == nil, "png-named links to other files")
    // links that stay inside are fine, but only to images
    let p = try a.save(data: pngBytes, ext: "png", day: "2026-10-06")
    try fm.createSymbolicLink(at: assets.appendingPathComponent("alias.png"), withDestinationURL: dir.appendingPathComponent(p))
    try "notes".write(to: dir.appendingPathComponent("notes.md"), atomically: true, encoding: .utf8)
    try fm.createSymbolicLink(at: assets.appendingPathComponent("md.png"), withDestinationURL: dir.appendingPathComponent("notes.md"))
    expect(a.resolve("assets/alias.png")?.path == AssetStore.realPath(dir.appendingPathComponent(p)), "alias inside the folder resolves to the real file")
    expect(a.resolve("assets/md.png") == nil, "a link to a non-image inside the folder")
    // the storage folder itself reached through a symlink still works
    let linkToStore = root.appendingPathComponent("storage-link-\(UUID().uuidString)")
    try fm.createSymbolicLink(at: linkToStore, withDestinationURL: dir)
    expect(AssetStore(dir: linkToStore).resolve(p) != nil, "root given as a symlink")
    // a symlinked assets/ directory pointing outside: no saves, no resolves
    let store2 = freshStore("assets-link2"); let outside2 = freshDir("outside2")
    try pngBytes.write(to: outside2.appendingPathComponent("a.png"))
    try fm.createSymbolicLink(at: store2.dir.appendingPathComponent("assets"), withDestinationURL: outside2)
    do { _ = try store2.assets.save(data: pngBytes, ext: "png", day: "2026-10-06"); expect(false) } catch { expect(error as? LogError == .badPath("assets"), "\(error)") }
    expect(store2.assets.resolve("assets/a.png") == nil, "everything behind an escaping assets/ link is refused")
    try expect(try fm.contentsOfDirectory(atPath: outside2.path) == ["a.png"], "nothing was written outside")
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
func weekFixture(minWords: Int = 20, template: String? = nil) throws -> (WeekSummary, LogStore) {
    let store = freshStore("week")
    let mon = "## What I did\nPlanned the week and reviewed pricing page copy with Ana.\nLong standup then deep work on the editor bridge.\n\n## Finished\nShipped A\nand B\n\n## Started\nDocs\n\n## Pending / blocked\n\n## To do next\n- [ ] Plan Q4"
    let tue = "## Standup notes\nQuick sync about launch dates and owners for the week ahead plans.\n\n## Finished\nShipped C\n### Details\nten words here to describe what was shipped for the customer demo\n\n## Pending / blocked\nWaiting on legal"
    let thu = "Spent the whole day on the editor bridge and fixed three bugs in the autosave debounce logic, then wrote notes for tomorrow."
    try store.save(day: "2026-10-05", body: mon); try store.save(day: "2026-10-06", body: tue)
    try store.skip("2026-10-07", reason: "Holiday")
    try store.save(day: "2026-10-08", body: thu); try store.save(day: "2026-10-09", body: "Short note only")
    try store.save(day: "2026-09-30", body: lorem(30, "outside"))
    var s = Settings(); s.minWords = minWords
    if let t = template { s.template = t }
    let w = WeeklyReview.summary(weekContaining: mk(2026, 10, 7), documents: try store.documents(from: "2026-10-05", to: "2026-10-11"),
                                 states: try store.fileStates(minWords: minWords), settings: s, calendar: cal, now: mk(2026, 10, 11, 20))
    return (w, store)
}
test("weekly review aggregate: by template heading plus Other notes") {
    let (w, _) = try weekFixture()
    expect(w.weekStart == "2026-10-05" && w.weekEnd == "2026-10-11" && w.days.count == 7)
    expect(w.loggedCount == 3 && w.workdayCount == 5 && w.skippedCount == 1)
    expect(w.days.map { $0.status } == [.logged, .logged, .skipped, .logged, .partial, .off, .off], "\(w.days.map { $0.status })")
    expect(w.sections.map { $0.title } == ["What I did", "Finished", "Started", "Pending / blocked", "To do next", "Other notes"], "\(w.sections.map { $0.title })")
    expect(w.sections.map { $0.isOther } == [false, false, false, false, false, true])
    let fin = w.section(titled: "finished")!
    expect(fin.items.map { $0.day } == ["2026-10-05", "2026-10-06"] && fin.items[0].text == "Shipped A\nand B")
    expect(fin.items[1].text == "Shipped C\n\n**Details**\nten words here to describe what was shipped for the customer demo", "nested heading stays with its owner")
    expect(w.section(titled: "⏳ Pending / blocked")!.items.map { $0.text } == ["Waiting on legal"], "empty Monday section is left out")
    expect(w.section(titled: "to do next")!.items.map { $0.text } == ["- [ ] Plan Q4"] && w.section(titled: "Started")!.items[0].text == "Docs")
    let other = w.section(titled: "Other notes")!
    expect(other.isOther && other.items.map { $0.day } == ["2026-10-06", "2026-10-08", "2026-10-09"])
    expect(other.items[0].text == "**Standup notes**\nQuick sync about launch dates and owners for the week ahead plans.")
    expect(other.items[1].text.hasPrefix("Spent the whole day") && other.items[2].text == "Short note only")
    expect(w.section(titled: "Nope") == nil)
    // a smaller template: everything else goes to Other notes (with its heading kept as a bold label)
    let (w2, _) = try weekFixture(template: "## Finished")
    expect(w2.sections.map { $0.title } == ["Finished", "Other notes"])
    expect(w2.section(titled: "other notes")!.items[0].text.hasPrefix("**What I did**\nPlanned the week"))
    let (w3, _) = try weekFixture(template: "")
    expect(w3.sections.map { $0.title } == ["Other notes"] && w3.sections[0].items.count == 4, "no template: one group, one item per page with content")
    let (w4, _) = try weekFixture(minWords: 3)
    expect(w4.loggedCount == 4, "minWords drives logged: Friday's 3 words now count")
    expect(WeeklyReview.shift(mk(2026, 10, 7), weeks: -1, calendar: cal) == mk(2026, 9, 30))
}
test("weekly review markdown (day + section grouping)") {
    let (w, _) = try weekFixture()
    let day = WeeklyReview.markdown(for: w, grouping: .day, calendar: cal)
    expect(day.hasPrefix("# Week of 5 Oct – 11 Oct 2026\n\nLogged 3 of 5 workdays · 1 skipped\n"), day)
    expect(day.contains("## Mon 5 Oct\n\n### What I did\nPlanned the week"))
    let monBlock = String(day[day.range(of: "## Mon 5 Oct")!.lowerBound..<day.range(of: "## Tue 6 Oct")!.lowerBound])
    expect(monBlock.contains("### Started\nDocs\n\n### To do next\n- [ ] Plan Q4") && !monBlock.contains("Pending / blocked"), "empty sections are pruned")
    expect(day.contains("## Tue 6 Oct\n\n### Standup notes\nQuick sync") && day.contains("#### Details\nten words here"))
    expect(day.contains("## Wed 7 Oct\n_Skipped: Holiday_"))
    expect(day.contains("## Thu 8 Oct\n\nSpent the whole day") && day.contains("## Fri 9 Oct\n\nShort note only"))
    expect(!day.contains("Sat 10 Oct") && !day.contains("outside") && !day.contains("30 Sep"))
    let sec = WeeklyReview.markdown(for: w, grouping: .section, calendar: cal)
    expect(sec.contains("## Finished\n\n- **Mon 5 Oct**: Shipped A\n  and B\n- **Tue 6 Oct**: Shipped C\n\n  **Details**\n  ten words here"), sec)
    expect(sec.contains("## To do next\n\n- **Mon 5 Oct**\n  - [ ] Plan Q4"), "list items get the label on its own line")
    expect(sec.contains("## Other notes\n\n- **Tue 6 Oct**\n  **Standup notes**\n  Quick sync"))
    expect(sec.contains("- **Thu 8 Oct**: Spent the whole day") && sec.contains("- **Fri 9 Oct**: Short note only"))
    expect(!sec.contains("Skipped") && sec.hasSuffix("\n") && !sec.hasSuffix("\n\n"))
    let empty = WeeklyReview.summary(weekContaining: mk(2026, 10, 7), documents: [:], states: [:], settings: Settings(), calendar: cal, now: mk(2026, 10, 7))
    for g in [WeekGrouping.day, .section] {
        let em = WeeklyReview.markdown(for: empty, grouping: g, calendar: cal)
        expect(em == "# Week of 5 Oct – 11 Oct 2026\n\nLogged 0 of 3 workdays\n", em)
    }
}

// MARK: carry-over
test("carry-over: card, items, apply, idempotent") {
    let store = freshStore("carry")
    let fri = "## What I did\n" + lorem(25) + "\n\n## To do next\n- [ ] Call Ana\n- [x] Sent invoice\nFix build\n1. Plan Q4\n\n## Pending / blocked\n- Legal review\n- [ ] Call Ana\n![](assets/x.png)"
    try store.save(day: "2026-10-02", body: fri)
    try store.skip("2026-10-05", reason: "Holiday")
    let load: (String) -> DayDocument? = { (try? store.load($0)) ?? nil }
    let s = Settings()
    let card = CarryOver.card(before: "2026-10-06", calendar: cal, settings: s, load: load)!
    expect(card.sourceDay == "2026-10-02" && card.sourceLabel == "Fri 2 Oct", "skipped Monday is ignored")
    expect(card.items == ["Call Ana", "Fix build", "Plan Q4", "Legal review"], "\(card.items)")
    expect(card.headingText == "Carried over from Fri 2 Oct")
    expect(CarryOver.heading(for: card, today: "2026-10-06", calendar: cal) == "Friday")
    expect(CarryOver.heading(for: card, today: "2026-10-03", calendar: cal) == "Yesterday")
    expect(CarryOver.heading(for: card, today: "2026-10-12", calendar: cal) == "2 Oct 2026")
    let block = "## Carried over from Fri 2 Oct\n\n- [ ] Call Ana\n- [ ] Fix build\n- [ ] Plan Q4\n- [ ] Legal review"
    expect(CarryOver.apply(card, to: "") == block)
    let once = CarryOver.apply(card, to: "## What I did\nstarted work")
    expect(once == block + "\n\n## What I did\nstarted work", "inserted at the TOP")
    expect(CarryOver.apply(card, to: once) == once && CarryOver.isApplied(card, in: once) && !CarryOver.isApplied(card, in: "x"), "idempotent")
    expect(CarryOver.apply(card, to: once.replacingOccurrences(of: "## Carried", with: "### Carried")) == once.replacingOccurrences(of: "## Carried", with: "### Carried"), "heading level does not matter")
    expect(CarryOver.apply(card, to: "- [x] Call Ana\n- [ ] Fix build\n  - [ ] Plan Q4\nlegal  review") == "- [x] Call Ana\n- [ ] Fix build\n  - [ ] Plan Q4\nlegal  review", "items already present (any marker, case, spacing) are not added again")
    expect(CarryOver.apply(card, to: "Call Ana\nfoo") == "## Carried over from Fri 2 Oct\n\n- [ ] Fix build\n- [ ] Plan Q4\n- [ ] Legal review\n\nCall Ana\nfoo", "only the missing items")
    let withTemplate = CarryOver.apply(card, to: Settings.defaultTemplate)
    expect(withTemplate.hasPrefix(block + "\n\n## What I did") && withTemplate.hasSuffix("## To do next"))
    expect(MarkdownBody.hasContent(block) && MarkdownBody.words(in: block) == 0, "carried tasks are content but not words (was 8 before the carried-over exclusion)")
}
test("carry-over: previous LOGGED day only, lookback, minWords, headings") {
    let store = freshStore("carry2")
    let load: (String) -> DayDocument? = { (try? store.load($0)) ?? nil }
    let s = Settings()
    try store.save(day: "2026-10-02", body: "## What I did\n" + lorem(25) + "\n\n## To do next\n- [ ] From Friday")
    try store.save(day: "2026-10-05", body: "## To do next\n- [ ] Should not carry")   // 3 words: partial
    try store.skip("2026-10-06", reason: "Leave")
    expect(CarryOver.card(before: "2026-10-07", calendar: cal, settings: s, load: load)?.items == ["From Friday"], "partial and skipped days are walked past")
    expect(CarryOver.card(before: "2026-10-02", calendar: cal, settings: s, load: load) == nil, "nothing before the first log")
    expect(CarryOver.card(before: "2026-10-16", calendar: cal, settings: s, load: load)?.sourceDay == "2026-10-02", "14 days back is still found")
    expect(CarryOver.card(before: "2026-10-17", calendar: cal, settings: s, load: load) == nil, "15 days back is not")
    var big = s; big.minWords = 40
    expect(CarryOver.card(before: "2026-10-07", calendar: cal, settings: big, load: load) == nil, "minWords decides what 'logged' means")
    try store.save(day: "2026-10-06", body: "## What I did\n" + lorem(25) + "\n\n## Notes\n- [ ] not a carry heading")
    expect(CarryOver.card(before: "2026-10-07", calendar: cal, settings: s, load: load) == nil, "the latest logged day has nothing to carry: stop, do not dig further back")
    try store.save(day: "2026-10-06", body: "## What I did\n" + lorem(25) + "\n\n## To do next\n- [x] done already\n\n## Pending / blocked\n")
    expect(CarryOver.card(before: "2026-10-07", calendar: cal, settings: s, load: load) == nil, "ticked tasks are not carried")
    var none = s; none.carryOverHeadings = []
    try store.save(day: "2026-10-06", body: "## To do next\n- [ ] x\n" + lorem(25))
    expect(CarryOver.card(before: "2026-10-07", calendar: cal, settings: none, load: load) == nil)
    expect(CarryOver.items(in: "## 🔜 Next\n- [ ] a\n### Sub\n- b\n## Other\n- c", headings: ["next"]) == ["a", "b"], "emoji-insensitive, sub-headings included")
    expect(CarryOver.items(in: "## 📌 TO DO NEXT\n- x\n## to-do next\n- y\n## To do next\n- x", headings: ["To do next"]) == ["x", "y"], "all matching headings, de-duplicated")
    expect(CarryOver.items(in: "## To do next\n![](assets/x.png)\n```\ncode\n```\n<!-- hidden -->\n- real\n\n   \n- [ ]   spaced   out  ", headings: ["To do next"]) == ["real", "spaced out"])
    expect(CarryOver.items(in: "- [ ] outside any heading\n## Other\n- c", headings: ["To do next"]).isEmpty && CarryOver.items(in: "x", headings: [" ", "🙂"]).isEmpty)
    expect(CarryOver.items(in: "## To do next\nFix build and test\n\nCall [Ana](http://x.com) today", headings: ["to do next"]) == ["Fix build and test", "Call [Ana](http://x.com) today"])
    expect(MarkdownBody.insertCarryOver(into: "body", heading: "Carried over from X", items: ["", "  ", "\n"]) == "body", "nothing to add")
    expect(MarkdownBody.insertCarryOver(into: "", heading: "H", items: ["a\nb"]) == "## H\n\n- [ ] a b", "items are single lines")
}

test("carried-over tasks never count toward the logged rule (one Carry over click cannot log a day)") {
    func carried(_ label: String = "Fri 2 Oct", items: Int = 4, per: Int = 8) -> String {
        "## Carried over from \(label)\n\n" + (1...items).map { "- [ ] " + lorem(per, "i\($0)w") }.joined(separator: "\n")
    }
    let block = carried()
    expect(MarkdownBody.hasContent(block) && W(block) == 0, "32 task words, none counted")
    expect(DayDocument(day: "2026-10-06", body: block).status(minWords: 20) == .missed && DayDocument(day: "2026-10-06", body: block).status(minWords: 1) == .missed)
    // the real flow: card from a logged day -> apply -> save
    let store = freshStore("carry-words"); let day = "2026-10-06"
    try store.save(day: "2026-10-02", body: "## What I did\n" + lorem(25) + "\n\n## To do next\n- [ ] " + lorem(10, "t") + "\n- [ ] " + lorem(10, "u"))
    let load: (String) -> DayDocument? = { (try? store.load($0)) ?? nil }
    let card = CarryOver.card(before: day, calendar: cal, settings: Settings(), load: load)!
    expect(card.items.count == 2 && card.items.joined(separator: " ").split(separator: " ").count == 20, "20 carried words, as many as minWords")
    let onTemplate = CarryOver.apply(card, to: Settings.defaultTemplate)
    expect(W(onTemplate) == 0 && MarkdownBody.hasContent(onTemplate) && W(CarryOver.apply(card, to: "")) == 0)
    try store.save(day: day, body: onTemplate)
    try expect(try store.load(day) != nil, "a page holding only carried tasks is kept, never treated as empty")
    try expect(try store.fileStates(minWords: 20)[day] == nil && (try store.fileStates(minWords: 1))[day] == nil, "neither logged nor partial")
    try expect(try store.fileStates(minWords: 20)["2026-10-02"] == .logged)
    try expect(try store.folderSummary().logs == 2, "it still has content")
    do { try store.skip(day); expect(false, "skip rules are unchanged: the page has content") } catch { expect(error as? LogError == .hasContent(day)) }
    // still unlogged for status, planner, streak and carry sources
    let st = try store.fileStates(minWords: 20)
    let now = mk(2026, 10, 6, 18)
    let status = Status.resolve(day: day, fileState: st[day], now: now, calendar: cal, weekdays: workdays, since: st.keys.min())
    expect(status == .missed)
    expect(ReminderPlanner.decide(now: now, calendar: cal, settings: Settings(), todayStatus: status, state: PlannerState(day: day), windowVisible: true).0 == .bringToFront(notify: true), "the reminder still fires")
    expect(CarryOver.card(before: "2026-10-07", calendar: cal, settings: Settings(), load: load)?.sourceDay == "2026-10-02", "a day with only carried tasks is not a carry source")
    expect(Streak.compute(states: st, now: now, calendar: cal, weekdays: workdays) == StreakResult(current: 0, best: 1), "Friday logged, Monday missed, Tuesday not yet")
    // partial / logged only through real words, wherever they are written
    for (n, want) in [(0, DayStatus.missed), (1, .partial), (19, .partial), (20, .logged), (50, .logged)] {
        let real = lorem(n, "real")
        let bodies = [onTemplate.replacingOccurrences(of: "## What I did", with: "## What I did\n" + real),   // under another heading
                      block + "\n\n" + real,                                                                  // headingless paragraph right below the block
                      block + "\n\n" + real + "\n\n## Finished\n",
                      block + "\n\n" + real.split(separator: " ").map { "- " + $0 }.joined(separator: "\n")]  // plain bullets
        for b in bodies {
            let d = DayDocument(day: day, body: b)
            expect(d.words == n && d.status(minWords: 20) == want, "n=\(n) got \(d.words) \(d.status(minWords: 20)) in: \(b.prefix(60))")
        }
    }
    // the reverse trap: a carry-over click above existing headingless writing must not swallow it
    let free = lorem(25)
    let bullets = (1...6).map { "- " + lorem(5, "b\($0)x") }.joined(separator: "\n")
    for body in [free, bullets, "## What I did\n" + lorem(30), "intro words here\n\n" + Settings.defaultTemplate] {
        let once = CarryOver.apply(card, to: body)
        expect(once != body && W(once) == W(body) && DayDocument(day: day, body: once).status(minWords: 20) == DayDocument(day: day, body: body).status(minWords: 20), "words unchanged by carrying: \(W(body)) vs \(W(once))")
    }
}
test("carried-over exclusion: which headings, which lines, nested and multiple blocks") {
    let t = "- [ ] " + lorem(4, "t")   // 4 words
    for h in ["## Carried over from Mon 5 Oct", "# Carried over from Mon", "### carried OVER FROM friday", "#### **Carried over from Mon**", "## 🔁 Carried over from Mon", "## Carried over from"] {
        expect(W("\(h)\n\(t)") == 0 && MarkdownBody.hasContent("\(h)\n\(t)"), h)
    }
    // look-alike headings are the user's own and count like any other
    for h in ["## Carried over", "## Carried over today", "## Not carried over from Mon", "## Carried overfrom Mon", "## Carry over from Mon", "## Carried from Mon"] {
        expect(W("\(h)\n\(t)") == 4, h)
    }
    expect(W("Carried over from Mon\n\(t)") == 8, "the phrase as plain text is not a heading (4 + 4)")
    expect(W("```\n## Carried over from Mon\n```\n\(t)") == 8, "a heading inside a code fence is not a heading (4 code words + 4 task words)")
    // extent: up to the next heading of the same or a higher level
    expect(W("## Carried over from Mon\n\(t)\n\n## What I did\nreal words here") == 3)
    expect(W("### Carried over from Mon\n\(t)\n## Next\n\(t)") == 4, "a higher-level heading ends the block")
    expect(W("## Carried over from Mon\n\(t)\n### Details\n\(t)\n## Next\nreal") == 1, "deeper sub-headings stay inside")
    expect(W("# Carried over from Mon\n\(t)\n## Notes\n\(t)\n# Real\nyes words") == 2)
    expect(W("## What I did\nmine here\n### Carried over from Mon\n\(t)\n## Next\nafter text") == 4, "a block nested in a normal section: 2 + 2")
    // multiple and nested blocks
    expect(W("## Carried over from Fri 2 Oct\n\(t)\n\n## Carried over from Mon 5 Oct\n\(t)\n\n## What I did\nreal words here") == 3)
    expect(W("## Carried over from Fri\n\(t)\n### Carried over from Mon\n\(t)\n## Next\nreal one") == 2)
    expect(W("## Carried over from Fri\n\(t)\n## Carried over from Mon\n\(t)\n### Carried over from Sun\n\(t)\n# Top\nreal one") == 2)
    // every kind of task line is skipped, ticked or rewritten, nested or not; other text under the block is the user's own
    let b = "## Carried over from Mon\n- [x] done thing here\n- [ ] rewritten into a much longer sentence than before\n* [ ] star task words\n1. [ ] numbered task words\n  - [ ] nested sub task words\n+ [X] plus task words"
    expect(W(b) == 0 && MarkdownBody.hasContent(b))
    expect(W(b + "\n\nmy own note under the block") == 6, "a paragraph typed under the block counts")
    expect(W(b + "\n- plain bullet two\n- plain bullet words") == 6, "so do plain bullets")
    expect(W(b + "\n\n```\ncode words\n```") == 2, "and code")
    expect(W("## Carried over from Mon\n<!-- c -->\n![](a.png)\n- [ ]\n\(t)") == 0 && MarkdownBody.hasContent("## Carried over from Mon\n![](a.png)"))
    // outside a carried block nothing changed
    expect(W("## To do next\n- [ ] one two three\n- [x] four five") == 5 && W("- [ ] loose task words") == 3)
    expect(W("## Carried over from Mon\n\n## Real\n\(t)") == 4, "an empty block ends at the next heading")
}
test("carry-over: apply is idempotent and never changes a page's word count") {
    let store = freshStore("carry-idem")
    try store.save(day: "2026-10-02", body: "## What I did\n" + lorem(25) + "\n\n## To do next\n- [ ] alpha beta\n- [ ] gamma delta\n\n## Pending / blocked\n- epsilon zeta")
    let card = CarryOver.card(before: "2026-10-06", calendar: cal, settings: Settings(), load: { (try? store.load($0)) ?? nil })!
    expect(card.items == ["alpha beta", "gamma delta", "epsilon zeta"])
    for body in ["", Settings.defaultTemplate, lorem(25), "## What I did\n" + lorem(30), "x y z\n\n" + Settings.defaultTemplate] {
        let once = CarryOver.apply(card, to: body)
        expect(CarryOver.apply(card, to: once) == once && CarryOver.isApplied(card, in: once) && !CarryOver.isApplied(card, in: body), "idempotent")
        expect(W(once) == W(body) && MarkdownBody.hasContent(once) && once.hasPrefix("## Carried over from Fri 2 Oct\n\n- [ ] alpha beta"))
        // ticking or editing the carried items afterwards changes nothing about the count or the idempotence
        let edited = once.replacingOccurrences(of: "- [ ] alpha beta", with: "- [x] alpha beta and a long rewrite of it")
        expect(W(edited) == W(body) && CarryOver.apply(card, to: edited) == edited)
    }
}

// MARK: search
test("search: headings, snippets, matching rules") {
    let store = freshStore("search")
    try store.save(day: "2026-10-05", body: "## 📝 What I did\nDrafted the Pricing page copy at the Café with Ana\n- [ ] review PRICING page with Ana\n\n## Finished\nPricing only")
    try store.save(day: "2026-10-06", body: "no headings here: notes on pricing and more")
    try store.skip("2026-10-07", reason: "pricing holiday")
    var hits = try store.search("pricing")
    expect(hits.map { $0.day } == ["2026-10-06", "2026-10-05", "2026-10-05"], "newest day first, one hit per section: \(hits.map { $0.day })")
    expect(hits.map { $0.heading } == [nil, "📝 What I did", "Finished"])
    let h = hits[1]
    expect(h.matchRange.map { String(h.snippet[$0]) } == "Pricing", "matchRange points at the match in its original case")
    expect(!h.snippet.contains("- [ ]") && !h.snippet.contains("##") && !h.snippet.contains("\n") && h.snippet.contains("review PRICING page"), h.snippet)
    try expect(try store.search("CAFE ana").map { $0.heading } == ["📝 What I did"], "case/diacritic-insensitive, words AND-ed")
    try expect(try store.search("pricing zebra").isEmpty && (try store.search("   ").isEmpty) && (try store.search("").isEmpty))
    try expect(try store.search("drafted finished").isEmpty, "words must co-occur inside one section (the heading text counts)")
    try expect(try store.search("pricing", heading: "to-do next").isEmpty && (try store.search("pricing", heading: "what I did").count == 1))
    try expect(try store.search("pricing", heading: "Finished").map { $0.day } == ["2026-10-05"])
    try expect(try store.search("holiday").isEmpty, "skipped days are not searched")
    try store.save(day: "2026-10-08", body: "## Pricing review\n\n## Notes\nnothing\n\n## Finished\n### Details\nneedle in a sub section\n\nintro without heading goes first")
    hits = try store.search("pricing review")
    expect(hits.map { $0.day } == ["2026-10-08", "2026-10-05"] && hits[0].heading == "Pricing review" && hits[0].snippet == "Pricing review", "heading-only match: \(hits)")
    try expect(try store.search("needle").map { $0.heading } == ["Details"], "nearest preceding heading")
    try store.save(day: "2026-10-09", body: "## Pricing\nreview notes")
    try expect(try store.search("pricing review").map { $0.day } == ["2026-10-09", "2026-10-08", "2026-10-05"], "words split between heading and text still match")
    try store.save(day: "2026-10-10", body: "```\nlet needle = 1\n```\n\n![needle alt](assets/x.png)\n<!-- needle -->")
    try expect(try store.search("needle").map { $0.day } == ["2026-10-10", "2026-10-08"].sorted(by: >), "code is searchable; image alt text and comments are not")
    let long = lorem(60) + " needle " + lorem(60, "t")
    try store.save(day: "2026-10-11", body: long)
    let lh = try store.search("needle").first { $0.day == "2026-10-11" }!
    expect(lh.heading == nil && lh.snippet.hasPrefix("…") && lh.snippet.hasSuffix("…") && lh.snippet.count < 140 && lh.matchRange.map { String(lh.snippet[$0]) } == "needle")
    // cutting a snippet next to combining marks / emoji sequences must neither crash nor shift the match
    let tricky = String(repeating: "e\u{0301}\u{0308} 👨‍👩‍👧 ", count: 30) + "needle" + String(repeating: " \u{0301}a👩🏽‍💻", count: 40)
    try store.save(day: "2026-10-13", body: tricky)
    let th = try store.search("needle").first { $0.day == "2026-10-13" }!
    expect(th.matchRange.map { String(th.snippet[$0]) } == "needle" && th.snippet.hasPrefix("…") && th.snippet.hasSuffix("…"))
    // an old v0.2 file is searchable too
    try raw("# 2026-10-12\n\n## 🚀 Started\nKicked off the zebra project\n\n", in: store.dir, day: "2026-10-12")
    try expect(try store.search("zebra").map { $0.heading } == ["🚀 Started"])
    expect(Search.hits(in: DayDocument(day: "2026-10-12", isSkipped: true, skipReason: "zebra"), query: "zebra").isEmpty)
}

// MARK: end to end through real files
test("store -> fileStates -> streak/heatmap/status/planner agree under the words rule") {
    let store = freshStore("e2e")
    for d in ["2026-10-05", "2026-10-06", "2026-10-08", "2026-10-09"] { try store.save(day: d, body: "## What I did\n" + lorem(25)) }
    try store.skip("2026-10-07", reason: "x")
    try store.save(day: "2026-10-12", body: Settings.defaultTemplate + "\n\n" + lorem(5))
    let now = mk(2026, 10, 12, 18)
    let st = try store.fileStates(minWords: 20)
    expect(st["2026-10-12"] == .partial && st["2026-10-05"] == .logged && st["2026-10-07"] == .skipped)
    expect(Streak.compute(states: st, now: now, calendar: cal, weekdays: workdays) == StreakResult(current: 4, best: 4), "partial today is 'not yet'")
    func status(_ day: String, _ s: [String: DayStatus]) -> DayStatus {
        Status.resolve(day: day, fileState: s[day], now: now, calendar: cal, weekdays: workdays, since: s.keys.min())
    }
    expect(status("2026-10-12", st) == .partial && status("2026-10-13", st) == .future && status("2026-10-10", st) == .off && status("2026-10-02", st) == .off)
    let hm = Heatmap.weeks(states: st, now: now, calendar: cal, weekdays: workdays)
    expect(hm.last!.map { $0.status } == [.partial, .future, .future, .future, .future, .future, .future] && hm.last![0].isToday)
    expect(hm[10].map { $0.status } == [.logged, .logged, .skipped, .logged, .logged, .off, .off])
    // planner: a partial page still nags; reaching minWords stops it
    var s = Settings(); s.minWords = 20
    let fresh = PlannerState(day: "2026-10-12")
    expect(ReminderPlanner.decide(now: now, calendar: cal, settings: s, todayStatus: status("2026-10-12", st), state: fresh, windowVisible: true).0 == .bringToFront(notify: true))
    try store.save(day: "2026-10-12", body: Settings.defaultTemplate + "\n\n" + lorem(25))
    let st2 = try store.fileStates(minWords: 20)
    expect(status("2026-10-12", st2) == .logged)
    expect(ReminderPlanner.decide(now: now, calendar: cal, settings: s, todayStatus: status("2026-10-12", st2), state: fresh, windowVisible: true).0 == .none)
    expect(Streak.compute(states: st2, now: now, calendar: cal, weekdays: workdays) == StreakResult(current: 5, best: 5))
    // changing the threshold re-evaluates history
    let st3 = try store.fileStates(minWords: 30)
    expect(st3["2026-10-05"] == .partial && st3["2026-10-07"] == .skipped)
    expect(Streak.compute(states: st3, now: now, calendar: cal, weekdays: workdays) == StreakResult(current: 0, best: 0))
    let st4 = try store.fileStates(minWords: 5)
    expect(st4["2026-10-12"] == .logged && Streak.compute(states: st4, now: now, calendar: cal, weekdays: workdays).current == 5)
    // a day that was emptied again is no log at all
    try store.save(day: "2026-10-09", body: "")
    try expect(try store.fileStates(minWords: 20)["2026-10-09"] == nil)
    try expect(Streak.compute(states: try store.fileStates(minWords: 20), now: now, calendar: cal, weekdays: workdays).current == 1, "Friday missed -> only Monday counts")
}

// MARK: settings added for real-world navigation (M1)
test("settings M1 fields: defaults, round trip, tolerant decode, clamping") {
    let d = Settings()
    expect(d.logStartDate == nil && d.appearance == .system && d.weekStart == nil && d.catchUpWindowDays == 30)
    let mem = MemoryStore()
    var s = Settings(); s.logStartDate = "2026-10-01"; s.appearance = .dark; s.weekStart = 2; s.catchUpWindowDays = 90
    s.save(to: mem)
    let back = Settings.load(from: mem)
    expect(back.logStartDate == "2026-10-01" && back.appearance == .dark && back.weekStart == 2 && back.catchUpWindowDays == 90)
    // a v0.3 save (none of the new keys) decodes to the defaults
    let old = #"{"reminderMinutes":1020,"minWords":25,"onboarded":true}"#.data(using: .utf8)!
    let o = try JSONDecoder().decode(Settings.self, from: old).normalized()
    expect(o.minWords == 25 && o.onboarded && o.logStartDate == nil && o.appearance == .system && o.catchUpWindowDays == 30)
    // clamping and validation
    var bad = Settings(); bad.catchUpWindowDays = 3; bad.logStartDate = "garbage"; bad.weekStart = 9
    let n = bad.normalized()
    expect(n.catchUpWindowDays == 7 && n.logStartDate == nil && n.weekStart == nil)
    bad.catchUpWindowDays = 99999; bad.weekStart = 2; bad.logStartDate = "2026-09-30"
    let m = bad.normalized()
    expect(m.catchUpWindowDays == 365 && m.weekStart == 2 && m.logStartDate == "2026-09-30")
}

// MARK: legacy migration (rename Daily Log -> Gloamlog)
test("legacy migration: settings keys are copied once, never overwritten, system keys ignored") {
    let oldName = "dl-test-old-" + UUID().uuidString, newName = "dl-test-new-" + UUID().uuidString
    let old = UserDefaults(suiteName: oldName)!, new = UserDefaults(suiteName: newName)!
    defer { old.removePersistentDomain(forName: oldName); new.removePersistentDomain(forName: newName) }
    old.set(Data([1, 2, 3]), forKey: "dailylog.settings.v2"); old.set(true, forKey: "showMenuBar"); old.set("x", forKey: "unrelated")
    let n = LegacyMigration.migrateDefaults(from: old, to: new)
    expect(n == 2, "copied \(n)")
    expect(new.data(forKey: "dailylog.settings.v2") == Data([1, 2, 3]) && new.bool(forKey: "showMenuBar"))
    expect(new.object(forKey: "unrelated") == nil, "keys outside our namespace are not copied")
    new.set(Data([9]), forKey: "dailylog.settings.v2")
    expect(LegacyMigration.migrateDefaults(from: old, to: new) == 0 && new.data(forKey: "dailylog.settings.v2") == Data([9]), "second run changes nothing, existing values win")
    expect(LegacyMigration.migrateDefaults(from: nil, to: new) == 0)
}
test("legacy migration: support folder moves once and only when the new one is absent") {
    let fm = FileManager.default
    let support = freshDir("support")
    let old = support.appendingPathComponent("Daily Log/backups/2026-10-06", isDirectory: true)
    try fm.createDirectory(at: old, withIntermediateDirectories: true)
    try "v1".write(to: old.appendingPathComponent("20261006-171500.md"), atomically: true, encoding: .utf8)
    expect(LegacyMigration.migrateSupportFolder(in: support) == true)
    expect(!fm.fileExists(atPath: support.appendingPathComponent("Daily Log").path))
    expect(fm.fileExists(atPath: support.appendingPathComponent("Gloamlog/backups/2026-10-06/20261006-171500.md").path), "backup survives the move")
    expect(LegacyMigration.migrateSupportFolder(in: support) == false, "nothing left to move")
    // both exist: leave both alone, never merge or overwrite
    try fm.createDirectory(at: support.appendingPathComponent("Daily Log"), withIntermediateDirectories: true)
    expect(LegacyMigration.migrateSupportFolder(in: support) == false)
    expect(fm.fileExists(atPath: support.appendingPathComponent("Daily Log").path) && fm.fileExists(atPath: support.appendingPathComponent("Gloamlog").path))
    // nothing at all
    expect(LegacyMigration.migrateSupportFolder(in: freshDir("empty-support")) == false)
}
test("default storage folder is Gloamlog for new installs") {
    expect(Settings.defaultFolder.lastPathComponent == "Gloamlog" && Settings().storageFolder.lastPathComponent == "Gloamlog")
}

try? FileManager.default.removeItem(at: root)
print("\(passed) passed, \(failed) failed")
exit(failed == 0 ? 0 : 1)
