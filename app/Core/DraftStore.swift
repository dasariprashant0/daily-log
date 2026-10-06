// DraftStore.swift - per-day draft autosave, stored OUTSIDE the storage folder.
//
// API: DraftStore(dir:)  (DraftStore.defaultDir = ~/Library/Application Support/Daily Log/drafts)
//      save(day:, texts:, now:) throws   all-empty texts clears the draft instead
//      load(day) -> Draft?               nil if none or unreadable
//      clear(day)                        also called after a successful LogStore.save
//      days() -> [String]                days that have a draft (sidebar "draft" badge)
import Foundation

struct Draft: Codable, Equatable {
    var day: String
    var texts: [String: String]   // sectionID -> text
    var savedAt: Date
}

final class DraftStore {
    static var defaultDir: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Daily Log/drafts")
    }
    let dir: URL
    init(dir: URL) { self.dir = dir }

    private func url(_ day: String) -> URL { dir.appendingPathComponent(day + ".json") }

    func save(day: String, texts: [String: String], now: Date) throws {
        guard DayKey.isWellFormed(day) else { throw LogError.badDay(day) }
        if texts.values.allSatisfy({ $0.dlTrimmed.isEmpty }) { clear(day); return }
        do {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let enc = JSONEncoder(); enc.dateEncodingStrategy = .iso8601
            try enc.encode(Draft(day: day, texts: texts, savedAt: now)).write(to: url(day), options: .atomic)
        } catch { throw LogError.io(error.localizedDescription) }
    }
    func load(_ day: String) -> Draft? {
        guard DayKey.isWellFormed(day), let d = try? Data(contentsOf: url(day)) else { return nil }
        let dec = JSONDecoder(); dec.dateDecodingStrategy = .iso8601
        return try? dec.decode(Draft.self, from: d)
    }
    func clear(_ day: String) {
        guard DayKey.isWellFormed(day) else { return }
        try? FileManager.default.removeItem(at: url(day))
    }
    func days() -> [String] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        return names.filter { $0.hasSuffix(".json") }.map { String($0.dropLast(5)) }.filter(DayKey.isWellFormed).sorted(by: >)
    }
}
