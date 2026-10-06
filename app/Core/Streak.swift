// Streak.swift - day status resolution, streak and 12-week heatmap. Pure; input is LogStore.fileStates().
//
// API:
//   Status.resolve(day:, fileState:, now:, calendar:, weekdays:, since:) -> DayStatus
//   Streak.compute(states:, now:, calendar:, weekdays:) -> StreakResult(current, best)
//   Heatmap.weeks(states:, now:, calendar:, weekdays:, count: 12) -> [[HeatCell]]
//       columns = weeks oldest first; each column = 7 cells in calendar.firstWeekday order.
// Rules (UX_SPEC 3.3): logged = +1 (scheduled or not); skipped = neutral; unlogged today = neutral ("not yet");
// unlogged/partial PAST scheduled day = break; unlogged non-scheduled day = neutral. Days before the first file
// ever written are neutral/.off (a new user has no "missed" history). Weekday changes re-evaluate all history.
import Foundation

enum Status {
    /// `fileState` = logged/partial/skipped if the day has a file, else nil. `since` = earliest day with a file.
    static func resolve(day: String, fileState: DayStatus?, now: Date, calendar: Calendar,
                        weekdays: Set<Int>, since: String?) -> DayStatus {
        let today = DayKey.string(now, calendar)
        if day > today { return .future }
        if let f = fileState { return f }
        if let s = since, day < s { return .off }
        return weekdays.contains(DayKey.weekday(day, calendar)) ? .missed : .off
    }
}

struct StreakResult: Equatable { var current: Int; var best: Int }

enum Streak {
    static func compute(states: [String: DayStatus], now: Date, calendar: Calendar, weekdays: Set<Int>) -> StreakResult {
        let today = DayKey.string(now, calendar)
        guard var cur = states.keys.filter({ $0 <= today }).min(), var date = DayKey.date(cur, calendar) else {
            return StreakResult(current: 0, best: 0)
        }
        var run = 0, best = 0, steps = 0
        while cur <= today && steps < 40000 {
            switch states[cur] {
            case .some(.logged): run += 1; best = max(best, run)
            case .some(.skipped): break
            default:
                if cur != today && weekdays.contains(calendar.component(.weekday, from: date)) { run = 0 }
            }
            guard let n = calendar.date(byAdding: .day, value: 1, to: date) else { break }
            date = n; cur = DayKey.string(n, calendar); steps += 1
        }
        return StreakResult(current: run, best: best)
    }
}

struct HeatCell: Equatable {
    var day: String
    var status: DayStatus
    var isToday: Bool
}

enum Heatmap {
    static func weeks(states: [String: DayStatus], now: Date, calendar: Calendar, weekdays: Set<Int>, count: Int = 12) -> [[HeatCell]] {
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return [] }
        let today = DayKey.string(now, calendar)
        let since = states.keys.min()
        var cols = [[HeatCell]]()
        for w in stride(from: -(count - 1), through: 0, by: 1) {
            guard let ws = calendar.date(byAdding: .weekOfYear, value: w, to: thisWeek) else { continue }
            var col = [HeatCell]()
            for i in 0..<7 {
                guard let d = calendar.date(byAdding: .day, value: i, to: ws) else { continue }
                let k = DayKey.string(d, calendar)
                col.append(HeatCell(day: k, status: Status.resolve(day: k, fileState: states[k], now: now, calendar: calendar,
                                                                 weekdays: weekdays, since: since), isToday: k == today))
            }
            cols.append(col)
        }
        return cols
    }
}
