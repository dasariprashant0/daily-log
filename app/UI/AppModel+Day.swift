// AppModel+Day.swift - skip day, undo skip, "From yesterday" carry-over, previous versions.
import SwiftUI
import AppKit

enum SkipFailure: Error {
    case message(String)
    var text: String { switch self { case .message(let m): return m } }
}

extension AppModel {
    // MARK: skip
    /// Skips `day` (or every scheduled day through `through`). The open page is saved first, so the core's rule
    /// "skip refuses a day with writing" sees what the user typed a moment ago.
    func skip(day: String, through: String?, reason: String, completion: @escaping (SkipFailure?) -> Void) {
        flushEditor { [weak self] in
            guard let self = self else { return }
            self.pinLogStart(before: day)               // a skip before the first page must not open a gap of unlogged days
            do {
                if let to = through, to > day {
                    let n = try self.store.skipRange(from: day, to: to, reason: reason, weekdays: self.settings.weekdays, calendar: self.cal)
                    if n.isEmpty { completion(.message("None of those days is a scheduled day, or they already have writing.")); return }
                } else {
                    try self.store.skip(day, reason: reason)
                }
            } catch LogError.hasContent { completion(.message("That day already has writing. Skipping would overwrite it.")); return }
            catch LogError.folderMissing { completion(.message("Your log folder can't be found.")); return }
            catch LogError.folderNotWritable { completion(.message("Gloamlog can't save to this folder.")); return }
            catch LogError.io(let m) { completion(.message(m)); return }
            catch { completion(.message(error.localizedDescription)); return }
            self.reload()
            if live { Notifier.shared.cancelAll() }
            // In a catch-up session the caller moves on to the next day, so the skipped page is not shown again.
            if case .day(let k) = self.selection, self.session == nil { self.editor?.abandon(); self.openDay(k, force: true) }
            completion(nil)
        }
    }

    func unskip(_ day: String) {
        do { _ = try store.unskip(day) } catch { pageNotice = "Couldn't undo the skip. \(error.localizedDescription)"; return }
        if day == today { planner = planner.suppressed(until: clock().addingTimeInterval(ReminderPlanner.graceAfterUndoSkip)) }
        reload()
        editor?.abandon()
        openDay(day, force: true)
    }

    func requestSkip(day: String? = nil) {
        let d = day ?? (editor?.day ?? today)
        guard states[d] != .logged else { return }
        showMainWindow(activate: true)
        sheet = .skip(d)
    }
    var canSkipToday: Bool { states[today] != .logged }

    // MARK: From yesterday
    func refreshCarry() {
        guard case .day(let k) = selection, k == today else { carryCard = nil; return }
        carryCard = CarryOver.card(before: today, calendar: cal, settings: settings, load: { (try? self.store.load($0)) ?? nil })
    }

    /// The strip shows only while there is something to carry and today's page does not already have it.
    var carryAvailable: Bool {
        guard let c = carryCard, let e = editor, e.day == today, e.showsEditor else { return false }
        return !CarryOver.isApplied(c, in: e.latest)
    }

    /// Inserts the carried items at the top of the page (CarryOver.apply on the editor's CURRENT markdown), keeping the cursor.
    func carryOver() {
        guard let card = carryCard, let e = editor, e.loaded, e.day == today, let b = bridgeStorage else { return }
        b.read(token: e.token) { [weak self] current in
            guard let self = self, let cur = current else { return }
            let next = CarryOver.apply(card, to: cur)
            guard next != cur else { return }
            b.replace(token: e.token, expecting: cur, markdown: next, cursor: .keep) { normalized in
                guard let n = normalized else { return }          // the user typed in between: leave the page alone
                e.programmaticEdit(to: n)                          // setMarkdown emits no change event: save it ourselves
                self.carryUndoBody = cur
                if self.live { UIAnnounce.say("Carried over from yesterday") }
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) { if self.carryUndoBody == cur { self.carryUndoBody = nil } }
            }
        }
    }

    func undoCarry() {
        guard let old = carryUndoBody, let e = editor, e.loaded, let b = bridgeStorage else { return }
        let now = e.latest
        b.replace(token: e.token, expecting: now, markdown: old, cursor: .keep) { normalized in
            guard let n = normalized else { self.carryUndoBody = nil; return }
            e.programmaticEdit(to: n)
            self.carryUndoBody = nil
        }
    }

    // MARK: previous versions
    func backups(for day: String) -> [BackupInfo] { store.listBackups(day: day) }

    /// Restores a safety copy as the day's page. The current page is saved first and the core backs it up again before
    /// the restore, so a restore can itself be undone from this same list.
    func restore(_ info: BackupInfo, day: String, completion: @escaping (String?) -> Void) {
        flushEditor { [weak self] in
            guard let self = self else { return }
            do { try self.store.restoreBackup(day: day, backup: info) }
            catch LogError.backupFailed { completion("Couldn't keep a copy of the current page, so nothing was changed."); return }
            catch LogError.backupsDisabled { completion("Backups are turned off."); return }
            catch LogError.folderNotWritable { completion("Gloamlog can't save to this folder."); return }
            catch { completion("Couldn't restore that version. \(error.localizedDescription)"); return }
            self.reload()
            if case .day(let k) = self.selection, k == day { self.editor?.abandon(); self.openDay(day, force: true) }
            completion(nil)
        }
    }
}
