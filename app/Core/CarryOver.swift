// CarryOver.swift - "Yesterday" card and carry-over text.
//
// API:
//   CarryOver.card(before: todayKey, calendar:, load: (dayKey) -> DayEntry?) -> CarryCard?
//       most recent previous LOGGED day (skipped/missing days are walked past, 14-day lookback) whose
//       "To do next" (id "todo") or "Pending / blocked" (id "pending") is non-empty.
//   CarryOver.heading(for: card, today:, calendar:) -> "Yesterday" | "Friday" | "29 Sep 2026"
//   CarryOver.apply(card, to: existingText) -> String   appends "(from Mon 5 Oct)" + "- " lines to the target section;
//                                                      de-duplicates identical lines; returns existing unchanged if nothing new
//   CarryOver.prefill(card) -> String                   apply(card, to: "")
//   CarryOver.targetSectionID(settings) -> String       Settings.carryOverSectionID if it exists, else first section
// UI keeps the previous text to implement "Undo".
import Foundation

struct CarryCard: Equatable {
    var sourceDay: String
    var sourceLabel: String   // "Mon 5 Oct"
    var todo: String
    var pending: String
}

enum CarryOver {
    static let todoID = "todo", pendingID = "pending", lookbackDays = 14

    static func card(before today: String, calendar: Calendar, load: (String) -> DayEntry?) -> CarryCard? {
        var d = today
        for _ in 0..<lookbackDays {
            guard let p = DayKey.adding(d, -1, calendar) else { return nil }
            d = p
            guard let e = load(d), !e.isSkipped, e.status == .logged else { continue }
            let todo = e.texts[todoID]?.dlTrimmed ?? "", pend = e.texts[pendingID]?.dlTrimmed ?? ""
            if todo.isEmpty && pend.isEmpty { return nil }
            return CarryCard(sourceDay: d, sourceLabel: DayKey.format(d, "EEE d MMM", calendar), todo: todo, pending: pend)
        }
        return nil
    }

    static func heading(for c: CarryCard, today: String, calendar: Calendar) -> String {
        guard let a = DayKey.date(c.sourceDay, calendar), let b = DayKey.date(today, calendar) else { return c.sourceDay }
        let n = calendar.dateComponents([.day], from: a, to: b).day ?? 0
        if n == 1 { return "Yesterday" }
        if n <= 6 { return DayKey.format(c.sourceDay, "EEEE", calendar) }
        return DayKey.format(c.sourceDay, "d MMM yyyy", calendar)
    }

    private static func hasListMarker(_ line: String) -> Bool {
        let t = line.dlTrimmed
        if t.hasPrefix("- ") || t.hasPrefix("* ") || t.hasPrefix("• ") { return true }
        let digits = t.prefix(while: { $0.isNumber })
        return !digits.isEmpty && t.dropFirst(digits.count).hasPrefix(". ")
    }

    static func apply(_ c: CarryCard, to existing: String) -> String {
        let have = Set(existing.components(separatedBy: "\n").map { $0.dlTrimmed })
        var lines = [String]()
        for text in [c.todo, c.pending] where !text.isEmpty {
            let src = text.components(separatedBy: "\n").filter { !$0.dlTrimmed.isEmpty }
            let list = src.contains(where: hasListMarker)
            for l in src {
                let line = list ? l.dlTrimmed : "- " + l.dlTrimmed
                if !have.contains(line) && !lines.contains(line) { lines.append(line) }
            }
        }
        if lines.isEmpty { return existing }
        let base = existing.dlTrimmed
        return (base.isEmpty ? "" : base + "\n\n") + "(from \(c.sourceLabel))\n" + lines.joined(separator: "\n")
    }

    static func prefill(_ c: CarryCard) -> String { apply(c, to: "") }

    static func targetSectionID(_ s: Settings) -> String {
        s.sections.contains { $0.id == s.carryOverSectionID } ? s.carryOverSectionID : (s.sections.first?.id ?? "")
    }
}
