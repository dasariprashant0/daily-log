// MonthGrid.swift - the month calendar's data. Pure. Owned by the core stream (task C2).
// CONTRACT (signatures are frozen so the UI can compile against them; the core stream replaces the stub body):
//   rows(...) -> 6 rows x 7 columns, columns start at calendar.firstWeekday; cells outside the month have inMonth == false.
//   status comes from Status.resolve with since = Status.effectiveSince(setting: logStart, states: states).
import Foundation

struct MonthCell: Equatable {
    var day: String          // "yyyy-MM-dd"
    var inMonth: Bool
    var status: DayStatus
    var isToday: Bool
    var isScheduled: Bool    // the day's weekday is one of the user's working weekdays
}

enum MonthGrid {
    static func rows(year: Int, month: Int, states: [String: DayStatus], now: Date, calendar: Calendar,
                     weekdays: Set<Int>, logStart: String?) -> [[MonthCell]] {
        []   // STUB: implemented by task C2
    }
}
