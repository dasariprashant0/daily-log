// CalendarView.swift - the month calendar of the sidebar and of the Go to date popover (DESIGN_V4 section 3).
// Every day up to today is a button that opens that day, with or without a page. Marks use the one vocabulary
// (DayMark): disc logged, half disc started, amber ring not logged, dash skipped. Data comes from MonthGrid (Core).
import SwiftUI

private let monthNames = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

/// Single-letter weekday labels (English, like every other date in the app), starting at the calendar's first weekday.
private func weekdayLetters(_ cal: Calendar) -> [String] {
    let l = ["S", "M", "T", "W", "T", "F", "S"]
    let s = min(6, max(0, cal.firstWeekday - 1))
    return Array(l[s...] + l[..<s])
}

extension AppModel {
    func monthTitle(_ m: YearMonth) -> String { DayKey.format(m.firstDay, "MMMM yyyy", cal) }
    /// The page that is open, which the calendar fills in.
    var openDayKey: String? { if case .day(let k) = selection { return k }; return session?.current }
}

// MARK: - grid

struct CalendarGrid: View {
    @ObservedObject var model: AppModel
    let month: YearMonth
    let cellW: CGFloat
    let cellH: CGFloat
    var weekOf: String?                 // the one-week strip: only the row that holds this day
    var selected: String?
    var onPick: (String) -> Void

    var body: some View {
        let rows = model.monthGrid(year: month.year, month: month.month)
        let shown: [[MonthCell]] = {
            if let w = weekOf, let r = rows.first(where: { $0.contains { $0.day == w } }) { return [r] }
            return rows
        }()
        VStack(spacing: Theme.calGap) {
            HStack(spacing: 0) {
                ForEach(Array(weekdayLetters(model.cal).enumerated()), id: \.offset) { _, l in
                    Text(l).font(Theme.font(11)).foregroundColor(Theme.textSecondary).frame(width: cellW, height: 16)
                }
            }
            .accessibilityHidden(true)
            ForEach(Array(shown.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 0) {
                    ForEach(row, id: \.day) { c in
                        CalendarCell(model: model, cell: c, w: cellW, h: cellH, selected: c.day == selected, onPick: onPick)
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Calendar, \(model.monthTitle(month))")
    }
}

private struct CalendarCell: View {
    @ObservedObject var model: AppModel
    let cell: MonthCell
    let w: CGFloat, h: CGFloat
    let selected: Bool
    let onPick: (String) -> Void

    private var future: Bool { cell.status == .future }
    private var number: Color {
        if selected { return Theme.onAccent }
        switch cell.status {
        case .future: return Theme.textTertiary
        case .off: return Theme.textSecondary
        default: return Theme.textPrimary
        }
    }

    var body: some View {
        if future {
            face(hovering: false).help("Upcoming").accessibilityElement(children: .ignore).accessibilityLabel(model.spokenStatus(cell.day))
        } else {
            HoverReader { hovering in
                Button { onPick(cell.day) } label: { face(hovering: hovering) }
                    .buttonStyle(.plain)
                    .help("\(model.shortDate(cell.day)): \(model.statusWord(cell.day))")
                    .accessibilityLabel(model.spokenStatus(cell.day))
                    .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
    }

    private func face(hovering: Bool) -> some View {
        VStack(spacing: 0) {
            Text("\(Int(cell.day.suffix(2)) ?? 0)")
                .font(Theme.font(12, cell.isToday || selected ? .semibold : .regular)).monospacedDigit()
                .foregroundColor(number).frame(height: 15)
            // Days outside the shown month are context only: no amber rings there.
            DayMark(status: cell.status, onFill: selected, showsMissed: !cell.isToday && cell.inMonth)
        }
        .padding(.top, 3).frame(width: w, height: h, alignment: .top)
        .background(Theme.rect().fill(selected ? Theme.accent : (hovering ? Theme.hover : Color.clear)).padding(1))
        .overlay { if cell.isToday && !selected { Theme.rect().stroke(Theme.accent, lineWidth: 1.5).padding(1) } }
        .opacity(cell.inMonth ? 1 : 0.55)
        .contentShape(Rectangle())
    }
}

// MARK: - month title and picker

/// "October 2026 v": opens a 4 x 3 month picker with a year stepper.
struct MonthTitleButton: View {
    @ObservedObject var model: AppModel
    let month: YearMonth
    let onPick: (YearMonth) -> Void
    @StateObject private var open = Box(false)

    var body: some View {
        Button { open.value.toggle() } label: {
            HStack(spacing: 4) {
                Text(model.monthTitle(month)).font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary)
                Image(systemName: "chevron.down").font(Theme.font(9, .semibold)).foregroundColor(Theme.textSecondary)
            }
            .frame(height: 24).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Choose a month")
        .accessibilityLabel("\(model.monthTitle(month)), choose a month")
        .popover(isPresented: Binding(get: { open.value }, set: { open.value = $0 }), arrowEdge: .bottom) {
            MonthPicker(model: model, current: month) { m in open.value = false; onPick(m) }
        }
    }
}

struct MonthPicker: View {
    @ObservedObject var model: AppModel
    let current: YearMonth
    let onPick: (YearMonth) -> Void
    @StateObject private var year: Box<Int>

    init(model: AppModel, current: YearMonth, onPick: @escaping (YearMonth) -> Void) {
        self.model = model; self.current = current; self.onPick = onPick
        _year = StateObject(wrappedValue: Box(current.year))
    }

    var body: some View {
        let first = YearMonth(day: AppModel.earliestDay), last = model.thisMonth
        VStack(spacing: Theme.s2) {
            HStack {
                arrow("chevron.left", "Previous year", enabled: year.value > first.year) { year.value -= 1 }
                Spacer()
                Text(String(year.value)).font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary).monospacedDigit()
                Spacer()
                arrow("chevron.right", "Next year", enabled: year.value < last.year) { year.value += 1 }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(52), spacing: 4), count: 4), spacing: 4) {
                ForEach(1...12, id: \.self) { m in
                    let ym = YearMonth(year: year.value, month: m)
                    let ok = !(ym < first) && !(last < ym)
                    Button { onPick(ym) } label: {
                        Text(monthNames[m - 1]).font(Theme.font(13, ym == current ? .semibold : .regular))
                            .foregroundColor(ok ? (ym == current ? Theme.accentText : Theme.textPrimary) : Theme.textTertiary)
                            .frame(width: 52, height: 32)
                            .background(Theme.rect().fill(ym == current ? Theme.accentTint : Color.clear))
                    }
                    .buttonStyle(.plain).disabled(!ok)
                    .accessibilityLabel("\(monthNames[m - 1]) \(year.value)")
                }
            }
        }
        .padding(Theme.s3).frame(width: 232)
    }

    private func arrow(_ symbol: String, _ label: String, enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(Theme.font(11, .semibold)).foregroundColor(enabled ? Theme.textSecondary : Theme.textTertiary)
                .frame(width: 24, height: 24).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(!enabled).accessibilityLabel(label)
    }
}

// MARK: - the sidebar's calendar

/// Month grid, 242 high; in a short window the one-week strip, 82 high (a day is still two clicks away: Go to date).
struct SidebarCalendar: View {
    @ObservedObject var model: AppModel
    let compact: Bool

    var body: some View {
        let month = compact ? YearMonth(day: model.stripDay) : model.shownMonth
        GeometryReader { geo in
            let cw = min(Theme.calMax, max(Theme.calMin, floor(geo.size.width / 7)))
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    MonthTitleButton(model: model, month: month) { m in
                        if compact { model.stripDay = m == model.thisMonth ? model.today : m.firstDay } else { model.shownMonth = m }
                    }
                    Spacer(minLength: 4)
                    step("chevron.left", compact ? "Previous week" : "Previous month", enabled: compact ? model.canShiftStrip(-1) : model.canShift(month, by: -1)) {
                        compact ? model.shiftStrip(-1) : model.shiftMonth(-1)
                    }
                    step("chevron.right", compact ? "Next week" : "Next month", enabled: compact ? model.canShiftStrip(1) : model.canShift(month, by: 1)) {
                        compact ? model.shiftStrip(1) : model.shiftMonth(1)
                    }
                }
                .frame(height: 28)
                CalendarGrid(model: model, month: month, cellW: cw, cellH: Theme.calH, weekOf: compact ? model.stripDay : nil,
                             selected: model.openDayKey) { model.select(.day($0)) }
                Spacer(minLength: 0)
            }
            .frame(width: cw * 7, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .frame(height: compact ? 82 : 242)
    }

    private func step(_ symbol: String, _ label: String, enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(Theme.font(11, .semibold)).foregroundColor(enabled ? Theme.textSecondary : Theme.textTertiary)
                .frame(width: 24, height: 24).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(!enabled).help(label).accessibilityLabel(label)
    }
}
