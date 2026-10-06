// WeeklyReview.swift - one week's aggregate and "Copy week as markdown".
//
// API:
//   WeeklyReview.summary(weekContaining:, entries:, states:, settings:, calendar:, now:) -> WeekSummary
//       entries = [dayKey: DayEntry] (LogStore.entries(from:to:)); states = LogStore.fileStates()
//   WeeklyReview.shift(_ date, weeks:, calendar:) -> Date          prev/next week (UI disables future)
//   WeeklyReview.markdown(for:, grouping: .day | .section, sections:, calendar:) -> String
//   WeekSummary: weekStart, weekEnd, days:[WeekDay], loggedCount, workdayCount (scheduled days not in the future),
//                skippedCount, items(forSection:) -> [(day, text)]   e.g. items(forSection: "finished")
// Weeks start on calendar.firstWeekday. Unlogged days are omitted from the markdown (never listed as missed).
import Foundation

struct WeekDay: Equatable {
    var day: String
    var status: DayStatus
    var entry: DayEntry?
}

struct WeekSummary: Equatable {
    var weekStart: String
    var weekEnd: String
    var days: [WeekDay]
    var sections: [SectionDef]
    var loggedCount: Int
    var workdayCount: Int
    var skippedCount: Int

    func items(forSection id: String) -> [(day: String, text: String)] {
        days.compactMap { d in
            guard let t = d.entry?.texts[id], !t.dlTrimmed.isEmpty, d.status != .skipped else { return nil }
            return (d.day, t)
        }
    }
    static func == (a: WeekSummary, b: WeekSummary) -> Bool {
        a.weekStart == b.weekStart && a.days == b.days && a.loggedCount == b.loggedCount
    }
}

enum WeekGrouping { case day, section }

enum WeeklyReview {
    static func shift(_ date: Date, weeks: Int, calendar: Calendar) -> Date {
        calendar.date(byAdding: .weekOfYear, value: weeks, to: date) ?? date
    }

    static func summary(weekContaining date: Date, entries: [String: DayEntry], states: [String: DayStatus],
                        settings: Settings, calendar: Calendar, now: Date) -> WeekSummary {
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start ?? date
        let since = states.keys.min()
        var days = [WeekDay](), logged = 0, work = 0, skipped = 0
        for i in 0..<7 {
            guard let d = calendar.date(byAdding: .day, value: i, to: start) else { continue }
            let k = DayKey.string(d, calendar)
            let st = Status.resolve(day: k, fileState: states[k], now: now, calendar: calendar, weekdays: settings.weekdays, since: since)
            days.append(WeekDay(day: k, status: st, entry: entries[k]))
            if st == .logged { logged += 1 }
            if st == .skipped { skipped += 1 }
            if st != .future && settings.weekdays.contains(calendar.component(.weekday, from: d)) { work += 1 }
        }
        return WeekSummary(weekStart: days.first?.day ?? "", weekEnd: days.last?.day ?? "", days: days, sections: settings.sections,
                           loggedCount: logged, workdayCount: work, skippedCount: skipped)
    }

    static func markdown(for w: WeekSummary, grouping: WeekGrouping, sections: [SectionDef], calendar: Calendar) -> String {
        func short(_ k: String) -> String { DayKey.format(k, "EEE d MMM", calendar) }
        var out = "# Week of \(DayKey.format(w.weekStart, "d MMM", calendar)) – \(DayKey.format(w.weekEnd, "d MMM yyyy", calendar))\n\n"
        out += "Logged \(w.loggedCount) of \(w.workdayCount) workdays" + (w.skippedCount > 0 ? " · \(w.skippedCount) skipped" : "") + "\n\n"
        switch grouping {
        case .day:
            for d in w.days {
                guard let e = d.entry else { continue }
                if d.status == .skipped {
                    out += "## \(short(d.day))\n_Skipped" + (e.skipReason.isEmpty ? "" : ": \(e.skipReason)") + "_\n\n"
                    continue
                }
                var body = ""
                for s in sections { if let t = e.texts[s.id], !t.dlTrimmed.isEmpty { body += "### \(s.title)\n\(t)\n\n" } }
                for x in e.extras where !x.text.dlTrimmed.isEmpty { body += "### \(x.title)\n\(x.text)\n\n" }
                if !body.isEmpty { out += "## \(short(d.day))\n\n" + body }
            }
        case .section:
            for s in sections {
                let items = w.items(forSection: s.id)
                if items.isEmpty { continue }
                out += "## \(s.title)\n\n"
                for it in items {
                    let lines = it.text.components(separatedBy: "\n")
                    out += "- **\(short(it.day))**: \(lines[0])\n"
                    for l in lines.dropFirst() { out += l.isEmpty ? "\n" : "  \(l)\n" }
                }
                out += "\n"
            }
        }
        return out.dlTrimmed + "\n"
    }
}
