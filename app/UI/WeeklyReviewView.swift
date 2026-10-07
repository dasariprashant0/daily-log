// WeeklyReviewView.swift - the week review: every day of the week is a tile that opens (empty weeks included), a counts line
// ("Logged 4 of 5 · 1 skipped · 2 not logged"), cards for what was written, and "Copy as markdown".
import SwiftUI

struct WeeklyReviewView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            Column {
                if let w = model.week {
                    header(w)
                    tiles
                    if hasNothing(w) { empty } else { content(w) }
                }
            }
        }
        .background(Theme.bg)
        .onAppear { model.refreshWeek() }
    }

    private func hasNothing(_ w: WeekSummary) -> Bool {
        let c = model.weekCounts()
        return c.logged == 0 && c.skipped == 0 && !w.days.contains(where: { $0.doc?.hasContent == true || $0.doc?.isSkipped == true })
    }

    private func countsLine() -> String {
        let c = model.weekCounts()
        if c.total == 0 { return model.weekTiles().allSatisfy({ $0.status == .off || $0.status == .future }) ? "No working days to count yet." : "Nothing to count yet." }
        return "Logged \(c.logged) of \(c.total)" + (c.skipped > 0 ? " · \(c.skipped) skipped" : "") + (c.notLogged > 0 ? " · \(c.notLogged) not logged" : "")
    }

    private func header(_ w: WeekSummary) -> some View {
        VStack(alignment: .leading, spacing: Theme.s3) {
            HStack(alignment: .firstTextBaseline) {
                Text(model.weekTitle(w)).font(Theme.font(28, .semibold)).tracking(-0.4).foregroundColor(Theme.textPrimary)
                    .lineLimit(1).minimumScaleFactor(0.7).accessibilityAddTraits(.isHeader)
                Spacer()
                HStack(spacing: 4) {
                    Button { model.step(-1) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Previous week").help("Previous week (⌘[)")
                    Button("This week") { model.goThisWeek() }.disabled(model.isCurrentWeek)
                    Button { model.step(1) } label: { Image(systemName: "chevron.right") }.accessibilityLabel("Next week").help("Next week (⌘])")
                        .disabled(!model.canShowNextWeek)
                }.buttonStyle(SecondaryButtonStyle())
            }
            Text(countsLine()).font(Theme.font(13)).foregroundColor(Theme.textSecondary).monospacedDigit()
            HStack(spacing: Theme.s3) {
                Picker("Group by", selection: $model.weekGrouping) {
                    Text("Day").tag(WeekGrouping.day); Text("Section").tag(WeekGrouping.section)
                }.pickerStyle(.segmented).fixedSize().accessibilityLabel("Group by")
                Spacer()
                if model.weekHasUnlogged && !hasNothing(w) {
                    Button("Catch up this week") { model.catchUpThisWeek() }.buttonStyle(SecondaryButtonStyle())
                }
                Button { model.copyWeek() } label: {
                    Label(model.copiedFlash ? "Copied ✓" : "Copy as markdown", systemImage: model.copiedFlash ? "checkmark" : "doc.on.doc")
                }.buttonStyle(SecondaryButtonStyle()).help("Copy as markdown (⇧⌘C)")
            }
        }.padding(.bottom, Theme.s4)
    }

    /// Seven tiles, Monday (or the chosen first weekday) to Sunday. Each opens its day; days off are dimmed but still open.
    private var tiles: some View {
        HStack(spacing: Theme.weekTileGap) {
            ForEach(model.weekTiles()) { t in WeekTileView(model: model, t: t).frame(maxWidth: .infinity) }
        }
        .accessibilityElement(children: .contain).accessibilityLabel("Days of this week")
        .padding(.bottom, Theme.s6)
    }

    private var empty: some View {
        VStack(spacing: Theme.s3) {
            Text("Nothing logged this week yet.").font(Theme.font(15)).foregroundColor(Theme.textSecondary)
            HStack(spacing: Theme.s3) {
                if model.weekHasUnlogged { Button("Catch up this week") { model.catchUpThisWeek() }.buttonStyle(PrimaryButtonStyle()) }
                Button("Go to today") { model.openToday() }
                    .buttonStyle(TextButtonStyle())
            }
        }.frame(maxWidth: .infinity).padding(.vertical, Theme.s8)
    }

    @ViewBuilder private func content(_ w: WeekSummary) -> some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            if model.weekGrouping == .day {
                ForEach(w.days, id: \.day) { d in WeekDayCard(model: model, d: d) }
            } else {
                ForEach(Array(w.sections.enumerated()), id: \.offset) { _, s in WeekSectionCard(model: model, section: s) }
            }
        }
    }
}

private struct WeekTileView: View {
    @ObservedObject var model: AppModel
    let t: WeekTile

    var body: some View {
        HoverReader { hovering in
            Button { if t.opens { model.select(.day(t.day)) } } label: {
                VStack(spacing: 3) {
                    Text(t.weekday).font(Theme.font(11)).foregroundColor(Theme.textSecondary)
                    HStack(spacing: 4) {
                        Text("\(t.number)").font(Theme.font(15, .semibold)).monospacedDigit().foregroundColor(Theme.textPrimary)
                        DayMark(status: t.status, size: 8, showsMissed: !t.isToday)
                    }
                    Text(t.bottom).font(Theme.font(11, t.status == .missed ? .semibold : .regular)).lineLimit(1)
                        .foregroundColor(t.status == .missed ? Theme.accentText : Theme.textSecondary)
                        .frame(height: 14)
                }
                .frame(maxWidth: .infinity).frame(height: Theme.weekTileH)
                .background(Theme.rect(Theme.radiusLg).fill(hovering && t.opens ? Theme.hover : Theme.surface))
                .overlay(Theme.rect(Theme.radiusLg).stroke(t.isToday ? Theme.accent : Theme.border, lineWidth: t.isToday ? 1.5 : 1))
                .opacity(t.status == .off ? 0.65 : (t.opens ? 1 : 0.5))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(t.opens ? "\(model.shortDate(t.day)): \(model.statusWord(t.day))" : "Upcoming")
            .accessibilityLabel(model.spokenStatus(t.day))
            .accessibilityHint(t.opens ? "Opens this day" : "")
        }
    }
}

private struct ReviewCard<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s3, content: content)
            .padding(Theme.s4).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.rect(Theme.radiusLg).fill(Theme.surface))
            .overlay(Theme.rect(Theme.radiusLg).stroke(Theme.border, lineWidth: 1))
            .accessibilityElement(children: .contain)
    }
}

/// A page's markdown, cut at a block boundary with Show more when long (never mid-line).
struct ClampedMarkdown: View {
    let markdown: String
    let store: AssetStore
    var maxLines: Double = 9
    @StateObject private var open = Box(false)

    private func clamp(_ all: [MDBlock]) -> (shown: [MDBlock], long: Bool) {
        var used = 0.0, cut = all.count
        for (i, b) in all.enumerated() {
            used += b.estimatedLines
            if used > maxLines && i > 0 { cut = i; break }
        }
        var shown = Array(all.prefix(cut))
        while case .heading? = shown.last, cut < all.count { shown.removeLast() }       // no heading left hanging
        return (shown, cut < all.count)
    }

    var body: some View {
        let all = MDParse.blocks(markdown)
        let c = clamp(all)
        VStack(alignment: .leading, spacing: 4) {
            MarkdownBlocksView(blocks: open.value ? all : c.shown, store: store, size: 14, compact: true)
            if c.long { Button(open.value ? "Show less" : "Show more") { open.value.toggle() }.buttonStyle(TextButtonStyle()) }
        }
    }
}

/// A day's writing (or its skip), for the By day view. Days with nothing are the tiles' job, not a card.
private struct WeekDayCard: View {
    @ObservedObject var model: AppModel
    let d: WeekDay
    var body: some View {
        let skipped = d.doc?.isSkipped == true
        let hasText = (d.doc?.hasContent ?? false) && !skipped
        if !skipped && !hasText { EmptyView() }
        else {
            ReviewCard {
                HStack {
                    Text(model.shortDate(d.day)).font(Theme.font(15, .semibold)).foregroundColor(Theme.textPrimary)
                    Spacer()
                    if skipped {
                        let r = d.doc?.skipReason ?? ""
                        Text("Skipped" + (r.isEmpty ? "" : " · \(r)")).font(Theme.font(12)).foregroundColor(Theme.textSecondary)
                    } else if d.doc?.status(minWords: model.minWords) == .partial {
                        Text("\(d.doc?.words ?? 0) of \(model.minWords) words").font(Theme.font(12)).foregroundColor(Theme.textSecondary).monospacedDigit()
                    }
                    Button("Open") { model.select(.day(d.day)) }.buttonStyle(TextButtonStyle())
                        .accessibilityLabel("Open \(model.spokenDate(d.day))")
                }
                if hasText, let doc = d.doc {
                    ClampedMarkdown(markdown: MarkdownBody.pruneEmptySections(doc.body), store: model.store.assets)
                }
            }
        }
    }
}

private struct WeekSectionCard: View {
    @ObservedObject var model: AppModel
    let section: WeekSection
    var body: some View {
        ReviewCard {
            Text(cleanHeading(section.title)).font(Theme.font(15, .semibold)).foregroundColor(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            ForEach(Array(section.items.enumerated()), id: \.offset) { _, it in
                HStack(alignment: .top, spacing: Theme.s3) {
                    Text(DayKey.format(it.day, "EEE d", model.cal)).font(Theme.font(12)).monospacedDigit()
                        .foregroundColor(Theme.textSecondary).frame(width: 56, alignment: .leading)
                    ClampedMarkdown(markdown: it.text, store: model.store.assets)
                }
            }
        }
    }
}
