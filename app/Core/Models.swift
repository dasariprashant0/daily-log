// Models.swift - core value types for Daily Log v0.2 (Foundation only).
//
// API:
//   DayKey            "yyyy-MM-dd" day strings: string(date,cal) / date(key,cal) / adding(key,n,cal) / weekday(key,cal)
//   DayStatus         logged | partial | skipped | missed | off | future
//   SectionDef        {id (stable), title, hint, required}; SectionDef.validationError(list) -> String?
//   DefaultSections   .all (v0.1 emoji headings, ids did/finished/started/pending/todo)
//   DayEntry          {date, texts[sectionID], extras (unknown headings, preserved), isSkipped, skipReason, status}
// All dates are passed in with a Calendar; nothing here reads the clock.
import Foundation

extension String {
    /// Whitespace/newline trimmed copy (named to avoid clashing with v0.1's `trimmed`).
    var dlTrimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

enum DayKey {
    /// Shape check only ("2026-10-06"); guards file names against path tricks.
    static func isWellFormed(_ s: String) -> Bool {
        let u = Array(s.utf8)
        guard u.count == 10 else { return false }
        for (i, b) in u.enumerated() {
            if i == 4 || i == 7 { if b != 45 { return false } } else if b < 48 || b > 57 { return false }
        }
        return true
    }
    static func string(_ date: Date, _ cal: Calendar) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04ld-%02ld-%02ld", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
    /// Start of that day in `cal`'s time zone; nil for malformed or impossible dates (2026-02-30).
    static func date(_ key: String, _ cal: Calendar) -> Date? {
        guard isWellFormed(key) else { return nil }
        let p = key.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3, let d = cal.date(from: DateComponents(year: p[0], month: p[1], day: p[2])) else { return nil }
        return string(d, cal) == key ? d : nil
    }
    /// Calendar-based day arithmetic (DST safe: never adds 86400 seconds).
    static func adding(_ key: String, _ days: Int, _ cal: Calendar) -> String? {
        guard let d = date(key, cal), let n = cal.date(byAdding: .day, value: days, to: d) else { return nil }
        return string(n, cal)
    }
    /// Calendar weekday number, 1 = Sunday ... 7 = Saturday.
    static func weekday(_ key: String, _ cal: Calendar) -> Int {
        guard let d = date(key, cal) else { return 0 }
        return cal.component(.weekday, from: d)
    }
    /// Formatted with `format` (e.g. "EEE d MMM"), English names, in cal's time zone.
    static func format(_ key: String, _ format: String, _ cal: Calendar) -> String {
        guard let d = date(key, cal) else { return key }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX"); f.calendar = cal; f.timeZone = cal.timeZone
        f.dateFormat = format
        return f.string(from: d)
    }
}

enum DayStatus: String, Codable, Equatable {
    case logged   // file exists, every (required) section filled
    case partial  // file exists, something empty
    case skipped  // skip marker file
    case missed   // scheduled day, no file (today unlogged is also .missed; UI draws today's ring)
    case off      // not a scheduled day, no file (or before the first ever entry)
    case future   // after today
}

struct SectionDef: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var hint: String
    var required: Bool
    init(id: String = UUID().uuidString, title: String, hint: String = "", required: Bool = true) {
        self.id = id; self.title = title; self.hint = hint; self.required = required
    }
    /// nil when valid: 1 to 10 sections, titles 1 to 40 chars, unique (case-insensitive), no leading '#', no newline.
    static func validationError(_ list: [SectionDef]) -> String? {
        if list.isEmpty || list.count > 10 { return "Use between 1 and 10 sections." }
        var seen = Set<String>(), ids = Set<String>()
        for s in list {
            let t = s.title.dlTrimmed
            if t.isEmpty || t.count > 40 { return "Section names must be 1 to 40 characters." }
            if t.hasPrefix("#") { return "Section names cannot start with #." }
            if t.contains("\n") { return "Section names must be one line." }
            if !seen.insert(t.lowercased()).inserted { return "Section names must be unique." }
            if !ids.insert(s.id).inserted { return "Duplicate section id." }
        }
        return nil
    }
}

enum DefaultSections {
    static let did = SectionDef(id: "did", title: "📝 What I did", hint: "Everything you worked on today…")
    static let finished = SectionDef(id: "finished", title: "✅ Finished", hint: "What got done and closed…")
    static let started = SectionDef(id: "started", title: "🚀 Started", hint: "What you kicked off…")
    static let pending = SectionDef(id: "pending", title: "⏳ Pending / blocked", hint: "What's waiting on someone or something…")
    static let todo = SectionDef(id: "todo", title: "📌 To do next", hint: "What needs doing tomorrow…")
    static let all: [SectionDef] = [did, finished, started, pending, todo]
}

/// A heading in a file that matches no known section; kept verbatim on save.
struct ExtraSection: Equatable { var title: String; var text: String }

struct DayEntry: Equatable {
    var date: String                       // "yyyy-MM-dd"
    var texts: [String: String]            // sectionID -> text. A missing key = section absent from the file.
    var extras: [ExtraSection] = []
    var isSkipped = false
    var skipReason = ""
    /// Set by LogStore.load (logged/partial/skipped). Ignored by save (recomputed from content).
    var status: DayStatus = .partial

    init(date: String, texts: [String: String] = [:], extras: [ExtraSection] = [], isSkipped: Bool = false, skipReason: String = "") {
        self.date = date; self.texts = texts; self.extras = extras
        self.isSkipped = isSkipped; self.skipReason = skipReason
        refreshStatus(sections: DefaultSections.all)
    }

    /// logged = has at least one section and every present section is non-empty (empty NON-required ones are tolerated).
    func computeStatus(sections: [SectionDef]) -> DayStatus {
        if isSkipped { return .skipped }
        if texts.isEmpty && extras.isEmpty { return .partial }
        for (id, t) in texts where t.dlTrimmed.isEmpty {
            if sections.first(where: { $0.id == id })?.required ?? true { return .partial }
        }
        if extras.contains(where: { $0.text.dlTrimmed.isEmpty }) { return .partial }
        return .logged
    }
    mutating func refreshStatus(sections: [SectionDef]) { status = computeStatus(sections: sections) }
}
