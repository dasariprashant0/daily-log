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
        Publishers.CombineLatest($searchText, $searchHeading).debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] q, h in self?.runSearch(q, h) }.store(in: &cancellables)
    }

    func runSearch(_ q: String, _ heading: String?) {
        guard !q.dlTrimmed.isEmpty else { searchHits = []; return }
        // What was typed a moment ago must be on disk to be found.
        flushEditor { [weak self] in
            guard let self = self else { return }
            self.searchHits = (try? self.store.search(q, heading: heading)) ?? []
            self.searchCursor = 0
        }
    }
    var searchDayCount: Int { Set(searchHits.map { $0.day }).count }
    /// Headings offered in the search filter: the template's headings.
    var searchHeadingChoices: [String] { MarkdownBody.headings(inTemplate: settings.template) }

    func moveSearchCursor(_ d: Int) {
        guard selection == .search, !searchHits.isEmpty else { return }
        searchCursor = (searchCursor + d + searchHits.count) % searchHits.count
    }
    func focusSearch() { searchFocusTick += 1 }
    func clearSearch() { searchText = "" }

    /// Opens the hit's day and scrolls the matched text into view.
    func open(hit: SearchHit) {
        let day = hit.day
        let needle = hit.matchRange.map { String(hit.snippet[$0]) } ?? ""
        searchText = ""
        openDay(day)
        if !needle.isEmpty {
            // Give the page a moment to load, then select the first occurrence (selection only, no edit).
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in self?.bridgeStorage?.reveal(text: needle) }
        }
    }

    // MARK: weekly review
    func refreshWeek() {
        let probe = WeeklyReview.summary(weekContaining: weekDate, documents: [:], states: states, settings: settings, calendar: cal, now: now)
        let docs = (try? store.documents(from: probe.weekStart, to: probe.weekEnd)) ?? [:]
        week = WeeklyReview.summary(weekContaining: weekDate, documents: docs, states: states, settings: settings, calendar: cal, now: now)
    }
    var canShowNextWeek: Bool {
        let next = WeeklyReview.shift(weekDate, weeks: 1, calendar: cal)
        return (cal.dateInterval(of: .weekOfYear, for: next)?.start ?? next) <= now
    }
    var isCurrentWeek: Bool { cal.isDate(weekDate, equalTo: now, toGranularity: .weekOfYear) }
    func goThisWeek() { weekDate = now; refreshWeek() }

    func weekMarkdown() -> String {
        guard let w = week else { return "" }
        return WeeklyReview.markdown(for: w, grouping: weekGrouping, calendar: cal)
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
