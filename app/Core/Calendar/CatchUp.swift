// CatchUp.swift - which scheduled days still need writing, and batch skipping. Owned by the core stream (task C4).
// CONTRACT (signatures frozen):
//   missing(...)  scheduled days in the last `windowDays` days BEFORE today, oldest first, whose state is .missed or .partial.
//                 Skipped, logged, off, future and today are never listed; days before the effective log start are never listed.
//                 windowDays is clamped to Settings.catchUpWindowRange (7...365): a day exactly windowDays back is in, one further is out.
//                 With no log start and no page at all there is nothing to catch up on (a new user's days before the first page don't count).
//   next(after:in:) first entry strictly after `day` (the first entry when day is nil); nil when there is none.
//   skipDays / unskipDays: one skip marker per day; both return the days actually changed, in the order given, each day once.
//
// skipDays rules (the existing LogStore.skip rules, applied per day):
//   - a day with writing is left alone, not an error; a day that is already a skip marker is left alone too (any reason), so the
//     returned list is exactly what Undo may remove and Undo can never delete a marker this call did not create;
//   - a page with no writing (headings only) is replaced by the marker; undo then leaves no file for that day (it carried nothing);
//   - all malformed days are rejected (.badDay) before anything is written; if a write fails midway the markers this call already
//     wrote are removed again and the error is thrown, so a failed call changes nothing.
// unskipDays removes a marker only while the file is still a pure skip marker (a day the user wrote into since, or a marker someone
// added notes to, is left alone). A skip followed by undo leaves the folder byte-identical for days that had no page.
import Foundation

enum CatchUp {
    /// The one rule behind the Catch up list, the sidebar count and WeekSummary.missingDays: a scheduled day, strictly before today and
    /// on or after the log start, that is unwritten (.missed) or only started (.partial). `status` is the day's resolved status.
    static func isMissing(day: String, weekday: Int, status: DayStatus, today: String, since: String?, weekdays: Set<Int>) -> Bool {
        guard let since = since, day >= since, day < today, weekdays.contains(weekday) else { return false }
        return status == .missed || status == .partial
    }

    static func missing(states: [String: DayStatus], now: Date, calendar: Calendar, weekdays: Set<Int>,
                        logStart: String?, windowDays: Int) -> [String] {
        let today = DayKey.string(now, calendar)
        guard let since = Status.effectiveSince(setting: logStart, states: states),
              var date = DayKey.date(today, calendar) else { return [] }
        let window = min(max(windowDays, Settings.catchUpWindowRange.lowerBound), Settings.catchUpWindowRange.upperBound)
        var newestFirst = [String]()
        for _ in 0..<window {                                   // yesterday, then one day further back each step
            guard let d = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = d
            let key = DayKey.string(d, calendar)
            if key < since { break }                            // nothing earlier counts
            let status = Status.resolve(day: key, fileState: states[key], now: now, calendar: calendar, weekdays: weekdays, since: since)
            if isMissing(day: key, weekday: calendar.component(.weekday, from: d), status: status, today: today, since: since, weekdays: weekdays) {
                newestFirst.append(key)
            }
        }
        return newestFirst.reversed()
    }

    static func next(after day: String?, in list: [String]) -> String? {
        guard let day = day else { return list.first }
        return list.first { $0 > day }
    }
}

extension LogStore {
    func skipDays(_ days: [String], reason: String) throws -> [String] {
        let list = try uniqueDays(days)
        var done = [String]()
        do {
            for d in list {
                if let page = try load(d), page.isSkipped { continue }
                do { try skip(d, reason: reason); done.append(d) } catch LogError.hasContent { continue }
            }
        } catch {
            for d in done { _ = try? unskip(d) }                // a failed call changes nothing
            throw error
        }
        return done
    }

    func unskipDays(_ days: [String]) throws -> [String] {
        var restored = [String]()
        for d in try uniqueDays(days) where try unskip(d) { restored.append(d) }
        return restored
    }

    /// `days` without repeats, in order; throws .badDay for the first malformed entry before anything is touched.
    private func uniqueDays(_ days: [String]) throws -> [String] {
        var seen = Set<String>(), out = [String]()
        for d in days {
            guard DayKey.isWellFormed(d) else { throw LogError.badDay(d) }
            if seen.insert(d).inserted { out.append(d) }
        }
        return out
    }
}
