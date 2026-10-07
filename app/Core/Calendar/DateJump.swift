// DateJump.swift - "Go to date" text parser. Pure. Owned by the core stream (task C3).
// CONTRACT (signature frozen):
//   parse("yesterday" | "today" | "-3" | "3 days ago" | "last fri" | "fri" | "2 oct" | "oct 2" | "2 October 2026" | "2026-10-02" | "10/2")
//   -> a day key "yyyy-MM-dd" that is not after today, or nil when the text cannot be read or names a future day.
//   "last fri" = the most recent Friday strictly before today; "fri" = the most recent Friday on or before today.
//
// Grammar (case, surrounding and repeated whitespace, commas and trailing periods are ignored; English words only):
//   today | yesterday                      -n  (n days back, n >= 0)            n day(s) ago | n week(s) ago
//   <weekday> | last <weekday>             sun mon tue(s) wed(s) thu(r)(s) fri sat, or the full name
//   <d> <month> | <month> <d>              d = 1...31 with an optional st/nd/rd/th; month = jan..dec, sept, full names
//   <d> <month> <yyyy> | <month> <d> <yyyy>
//   yyyy-M-d (also yyyy/M/d, yyyy.M.d)     ISO order, never locale dependent
//   a/b, a/b/yy, a/b/yyyy (also - and .)   field ORDER comes from calendar.locale (en_US 10/2 = 2 Oct, en_GB 10/2 = 10 Feb,
//                                          ja_JP y/M/d); a calendar with no locale (nil, or the empty root locale that
//                                          Calendar(identifier:) carries) behaves like en_US so results never depend on the machine.
// A date without a year is the most recent occurrence on or before today (2 dec read in October = last December; 29 feb = the last
// leap day), so the result is never in the future. An explicit year in the future gives nil. "tomorrow" gives nil. Days before
// 2000-01-01 and impossible dates (31 feb, month 13, 29 feb 2026) give nil. No guessing: 13/2 is nil in en_US, never swapped to 13 Feb.
// DateFormatter is used only to learn the locale's field order; month and weekday names are not localised and NSDataDetector is
// not used, so the result is the same on every machine.
import Foundation

enum DateJump {
    static let earliestDay = "2000-01-01"
    private static let maxDaysBack = 60_000   // far beyond 2000 for any real "now"; keeps the arithmetic far from overflow

    static func parse(_ input: String, now: Date, calendar: Calendar) -> String? {
        let today = DayKey.string(now, calendar)
        guard let key = resolve(words(input), today: today, calendar: calendar),
              key >= earliestDay, key <= today, DayKey.date(key, calendar) != nil else { return nil }
        return key
    }

    // MARK: grammar
    private static let weekdayNames: [String: Int] = [
        "sun": 1, "sunday": 1, "mon": 2, "monday": 2, "tue": 3, "tues": 3, "tuesday": 3, "wed": 4, "weds": 4, "wednesday": 4,
        "thu": 5, "thur": 5, "thurs": 5, "thursday": 5, "fri": 6, "friday": 6, "sat": 7, "saturday": 7]
    private static let monthNames: [String: Int] = [
        "jan": 1, "january": 1, "feb": 2, "february": 2, "mar": 3, "march": 3, "apr": 4, "april": 4, "may": 5, "jun": 6, "june": 6,
        "jul": 7, "july": 7, "aug": 8, "august": 8, "sep": 9, "sept": 9, "september": 9, "oct": 10, "october": 10,
        "nov": 11, "november": 11, "dec": 12, "december": 12]

    private static func words(_ input: String) -> [String] {
        input.lowercased().replacingOccurrences(of: ",", with: " ").split(whereSeparator: { $0.isWhitespace }).map { w in
            var s = Substring(w)
            while s.hasSuffix(".") { s = s.dropLast() }          // "oct.", "fri.", "10.2."
            return String(s)
        }.filter { !$0.isEmpty }
    }

    private static func resolve(_ t: [String], today: String, calendar: Calendar) -> String? {
        func back(_ days: Int) -> String? { (0...maxDaysBack).contains(days) ? DayKey.adding(today, -days, calendar) : nil }
        func weekday(_ name: String, strictlyBefore: Bool) -> String? {
            guard let wd = weekdayNames[name] else { return nil }
            let delta = (DayKey.weekday(today, calendar) - wd + 7) % 7
            return back(strictlyBefore && delta == 0 ? 7 : delta)
        }
        switch t.count {
        case 1:
            let w = t[0]
            if w == "today" { return today }
            if w == "yesterday" { return back(1) }
            if w.hasPrefix("-") { return number(w.dropFirst()).flatMap(back) }          // "-3"
            return weekday(w, strictlyBefore: false) ?? numericDate(w, today: today, calendar: calendar)
        case 2:
            if t[0] == "last" { return weekday(t[1], strictlyBefore: true) }
            return monthDay(t, today: today, calendar: calendar)
        case 3:
            if t[2] == "ago", let n = number(t[0]) {
                switch t[1] {
                case "day", "days": return back(n)
                case "week", "weeks": return back(n * 7)                                // n <= 999,999,999, so n * 7 cannot overflow
                default: return nil
                }
            }
            return monthDay(t, today: today, calendar: calendar)
        default:
            return nil
        }
    }

    /// "2 oct", "oct 2", "2nd october", "2 oct 2026", "oct 2, 2026": one month name, one day, an optional 4-digit year last.
    private static func monthDay(_ t: [String], today: String, calendar: Calendar) -> String? {
        var month: Int?, day: Int?, year: Int?
        for (i, w) in t.enumerated() {
            if let m = monthNames[w] {
                guard month == nil else { return nil }
                month = m
            } else if t.count == 3, i == 2, w.count == 4, let y = number(w) {
                year = y
            } else if let d = dayNumber(w) {
                guard day == nil else { return nil }
                day = d
            } else {
                return nil
            }
        }
        guard let m = month, let d = day else { return nil }
        return year.map { dateKey($0, m, d, calendar) } ?? latest(month: m, day: d, today: today, calendar: calendar)
    }

    /// "10/2", "10/2/26", "10/2/2026", "2026-10-02" (and the "." and "-" separators).
    private static func numericDate(_ w: String, today: String, calendar: Calendar) -> String? {
        guard let sep = w.first(where: { !isDigit($0) }), "/.-".contains(sep) else { return nil }
        let parts = w.split(separator: sep, omittingEmptySubsequences: false).map(String.init)
        let n = parts.compactMap { $0.count <= 4 ? number($0) : nil }
        guard (2...3).contains(parts.count), n.count == parts.count else { return nil }   // 2 or 3 parts, each 1-4 digits
        if parts.count == 3, parts[0].count == 4 { return dateKey(n[0], n[1], n[2], calendar) }   // ISO order, not locale dependent
        // Calendar(identifier:) carries the root locale (empty identifier), not nil: both count as "no locale" and read like en_US.
        let order = fieldOrder(calendar.locale.flatMap { $0.identifier.isEmpty ? nil : $0 } ?? Locale(identifier: "en_US"))
        var month: Int?, day: Int?, year: Int?
        for (i, field) in (parts.count == 3 ? order : order.filter { $0 != "y" }).enumerated() {
            switch field {
            case "y":
                guard parts[i].count == 2 || parts[i].count == 4 else { return nil }
                year = parts[i].count == 2 ? 2000 + n[i] : n[i]
            case "M": guard parts[i].count <= 2 else { return nil }; month = n[i]
            default: guard parts[i].count <= 2 else { return nil }; day = n[i]
            }
        }
        guard let m = month, let d = day else { return nil }
        return parts.count == 3 ? year.flatMap { dateKey($0, m, d, calendar) } : latest(month: m, day: d, today: today, calendar: calendar)
    }

    /// Order of the numeric fields in the locale's short date: ["M","d","y"] (en_US), ["d","M","y"] (en_GB), ["y","M","d"] (ja_JP).
    private static func fieldOrder(_ locale: Locale) -> [Character] {
        var order = [Character]()
        for ch in DateFormatter.dateFormat(fromTemplate: "yMd", options: 0, locale: locale) ?? "" {
            let f: Character = (ch == "y" || ch == "Y") ? "y" : (ch == "M" || ch == "L") ? "M" : ch == "d" ? "d" : " "
            if f != " ", !order.contains(f) { order.append(f) }
        }
        return order.count == 3 ? order : ["M", "d", "y"]
    }

    // MARK: helpers
    private static func isDigit(_ c: Character) -> Bool { c.asciiValue.map { $0 >= 48 && $0 <= 57 } ?? false }   // ASCII only
    /// 1...9 ASCII digits -> Int (nine digits cannot overflow); anything else nil.
    private static func number<S: StringProtocol>(_ s: S) -> Int? {
        s.isEmpty || s.count > 9 || !s.allSatisfy(isDigit) ? nil : Int(s)
    }
    /// "2", "02", "2nd", "31st" -> 2, 2, 2, 31 (1...31 only).
    private static func dayNumber(_ w: String) -> Int? {
        var s = Substring(w)
        for suffix in ["st", "nd", "rd", "th"] where s.hasSuffix(suffix) { s = s.dropLast(2); break }
        guard s.count <= 2, let d = number(s), (1...31).contains(d) else { return nil }
        return d
    }
    /// The key for y-m-d, or nil when that date does not exist (31 feb, 29 feb 2026).
    private static func dateKey(_ y: Int, _ m: Int, _ d: Int, _ calendar: Calendar) -> String? {
        let key = String(format: "%04ld-%02ld-%02ld", y, m, d)
        return DayKey.date(key, calendar) == nil ? nil : key
    }
    /// Month and day without a year: the most recent occurrence on or before today (29 feb walks back to the last leap day).
    private static func latest(month: Int, day: Int, today: String, calendar: Calendar) -> String? {
        guard let year = Int(today.prefix(4)) else { return nil }
        for y in stride(from: year, through: year - 8, by: -1) {
            if let k = dateKey(y, month, day, calendar), k <= today { return k }
        }
        return nil
    }
}
