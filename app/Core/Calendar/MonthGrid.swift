// MonthGrid.swift - the month calendar's data. Pure. Owned by the core stream (task C2).
// CONTRACT (signatures are frozen so the UI can compile against them):
//   rows(...) -> 6 rows x 7 columns, columns start at calendar.firstWeekday; cells outside the month have inMonth == false.
//   status comes from Status.resolve with since = Status.effectiveSince(setting: logStart, states: states), so:
//     future days are .future, days before the effective log start are .off (a page written there still shows its own state),
//     unscheduled days with no page are .off, scheduled past days with no page are .missed.
//   Cells outside the month are real days and get the same status, scheduled and today flags as the others.
//   Always 6 rows, even for a month that needs 4 or 5, so the calendar never changes height. A month outside 1...12 gives [].
// Days are stepped with Calendar.date(byAdding: .day) from one anchor, never by adding 86,400 s, so DST days (23 h / 25 h, and
// zones where DST changes at midnight) neither repeat nor skip a day.
import Foundation

struct MonthCell: Equatable {
    var day: String          // "yyyy-MM-dd"
    var inMonth: Bool
    var status: DayStatus
    var isToday: Bool
    var isScheduled: Bool    // the day's weekday is one of the user's working weekdays
}

enum MonthGrid {
    static let rowCount = 6, columnCount = 7

    static func rows(year: Int, month: Int, states: [String: DayStatus], now: Date, calendar: Calendar,
                     weekdays: Set<Int>, logStart: String?) -> [[MonthCell]] {
        guard (1...12).contains(month),
              let first = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let anchor = calendar.date(byAdding: .day, value: -((calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7),
                                         to: first) else { return [] }
        let today = DayKey.string(now, calendar)
        let since = Status.effectiveSince(setting: logStart, states: states)
        var rows = [[MonthCell]]()
        for r in 0..<rowCount {
            var row = [MonthCell]()
            for c in 0..<columnCount {
                guard let d = calendar.date(byAdding: .day, value: r * columnCount + c, to: anchor) else { return [] }
                let key = DayKey.string(d, calendar)
                let ym = calendar.dateComponents([.year, .month], from: d)
                row.append(MonthCell(day: key, inMonth: ym.year == year && ym.month == month,
                                     status: Status.resolve(day: key, fileState: states[key], now: now, calendar: calendar,
                                                            weekdays: weekdays, since: since),
                                     isToday: key == today,
                                     isScheduled: weekdays.contains(calendar.component(.weekday, from: d))))
            }
            rows.append(row)
        }
        return rows
    }
}
