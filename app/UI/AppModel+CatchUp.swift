// AppModel+CatchUp.swift - what Catch up does with the list of unlogged days: the session ("Catching up 3 of 5" on the normal
// page, one editor and one writer), skipping several days at once with an 8 second Undo, and the quiet notice on Today.
import SwiftUI

/// A run through the unlogged days. `days` is fixed when it starts (so "3 of 5" stays put); which day comes next is always
/// asked of the live list, so a day written in the meantime is never offered again.
struct CatchSession: Equatable {
    var days: [String]            // the unlogged days when the session began, oldest first
    var current: String
    var note: String?             // a short hint in the bar ("This is the only day left.")
    var position: Int { (days.firstIndex(of: current) ?? 0) + 1 }
}
struct SessionResult: Equatable { var logged: Int; var skipped: Int }
struct SkipUndo: Equatable {
    var days: [String]
    var reason: String
    var id = UUID()
    var text: String { "Skipped \(Fmt.plural(days.count, "day"))" + (reason.isEmpty ? "." : " as \(reason).") }
}

extension AppModel {
    // MARK: the list
    /// The unlogged working days inside `windowDays` (default: Settings, Page), oldest first.
    func catchUpList(windowDays: Int? = nil) -> [String] {
        CatchUp.missing(states: states, now: now, calendar: cal, weekdays: settings.weekdays, logStart: settings.logStartDate,
                        windowDays: windowDays ?? settings.catchUpWindowDays)
    }
    var catchUpLabel: String {
        catchUpDays.isEmpty ? "You're all caught up." : "You have \(Fmt.plural(catchUpDays.count, "unlogged day"))."
    }

    // MARK: the notice on Today
    /// The previous working day, when it is the only unlogged day: Today says "You haven't logged Thu 8 Oct."
    var singleUnloggedYesterday: String? {
        guard catchUpDays.count == 1, let d = catchUpDays.first else { return nil }
        var p = DayKey.adding(today, -1, cal), n = 0
        while let k = p, !isWorkday(k), n < 7 { p = DayKey.adding(k, -1, cal); n += 1 }
        return p == d ? d : nil
    }
    /// Once a day, and only while something is unlogged.
    var catchNoticeVisible: Bool { !catchUpDays.isEmpty && catchNoticeDay != today }
    func dismissCatchNotice() { catchNoticeDay = today; defaults.set(today, forKey: AppModel.catchNoticeKey) }

    // MARK: the session
    /// Opens the oldest day of `days` (default: the whole list) on the normal page, with the session bar above it.
    func startSession(days: [String]? = nil) {
        let list = days ?? catchUpDays
        guard let first = list.first else { return }
        sessionResult = nil
        session = CatchSession(days: list, current: first)
        openDay(first, focus: true)                    // `first` belongs to the session, so openDay keeps it
        announceSession()
    }

    /// "Next unlogged day" (⌘↩): the next unlogged day after this one, wrapping once. Never moves by itself, and a day left
    /// under the minimum stays in the list. When nothing else is left the session is over, or says this day is the last.
    func nextUnloggedDay() {
        flushEditor { [weak self] in                   // what was typed a moment ago decides what is still unlogged
            guard let self = self else { return }
            var cur: String?
            if case .day(let k) = self.selection { cur = k } else { cur = self.session?.current }
            let list = self.catchUpDays
            var next = CatchUp.next(after: cur, in: list)
            if next == nil { next = list.first(where: { $0 != cur }) }          // wrap once
            if let n = next {
                if self.session == nil { self.session = CatchSession(days: list, current: n) }
                else {
                    self.session?.current = n; self.session?.note = nil
                    if !(self.session?.days.contains(n) ?? true) { self.session?.days = (self.session?.days ?? []) + [n]; self.session?.days.sort() }
                }
                self.sessionResult = nil
                self.openDay(n, focus: true)
                self.announceSession()
            } else if let c = cur, list.contains(c), self.session != nil {
                self.session?.note = "This is the only day left. Write a little more, or skip it."
                let hint = self.session?.note
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { if self.session?.note == hint { self.session?.note = nil } }
            } else {
                self.finishSession()
            }
        }
    }

    /// The bar's ‹: back to the day before this one in the session, written or not.
    func previousSessionDay() {
        flushEditor { [weak self] in
            guard let self = self, let s = self.session, let i = s.days.firstIndex(of: s.current), i > 0 else { return }
            self.session?.current = s.days[i - 1]; self.session?.note = nil
            self.openDay(s.days[i - 1], focus: true)
            self.announceSession()
        }
    }

    /// After "Skip day" in a session: the skipped day has left the list, so go on to the next one, or finish.
    func advanceSession(after day: String) {
        guard session != nil else { return }
        let list = catchUpDays
        if let n = CatchUp.next(after: day, in: list) ?? list.first {
            session?.current = n; session?.note = nil
            openDay(n, focus: true)
            announceSession()
        } else { finishSession() }
    }

    /// "End" or Esc: back to the list. Everything was saved as it was typed, so nothing needs confirming.
    func endSession() {
        guard session != nil else { return }
        flushEditor { [weak self] in
            guard let self = self else { return }
            self.session = nil
            self.selection = .catchUp
            self.recompute()
        }
    }

    /// Nothing left to catch up: the page area shows "All caught up. 3 logged, 1 skipped."
    func finishSession() {
        let days = session?.days ?? []
        sessionResult = SessionResult(logged: days.filter { states[$0] == .logged }.count,
                                      skipped: days.filter { states[$0] == .skipped }.count)
        session = nil
        selection = .catchUp
        if live { UIAnnounce.say("All caught up") }
    }

    private func announceSession() {
        guard live, let s = session else { return }
        UIAnnounce.say("Catching up, \(s.position) of \(s.days.count), \(spokenDate(s.current))")
    }

    // MARK: skip several days
    /// One skip marker per day, one reason, one confirmation. Days with writing are left alone. Shows "Undo" for 8 seconds.
    func skipMany(_ days: [String], reason: String, completion: @escaping (SkipFailure?) -> Void) {
        flushEditor { [weak self] in
            guard let self = self else { return }
            let done: [String]
            do { done = try self.store.skipDays(days, reason: reason) }
            catch LogError.folderMissing { completion(.message("Your log folder can't be found.")); return }
            catch LogError.folderNotWritable { completion(.message("Gloamlog can't save to this folder.")); return }
            catch LogError.io(let m) { completion(.message(m)); return }
            catch { completion(.message(error.localizedDescription)); return }
            if done.isEmpty { completion(.message("None of those days could be skipped. They may already have writing.")); return }
            self.reload()
            if case .day(let k) = self.selection, done.contains(k) { self.editor?.abandon(); self.openDay(k, force: true) }
            let undo = SkipUndo(days: done, reason: reason)
            self.skipUndo = undo
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { if self.skipUndo?.id == undo.id { self.skipUndo = nil } }
            if self.live { UIAnnounce.say(undo.text) }
            completion(nil)
        }
    }

    /// Puts the last batch back: markers go, only where the file is still a pure skip marker.
    func undoLastSkip() {
        guard let u = skipUndo else { return }
        skipUndo = nil
        do { _ = try store.unskipDays(u.days) } catch { pageNotice = "Couldn't undo the skip. \(error.localizedDescription)"; return }
        reload()
        if case .day(let k) = selection, u.days.contains(k) { editor?.abandon(); openDay(k, force: true) }
    }
}
