// CaptureJournal.swift - write-ahead journal: a note is durable here (fsynced) before anything else happens. Owned by the core stream (task K2).
// CONTRACT (signatures frozen; K2 replaces the stub bodies):
//   File: <dir>/journal.jsonl, mode 0600, one JSON object per line: a CaptureItem, or {"ack":"<id>"}.
//   append   open(O_WRONLY|O_APPEND|O_CREAT, 0600), write ONE line, F_FULLFSYNC: the durability point. Throws on failure.
//   ack      appends {"ack": id}.
//   pending  items without an ack, in order; tolerant of a torn last line (a crash mid-write) and of unknown/garbled lines.
//   compact  rewrites the file without acked items (atomically); call at launch when everything is acked or the file has > 1,000 lines.
import Foundation

enum JournalError: Error, Equatable { case io(String) }                                    // STUB (K2)

final class CaptureJournal {
    let dir: URL
    init(dir: URL) { self.dir = dir }
    var fileURL: URL { dir.appendingPathComponent("journal.jsonl") }                          // STUB (K2)
    static func line(for item: CaptureItem) -> String { "" }                                  // STUB (K2)
    static func ackLine(_ id: String) -> String { "" }                                        // STUB (K2)
    func append(_ item: CaptureItem) throws { }          // STUB (K2)
    func ack(_ id: String) throws { }                     // STUB (K2)
    func pending() -> [CaptureItem] { [] }                // STUB (K2)
    func compact() throws { }                             // STUB (K2)
    static var defaultDir: URL {                          // ~/Library/Application Support/Gloamlog/capture
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Gloamlog/capture")
    }
}
