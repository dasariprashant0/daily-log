// SkipSheet.swift - "Skip today?" with reason chips and an optional date range (scheduled days only). In list mode (Catch up) it
// skips exactly the days it is given with one reason: "Skip these 3 days?".
import SwiftUI

final class SkipForm: ObservableObject {
    @Published var reason = ""
    @Published var other = ""
    @Published var range = false
    @Published var through: Date
    @Published var error: String?
    init(start: Date) { through = start }
}

struct SkipSheet: View {
    @ObservedObject var model: AppModel
    let day: String
    var days: [String]? = nil                      // list mode: the days chosen in Catch up
    @StateObject private var form = SkipForm(start: Date())
    static let reasons = ["Holiday", "Leave", "Sick", "Day off", "Other…"]

    private var listDays: [String] { days ?? [] }
    private var many: Bool { days != nil }
    private var startDate: Date { DayKey.date(day, model.cal) ?? model.now }
    private var throughKey: String { DayKey.string(max(form.through, startDate), model.cal) }
    private var workdays: Int {
        var n = 0, d = day
        while d <= throughKey && n < 400 { if model.isWorkday(d) { n += 1 }; guard let x = DayKey.adding(d, 1, model.cal) else { break }; d = x }
        return n
    }
    private var finalReason: String { form.reason == "Other…" ? String(form.other.dlTrimmed.prefix(40)) : form.reason }
    private var isRange: Bool { !many && form.range && throughKey > day }

    private var title: String {
        if many { return listDays.count == 1 ? "Skip this day?" : "Skip these \(listDays.count) days?" }
        return isRange ? "Skip these days?" : (day == model.today ? "Skip today?" : "Skip this day?")
    }
    private var which: String {
        guard many, let f = listDays.first, let l = listDays.last else { return "" }
        return listDays.count == 1 ? model.longDate(f) : "\(model.shortDate(f)) to \(model.shortDate(l))"
    }
    private var button: String {
        if many { return listDays.count == 1 ? "Skip day" : "Skip \(listDays.count) days" }
        return isRange ? "Skip \(Fmt.plural(workdays, "day"))" : "Skip day"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(Theme.font(22, .semibold)).foregroundColor(Theme.textPrimary).accessibilityAddTraits(.isHeader)
                if many { Text(which).font(Theme.font(13)).foregroundColor(Theme.textSecondary) }
            }
            Text("No reminders, and your streak stays as it is. You can undo this any time.")
                .font(Theme.font(13)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: Theme.s2) {
                Text("Reason (optional)").font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary)
                HStack(spacing: Theme.s2) {
                    ForEach(Self.reasons, id: \.self) { r in
                        let on = form.reason == r
                        Button(r) { form.reason = on ? "" : r }
                            .buttonStyle(ChipStyle(on: on))
                            .accessibilityLabel("\(r)\(on ? ", selected" : "")").accessibilityAddTraits(.isButton)
                    }
                }
                if form.reason == "Other…" {
                    TextField("Reason (up to 40 characters)", text: $form.other).textFieldStyle(.roundedBorder)
                        .onChange(of: form.other) { v in if v.count > 40 { form.other = String(v.prefix(40)) } }
                }
            }

            if !many {
                VStack(alignment: .leading, spacing: Theme.s2) {
                    Picker("", selection: $form.range) {
                        Text("Today only").tag(false)
                        Text("Through a later date").tag(true)
                    }.pickerStyle(.radioGroup).labelsHidden()
                    if form.range {
                        HStack {
                            DatePicker("Through", selection: $form.through, in: startDate..., displayedComponents: .date)
                                .datePickerStyle(.field).fixedSize()
                            Text(isRange ? "\(Fmt.plural(workdays, "workday"))" : "").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
                        }
                    }
                }
            }
            Text("A day with writing can't be skipped, so nothing you wrote is touched.").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
            if let e = form.error { Text(e).font(Theme.font(13)).foregroundColor(Theme.danger) }
            HStack {
                Spacer()
                Button("Cancel") { model.sheet = nil }.buttonStyle(SecondaryButtonStyle()).keyboardShortcut(.cancelAction)
                Button(button) { commit() }
                    .buttonStyle(PrimaryButtonStyle()).keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.s8).frame(width: 500).background(Theme.surface)
        .onAppear { form.through = startDate }
    }

    private func commit() {
        if let list = days {
            model.skipMany(list, reason: finalReason) { failure in
                if let f = failure { form.error = f.text } else { model.sheet = nil }
            }
            return
        }
        model.skip(day: day, through: isRange ? throughKey : nil, reason: finalReason) { failure in
            if let f = failure { form.error = f.text; return }
            model.sheet = nil
            model.advanceSession(after: day)              // a catch-up session goes on to the next day
        }
    }
}

struct ChipStyle: ButtonStyle {
    let on: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(Theme.font(12, on ? .semibold : .regular))
            .foregroundColor(on ? Theme.accentText : Theme.textPrimary)
            .padding(.horizontal, 10).frame(height: 26)
            .background(Capsule().fill(on ? Theme.accentTint : Theme.surface))
            .overlay(Capsule().stroke(on ? Theme.accent : Theme.borderStrong, lineWidth: 1))
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}
