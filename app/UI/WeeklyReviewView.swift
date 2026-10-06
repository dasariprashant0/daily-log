// WeeklyReviewView.swift - read-only week summary built from saved files, with "Copy as markdown".
import SwiftUI

struct WeeklyReviewView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        ScrollView {
            Column {
                if let w = model.week {
                    header(w)
                    if w.loggedCount == 0 && w.skippedCount == 0 { empty } else { content(w) }
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
            if model.weekGrouping == .day { ForEach(w.days, id: \.day) { d in DayBlock(model: model, d: d, sections: w.sections) } }
            else { ForEach(w.sections) { s in SectionBlock(model: model, week: w, s: s) } }
        }
    }
}

private struct DayBlock: View {
    @ObservedObject var model: AppModel
    let d: WeekDay
    let sections: [SectionDef]
    var body: some View {
        if d.status == .future || (d.entry == nil && d.status == .off) { EmptyView() } else {
            VStack(alignment: .leading, spacing: Theme.s3) {
                HStack {
                    Text(model.shortDate(d.day)).font(Theme.font(15, .semibold)).foregroundColor(Theme.textPrimary)
                    Spacer()
                    if d.status == .skipped {
                        Text("Skipped" + ((d.entry?.skipReason ?? "").isEmpty ? "" : " · \(d.entry?.skipReason ?? "")")).font(Theme.font(12)).foregroundColor(Theme.textSecondary)
                    } else if d.entry == nil { Text("Not logged yet").font(Theme.font(12)).foregroundColor(Theme.textSecondary) }
                    Button("Open") { model.select(.day(d.day)) }.buttonStyle(TextButtonStyle()).accessibilityLabel("Open \(model.spokenDate(d.day))")
                }
                if d.status != .skipped, let e = d.entry {
                    ForEach(sections) { s in
                        if let t = e.texts[s.id], !t.dlTrimmed.isEmpty {
                            HStack(alignment: .top, spacing: Theme.s3) {
                                Text(s.displayTitle).font(Theme.font(12, .semibold)).foregroundColor(Theme.textSecondary).frame(width: 112, alignment: .leading)
                                ClampedText(text: t, lines: 4, font: Theme.font(14), color: Theme.textPrimary)
                            }
                        }
                    }
                }
            }
            .padding(Theme.s4).frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.rect(Theme.radiusLg).fill(Theme.surface))
            .overlay(Theme.rect(Theme.radiusLg).stroke(Theme.border, lineWidth: 1))
            .accessibilityElement(children: .contain)
        }
    }
}

private struct SectionBlock: View {
    @ObservedObject var model: AppModel
    let week: WeekSummary
    let s: SectionDef
    var body: some View {
        let items = week.items(forSection: s.id)
        VStack(alignment: .leading, spacing: Theme.s3) {
            Text(s.displayTitle).font(Theme.font(15, .semibold)).foregroundColor(Theme.textPrimary)
            if items.isEmpty { Text("Nothing this week.").font(Theme.font(13)).foregroundColor(Theme.textSecondary) }
            ForEach(items, id: \.day) { it in
                HStack(alignment: .top, spacing: Theme.s3) {
                    Text(DayKey.format(it.day, "EEE d", model.cal)).font(Theme.font(12)).monospacedDigit()
                        .foregroundColor(Theme.textSecondary).frame(width: 56, alignment: .leading)
                    ClampedText(text: it.text, lines: 4, font: Theme.font(14), color: Theme.textPrimary)
                }
            }
        }
        .padding(Theme.s4).frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.rect(Theme.radiusLg).fill(Theme.surface))
        .overlay(Theme.rect(Theme.radiusLg).stroke(Theme.border, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }
}
