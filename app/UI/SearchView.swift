// SearchView.swift - results for the sidebar search (saved files only, drafts excluded).
import SwiftUI

struct SearchView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        let q = model.searchText.dlTrimmed
        let grouped = Dictionary(grouping: Array(model.searchHits.enumerated()), by: { $0.element.day })
        let days = grouped.keys.sorted(by: >)
        ScrollViewReader { proxy in
            ScrollView {
                Column {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Search: \"\(q)\"").font(Theme.font(28, .semibold)).tracking(-0.4).foregroundColor(Theme.textPrimary)
                            .lineLimit(1).accessibilityAddTraits(.isHeader)
                        Spacer()
                        Text(model.searchHits.isEmpty ? "" : "\(Fmt.plural(model.searchHits.count, "match")) in \(Fmt.plural(model.searchDayCount, "day"))")
                            .font(Theme.font(13)).foregroundColor(Theme.textSecondary).monospacedDigit()
                    }
                    HStack {
                        Picker("Section", selection: $model.searchSection) {
                            Text("All sections").tag(String?.none)
                            ForEach(model.settings.sections) { s in Text(s.displayTitle).tag(String?.some(s.id)) }
                        }.fixedSize()
                        Spacer()
                    }.padding(.top, Theme.s2)
                    Rectangle().fill(Theme.border).frame(height: 1).padding(.vertical, Theme.s4)
                    if model.searchHits.isEmpty {
                        VStack(alignment: .leading, spacing: Theme.s2) {
                            Text("No matches for \"\(q)\". Try a shorter word.").font(Theme.font(13)).foregroundColor(Theme.textSecondary)
                            Button("Clear search") { model.clearSearch() }.buttonStyle(TextButtonStyle())
                        }
                    } else {
                        VStack(alignment: .leading, spacing: Theme.s4) {
                            ForEach(days, id: \.self) { d in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(model.longDate(d)).font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary).padding(.leading, 10)
                                    ForEach(grouped[d] ?? [], id: \.offset) { idx, hit in
                                        HitRow(model: model, hit: hit, selected: idx == model.searchCursor).id(idx)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .onChange(of: model.searchCursor) { i in withAnimation { proxy.scrollTo(i, anchor: .center) } }
        }
        .background(Theme.bg)
        .background(Button("") { if model.searchHits.indices.contains(model.searchCursor) { model.open(hit: model.searchHits[model.searchCursor]) } }
            .keyboardShortcut(.return, modifiers: []).opacity(0).accessibilityHidden(true))
    }
}

private struct HitRow: View {
    @ObservedObject var model: AppModel
    let hit: SearchHit
    let selected: Bool

    private var snippet: AttributedString {
        var a = AttributedString(hit.snippet)
        if let r = hit.matchRange, let rr = Range(r, in: a) {
            a[rr].backgroundColor = Theme.accentTint
            a[rr].foregroundColor = Theme.textPrimary
            a[rr].font = Theme.font(13, .semibold)
        }
        return a
    }

    var body: some View {
        HoverReader { hovering in
            Button { model.open(hit: hit) } label: {
                HStack(alignment: .firstTextBaseline, spacing: Theme.s3) {
                    Text(displayTitle(of: hit.sectionTitle)).font(Theme.font(12, .semibold)).foregroundColor(Theme.textSecondary)
                        .frame(width: 120, alignment: .leading).lineLimit(1)
                    Text(snippet).font(Theme.font(13)).foregroundColor(Theme.textSecondary).lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 10).padding(.vertical, Theme.s2)
                .background(Theme.rect().fill(selected ? Theme.accentTint : (hovering ? Theme.hover : Color.clear)))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(model.spokenDate(hit.day)), \(displayTitle(of: hit.sectionTitle)), \(hit.snippet)")
        }
    }
}
