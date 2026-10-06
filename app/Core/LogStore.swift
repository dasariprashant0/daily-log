// LogStore.swift - reads/writes the markdown day files in the storage folder.
//
// API (all throw LogError; nothing touches the clock):
//   LogStore(dir:, sections:)         `sections` is a var: set it when Settings.sections change
//   ensureFolder()                    create the folder (onboarding / "Choose folder")
//   checkFolder()                     .folderMissing / .folderNotWritable
//   listDays() -> [String]            day keys that have a file, newest first
//   load(day) -> DayEntry?            nil = no file. Unknown headings land in entry.extras
//   save(entry)                       atomic. Writes a section for every key in entry.texts (+ extras).
//                                     Replaces a skip marker ("Write a log anyway").
//   skip(day, reason)                 writes `> Skipped: reason`; throws .hasContent if the day has log text
//   skipRange(from:to:reason:weekdays:calendar:) -> [String]   one file per scheduled day; days with content are left alone
//   unskip(day) -> Bool               deletes the marker only
//   fileStates() -> [String: DayStatus]   logged/partial/skipped per file (input for Streak/Heatmap/WeeklyReview)
//   search(query, sectionID:) -> [SearchHit]   see Search.swift
//   folderSummary() -> FolderSummary  counts for Settings > Storage
import Foundation

enum LogError: Error, Equatable {
    case folderMissing(String)
    case folderNotWritable(String)
    case badDay(String)
    case hasContent(String)   // refusing to overwrite a day that has log text
    case io(String)
}

struct FolderSummary: Equatable { var logs = 0, skipped = 0, unrecognized = 0 }

final class LogStore {
    let dir: URL
    var sections: [SectionDef]
    private let fm = FileManager.default

    init(dir: URL, sections: [SectionDef] = DefaultSections.all) { self.dir = dir; self.sections = sections }

    // MARK: folder
    func ensureFolder() throws {
        do { try fm.createDirectory(at: dir, withIntermediateDirectories: true) }
        catch { throw LogError.folderNotWritable(dir.path) }
        try checkFolder()
    }
    func checkFolder(writable: Bool = true) throws {
        var isDir: ObjCBool = false
        guard fm.fileExists(atPath: dir.path, isDirectory: &isDir), isDir.boolValue else { throw LogError.folderMissing(dir.path) }
        if writable && !fm.isWritableFile(atPath: dir.path) { throw LogError.folderNotWritable(dir.path) }
    }

    func url(for day: String) -> URL { dir.appendingPathComponent(day + ".md") }
    private func validate(_ day: String) throws { if !DayKey.isWellFormed(day) { throw LogError.badDay(day) } }

    // MARK: read
    private func dayFiles() throws -> (days: [String], other: Int) {
        try checkFolder(writable: false)
        let names: [String]
        do { names = try fm.contentsOfDirectory(atPath: dir.path) } catch { throw LogError.io(error.localizedDescription) }
        var days = [String](), other = 0
        for n in names where !n.hasPrefix(".") {
            if n.hasSuffix(".md"), DayKey.isWellFormed(String(n.dropLast(3))) { days.append(String(n.dropLast(3))) } else { other += 1 }
        }
        return (days.sorted(by: >), other)
    }
    func listDays() throws -> [String] { try dayFiles().days }

    func load(_ day: String) throws -> DayEntry? {
        try validate(day)
        try checkFolder(writable: false)
        guard fm.fileExists(atPath: url(for: day).path) else { return nil }
        let text: String
        do { text = try String(contentsOf: url(for: day), encoding: .utf8) } catch { throw LogError.io(error.localizedDescription) }
        return entry(day: day, parsed: MarkdownFormat.parse(text))
    }

    private func entry(day: String, parsed: ParsedDay) -> DayEntry {
        var e = DayEntry(date: day)
        e.isSkipped = parsed.isSkipped; e.skipReason = parsed.skipReason
        for (title, text) in parsed.sections {
            let def = sections.first { $0.title == title } ?? sections.first { $0.title.lowercased() == title.lowercased() }
            if let d = def, e.texts[d.id] == nil { e.texts[d.id] = text } else { e.extras.append(ExtraSection(title: title, text: text)) }
        }
        e.refreshStatus(sections: sections)
        if !parsed.isSkipped && parsed.sections.isEmpty { e.status = .partial }
        return e
    }

    func fileStates() throws -> [String: DayStatus] {
        var out = [String: DayStatus]()
        for d in try listDays() { if let e = try? load(d) { out[d] = e.status } }
        return out
    }
    func entries(from: String, to: String) throws -> [String: DayEntry] {
        var out = [String: DayEntry]()
        for d in try listDays() where d >= from && d <= to { if let e = try load(d) { out[d] = e } }
        return out
    }
    func allEntries() throws -> [DayEntry] { try listDays().compactMap { try load($0) } }

    func folderSummary() throws -> FolderSummary {
        var s = FolderSummary()
        let f = try dayFiles(); s.unrecognized = f.other
        for d in f.days { if let e = try load(d) { if e.isSkipped { s.skipped += 1 } else { s.logs += 1 } } }
        return s
    }

    // MARK: write
    private func write(_ text: String, day: String) throws {
        try checkFolder()
        do { try text.write(to: url(for: day), atomically: true, encoding: .utf8) }
        catch let e as NSError {
            if e.domain == NSCocoaErrorDomain && (e.code == NSFileWriteNoPermissionError || e.code == NSFileWriteVolumeReadOnlyError) {
                throw LogError.folderNotWritable(dir.path)
            }
            throw LogError.io(e.localizedDescription)
        }
    }

    func save(_ e: DayEntry) throws {
        try validate(e.date)
        var parts = [(title: String, text: String)]()
        for s in sections { if let t = e.texts[s.id] { parts.append((s.title, t)) } }
        parts += e.extras.map { ($0.title, $0.text) }
        try write(MarkdownFormat.serialize(day: e.date, sections: parts), day: e.date)
    }

    func skip(_ day: String, reason: String = "") throws {
        try validate(day)
        if let e = try load(day), !e.isSkipped, !(e.texts.isEmpty && e.extras.isEmpty) { throw LogError.hasContent(day) }
        try write(MarkdownFormat.serializeSkip(day: day, reason: reason), day: day)
    }

    /// Skips every scheduled day (per `weekdays`) in from...to inclusive. Returns the days written.
    @discardableResult
    func skipRange(from: String, to: String, reason: String = "", weekdays: Set<Int>, calendar: Calendar) throws -> [String] {
        try validate(from); try validate(to)
        var written = [String](), d = from
        var guardCount = 0
        while d <= to && guardCount < 3700 {
            if weekdays.contains(DayKey.weekday(d, calendar)) {
                do { try skip(d, reason: reason); written.append(d) } catch LogError.hasContent { }
            }
            guard let n = DayKey.adding(d, 1, calendar) else { break }
            d = n; guardCount += 1
        }
        return written
    }

    @discardableResult
    func unskip(_ day: String) throws -> Bool {
        try validate(day)
        guard let e = try load(day), e.isSkipped else { return false }
        do { try fm.removeItem(at: url(for: day)) } catch { throw LogError.io(error.localizedDescription) }
        return true
    }

    func search(_ query: String, sectionID: String? = nil) throws -> [SearchHit] {
        var hits = [SearchHit]()
        for d in try listDays() { if let e = try load(d) { hits += Search.hits(in: e, query: query, sections: sections, sectionID: sectionID) } }
        return hits
    }
}
