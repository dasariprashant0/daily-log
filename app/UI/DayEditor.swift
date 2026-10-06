// DayEditor.swift - editing state for ONE day (bound to the day it was opened for, so midnight never moves text).
// Autosaves a draft ~1 s after the last keystroke via DraftStore (outside the storage folder).
import SwiftUI
import AppKit

final class DayEditor: ObservableObject {
    let day: String
    unowned let model: AppModel
    @Published var texts: [String: String] = [:]
    @Published var extras: [ExtraSection] = []
    @Published var isSkipped = false
    @Published var skipReason = ""
    @Published var hasFile = false
    @Published var writingAnyway = false
    @Published var restoredFrom: Date?
    @Published var draftSavedAt: Date?
    @Published var savedAt: Date?
    @Published var errorText: String?
    @Published var note: String?            // transient status line, e.g. "2 sections still empty"
    @Published var editBannerDismissed = false
    let openedAsToday: Bool
    private var baseTexts: [String: String] = [:]
    private var baseExtras: [ExtraSection] = []
    private var pending: DispatchWorkItem?

    init(day: String, model: AppModel) {
        self.day = day; self.model = model
        openedAsToday = day == model.today
        let sections = model.settings.sections
        let entry = (try? model.store.load(day)) ?? nil
        for s in sections { texts[s.id] = entry?.texts[s.id] ?? "" }
        extras = entry?.extras ?? []
        isSkipped = entry?.isSkipped ?? false
        skipReason = entry?.skipReason ?? ""
        hasFile = entry != nil
        baseTexts = texts; baseExtras = extras
        if let d = model.drafts.load(day) {
            var merged = texts
            for (k, v) in d.texts where merged[k] != nil { merged[k] = v }
            if merged == baseTexts { model.drafts.clear(day) } else { texts = merged; restoredFrom = d.savedAt }
        }
    }

    // MARK: derived state
    var sections: [SectionDef] { model.settings.sections }
    func text(_ id: String) -> String { texts[id] ?? "" }
    func isFilled(_ id: String) -> Bool { !text(id).dlTrimmed.isEmpty }
    var filled: Int { sections.filter { isFilled($0.id) }.count }
    var total: Int { sections.count }
    var missing: [SectionDef] { sections.filter { $0.required && !isFilled($0.id) } }
    var dirty: Bool {
        if hasFile { return texts != baseTexts || extras != baseExtras }
        return texts.values.contains { !$0.dlTrimmed.isEmpty }
    }
    var showsEditors: Bool { !isSkipped || writingAnyway }
    var canSave: Bool { showsEditors && missing.isEmpty && dirty }
    var firstEmptyID: String? { (missing.first ?? sections.first { !isFilled($0.id) })?.id }

    var chip: (StatusChip.Kind, String) {
        if errorText != nil { return (.error, "Couldn't save") }
        if let n = note { return (.unsaved, n) }
        if dirty {
            if !hasFile, let t = draftSavedAt ?? restoredFrom { return (.draft, "Draft saved \(Fmt.time(t))") }
            return (.unsaved, "Unsaved changes")
        }
        if let s = savedAt { return (.saved, "Saved ✓ \(Fmt.time(s))") }
        if hasFile && !isSkipped { return (.saved, "Saved ✓") }
        return (.none, "Not started")
    }

    // MARK: editing
    func setText(_ id: String, _ v: String) {
        guard texts[id] != v else { return }
        texts[id] = v; touched()
    }
    func setExtra(_ i: Int, _ v: String) {
        guard extras.indices.contains(i), extras[i].text != v else { return }
        extras[i].text = v; touched()
    }
    private func touched() { errorText = nil; note = nil; savedAt = nil; scheduleDraft() }
    func insertNothing(_ id: String) { setText(id, "Nothing.") }

    func revert() {
        texts = baseTexts; extras = baseExtras; restoredFrom = nil; draftSavedAt = nil
        pending?.cancel(); model.drafts.clear(day); model.draftDays.remove(day)
    }
    func discardDraft() { revert() }

    // MARK: draft autosave
    private func scheduleDraft() {
        pending?.cancel()
        let w = DispatchWorkItem { [weak self] in if let s = self { s.writeDraft(sync: false) } }
        pending = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: w)
    }
    /// Flush now (terminate, window close, resign active, day switch).
    func flush() { if pending != nil { pending?.cancel(); pending = nil; writeDraft(sync: true) } }

    private func writeDraft(sync: Bool) {
        pending = nil
        let store = model.drafts, day = self.day, snapshot = texts, isDirty = dirty, now = model.clock()
        let job: () -> Void = {
            if isDirty { _ = try? store.save(day: day, texts: snapshot, now: now) } else { store.clear(day) }
        }
        if sync { job() } else { DispatchQueue.global(qos: .utility).async(execute: job) }
        if isDirty { draftSavedAt = now; model.draftDays.insert(day) } else { draftSavedAt = nil; model.draftDays.remove(day) }
    }

    // MARK: save
    @discardableResult
    func save() -> Bool {
        guard showsEditors else { return false }
        if !missing.isEmpty {
            let n = missing.count
            note = "\(Fmt.plural(n, "section")) still empty"
            model.requestFocus(missing[0].id)
            return false
        }
        var entry = DayEntry(date: day, texts: texts, extras: extras.filter { !$0.text.dlTrimmed.isEmpty })
        entry.refreshStatus(sections: sections)
        do { try model.store.save(entry) }
        catch let e as LogError { fail(e); return false }
        catch { errorText = error.localizedDescription; return false }
        pending?.cancel(); pending = nil
        model.drafts.clear(day)
        for k in texts.keys { texts[k] = text(k).dlTrimmed }
        extras = entry.extras
        baseTexts = texts; baseExtras = extras
        hasFile = true; isSkipped = false; writingAnyway = false
        savedAt = model.clock(); restoredFrom = nil; draftSavedAt = nil; errorText = nil; note = nil
        model.didSave(self)
        return true
    }

    private func fail(_ e: LogError) {
        switch e {
        case .folderMissing(let p): model.folderProblem = .missing(p); errorText = "Folder not found"
        case .folderNotWritable(let p): model.folderProblem = .notWritable(p); errorText = "Folder not writable"
        case .io(let m): errorText = m
        default: errorText = "Couldn't save today's log."
        }
        flush(); writeDraft(sync: true)   // text stays safe as a draft
    }

    func markdown() -> String {
        MarkdownFormat.serialize(day: day, sections: sections.map { ($0.title, text($0.id)) } + extras.map { ($0.title, $0.text) })
    }
    func copyText() {
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(markdown(), forType: .string)
    }
}
