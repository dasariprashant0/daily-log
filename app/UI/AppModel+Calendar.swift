// AppModel+Calendar.swift - any-date navigation: which days can be opened, the sidebar's month, the relative label for a
// past page, "Go to date", and the folder stamp that decides whether the day files must be read again.
import SwiftUI

struct YearMonth: Equatable, Hashable {
    var year: Int
    var month: Int
    init(year: Int, month: Int) { self.year = year; self.month = month }
    init(day: String) { year = Int(day.prefix(4)) ?? 2000; month = Int(day.dropFirst(5).prefix(2)) ?? 1 }
    func adding(months n: Int) -> YearMonth {
        let t = max(0, year * 12 + (month - 1) + n)
        return YearMonth(year: t / 12, month: t % 12 + 1)
    }
    var key: String { String(format: "%04d-%02d", year, month) }
    var firstDay: String { key + "-01" }
    static func < (a: YearMonth, b: YearMonth) -> Bool { a.year != b.year ? a.year < b.year : a.month < b.month }
}

enum GoToOutcome: Equatable { case opened(String), unreadable, future }

extension AppModel {
    /// The oldest page the app offers (PRD: any date up to today, back to the year 2000).
    static let earliestDay = "2000-01-01"

    // MARK: which days open
    /// Any real date from 2000-01-01 to today, whether or not a file exists. Opening never writes: the first real edit does.
    func canOpen(_ day: String) -> Bool { DayKey.date(day, cal) != nil && day >= AppModel.earliestDay && day <= today }
    func canStep(_ dir: Int) -> Bool {
        guard case .day(let cur) = selection, let n = DayKey.adding(cur, dir, cal) else { return false }
        return canOpen(n)
    }
    func isBeforeLogStart(_ day: String) -> Bool { if let s = since { return day < s }; return false }

    // MARK: the sidebar month
    var thisMonth: YearMonth { YearMonth(day: today) }
    func canShift(_ m: YearMonth, by n: Int) -> Bool {
        let t = m.adding(months: n)
        return !(t < YearMonth(day: AppModel.earliestDay)) && !(thisMonth < t)
    }
    func shiftMonth(_ n: Int) { if canShift(shownMonth, by: n) { shownMonth = shownMonth.adding(months: n) } }
    /// The one-week strip (windows too short for a month): arrows move a week at a time.
    func weekStart(of day: String) -> String? {
        guard let d = DayKey.date(day, cal), let s = cal.dateInterval(of: .weekOfYear, for: d)?.start else { return nil }
        return DayKey.string(s, cal)
    }
    func canShiftStrip(_ weeks: Int) -> Bool {
        guard let t = DayKey.adding(stripDay, 7 * weeks, cal), let ws = weekStart(of: t) else { return false }
        return weeks < 0 ? (DayKey.adding(ws, 6, cal) ?? ws) >= AppModel.earliestDay : ws <= today
    }
    func shiftStrip(_ weeks: Int) { if canShiftStrip(weeks), let t = DayKey.adding(stripDay, 7 * weeks, cal) { stripDay = t } }

    func monthGrid(year: Int, month: Int) -> [[MonthCell]] {
        MonthGrid.rows(year: year, month: month, states: states, now: now, calendar: cal, weekdays: settings.weekdays,
                       logStart: settings.logStartDate)
    }

    // MARK: words for a day
    /// "Tuesday 6 October, not logged" for VoiceOver and tooltips.
    func statusWord(_ day: String) -> String {
        switch status(of: day) {
        case .logged: return "logged"
        case .partial: return "started"
        case .missed: return "not logged"
        case .skipped: let r = skipReasons[day] ?? ""; return r.isEmpty ? "skipped" : "skipped, \(r)"
        case .off: return isBeforeLogStart(day) ? "before your log start" : "not a workday"
        case .future: return "upcoming"
        }
    }
    func spokenStatus(_ day: String) -> String {
        "\(spokenDate(day)), \(statusWord(day))" + (day == today ? ", today" : "")
    }

    /// "Yesterday", "6 days ago", "3 weeks ago": the only cue that a page is a past one. Nothing for today.
    func relativeLabel(for day: String) -> String? {
        guard day < today, let a = DayKey.date(day, cal), let b = DayKey.date(today, cal) else { return nil }
        let n = cal.dateComponents([.day], from: a, to: b).day ?? 0
        switch n {
        case ..<1: return nil
        case 1: return "Yesterday"
        case 2...13: return "\(n) days ago"
        case 14...55: return "\(n / 7) weeks ago"
        default:
            let m = cal.dateComponents([.month], from: a, to: b).month ?? 0
            if m >= 12 { let y = m / 12; return y == 1 ? "1 year ago" : "\(y) years ago" }
            return m <= 1 ? "1 month ago" : "\(m) months ago"
        }
    }

    // MARK: Go to date
    /// What the text names, as a day key, or nil. Also drives the live preview in the popover.
    func resolvedDate(_ text: String) -> String? {
        guard !text.dlTrimmed.isEmpty, let d = DateJump.parse(text, now: now, calendar: cal), canOpen(d) else { return nil }
        return d
    }
    private func namesAFutureDay(_ text: String) -> Bool {
        let t = text.dlTrimmed.lowercased()
        if t == "tomorrow" { return true }
        return DayKey.isWellFormed(t) && DayKey.date(t, cal) != nil && t > today
    }
    /// Opens the day the text names. An unreadable entry opens nothing.
    @discardableResult
    func goToDate(_ text: String) -> GoToOutcome {
        if let d = resolvedDate(text) { openDay(d, focus: true); return .opened(d) }
        return namesAFutureDay(text) ? .future : .unreadable
    }

    // MARK: the folder stamp
    /// Names, times and sizes of the day files (Core: LogStore.folderStamp): unchanged means nothing outside the app touched the
    /// folder, so the pages need not be read again. nil when the folder cannot be read.
    func currentStamp() -> String? { try? store.folderStamp() }
}
