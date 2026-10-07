// MarkdownFormat.swift - the day file <-> DayDocument. Pure functions, no disk.
//
// File:   "# YYYY-MM-DD\n\n<body>\n"   (the app writes the title; on load a leading "# <date>" line is stripped)
// Skip:   "# YYYY-MM-DD\n\n> Skipped: reason\n"   or "> Skipped" (no reason). Recognised only when it is the ONLY content,
//         and the text after "> Skipped" is empty or starts with ":" ("> Skipped the meeting" in a longer note is just text).
// Old files (v0.1/v0.2 "## 📝 What I did" ... headings) load unchanged: they are simply markdown. The old "\## " escape
// (a backslash before a line-start "## ") is undone on load, outside fenced code. Nothing is escaped on save.
// BOM and CRLF are tolerated on load.
//
// API: MarkdownFormat.parse(day:raw:) -> DayDocument, serialize(day:body:) -> String, serializeSkip(day:reason:) -> String
import Foundation

enum MarkdownFormat {
    private static func isDateTitle(_ line: String) -> Bool {
        let t = line.dlTrimmed
        return t.hasPrefix("# ") && DayKey.isWellFormed(String(t.dropFirst(2)).dlTrimmed)
    }

    /// "> Skipped" / "> Skipped: reason" as the whole body -> reason ("" when none); otherwise nil.
    static func skipReason(inBody body: String) -> String? {
        let t = body.dlTrimmed
        guard t.hasPrefix("> Skipped"), !t.contains("\n") else { return nil }
        var rest = String(t.dropFirst("> Skipped".count))
        if rest.isEmpty { return "" }
        guard rest.hasPrefix(":") else { return nil }
        rest.removeFirst()
        return rest.dlTrimmed
    }

    private static func unescapeLegacy(_ text: String) -> String {
        var out = [String](), fence: (ch: Character, len: Int)?
        for line in text.components(separatedBy: "\n") {
            if let f = fence { if MarkdownBody.isClosingFence(line, f) { fence = nil }; out.append(line); continue }
            if let f = MarkdownBody.openingFence(line) { fence = f; out.append(line); continue }
            if line.hasPrefix("\\"), line.drop(while: { $0 == "\\" }).hasPrefix("## ") { out.append(String(line.dropFirst())) }
            else { out.append(line) }
        }
        return out.joined(separator: "\n")
    }

    static func parse(day: String, raw: String) -> DayDocument {
        var text = raw
        if text.hasPrefix("\u{FEFF}") { text.removeFirst() }
        var lines = text.replacingOccurrences(of: "\r\n", with: "\n").components(separatedBy: "\n")
        while let f = lines.first, f.dlTrimmed.isEmpty { lines.removeFirst() }
        if let f = lines.first, isDateTitle(f) { lines.removeFirst() }
        let body = MarkdownBody.trimBody(lines.joined(separator: "\n"))
        if let reason = skipReason(inBody: body) { return DayDocument(day: day, body: "", isSkipped: true, skipReason: reason) }
        return DayDocument(day: day, body: MarkdownBody.trimBody(unescapeLegacy(body)))
    }

    static func serialize(day: String, body: String) -> String {
        "# \(day)\n\n" + MarkdownBody.trimBody(body) + "\n"
    }
    static func serializeSkip(day: String, reason: String) -> String {
        let r = reason.replacingOccurrences(of: "\n", with: " ").dlTrimmed
        return "# \(day)\n\n> Skipped" + (r.isEmpty ? "" : ": \(r)") + "\n"
    }
}
