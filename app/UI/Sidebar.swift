// Sidebar.swift - search field, Today / This week, month-grouped history, streak + heatmap footer.
import SwiftUI

struct SidebarView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                SearchField(model: model).padding(.horizontal, Theme.s3).padding(.top, Theme.s3).padding(.bottom, Theme.s2)
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 1) {
                        TodayRow(model: model)
                        WeekRow(model: model)
                        HistoryList(model: model)
                    }.padding(.horizontal, Theme.s2).padding(.bottom, Theme.s3)
                }
                if geo.size.height >= 560 { SidebarFooter(model: model) }
            }
        }
        .background(Theme.sidebar.ignoresSafeArea())
    }
}

struct SearchField: View {
    @ObservedObject var model: AppModel
    @FocusState private var focused: Bool
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass").font(Theme.font(12)).foregroundColor(Theme.textTertiary).accessibilityHidden(true)
            TextField("Search your logs", text: $model.searchText)
                .textFieldStyle(.plain).font(Theme.font(13)).focused($focused)
                .onExitCommand { model.clearSearch() }
                .accessibilityLabel("Search your logs")
            if !model.searchText.isEmpty {
                Button { model.clearSearch() } label: {
                    Image(systemName: "xmark.circle.fill").font(Theme.font(12)).foregroundColor(Theme.textTertiary)
                }.buttonStyle(.plain).accessibilityLabel("Clear search").help("Clear search")
            }
        }
        .padding(.horizontal, Theme.s2).frame(height: 28)
        .background(Theme.rect().fill(Theme.surface))
        .overlay(Theme.rect().stroke(focused ? Theme.accent : Theme.border, lineWidth: focused ? 1.5 : 1))
        .onChange(of: model.searchFocusTick) { _ in focused = true }
    }
}

struct SidebarRow: View {
    let symbol: String
    let color: Color
    let title: String
    var trailing: String?
    var weight: Font.Weight = .regular
    let selected: Bool
    let label: String
    let action: () -> Void
    var body: some View {
        HoverReader { hovering in
            Button(action: action) {
                HStack(spacing: Theme.s2) {
                    StatusGlyph(symbol: symbol, color: color)
                    Text(title).font(Theme.font(13, selected ? .medium : weight)).foregroundColor(Theme.textPrimary).lineLimit(1)
                    Spacer(minLength: 4)
                    if let t = trailing { Text(t).font(Theme.font(11)).foregroundColor(Theme.textSecondary).monospacedDigit() }
                }
                .padding(.horizontal, 10).frame(height: 30)
                .background(Theme.rect().fill(selected ? Theme.accentTint : (hovering ? Theme.hover : Color.clear)))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(label).accessibilityAddTraits(selected ? .isSelected : [])
        }
    }
}

struct TodayRow: View {
    @ObservedObject var model: AppModel
    var body: some View {
        let st = model.status(of: model.today)
        let draft = model.draftDays.contains(model.today)
        let (sym, col): (String, Color) = {
            switch st {
            case .logged: return ("checkmark.circle.fill", Theme.accent)
            case .skipped: return ("minus.circle", Theme.textTertiary)
            case .off: return ("moon.zzz", Theme.textTertiary)
            default: return (draft ? "circle.lefthalf.filled" : "circle", Theme.textSecondary)
            }
        }()
        let state = st == .logged ? "logged" : st == .skipped ? "skipped" : st == .off ? "not a workday" : (draft ? "not logged, draft saved" : "not logged")
        SidebarRow(symbol: sym, color: col, title: "Today", trailing: draft && st != .logged ? "draft" : nil, weight: .semibold,
                   selected: model.selection == .day(model.today), label: "Today, \(state)") { model.openToday() }
    }
}

struct WeekRow: View {
    @ObservedObject var model: AppModel
    var body: some View {
        SidebarRow(symbol: "calendar", color: Theme.textSecondary, title: "This week", selected: model.selection == .week,
                   label: "This week, weekly review") { model.select(.week) }
    }
}

struct HistoryList: View {
    @ObservedObject var model: AppModel
    private func monthKey(_ d: String) -> String { String(d.prefix(7)) }

    var body: some View {
        let days = model.historyDays
        if days.isEmpty {
            EmptyHint(text: "Your logs will appear here.").padding(.top, Theme.s2)
        } else {
            let months = Array(NSOrderedSet(array: days.map(monthKey))).compactMap { $0 as? String }
            ForEach(Array(months.enumerated()), id: \.element) { idx, m in
                MonthHeader(model: model, monthKey: m, index: idx, days: days.filter { monthKey($0) == m })
                if !(model.collapsedMonths[m] ?? (idx >= 2)) {
                    ForEach(days.filter { monthKey($0) == m }, id: \.self) { d in HistoryRow(model: model, day: d) }
                }
            }
        }
    }
}

struct MonthHeader: View {
    @ObservedObject var model: AppModel
    let monthKey: String, index: Int, days: [String]
    var body: some View {
        let collapsed = model.collapsedMonths[monthKey] ?? (index >= 2)
        let logged = days.filter { model.states[$0] == .logged }.count
        Button { model.toggleMonth(monthKey, defaultCollapsed: index >= 2) } label: {
            HStack(spacing: 6) {
                Image(systemName: collapsed ? "chevron.right" : "chevron.down").font(Theme.font(9, .semibold)).frame(width: 10)
                Text(DayKey.format(days[0], "MMMM yyyy", model.cal)).font(Theme.font(12, .semibold))
                Spacer()
                if collapsed { Text("\(logged)/\(days.count)").font(Theme.font(11)).monospacedDigit() }
            }
            .foregroundColor(Theme.textSecondary).padding(.horizontal, 10).frame(height: 28).contentShape(Rectangle())
        }
        .buttonStyle(.plain).padding(.top, index == 0 ? Theme.s3 : Theme.s2)
        .accessibilityLabel("\(DayKey.format(days[0], "MMMM yyyy", model.cal)), \(collapsed ? "collapsed" : "expanded")")
    }
}

struct HistoryRow: View {
    @ObservedObject var model: AppModel
    let day: String
    var body: some View {
        let st = model.states[day]
        let draft = model.draftDays.contains(day) && st != .logged
        let (sym, col, word): (String, Color, String) = {
            switch st {
            case .some(.logged): return (draft ? "pencil.circle" : "checkmark.circle.fill", Theme.accent, "logged")
            case .some(.skipped): return ("minus.circle", Theme.textTertiary, "skipped")
            case .some(.partial): return ("circle.lefthalf.filled", Theme.textSecondary, "partly logged")
            default: return ("pencil.circle", Theme.textSecondary, "draft")
            }
        }()
        let reason = model.skipReasons[day] ?? ""
        SidebarRow(symbol: sym, color: col, title: model.shortDate(day),
                   trailing: draft ? "draft" : (st == .skipped ? "skipped" : nil),
                   selected: model.selection == .day(day),
                   label: "\(model.spokenDate(day)), \(word)\(st == .skipped && !reason.isEmpty ? ", \(reason)" : "")\(draft && st != nil ? ", unsaved edits" : "")") {
            model.select(.day(day))
        }
        .contextMenu {
            Button("Show in Finder") { model.reveal([model.store.url(for: day)]) }
            if st == .some(.logged) || st == .some(.partial) {
                Button("Copy as Markdown") {
                    if let e = (try? model.store.load(day)) ?? nil {
                        let md = MarkdownFormat.serialize(day: day, sections: model.settings.sections.compactMap { s in e.texts[s.id].map { (s.title, $0) } } + e.extras.map { ($0.title, $0.text) })
                        NSPasteboard.general.clearContents(); NSPasteboard.general.setString(md, forType: .string)
                    }
                }
            }
            if st != .some(.logged) && st != .some(.skipped) { Button("Skip this day") { model.requestSkip(day: day) } }
        }
    }
}

struct SidebarFooter: View {
    @ObservedObject var model: AppModel
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s2) {
            StreakLine(model: model)
            HeatmapView(model: model, cell: 11, gap: 3)
        }
        .padding(Theme.s4).frame(maxWidth: .infinity, alignment: .leading)
        .overlay(Rectangle().fill(Theme.border).frame(height: 1), alignment: .top)
    }
}

struct StreakLine: View {
    @ObservedObject var model: AppModel
    var body: some View {
        let s = model.streak
        HStack(alignment: .firstTextBaseline) {
            Text(s.current == 0 ? "No streak yet" : "\(s.current) day streak")
                .font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary).monospacedDigit()
            Spacer()
            if s.best > 0 { Text("Best: \(s.best)").font(Theme.font(11)).foregroundColor(Theme.textSecondary).monospacedDigit() }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(s.current == 0 ? "No streak yet" : "\(s.current) day streak. Best \(s.best).")
    }
}
