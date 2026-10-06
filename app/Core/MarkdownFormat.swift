// MarkdownFormat.swift - parse/serialize one day file. Pure functions, no disk.
//
// Format (v0.1 compatible):   # 2026-10-06\n\n## <title>\n<text>\n\n ...
// Skip marker (no sections):  # 2026-10-06\n\n> Skipped: reason\n
// Escaping: any user line matching ^\\*"## " gets one extra leading backslash on save and loses one on load,
// so user text can never open a section, and a literal "\## " round-trips.
import Foundation

struct ParsedDay: Equatable {
    var sections: [(title: String, text: String)] = []
    var isSkipped = false
    var skipReason = ""
    static func == (a: ParsedDay, b: ParsedDay) -> Bool {
        a.isSkipped == b.isSkipped && a.skipReason == b.skipReason && a.sections.count == b.sections.count
            && zip(a.sections, b.sections).allSatisfy { $0.title == $1.title && $0.text == $1.text }
    }
}

enum MarkdownFormat {
    private static func needsEscape(_ line: String) -> Bool {
        let rest = line.drop(while: { $0 == "\\" })
        return rest.hasPrefix("## ")
    }
    static func escape(_ text: String) -> String {
        text.components(separatedBy: "\n").map { needsEscape($0) ? "\\" + $0 : $0 }.joined(separator: "\n")
    }
    static func unescape(_ text: String) -> String {
        text.components(separatedBy: "\n").map { needsEscape($0) && $0.hasPrefix("\\") ? String($0.dropFirst()) : $0 }.joined(separator: "\n")
    }

    static func parse(_ raw: String) -> ParsedDay {
        let text = raw.replacingOccurrences(of: "\r\n", with: "\n")
        var out = ParsedDay()
        var cur: String?, buf = [String](), pre = [String]()
        func flush() { if let c = cur { out.sections.append((c, unescape(buf.joined(separator: "\n")).dlTrimmed)) } }
        for line in text.components(separatedBy: "\n") {
            if line.hasPrefix("## ") { flush(); buf = []; cur = String(line.dropFirst(3)).dlTrimmed }
            else if cur == nil { pre.append(line) } else { buf.append(line) }
        }
        flush()
        if out.sections.isEmpty, let m = pre.first(where: { $0.dlTrimmed.hasPrefix("> Skipped") }) {
            out.isSkipped = true
            var r = String(m.dlTrimmed.dropFirst("> Skipped".count))
            if r.hasPrefix(":") { r.removeFirst() }
            out.skipReason = r.dlTrimmed
        }
        return out
    }

    static func serialize(day: String, sections: [(title: String, text: String)]) -> String {
        "# \(day)\n\n" + sections.map { s in
            let title = s.title.replacingOccurrences(of: "\n", with: " ")
            return "## \(title)\n\(escape(s.text.dlTrimmed))\n\n"
        }.joined()
    }
    static func serializeSkip(day: String, reason: String) -> String {
        let r = reason.replacingOccurrences(of: "\n", with: " ").dlTrimmed
        return "# \(day)\n\n> Skipped" + (r.isEmpty ? "" : ": \(r)") + "\n"
    }
}
