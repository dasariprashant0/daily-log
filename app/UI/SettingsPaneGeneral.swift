// SettingsPaneGeneral.swift - Settings > General: appearance, week start, open at login, menu-bar item.
import SwiftUI

struct GeneralSettings: View {
    @ObservedObject var model: AppModel

    /// 0 = follow the system, else a Calendar weekday (1 = Sunday).
    private var weekStart: Binding<Int> {
        Binding(get: { model.settings.weekStart ?? 0 }, set: { model.settings.weekStart = $0 == 0 ? nil : $0 })
    }
    private var systemWeekStart: String {
        let c = Calendar.current
        return c.weekdaySymbols[(c.firstWeekday - 1) % 7]
    }

    var body: some View {
        SettingsPaneFrame(model: model, pane: .general, resetSummary: "appearance, week start and the menu bar item") {
            Section {
                SettingsRow("Appearance", help: "System follows your Mac's light or dark setting.") {
                    Picker("Appearance", selection: $model.settings.appearance) {
                        Text("System").tag(AppAppearance.system)
                        Text("Light").tag(AppAppearance.light)
                        Text("Dark").tag(AppAppearance.dark)
                    }.pickerStyle(.segmented).labelsHidden().fixedSize()
                }
                SettingsRow("Week starts on", help: "Used by the calendar and the week review. System follows your Mac, which starts the week on \(systemWeekStart).") {
                    Picker("Week starts on", selection: weekStart) {
                        Text("System").tag(0)
                        Text("Monday").tag(2)
                        Text("Sunday").tag(1)
                        Text("Saturday").tag(7)
                    }.labelsHidden().fixedSize()
                }
            } header: { Text("Display").font(Theme.font(13, .semibold)) }

            Section {
                SettingsRow("Open Gloamlog at login", help: "Starts Gloamlog hidden, so your reminder still works after a restart.") {
                    Toggle("Open Gloamlog at login", isOn: Binding(get: { model.loginEnabled }, set: { model.setLogin($0) }))
                        .labelsHidden().toggleStyle(.switch)
                }
                if let m = model.loginMessage {
                    SettingsStatus(symbol: "exclamationmark.triangle", tint: Theme.warning, m) {
                        if m.hasPrefix("Approve") { Button("Open Login Items") { model.openLoginItems() } }
                    }
                }
                SettingsRow("Show in the menu bar", help: "The menu bar item shows today's status and opens Settings. Reminders work without it.") {
                    Toggle("Show in the menu bar", isOn: Binding(get: { model.showMenuBarItem }, set: { model.showMenuBarItem = $0 }))
                        .labelsHidden().toggleStyle(.switch)
                }
            } header: { Text("Startup").font(Theme.font(13, .semibold)) }
        }
    }
}
