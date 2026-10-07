// CarryOver.swift - "Yesterday" card and carry-over into today's page.
//
// API:
//   CarryOver.card(before: todayKey, calendar:, settings:, load: (dayKey) -> DayDocument?) -> CarryCard?
//       Source = the most recent previous LOGGED day (status .logged under settings.minWords; skipped, missing and
//       partial days are walked past, 14-day lookback). Items = non-empty lines under that day's
//       settings.carryOverHeadings (matched with MarkdownBody.normalizeHeading; deeper sub-headings stay included),
//       list/checkbox markers stripped, ticked tasks ("- [x]") and code/images skipped, de-duplicated.
//       nil when that day has nothing to carry.
//   CarryOver.heading(for: card, today:, calendar:) -> "Yesterday" | "Friday" | "2 Oct 2026"
//   CarryOver.apply(card, to: body) -> String
//       Inserts "## Carried over from Fri 2 Oct" + "- [ ] item" lines at the TOP of `body`. Idempotent: returns `body`
//       unchanged if that heading (any level) is already there or every item already appears as a line.
//   CarryOver.isApplied(card, in: body) -> Bool     true when apply() would change nothing (hide the card)
//   CarryOver.items(in: body, headings:) -> [String]
// The UI keeps the previous body to implement "Undo". Pass the editor's current markdown (template included) to apply().
import Foundation

struct CarryCard: Equatable {
    var sourceDay: String
    var sourceLabel: String   // "Mon 5 Oct"
    var items: [String]
    var headingText: String { "\(CarryOver.headingPrefix)\(sourceLabel)" }
}

enum CarryOver {
    static let lookbackDays = 14
    static let headingPrefix = "Carried over from "

    static func items(in body: String, headings: [String]) -> [String] {
        let norm = headings.map { MarkdownBody.normalizeHeading($0) }.filter { !$0.isEmpty }
        guard !norm.isEmpty else { return [] }
        var seen = Set<String>(), out = [String]()
        for m in MarkdownBody.partition(body, headings: norm, subheadings: .drop).matched {
            for l in MarkdownBody.contentLines(m.text) where !l.isCode && l.checked != true {
                let text = MarkdownBody.collapse(MarkdownBody.removeNoise(l.text))
                let key = MarkdownBody.itemKey(text)
                if key.isEmpty || !seen.insert(key).inserted { continue }
                out.append(text)
            }
        }
        return out
    }

    static func card(before today: String, calendar: Calendar, settings: Settings, load: (String) -> DayDocument?) -> CarryCard? {
        var d = today
        for _ in 0..<lookbackDays {
            guard let p = DayKey.adding(d, -1, calendar) else { return nil }
            d = p
            guard let doc = load(d), !doc.isSkipped, doc.status(minWords: settings.minWords) == .logged else { continue }
            let items = items(in: doc.body, headings: settings.carryOverHeadings)
            return items.isEmpty ? nil : CarryCard(sourceDay: d, sourceLabel: DayKey.format(d, "EEE d MMM", calendar), items: items)
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

    static func apply(_ c: CarryCard, to body: String) -> String {
        MarkdownBody.insertCarryOver(into: body, heading: c.headingText, items: c.items)
    }
    static func isApplied(_ c: CarryCard, in body: String) -> Bool { apply(c, to: body) == body }
}
