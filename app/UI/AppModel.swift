// AppModel.swift - the single ObservableObject that owns LogStore, Settings, planner state, navigation and the open page.
// Everything runs on the main thread by convention (no @MainActor: closures from Timer/NotificationCenter stay simple).
// Extensions: +Editor (page switching, flush, bridge delegate), +Day (skip, carry-over, versions), +Reminders (timer,
// notifications, window), +Storage (folder, login item), +Browse (search, weekly review).
import SwiftUI
import Combine
import AppKit

enum Destination: Hashable { case day(String), week, search }

enum ActiveSheet: Identifiable, Equatable {
    case skip(String), onboarding, whatsNew, restore(String)
    var id: String {
        switch self {
        case .skip(let d): return "skip-\(d)"
        case .onboarding: return "onboarding"
        case .whatsNew: return "whatsnew"
        case .restore(let d): return "restore-\(d)"
        }
    }
}

enum FolderProblem: Equatable {
    case missing(String), notWritable(String)
    var path: String { switch self { case .missing(let p), .notWritable(let p): return p } }
}

enum NotifState { case unknown, allowed, denied }

final class AppModel: ObservableObject {
    static let shared = AppModel()
    static let plannerKey = "dailylog.planner.v1"
    static let whatsNewKey = "dailylog.whatsNew.0.3"
    /// Safety copies live outside the storage folder so they never sync with the logs.
    static var defaultBackupDir: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Gloamlog/backups")
    }
    /// Autosave overwrites while the newest backup is younger than this do not copy again, so the 10 slots span a long session.
    static let backupInterval: TimeInterval = 120

    let cal = Calendar.current
    let defaults: UserDefaults
    let live: Bool                       // false in the snapshot harness: no timers, web view, notifications or login item
    var clock: () -> Date
    let backupDir: URL
    var store: LogStore

    @Published var now: Date
    @Published var settings: Settings { didSet { settingsChanged(old: oldValue) } }
    @Published var states: [String: DayStatus] = [:]
    @Published var skipReasons: [String: String] = [:]
    @Published var folderProblem: FolderProblem?
    @Published var streak = StreakResult(current: 0, best: 0)
    @Published var heat: [[HeatCell]] = []
    @Published var selection: Destination
    @Published var editor: DayEditor!
    @Published var sheet: ActiveSheet?
    @Published var planner: PlannerState { didSet { persistPlanner() } }
    @Published var notifState: NotifState = .unknown
    @Published var collapsedMonths: [String: Bool] = [:]
    @Published var rolloverDismissed = false
    @Published var nagDismissedDay = ""
    @Published var editorProblem: String?
    @Published var pageNotice: String?          // transient: an image that could not be added, etc.
    /// Pages the user has left whose last edits could not be written (folder unavailable). Kept in memory and retried, so
    /// leaving a page never discards unsaved text; the quit path asks before giving them up.
    @Published var orphans: [DayEditor] = []
    // From yesterday
    @Published var carryCard: CarryCard?
    @Published var carryUndoBody: String?
    // search
    @Published var searchText = ""
    @Published var searchHeading: String?
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
    var timer: Timer?
    var screensAsleep = false
    var openWindowAction: (() -> Void)?
    var bridgeStorage: EditorBridge?
    var retiredMarkdown: String?         // the previous page's final text: a late change event equal to it is not the new page's

    init(defaults: UserDefaults = .standard, backupDir: URL = AppModel.defaultBackupDir, live: Bool = true,
         clock: @escaping () -> Date = Date.init) {
        self.defaults = defaults; self.live = live; self.clock = clock; self.backupDir = backupDir
        // Once-only carry-over from the app's earlier name. Only for the real app (the standard defaults), never for the
        // test/snapshot harnesses, which pass their own throwaway suites and must not touch the user's real data.
        if live && defaults === UserDefaults.standard { LegacyMigration.run(into: defaults) }
        var s = Settings.load(from: defaults)
        let isV1 = defaults.object(forKey: Settings.storageKey) == nil && defaults.object(forKey: "remindMinutes") != nil
        if isV1 { s.reminderMinutes = defaults.integer(forKey: "remindMinutes"); s.onboarded = true }
        if !s.onboarded { s.launchAtLogin = false }     // login item is opt-in: never registered silently
        settings = s.normalized()
        let n = clock()
        now = n
        let today = DayKey.string(n, cal)
        selection = .day(today); returnSelection = .day(today); weekDate = n
        store = AppModel.makeStore(dir: s.storageFolder, backupDir: backupDir)
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

    static func makeStore(dir: URL, backupDir: URL) -> LogStore {
        LogStore(dir: dir, backupDir: backupDir, minBackupInterval: backupInterval)
    }

    private func decideFirstRun(isV1: Bool) {
        if !settings.onboarded { sheet = .onboarding }
        else if defaults.object(forKey: AppModel.whatsNewKey) == nil { sheet = .whatsNew }
    }

    // MARK: derived
    var today: String { DayKey.string(now, cal) }
    var since: String? { states.keys.min() }
    var todayStatus: DayStatus { status(of: today) }
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
    var minWords: Int { settings.minWords }

    /// History rows: every day with a file (logged, partial or skipped), except today, newest first.
    var historyDays: [String] {
        var set = Set(states.keys)
        set.remove(today)
        return set.sorted(by: >)
    }

    // MARK: data
    func reload() {
        do { try store.checkFolder(); folderProblem = nil }
        catch LogError.folderMissing(let p) { folderProblem = .missing(p) }
        catch LogError.folderNotWritable(let p) { folderProblem = .notWritable(p) }
        catch { }
        let st = (try? store.fileStates(minWords: settings.minWords)) ?? [:]
        states = st
        var reasons = [String: String]()
        for (d, s) in st where s == .skipped { if let e = (try? store.load(d)) ?? nil { reasons[d] = e.skipReason } }
        skipReasons = reasons
        recompute()
    }

    /// Streak and heatmap from the in-memory states (no disk). Also used after a single day's save.
    func recompute() {
        streak = Streak.compute(states: states, now: now, calendar: cal, weekdays: settings.weekdays)
        heat = Heatmap.weeks(states: states, now: now, calendar: cal, weekdays: settings.weekdays)
        if selection == .week { refreshWeek() }
    }

    /// One day was written: update just that day's state, not every file.
    func didSave(day: String) {
        let doc = (try? store.load(day)) ?? nil
        let st = doc?.status(minWords: settings.minWords)
        if let s = st, s != .missed { states[day] = s } else { states[day] = nil }
        if st == .skipped { skipReasons[day] = doc?.skipReason ?? "" } else { skipReasons[day] = nil }
        folderProblem = nil
        recompute()
        if live && todayStatus == .logged { Notifier.shared.cancelAll() }
        if st == .logged && day == today && live { UIAnnounce.say("Logged for today") }
    }

    func settingsChanged(old: Settings) {
        let words = min(max(settings.minWords, Settings.minWordsRange.lowerBound), Settings.minWordsRange.upperBound)
        if words != settings.minWords { settings.minWords = words; return }          // re-enters with a valid value
        settings.save(to: defaults)
        if live && old != settings { planner = planner.suppressed(until: clock().addingTimeInterval(ReminderPlanner.graceAfterSettingsChange)) }
        if old.weekdays != settings.weekdays || old.reminderMinutes != settings.reminderMinutes || old.minWords != settings.minWords { reload() }
        if old.carryOverHeadings != settings.carryOverHeadings { refreshCarry() }
        // A page nobody has touched follows the template; a page with writing never does.
        if old.template != settings.template, let e = editor, !e.userEdited, e.diskBody == nil, !e.isSkipped, case .day = selection {
            openDay(e.day, force: true)
        }
    }

    func persistPlanner() { defaults.set(try? JSONEncoder().encode(planner), forKey: AppModel.plannerKey) }

    // MARK: navigation
    func select(_ d: Destination) {
        switch d {
        case .day(let k): openDay(k)
        case .week:
            selection = .week
            weekDate = clock(); refreshWeek()
            flushEditor { [weak self] in self?.refreshWeek() }       // include text typed a moment ago
        case .search: selection = .search
        }
        if case .search = d {} else if !searchText.isEmpty { searchText = "" }
    }
    func openToday() { select(.day(today)) }

    /// Previous/next in the history order (⌘[ / ⌘]) or previous/next week.
    func step(_ dir: Int) {
        if selection == .week {
            guard dir < 0 || canShowNextWeek else { return }
            weekDate = WeeklyReview.shift(weekDate, weeks: dir, calendar: cal); refreshWeek(); return
        }
        guard case .day(let cur) = selection else { return }
        let list = [today] + historyDays
        guard let i = list.firstIndex(of: cur) else { return }
        let j = i - dir                       // newest first: "previous" = older = higher index
        if list.indices.contains(j) { select(.day(list[j])) }
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
            planner = PlannerState(day: today, graceUntil: planner.graceUntil)
        }
        reload()
        if today != old { refreshCarry() }
    }
}
