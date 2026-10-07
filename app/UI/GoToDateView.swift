// GoToDateView.swift - "Go to date" (⇧⌘T): a field that reads "last fri", "2 oct", "-3", "2026-10-02", with the same calendar
// below it, so any day is one popover away. Parsing is DateJump (Core); nothing here touches the disk.
import SwiftUI

final class GoToState: ObservableObject {
    @Published var text = ""
    @Published var failure: GoToOutcome?          // set when Return found nothing to open; cleared by the next keystroke
    @Published var month: YearMonth
    init(month: YearMonth) { self.month = month }
}

/// The toolbar's date button: "Fri 9 Oct v" on a day page, "Go to date" elsewhere. Opens the popover.
struct GoToDateButton: View {
    @ObservedObject var model: AppModel

    private var title: String {
        guard case .day(let d) = model.selection else { return "Go to date" }
        let sameYear = d.prefix(4) == model.today.prefix(4)
        return DayKey.format(d, sameYear ? "EEE d MMM" : "EEE d MMM yyyy", model.cal)
    }

    var body: some View {
        Button { model.goToDateOpen.toggle() } label: {
            HStack(spacing: 5) {
                Text(title).font(Theme.font(13, .medium)).monospacedDigit()
                Image(systemName: "chevron.down").font(Theme.font(9, .semibold))
            }
        }
        .help("Go to date (⇧⌘T)")
        .accessibilityLabel("Go to date")
        .accessibilityValue(title)
        .popover(isPresented: $model.goToDateOpen, arrowEdge: .bottom) { GoToDateView(model: model) }
    }
}

struct GoToDateView: View {
    @ObservedObject var model: AppModel
    @StateObject private var st: GoToState
    @FocusState private var focused: Bool

    init(model: AppModel) {
        self.model = model
        _st = StateObject(wrappedValue: GoToState(month: model.openDayKey.map { YearMonth(day: $0) } ?? model.thisMonth))
    }

    private func submit() {
        guard !st.text.dlTrimmed.isEmpty else { return }
        let r = model.goToDate(st.text)
        if case .opened = r { model.goToDateOpen = false } else { st.failure = r }
    }
    private func pick(_ day: String) { model.select(.day(day)); model.goToDateOpen = false }

    var body: some View {
        let resolved = model.resolvedDate(st.text)
        VStack(alignment: .leading, spacing: Theme.s2) {
            HStack(spacing: 6) {
                Image(systemName: "calendar").font(Theme.font(12)).foregroundColor(Theme.textSecondary).accessibilityHidden(true)
                TextField("Go to date", text: $st.text, prompt: Text("last fri, 2 oct, -3"))
                    .textFieldStyle(.plain).font(Theme.font(13)).focused($focused)
                    .onSubmit { submit() }
                    .onChange(of: st.text) { _ in st.failure = nil }
                    .accessibilityLabel("Go to date")
            }
            .padding(.horizontal, Theme.s2).frame(height: 28)
            .background(Theme.rect().fill(Theme.surface))
            .overlay(Theme.rect().stroke(focused ? Theme.accent : Theme.border, lineWidth: focused ? 1.5 : 1))

            feedback(resolved).frame(height: 16, alignment: .leading)

            HStack(spacing: 0) {
                MonthTitleButton(model: model, month: st.month) { st.month = $0 }
                Spacer(minLength: 4)
                step("chevron.left", "Previous month", enabled: model.canShift(st.month, by: -1)) { st.month = st.month.adding(months: -1) }
                step("chevron.right", "Next month", enabled: model.canShift(st.month, by: 1)) { st.month = st.month.adding(months: 1) }
            }.frame(height: 28)
            CalendarGrid(model: model, month: st.month, cellW: Theme.popCellW, cellH: Theme.popCellH,
                         selected: resolved ?? model.openDayKey) { pick($0) }

            HStack {
                Button("Today") { model.openToday(); model.goToDateOpen = false }.buttonStyle(SecondaryButtonStyle())
                    .disabled(model.openDayKey == model.today)
                Spacer()
                Button("Open") { submit() }.buttonStyle(PrimaryButtonStyle()).disabled(resolved == nil)
            }.padding(.top, Theme.s1)
        }
        .padding(Theme.s3).frame(width: 280)
        .onAppear { DispatchQueue.main.async { focused = true } }
        .onChange(of: resolved) { d in if let d = d { st.month = YearMonth(day: d) } }
    }

    @ViewBuilder private func feedback(_ resolved: String?) -> some View {
        if let f = st.failure {
            Text(f == .future ? "That day hasn't happened yet." : "Couldn't read that date. Try 2 Oct, last friday or 2026-10-02.")
                .font(Theme.font(12)).foregroundColor(Theme.danger).lineLimit(1).minimumScaleFactor(0.85)
                .accessibilityAddTraits(.updatesFrequently)
        } else if let d = resolved {
            Text(DayKey.format(d, "EEE d MMM yyyy", model.cal)).font(Theme.font(12, .semibold)).foregroundColor(Theme.accentText).monospacedDigit()
        } else {
            Text("Try last fri, 2 oct, -3 or 2026-10-02.").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
        }
    }

    private func step(_ symbol: String, _ label: String, enabled: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(Theme.font(11, .semibold)).foregroundColor(enabled ? Theme.textSecondary : Theme.textTertiary)
                .frame(width: 24, height: 24).contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(!enabled).help(label).accessibilityLabel(label)
    }
}
