// AppModel+Day.swift - skip day, undo skip, Yesterday card carry-over.
import SwiftUI
import AppKit

enum SkipFailure: Error {
    case message(String)
    var text: String { switch self { case .message(let m): return m } }
}

extension AppModel {
    // MARK: skip
    /// Skips `day` (or every scheduled day through `through`). Throws SkipFailure with a user-readable message.
    func skip(day: String, through: String?, reason: String) throws {
        do {
            if let to = through, to > day {
                let n = try store.skipRange(from: day, to: to, reason: reason, weekdays: settings.weekdays, calendar: cal)
                if n.isEmpty { throw LogError.io("No scheduled days in that range.") }
            } else {
                try store.skip(day, reason: reason)
            }
        } catch LogError.hasContent { throw SkipFailure.message("That day already has a log. Skipping would overwrite it.") }
        catch LogError.folderMissing { throw SkipFailure.message("Your log folder can't be found.") }
        catch LogError.folderNotWritable { throw SkipFailure.message("Daily Log can't save to this folder.") }
        catch LogError.io(let m) { throw SkipFailure.message(m) }
        reload()
        if live { Notifier.shared.cancelAll() }
        if case .day(let k) = selection { editor = DayEditor(day: k, model: self) }
    }

    func unskip(_ day: String) {
        do { _ = try store.unskip(day) } catch { editor.errorText = "Couldn't undo the skip. \(error.localizedDescription)"; return }
        if day == today { planner = planner.suppressed(until: clock().addingTimeInterval(ReminderPlanner.graceAfterUndoSkip)) }
        reload()
        editor = DayEditor(day: day, model: self)
    }

    func requestSkip(day: String? = nil) {
        let d = day ?? today
        guard states[d] != .logged else { return }
        showMainWindow(activate: true)
        sheet = .skip(d)
    }
    var canSkipToday: Bool { states[today] != .logged }

    // MARK: yesterday card
    var carryHidden: Bool { defaults.string(forKey: "yesterdayHiddenDay") == today }

    func refreshCarry() {
        guard case .day(let k) = selection, k == today, !carryHidden else { carryCard = nil; return }
        let c = CarryOver.card(before: today, calendar: cal, load: { (try? self.store.load($0)) ?? nil })
        if c?.sourceDay != carryCard?.sourceDay { carried = false; carryUndo = nil; carryExpanded = false }
        carryCard = c
    }
    var carryTargetID: String { CarryOver.targetSectionID(settings) }
    func sectionTitle(_ id: String) -> String { settings.sections.first { $0.id == id }?.displayTitle ?? "" }

    func carryOver(into id: String? = nil) {
        guard let c = carryCard, editor.day == today else { return }
        let target = id ?? carryTargetID
        guard !target.isEmpty else { return }
        let old = editor.text(target)
        let new = CarryOver.apply(c, to: old)
        guard new != old else { carried = true; carryUndo = nil; return }
        editor.setText(target, new)
        carried = true
        let marker = target + "\u{0}" + old
        carryUndo = marker
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in if self?.carryUndo == marker { self?.carryUndo = nil } }
        if live {
            NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested,
                                 userInfo: [.announcement: "Carried over to \(sectionTitle(target))"])
        }
    }
    func undoCarry() {
        guard let u = carryUndo, let r = u.range(of: "\u{0}") else { return }
        editor.setText(String(u[..<r.lowerBound]), String(u[r.upperBound...]))
        carryUndo = nil; carried = false
    }
    func hideCarry() { defaults.set(today, forKey: "yesterdayHiddenDay"); carryCard = nil }
}
