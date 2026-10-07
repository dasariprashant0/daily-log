// DateJump.swift - "Go to date" text parser. Pure. Owned by the core stream (task C3).
// CONTRACT (signature frozen; the core stream replaces the stub body):
//   parse("yesterday" | "today" | "-3" | "3 days ago" | "last fri" | "fri" | "2 oct" | "oct 2" | "2 October 2026" | "2026-10-02" | "10/2")
//   -> a day key "yyyy-MM-dd" that is not after today, or nil when the text cannot be read or names a future day.
//   "last fri" = the most recent Friday strictly before today; "fri" = the most recent Friday on or before today.
import Foundation

enum DateJump {
    static func parse(_ input: String, now: Date, calendar: Calendar) -> String? {
        nil  // STUB: implemented by task C3
    }
}
