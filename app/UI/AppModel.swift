// AppModel.swift - the single ObservableObject that owns LogStore, DraftStore, Settings, planner state and navigation.
// Everything runs on the main thread by convention (no @MainActor: closures from Timer/NotificationCenter stay simple).
// Extensions: AppModel+Day (skip/carry), +Reminders (timer/notify/window), +Storage (folder/login), +Browse (search/week).
import SwiftUI
import Combine
import AppKit

enum Destination: Hashable { case day(String), week, search }

enum ActiveSheet: Identifiable, Equatable {
    case skip(String), onboarding, whatsNew
    var id: String {
        switch self { case .skip(let d): return "skip-\(d)"; case .onboarding: return "onboarding"; case .whatsNew: return "whatsnew" }
    }
}

enum FolderProblem: Equatable {
    case missing(String), notWritable(String)
    var path: String { switch self { case .missing(let p), .notWritable(let p): return p } }
}

enum NotifState { case unknown, allowed, denied }
struct FocusRequest: Equatable { var sectionID: String; var token: Int }

final class AppModel: ObservableObject {
    static let shared = AppModel()
    static let plannerKey = "dailylog.planner.v1"

    let cal = Calendar.current
    let defaults: UserDefaults
    let live: Bool                       // false in the snapshot harness: no timers, notifications or login item
    var clock: () -> Date
    var store: LogStore
    let drafts: DraftStore

    @Published var now: Date
    @Published var settings: Settings { didSet { settingsChanged(old: oldValue) } }
    @Published var states: [String: DayStatus] = [:]
    @Published var skipReasons: [String: String] = [:]
    @Published var draftDays: Set<String> = []
    @Published var folderProblem: FolderProblem?
    @Published var streak = StreakResult(current: 0, best: 0)
    @Published var heat: [[HeatCell]] = []
    @Published var selection: Destination
    @Published var editor: DayEditor!
    @Published var sheet: ActiveSheet?
    @Published var planner: PlannerState { didSet { persistPlanner() } }
    @Published var notifState: NotifState = .unknown
    @Published var collapsedMonths: [String: Bool] = [:]
    @Published var focusRequest: FocusRequest?
    @Published var quietLine: String?
    @Published var rolloverDismissed = false
    // carry-over
    @Published var carryCard: CarryCard?
    @Published var carried = false
    @Published var carryUndo: String?
    @Published var carryExpanded = false
    // search
    @Published var searchText = ""
    @Published var searchSection: String?
    @Published var searchHits: [SearchHit] = []
    @Published var searchCursor = 0
    @Published var searchFocusTick = 0
    var returnSelection: Destination
    // weekly review
    @Published var weekDate: Date
    @Published var week: WeekSummary?
    @Published var weekGrouping: WeekGrouping = .day
    @Published var copiedFlash = false
    // storage
    @Published var storageSummary: FolderSummary?
    @Published var storageResult: StorageResult?
    @Published var loginMessage: String?

    var cancellables = Set<AnyCancellable>()
    var focusToken = 0
    var timer: Timer?
    var screensAsleep = false
    var quietWork: DispatchWorkItem?
    var openWindowAction: (() -> Void)?
    var editorStartedFocused = false

    init(defaults: UserDefaults = .standard, draftsDir: URL = DraftStore.defaultDir, live: Bool = true,
         clock: @escaping () -> Date = Date.init) {
        self.defaults = defaults; self.live = live; self.clock = clock
        var s = Settings.load(from: defaults)
        let isV1 = defaults.object(forKey: Settings.storageKey) == nil && defaults.object(forKey: "remindMinutes") != nil
        if isV1 { s.reminderMinutes = defaults.integer(forKey: "remindMinutes"); s.onboarded = true }
        if !s.onboarded { s.launchAtLogin = false }     // login item is opt-in: never registered silently
        settings = s.normalized()
        let n = clock()
        now = n
        let today = DayKey.string(n, cal)
        selection = .day(today); returnSelection = .day(today); weekDate = n
        store = LogStore(dir: s.storageFolder, sections: s.sections)
        drafts = DraftStore(dir: draftsDir)
        if let d = defaults.data(forKey: AppModel.plannerKey), let p = try? JSONDecoder().decode(PlannerState.self, from: d) {
            planner = PlannerState.atLaunch(previous: p, now: n, calendar: cal)
        } else { planner = PlannerState.atLaunch(previous: nil, now: n, calendar: cal) }
        if !live { planner.graceUntil = nil }
        reload()
        editor = DayEditor(day: today, model: self)
        refreshCarry()
        bindSearch()
        if live { decideFirstRun(isV1: isV1) }
    }

    private func decideFirstRun(isV1: Bool) {
        if !settings.onboarded {
            sheet = .onboarding
        } else if defaults.object(forKey: "dailylog.whatsNew.0.2") == nil && isV1 {
            sheet = .whatsNew
        }
    }

    // MARK: derived
    var today: String { DayKey.string(now, cal) }
    var since: String? { states.keys.min() }
    var todayStatus: DayStatus {
        Status.resolve(day: today, fileState: states[today], now: now, calendar: cal, weekdays: settings.weekdays, since: since)
    }
    var snoozed: Bool { if let u = planner.snoozedUntil { return now < u }; return false }
    var isDue: Bool {
        ReminderPlanner.isPending(now: now, calendar: cal, settings: settings, todayStatus: todayStatus) && !snoozed
    }
    func status(of day: String) -> DayStatus {
        Status.resolve(day: day, fileState: states[day], now: now, calendar: cal, weekdays: settings.weekdays, since: since)
    }
    func isWorkday(_ day: String) -> Bool { settings.weekdays.contains(DayKey.weekday(day, cal)) }
    func longDate(_ day: String) -> String { DayKey.format(day, "EEEE, d MMMM yyyy", cal) }
    func shortDate(_ day: String) -> String { DayKey.format(day, "EEE d MMM", cal) }
    func spokenDate(_ day: String) -> String { DayKey.format(day, "EEEE d MMMM", cal) }
    var reminderLabel: String { Fmt.clock(minutes: settings.reminderMinutes, calendar: cal, now: now) }
    var folderDisplay: String { (settings.storageFolder.path as NSString).abbreviatingWithTildeInPath }

    /// History rows: every day with a file or a draft, except today, newest first.
    var historyDays: [String] {
        var set = Set(states.keys).union(draftDays)
        set.remove(today)
        return set.sorted(by: >)
    }

    // MARK: data
    func reload() {
        do { try store.checkFolder(); folderProblem = nil }
        catch LogError.folderMissing(let p) { folderProblem = .missing(p) }
        catch LogError.folderNotWritable(let p) { folderProblem = .notWritable(p) }
        catch { }
        let st = (try? store.fileStates()) ?? [:]
        states = st
        var reasons = [String: String]()
        for (d, s) in st where s == .skipped { if let e = (try? store.load(d)) ?? nil { reasons[d] = e.skipReason } }
        skipReasons = reasons
        draftDays = Set(drafts.days())
        streak = Streak.compute(states: st, now: now, calendar: cal, weekdays: settings.weekdays)
        heat = Heatmap.weeks(states: st, now: now, calendar: cal, weekdays: settings.weekdays)
        if selection == .week { refreshWeek() }
    }

    func settingsChanged(old: Settings) {
        settings.save(to: defaults)
        store.sections = settings.sections
        if live && old != settings { planner = planner.suppressed(until: clock().addingTimeInterval(ReminderPlanner.graceAfterSettingsChange)) }
        if old.weekdays != settings.weekdays || old.reminderMinutes != settings.reminderMinutes { reload() }
        if old.sections != settings.sections, let e = editor, !e.dirty { editor = DayEditor(day: e.day, model: self) }
    }

    func persistPlanner() { defaults.set(try? JSONEncoder().encode(planner), forKey: AppModel.plannerKey) }

    // MARK: navigation
    func select(_ d: Destination) {
        flushEditor()
        switch d {
        case .day(let k):
            if editor?.day != k { editor = DayEditor(day: k, model: self); rolloverDismissed = false }
            refreshCarry()
        case .week: weekDate = clock(); refreshWeek()
        case .search: break
        }
        selection = d
        if case .search = d {} else if !searchText.isEmpty { searchText = "" }
    }
    func openToday() { select(.day(today)) }
    func flushEditor() { editor?.flush() }

    /// Previous/next in the History order (⌘[ / ⌘]) or previous/next week.
    func step(_ dir: Int) {
        if selection == .week {
            let next = WeeklyReview.shift(weekDate, weeks: dir, calendar: cal)
            guard dir < 0 || canShowNextWeek else { return }
            weekDate = next; refreshWeek(); return
        }
        guard case .day(let cur) = selection else { return }
        let list = [today] + historyDays
        guard let i = list.firstIndex(of: cur) else { return }
        let j = i - dir                       // list is newest first; "previous" = older = higher index
        if list.indices.contains(j) { select(.day(list[j])) }
    }

    func requestFocus(_ id: String) { focusToken += 1; focusRequest = FocusRequest(sectionID: id, token: focusToken) }
    func focusFirstEmpty() { if let id = editor.firstEmptyID { requestFocus(id) } }
    func moveFocus(_ delta: Int, from current: String?) {
        let ids = editor.sections.map { $0.id }
        guard !ids.isEmpty else { return }
        let i = current.flatMap { ids.firstIndex(of: $0) } ?? (delta > 0 ? -1 : ids.count)
        requestFocus(ids[min(max(i + delta, 0), ids.count - 1)])
    }

    func saveCurrent() {
        guard case .day = selection, editor.showsEditors else { return }
        editor.save()
    }

    func didSave(_ e: DayEditor) {
        let before = streak.current
        reload()
        if live { Notifier.shared.cancelAll() }
        if e.day == today && streak.current > before && streak.current >= 2 { flashQuiet("\(streak.current) days in a row.") }
        refreshCarry()
    }

    func flashQuiet(_ s: String) {
        quietLine = s; quietWork?.cancel()
        let w = DispatchWorkItem { [weak self] in if let s = self { s.quietLine = nil } }
        quietWork = w; DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: w)
    }

    func toggleMonth(_ key: String, defaultCollapsed: Bool) {
        collapsedMonths[key] = !(collapsedMonths[key] ?? defaultCollapsed)
    }
}

/// Midnight handling: called by the timer and by day/clock/wake notifications.
extension AppModel {
    func refreshClock() {
        let old = today
        now = clock()
        if today != old {
            rolloverDismissed = false
            states = states   // nudge views; reload() below recomputes everything
            planner = PlannerState(day: today, graceUntil: planner.graceUntil)
        }
        reload()
        if today != old { refreshCarry() }
    }
}
