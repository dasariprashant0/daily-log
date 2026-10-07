// CatchUp.swift - which scheduled days still need writing, and batch skipping. Owned by the core stream (task C4).
// CONTRACT (signatures frozen; the core stream replaces the stub bodies):
//   missing(...)  scheduled days in the last `windowDays` days BEFORE today, oldest first, whose state is .missed or .partial.
//                 Skipped, logged, off, future and today are never listed; days before the effective log start are never listed.
//   next(after:in:) first entry strictly after `day` (the first entry when day is nil); nil when there is none.
//   skipDays / unskipDays: one skip marker per day (days that contain writing are left alone); both return the days actually changed.
import Foundation

enum CatchUp {
    static func missing(states: [String: DayStatus], now: Date, calendar: Calendar, weekdays: Set<Int>,
                        logStart: String?, windowDays: Int) -> [String] {
        []   // STUB: implemented by task C4
    }
    static func next(after day: String?, in list: [String]) -> String? {
        nil  // STUB: implemented by task C4
    }
}

extension LogStore {
    func skipDays(_ days: [String], reason: String) throws -> [String] {
        []   // STUB: implemented by task C4
    }
    func unskipDays(_ days: [String]) throws -> [String] {
        []   // STUB: implemented by task C4
    }
}
