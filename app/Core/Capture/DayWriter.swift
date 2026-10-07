// DayWriter.swift - the single place a captured note is routed. Main thread only. Owned by the core stream (task K3).
// CONTRACT (signatures frozen; K3 replaces the stub bodies):
//   capture(text:source:)  normalise (trim, strip control chars except newlines, cap 4,000, "[]" to-do shorthand, timestamp per prefs), return nil
//                          when nothing is left; journal.append (durable) FIRST; then route:
//                            - page open for that day and loaded -> page.appendJot (live editor transaction); on .appended the editor's
//                              own autosave writes the file, and acknowledgeSaved(day:body:) acks the note once the file holds it;
//                              .notLoaded -> keep waiting (retried by replayJournal); .stale -> re-route once; .alreadyPresent -> ack when saved
//                            - no open page for that day -> load the file (or ""), CapturePlacement.apply, LogStore.save, ack
//                            - the folder is unavailable or the save fails -> the note stays in the journal (waiting > 0), nothing is lost
//   replayJournal()        re-route every pending item (launch, folder returns, wake, app activation); idempotent via CapturePlacement.contains
//   waiting                journal items not yet acknowledged
//   acknowledgeSaved       the UI calls this after every successful page save; acks pending items whose line is now in the written body
import Foundation

final class DayWriter {
    init(store: LogStore, journal: CaptureJournal, pages: EditorLookup, prefs: @escaping () -> CapturePrefs,
         clock: @escaping () -> Date, calendar: @escaping () -> Calendar) { }
    func capture(text: String, source: String) -> CaptureReceipt? { nil }                       // STUB (K3)
    func replayJournal() { }                                                                      // STUB (K3)
    var waiting: Int { 0 }                                                                        // STUB (K3)
    func acknowledgeSaved(day: String, body: String) { }                                          // STUB (K3)
}
