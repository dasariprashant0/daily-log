// CatchUpView.swift - the unlogged working days, oldest first, grouped by week. Write (or Continue) and Skip on every row;
// ⇧-click or ⌘-click selects several, "Skip…" asks once for a reason and can be undone for 8 seconds; "Start catching up"
// runs through them as a session on the normal page (SessionBar). Empty, new-user and finished states live here too.
import SwiftUI

final class CatchState: ObservableObject {
    @Published var days: [String] = []          // listed when the screen opened or the scope changed; rows stay until you leave
    @Published var anchor: String?
    @Published var window: Int?                 // nil = the Settings window; a scope picked here applies to this screen only
    @Published var words: [String: Int] = [:]   // words so far on started days
}

struct CatchUpView: View {
    @ObservedObject var model: AppModel
    @StateObject private var st = CatchState()
    @Environment(\.accessibilityReduceMotion) private var reduce

    // MARK: rows
    private var rows: [String] { st.days.filter { model.status(of: $0) != .skipped } }
    private var pending: [String] { rows.filter { let s = model.status(of: $0); return s == .missed || s == .partial } }
    private var groups: [(start: String, days: [String])] {
        var out = [(start: String, days: [String])]()
        for d in rows {
            let ws = model.weekStart(of: d) ?? d
            if let last = out.last, last.start == ws { out[out.count - 1].days.append(d) } else { out.append((ws, [d])) }
        }
        return out
    }

    private func reload() {
        let list: [String]
        if let r = model.catchRange { list = model.catchUpList(windowDays: 365).filter { r.contains($0) } }
        else { list = model.catchUpList(windowDays: st.window) }
        st.days = list
        model.catchSelection = model.catchSelection.intersection(Set(list))
        var w = [String: Int]()
        for d in list where model.states[d] == .partial { w[d] = ((try? model.store.load(d)) ?? nil)?.words ?? 0 }
        st.words = w
    }

    private func click(_ d: String) {
        let flags = NSEvent.modifierFlags
        let order = pending
        if flags.contains(.command) {
            if model.catchSelection.contains(d) { model.catchSelection.remove(d) } else { model.catchSelection.insert(d) }
            st.anchor = d
        } else if flags.contains(.shift), let a = st.anchor, let i = order.firstIndex(of: a), let j = order.firstIndex(of: d) {
            model.catchSelection = Set(order[min(i, j)...max(i, j)])
        } else { model.catchSelection = [d]; st.anchor = d }
    }

    // MARK: body
    var body: some View {
        ScrollView {
            Column {
                if let u = model.skipUndo {
                    Banner(.success, u.text) { Button("Undo") { model.undoLastSkip() }.buttonStyle(TextButtonStyle()) }
                        .padding(.bottom, Theme.s4)
                }
                header
                if let r = model.sessionResult { finished(r) }
                else if rows.isEmpty { empty }
                else {
                    controls.padding(.top, Theme.s4).padding(.bottom, Theme.s2)
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(groups, id: \.start) { g in
                            groupHeader(g.start, g.days)
                            ForEach(g.days, id: \.self) { d in
                                CatchRow(model: model, st: st, day: d, onClick: { click(d) })
                                    .transition(.opacity)
                            }
                        }
                    }
                    .animation(Theme.animation(.easeIn(duration: 0.18), reduce: reduce), value: rows)
                }
            }
        }
        .background(Theme.bg)
        .safeAreaInset(edge: .bottom, spacing: 0) { if !model.catchSelection.isEmpty && model.sessionResult == nil { selectionBar } }
        .onAppear { reload() }
        .onChange(of: model.catchRange) { _ in reload() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.s1) {
            HStack(alignment: .firstTextBaseline) {
                Text("Catch up").font(Theme.font(28, .semibold)).tracking(-0.4).foregroundColor(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                if model.sessionResult == nil {
                    Button("Start catching up") { model.startSession(days: pending) }
                        .buttonStyle(PrimaryButtonStyle()).disabled(pending.isEmpty)
                        .help("Open the oldest unlogged day (⌘↩)")
                }
            }
            if model.sessionResult == nil {
                Text(pending.isEmpty ? "You're all caught up." : "You have \(Fmt.plural(pending.count, "unlogged day")).")
                    .font(Theme.font(13)).foregroundColor(Theme.textSecondary).monospacedDigit()
            }
        }
    }

    // MARK: scope, skip menu
    private var scopeChoices: [Int] {
        var c = [14, 30, 60, 90, 365]
        let s = model.settings.catchUpWindowDays
        if !c.contains(s) { c.append(s); c.sort() }
        return c
    }
    private func scopeTitle(_ days: Int) -> String { days >= 365 ? "Since log start" : "Last \(days) days" }
    private var currentScope: Int { st.window ?? model.settings.catchUpWindowDays }

    private var controls: some View {
        HStack(spacing: Theme.s3) {
            if let r = model.catchRange {
                HStack(spacing: 6) {
                    Text("\(model.shortDate(r.lowerBound)) to \(model.shortDate(r.upperBound))").font(Theme.font(13))
                    Button { model.catchRange = nil } label: { Image(systemName: "xmark").font(Theme.font(10, .semibold)) }
                        .buttonStyle(.plain).help("Show every unlogged day").accessibilityLabel("Show every unlogged day")
                }
                .foregroundColor(Theme.textPrimary).padding(.horizontal, 10).frame(height: 28)
                .background(Capsule().fill(Theme.accentTint))
                .accessibilityElement(children: .combine)
            } else {
                Menu {
                    ForEach(scopeChoices, id: \.self) { d in
                        Button { st.window = d; reload() } label: {
                            if d == currentScope { Label(scopeTitle(d), systemImage: "checkmark") } else { Text(scopeTitle(d)) }
                        }
                    }
                } label: { Text(scopeTitle(currentScope)).font(Theme.font(13)) }
                    .menuStyle(.borderedButton).fixedSize().accessibilityLabel("How far back: \(scopeTitle(currentScope))")
            }
            Spacer()
            Menu {
                if !model.catchSelection.isEmpty {
                    Button("Skip \(Fmt.plural(model.catchSelection.count, "selected day"))…") { model.sheet = .skipMany(model.catchSelection.sorted()) }
                }
                Button("Skip all \(pending.count) days…") { model.sheet = .skipMany(pending) }.disabled(pending.isEmpty)
            } label: { Text("Skip…").font(Theme.font(13)) }
                .menuStyle(.borderedButton).fixedSize().disabled(pending.isEmpty)
        }
    }

    private func groupHeader(_ start: String, _ days: [String]) -> some View {
        let done = days.filter { model.status(of: $0) == .logged }.count
        return HStack {
            Text("Week of \(DayKey.format(start, "d MMM", model.cal))").font(Theme.font(12, .semibold)).foregroundColor(Theme.textSecondary)
            Spacer()
            Text("\(done) of \(days.count) logged").font(Theme.font(11)).foregroundColor(Theme.textSecondary).monospacedDigit()
        }
        .padding(.horizontal, Theme.s3).frame(height: 28).padding(.top, Theme.s2)
        .accessibilityElement(children: .combine).accessibilityAddTraits(.isHeader)
    }

    private var selectionBar: some View {
        HStack(spacing: Theme.s3) {
            Text("\(model.catchSelection.count) selected").font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary).monospacedDigit()
            Button("Skip…") { model.sheet = .skipMany(model.catchSelection.sorted()) }.buttonStyle(SecondaryButtonStyle())
            Button("Clear") { model.catchSelection = []; st.anchor = nil }.buttonStyle(TextButtonStyle(color: Theme.textSecondary))
            Spacer()
            Text("⇧-click or ⌘-click to select more").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
        }
        .padding(.horizontal, Theme.s4).frame(height: Theme.sessionBarH)
        .background(Theme.sidebar)
        .overlay(Rectangle().fill(Theme.border).frame(height: 1), alignment: .top)
    }

    // MARK: empty, new user, finished
    private func state<Actions: View>(_ title: String, _ detail: String, @ViewBuilder actions: () -> Actions) -> some View {
        VStack(spacing: Theme.s3) {
            Text(title).font(Theme.font(15, .semibold)).foregroundColor(Theme.textPrimary).accessibilityAddTraits(.isHeader)
            Text(detail).font(Theme.font(13)).foregroundColor(Theme.textSecondary).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: Theme.s3) { actions() }.padding(.top, Theme.s2)
        }
        .frame(maxWidth: .infinity).padding(.vertical, Theme.s12)
    }

    @ViewBuilder private var empty: some View {
        if model.states.isEmpty && model.settings.logStartDate == nil {
            state("Nothing to catch up on yet.", "Days before your first page don't count.") {
                Button("Open calendar") { model.goToDateOpen = true }.buttonStyle(SecondaryButtonStyle())
                Button("Log start date…") { model.openSettings(pane: .page) }.buttonStyle(TextButtonStyle())
            }
        } else {
            let since = model.since.map { DayKey.format($0, "d MMM", model.cal) } ?? "the start"
            state("You're all caught up.", "Every working day since \(since) has a page or a skip.") {
                Button("Go to today") { model.openToday() }.buttonStyle(SecondaryButtonStyle())
                Button("Review this week") { model.select(.week) }.buttonStyle(TextButtonStyle())
            }
        }
    }

    private func finished(_ r: SessionResult) -> some View {
        let parts = [r.logged > 0 ? "\(r.logged) logged" : nil, r.skipped > 0 ? "\(r.skipped) skipped" : nil].compactMap { $0 }
        return state("All caught up." + (parts.isEmpty ? "" : " \(parts.joined(separator: ", "))."),
                     model.streak.current > 1 ? "Your streak is \(model.streak.current) days." : "Every working day in this run has a page or a skip.") {
            Button("Review this week") { model.select(.week) }.buttonStyle(SecondaryButtonStyle())
            Button("Go to today") { model.openToday() }.buttonStyle(TextButtonStyle())
        }
    }
}

// MARK: - one row

private struct CatchRow: View {
    @ObservedObject var model: AppModel
    @ObservedObject var st: CatchState
    let day: String
    let onClick: () -> Void

    var body: some View {
        let status = model.status(of: day)
        let logged = status == .logged
        let picked = model.catchSelection.contains(day)
        let partial = status == .partial
        HoverReader { hovering in
            HStack(spacing: Theme.s3) {
                Image(systemName: logged ? "checkmark.circle.fill" : (partial ? "circle.lefthalf.filled" : "circle.dashed"))
                    .font(Theme.font(14)).foregroundColor(logged ? Theme.accent : (partial ? Theme.textSecondary : Theme.warning))
                    .frame(width: 16).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 1) {
                    Text(model.shortDate(day)).font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary)
                    Text(logged ? "Logged" : (partial ? "\(st.words[day] ?? 0) of \(model.minWords) words" : "Not started"))
                        .font(Theme.font(12)).foregroundColor(Theme.textSecondary).monospacedDigit()
                }
                Spacer()
                if !logged {
                    Button(partial ? "Continue" : "Write") { model.select(.day(day)) }.buttonStyle(SecondaryButtonStyle())
                        .accessibilityLabel("\(partial ? "Continue" : "Write") \(model.spokenDate(day))")
                    Button("Skip") { model.sheet = .skipMany([day]) }
                        .buttonStyle(TextButtonStyle(color: Theme.textSecondary)).frame(minWidth: 44, minHeight: 28)
                        .accessibilityLabel("Skip \(model.spokenDate(day))")
                }
            }
            .padding(.horizontal, Theme.s3).frame(height: Theme.catchRowH)
            .background(Theme.rect().fill(picked ? Theme.accentTint : (hovering ? Theme.hover : Color.clear)))
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { if !logged { model.select(.day(day)) } }
            .onTapGesture { if !logged { onClick() } }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(model.spokenStatus(day) + (partial ? ", \(st.words[day] ?? 0) of \(model.minWords) words" : ""))
            .accessibilityAddTraits(picked ? .isSelected : [])
        }
    }
}
