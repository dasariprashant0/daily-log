// SkipSheet.swift - "Skip today?" with reason chips and an optional date range (scheduled days only).
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
    @StateObject private var form = SkipForm(start: Date())
    static let reasons = ["Holiday", "Leave", "Sick", "Day off", "Other…"]

    private var startDate: Date { DayKey.date(day, model.cal) ?? model.now }
    private var throughKey: String { DayKey.string(max(form.through, startDate), model.cal) }
    private var workdays: Int {
        var n = 0, d = day
        while d <= throughKey && n < 400 { if model.isWorkday(d) { n += 1 }; guard let x = DayKey.adding(d, 1, model.cal) else { break }; d = x }
        return n
    }
    private var finalReason: String { form.reason == "Other…" ? String(form.other.dlTrimmed.prefix(40)) : form.reason }
    private var isRange: Bool { form.range && throughKey > day }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.s4) {
            Text(isRange ? "Skip these days?" : (day == model.today ? "Skip today?" : "Skip this day?"))
                .font(Theme.font(22, .semibold)).foregroundColor(Theme.textPrimary).accessibilityAddTraits(.isHeader)
            Text("No reminder, no nag, and your streak stays as it is. You can undo this any time.")
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
            if model.draftDays.contains(day) {
                Text("Your draft for this day is kept, not deleted.").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
            }
            if let e = form.error { Text(e).font(Theme.font(13)).foregroundColor(Theme.danger) }
            HStack {
                Spacer()
                Button("Cancel") { model.sheet = nil }.buttonStyle(SecondaryButtonStyle()).keyboardShortcut(.cancelAction)
                Button(isRange ? "Skip \(Fmt.plural(workdays, "day"))" : "Skip day") { commit() }
                    .buttonStyle(PrimaryButtonStyle()).keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.s8).frame(width: 500).background(Theme.surface)
        .onAppear { form.through = startDate }
    }

    private func commit() {
        do {
            try model.skip(day: day, through: isRange ? throughKey : nil, reason: finalReason)
            model.sheet = nil
        } catch let e as SkipFailure { form.error = e.text } catch { form.error = error.localizedDescription }
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
