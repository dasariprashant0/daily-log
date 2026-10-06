// Search.swift - search over saved logs (drafts excluded).
//
// API: LogStore.search(query, sectionID:) -> [SearchHit]   (newest day first, then section order)
//      Search.hits(in: entry, query:, sections:, sectionID:)  pure per-day matcher
// Matching: case- and diacritic-insensitive; whitespace-separated words are AND-ed within one section.
// SearchHit.snippet is ~120 chars around the first word, with "…" at cut edges; matchRange indexes into snippet.
import Foundation

struct SearchHit: Equatable {
    var day: String
    var sectionID: String?      // nil for unknown (extra) headings
    var sectionTitle: String
    var snippet: String
    var matchRange: Range<String.Index>?
}

enum Search {
    private static let opts: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]

    static func words(_ q: String) -> [String] { q.split(whereSeparator: { $0.isWhitespace }).map(String.init) }

    static func hits(in e: DayEntry, query: String, sections: [SectionDef], sectionID: String? = nil) -> [SearchHit] {
        let ws = words(query)
        guard !ws.isEmpty else { return [] }
        var out = [SearchHit]()
        func consider(id: String?, title: String, text: String) {
            let flat = text.replacingOccurrences(of: "\n", with: " ")
            var first: Range<String.Index>?
            for w in ws {
                guard let r = flat.range(of: w, options: opts) else { return }
                if first == nil || r.lowerBound < first!.lowerBound { first = r }
            }
            guard let r = first else { return }
            let (snip, range) = snippet(flat, r)
            out.append(SearchHit(day: e.date, sectionID: id, sectionTitle: title, snippet: snip, matchRange: range))
        }
        for s in sections where sectionID == nil || sectionID == s.id {
            if let t = e.texts[s.id], !t.isEmpty { consider(id: s.id, title: s.title, text: t) }
        }
        if sectionID == nil { for x in e.extras where !x.text.isEmpty { consider(id: nil, title: x.title, text: x.text) } }
        return out
    }

    private static func snippet(_ s: String, _ r: Range<String.Index>) -> (String, Range<String.Index>?) {
        let start = s.index(r.lowerBound, offsetBy: -40, limitedBy: s.startIndex) ?? s.startIndex
        let end = s.index(r.upperBound, offsetBy: 80, limitedBy: s.endIndex) ?? s.endIndex
        let pre = start > s.startIndex ? "…" : "", post = end < s.endIndex ? "…" : ""
        let out = pre + String(s[start..<end]) + post
        let from = out.index(out.startIndex, offsetBy: pre.count + s.distance(from: start, to: r.lowerBound))
        let to = out.index(from, offsetBy: s.distance(from: r.lowerBound, to: r.upperBound))
        return (out, from..<to)
    }
}
