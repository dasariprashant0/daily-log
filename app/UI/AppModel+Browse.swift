// AppModel+Browse.swift - search (debounced, saved files only) and the weekly review.
import SwiftUI
import AppKit
import Combine

extension AppModel {
    // MARK: search
    func bindSearch() {
        $searchText.removeDuplicates().sink { [weak self] q in
            guard let self = self else { return }
            let empty = q.dlTrimmed.isEmpty
            if !empty, self.selection != .search { self.returnSelection = self.selection; self.selection = .search }
            if empty { self.searchHits = []; if self.selection == .search { self.selection = self.returnSelection } }
        }.store(in: &cancellables)
        Publishers.CombineLatest($searchText, $searchSection).debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] q, sec in self?.runSearch(q, sec) }.store(in: &cancellables)
    }

    func runSearch(_ q: String, _ sec: String?) {
        guard !q.dlTrimmed.isEmpty else { searchHits = []; return }
        searchHits = (try? store.search(q, sectionID: sec)) ?? []
        searchCursor = 0
    }
    var searchDayCount: Int { Set(searchHits.map { $0.day }).count }

    func moveSearchCursor(_ d: Int) {
        guard selection == .search, !searchHits.isEmpty else { return }
        searchCursor = (searchCursor + d + searchHits.count) % searchHits.count
    }
    func focusSearch() { searchFocusTick += 1 }
    func clearSearch() { searchText = "" }

    func open(hit: SearchHit) {
        let sid = hit.sectionID
        let target = hit.day
        searchText = ""
        select(.day(target))
        if let id = sid { DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { self.requestFocus(id) } }
    }

    // MARK: weekly review
    func refreshWeek() {
        let probe = WeeklyReview.summary(weekContaining: weekDate, entries: [:], states: states, settings: settings, calendar: cal, now: now)
        let entries = (try? store.entries(from: probe.weekStart, to: probe.weekEnd)) ?? [:]
        week = WeeklyReview.summary(weekContaining: weekDate, entries: entries, states: states, settings: settings, calendar: cal, now: now)
    }
    var canShowNextWeek: Bool {
        let next = WeeklyReview.shift(weekDate, weeks: 1, calendar: cal)
        return (cal.dateInterval(of: .weekOfYear, for: next)?.start ?? next) <= now
    }
    var isCurrentWeek: Bool { cal.isDate(weekDate, equalTo: now, toGranularity: .weekOfYear) }
    func goThisWeek() { weekDate = now; refreshWeek() }

    func weekMarkdown() -> String {
        guard let w = week else { return "" }
        return WeeklyReview.markdown(for: w, grouping: weekGrouping, sections: settings.sections, calendar: cal)
    }
    func copyWeek() {
        guard week != nil else { return }
        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(weekMarkdown(), forType: .string)
        copiedFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in self?.copiedFlash = false }
    }
    func weekTitle(_ w: WeekSummary) -> String {
        "Week of \(DayKey.format(w.weekStart, "d", cal)) to \(DayKey.format(w.weekEnd, "d MMM yyyy", cal))"
    }
}
