// WeeklyReviewView.swift - read-only week summary built from saved pages, with "Copy as markdown".
import SwiftUI

struct WeeklyReviewView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            Column {
                if let w = model.week {
                    header(w)
                    if w.loggedCount == 0 && w.skippedCount == 0 && !w.days.contains(where: { $0.doc?.hasContent == true }) { empty }
                    else { content(w) }
                }
            }
        }
        .background(Theme.bg)
        .onAppear { model.refreshWeek() }
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
            Text("Logged \(w.loggedCount) of \(w.workdayCount)" + (w.skippedCount > 0 ? " · \(w.skippedCount) skipped" : "") + " · streak \(model.streak.current)")
                .font(Theme.font(13)).foregroundColor(Theme.textSecondary).monospacedDigit()
            HStack {
                Picker("Group by", selection: $model.weekGrouping) {
                    Text("Day").tag(WeekGrouping.day); Text("Section").tag(WeekGrouping.section)
                }.pickerStyle(.segmented).fixedSize().accessibilityLabel("Group by")
                Spacer()
                Button { model.copyWeek() } label: {
                    Label(model.copiedFlash ? "Copied ✓" : "Copy as markdown", systemImage: model.copiedFlash ? "checkmark" : "doc.on.doc")
                }.buttonStyle(SecondaryButtonStyle()).help("Copy as markdown (⇧⌘C)")
            }
            Rectangle().fill(Theme.border).frame(height: 1).padding(.top, Theme.s2)
        }.padding(.bottom, Theme.s6)
    }

    private var empty: some View {
        VStack(spacing: Theme.s3) {
            Text("Nothing logged this week yet.").font(Theme.font(15)).foregroundColor(Theme.textSecondary)
            Button("Go to today") { model.openToday() }.buttonStyle(TextButtonStyle())
        }.frame(maxWidth: .infinity).padding(.vertical, Theme.s12)
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

private struct WeekDayCard: View {
    @ObservedObject var model: AppModel
    let d: WeekDay
    var body: some View {
        let hasText = (d.doc?.hasContent ?? false) && d.status != .skipped
        if d.status == .future || (!hasText && d.status != .skipped && d.status != .missed) { EmptyView() }
        else if d.status == .missed && !model.isWorkday(d.day) { EmptyView() }
        else {
            ReviewCard {
                HStack {
                    Text(model.shortDate(d.day)).font(Theme.font(15, .semibold)).foregroundColor(Theme.textPrimary)
                    Spacer()
                    if d.status == .skipped {
                        let r = d.doc?.skipReason ?? ""
                        Text("Skipped" + (r.isEmpty ? "" : " · \(r)")).font(Theme.font(12)).foregroundColor(Theme.textSecondary)
                    } else if !hasText {
                        Text("Not logged yet").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
                    } else if d.status == .partial {
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
