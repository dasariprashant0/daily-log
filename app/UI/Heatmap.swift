// Heatmap.swift - 12-week activity grid (sidebar footer) and the last-7-days strip (menu bar popover).
// States differ by shape, not hue: filled square (logged), dash (skipped), bordered empty (missed),
// faint dot (non-workday), ring (today), blank (future).
import SwiftUI

struct HeatCellView: View {
    let cell: HeatCell
    let size: CGFloat
    var body: some View {
        ZStack {
            switch cell.status {
            case .logged: Theme.rect(3).fill(Theme.heat[4])
            case .partial: Theme.rect(3).fill(Theme.heat[2])
            case .skipped:
                Theme.rect(3).fill(Theme.heat[0])
                Rectangle().fill(Theme.textTertiary).frame(width: size * 0.5, height: 1.5)
            case .missed: Theme.rect(3).stroke(Theme.borderStrong, lineWidth: 1)
            case .off: Circle().fill(Theme.borderStrong.opacity(0.7)).frame(width: 3, height: 3)
            case .future: Color.clear
            }
            if cell.isToday { Theme.rect(3).stroke(Theme.accent, lineWidth: 1.5).padding(-1.5) }
        }
        .frame(width: size, height: size)
    }
}

enum HeatText {
    static func word(_ s: DayStatus) -> String {
        switch s { case .logged: return "logged"; case .partial: return "partly logged"; case .skipped: return "skipped"
        case .missed: return "not logged"; case .off: return "not a workday"; case .future: return "upcoming" }
    }
    static func summary(_ weeks: [[HeatCell]]) -> String {
        let all = weeks.flatMap { $0 }
        let l = all.filter { $0.status == .logged }.count, s = all.filter { $0.status == .skipped }.count
        let m = all.filter { $0.status == .missed && !$0.isToday }.count
        return "Activity, last 12 weeks: \(l) logged, \(s) skipped, \(m) missed"
    }
}

struct HeatmapView: View {
    @ObservedObject var model: AppModel
    var cell: CGFloat = 11, gap: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s2) {
            HStack(alignment: .top, spacing: gap) {
                ForEach(Array(model.heat.enumerated()), id: \.offset) { _, col in
                    VStack(spacing: gap) {
                        ForEach(col, id: \.day) { c in
                            Button { if c.status != .future { model.select(.day(c.day)) } } label: {
                                HeatCellView(cell: c, size: cell).padding(1).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .help("\(model.shortDate(c.day)): \(HeatText.word(c.status))")
                            .accessibilityLabel("\(model.spokenDate(c.day)), \(HeatText.word(c.status))")
                        }
                    }
                }
            }
            if model.states.isEmpty {
                Text("Your first weeks fill in as you log.").font(Theme.font(11)).foregroundColor(Theme.textSecondary)
            } else {
                HeatLegend()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(HeatText.summary(model.heat))
    }
}

struct HeatLegend: View {
    var body: some View {
        HStack(spacing: 6) {
            item(AnyView(Theme.rect(2).fill(Theme.heat[4]).frame(width: 9, height: 9)), "logged")
            item(AnyView(ZStack { Theme.rect(2).fill(Theme.heat[0]); Rectangle().fill(Theme.textTertiary).frame(width: 5, height: 1.5) }.frame(width: 9, height: 9)), "skipped")
            item(AnyView(Theme.rect(2).stroke(Theme.borderStrong, lineWidth: 1).frame(width: 9, height: 9)), "missed")
        }
        .accessibilityHidden(true)
    }
    private func item(_ v: AnyView, _ t: String) -> some View {
        HStack(spacing: 3) { v; Text(t).font(Theme.font(11)).foregroundColor(Theme.textSecondary) }
    }
}

/// Last 7 days (ending today) for the menu bar popover.
struct WeekStrip: View {
    @ObservedObject var model: AppModel
    var body: some View {
        let cells = Array(model.heat.flatMap { $0 }.filter { $0.status != .future || $0.isToday }.suffix(7))
        HStack(spacing: 6) {
            ForEach(cells, id: \.day) { c in
                VStack(spacing: 3) {
                    Text(DayKey.format(c.day, "EEEEE", model.cal)).font(Theme.font(10)).foregroundColor(Theme.textSecondary)
                    HeatCellView(cell: c, size: 16)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(model.spokenDate(c.day)), \(HeatText.word(c.status))")
            }
        }
    }
}
