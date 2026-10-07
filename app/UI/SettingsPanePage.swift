// SettingsPanePage.swift - Settings > Page: the words rule, log start date, catch-up window, new-day template, carry-over headings.
import SwiftUI

struct PageSettings: View {
    @ObservedObject var model: AppModel

    private static let windowChoices = [7, 14, 30, 60, 90, 180, 365]
    private func windowLabel(_ days: Int) -> String { days == 365 ? "1 year" : "\(days) days" }
    /// The usual choices, plus the stored value when it is something else (an older save or another Mac).
    private var windowChoices: [Int] {
        var c = PageSettings.windowChoices
        if !c.contains(model.settings.catchUpWindowDays) { c.append(model.settings.catchUpWindowDays); c.sort() }
        return c
    }

    /// The day before which nothing counts as unlogged: the one set here, else the first log in the folder.
    private var effectiveStart: String? { Status.effectiveSince(setting: model.settings.logStartDate, states: model.states) }
    private var logStart: Binding<Date> {
        Binding(get: { effectiveStart.flatMap { DayKey.date($0, model.cal) } ?? model.now },
                set: { model.settings.logStartDate = DayKey.string($0, model.cal) })
    }
    private var logStartRange: ClosedRange<Date> {
        (DayKey.date("2000-01-01", model.cal) ?? .distantPast)...max(model.now, DayKey.date("2000-01-01", model.cal) ?? .distantPast)
    }
    private var logStartHelp: String {
        if model.settings.logStartDate == nil {
            let first = effectiveStart.map { " (\(DayKey.format($0, "d MMM yyyy", model.cal)))" } ?? ""
            return "Following your first log\(first). Days before it never count as unlogged and never break your streak."
        }
        return "Days before this date never count as unlogged and never break your streak. Pages you write earlier are still saved."
    }

    var body: some View {
        SettingsPaneFrame(model: model, pane: .page,
                          resetSummary: "the word count, catch-up window, log start, template and headings") {
            Section {
                SettingsRow("A day counts as logged after",
                            help: "Headings, empty list items and images don't count as words. A page with fewer words shows as partly written.") {
                    WordsStepper(minWords: $model.settings.minWords)
                }
            } header: { Text("Logging").font(Theme.font(13, .semibold)) }

            Section {
                SettingsRow("Log start date", help: logStartHelp) {
                    HStack(spacing: Theme.s2) {
                        DatePicker("Log start date", selection: logStart, in: logStartRange, displayedComponents: .date)
                            .labelsHidden().datePickerStyle(.field).fixedSize()
                        Button("Use first log") { model.settings.logStartDate = nil }.disabled(model.settings.logStartDate == nil)
                            .help("Follow the earliest page in your log folder")
                        Button("Start from today") { model.settings.logStartDate = model.today }
                            .disabled(model.settings.logStartDate == model.today)
                            .help("Ignore every day before today")
                    }
                }
                SettingsRow("Catch-up window", help: "How far back Catch up looks for days you haven't written. Older days stay reachable from the calendar.") {
                    Picker("Catch-up window", selection: $model.settings.catchUpWindowDays) {
                        ForEach(windowChoices, id: \.self) { Text(windowLabel($0)).tag($0) }
                    }.labelsHidden().fixedSize()
                }
            } header: { Text("Catching up").font(Theme.font(13, .semibold)) }

            Section {
                TemplateEditor(model: model)
            } header: { Text("New day template").font(Theme.font(13, .semibold)) }

            Section {
                CarryHeadingsEditor(model: model)
            } header: { Text("Carried over from yesterday").font(Theme.font(13, .semibold)) }
        }
    }
}
