// SettingsView.swift - Settings scene: General | Page | Storage. Changes apply immediately (no Save button).
import SwiftUI

struct SettingsView: View {
    @ObservedObject var model: AppModel
    var body: some View {
        TabView {
            GeneralSettings(model: model).tabItem { Label("General", systemImage: "gearshape") }
            PageSettings(model: model).tabItem { Label("Page", systemImage: "doc.text") }
            StorageSettings(model: model).tabItem { Label("Storage", systemImage: "folder") }
        }
        .frame(width: 520).padding(.vertical, Theme.s2)
    }
}

struct WeekdayToggles: View {
    @Binding var days: Set<Int>
    let cal: Calendar
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { i in
                let wd = (cal.firstWeekday - 1 + i) % 7 + 1
                let on = days.contains(wd)
                let full = cal.weekdaySymbols[wd - 1]
                Toggle(String(cal.veryShortWeekdaySymbols[wd - 1]), isOn: Binding(
                    get: { on },
                    set: { v in if v { days.insert(wd) } else if days.count > 1 { days.remove(wd) } }))
                    .toggleStyle(.button).frame(minWidth: 30)
                    .disabled(on && days.count == 1)
                    .accessibilityLabel(full).accessibilityValue(on ? "on" : "off")
                    .help(on && days.count == 1 ? "Keep at least one day." : full)
            }
        }
    }
}

struct GeneralSettings: View {
    @ObservedObject var model: AppModel
    @AppStorage("showMenuBar") private var showMenuBar = true

    private var timeBinding: Binding<Date> {
        Binding(get: { model.cal.date(bySettingHour: model.settings.reminderMinutes / 60, minute: model.settings.reminderMinutes % 60, second: 0, of: model.now) ?? model.now },
                set: { d in let c = model.cal.dateComponents([.hour, .minute], from: d); model.settings.reminderMinutes = (c.hour ?? 16) * 60 + (c.minute ?? 55) })
    }

    var body: some View {
        Form {
            Section {
                DatePicker("Remind me at", selection: timeBinding, displayedComponents: .hourAndMinute)
                LabeledContent("On these days") { WeekdayToggles(days: $model.settings.weekdays, cal: model.cal) }
                Text("Keep at least one day.").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
            }
            Section("When the reminder fires") {
                ModeRow(mode: .strict, title: "Strict", detail: "Brings Gloamlog to the front and keeps re-opening it every 5 minutes until you save or skip the day.", current: $model.settings.mode)
                ModeRow(mode: .gentle, title: "Gentle", detail: "Sends one notification. Nothing else.", current: $model.settings.mode)
                Picker("Snooze for", selection: $model.settings.snoozeMinutes) {
                    ForEach(Settings.snoozeChoices, id: \.self) { Text("\($0) minutes").tag($0) }
                }.fixedSize()
                Text("Strict allows 2 snoozes a day. Gentle allows any number.").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
            }
            Section {
                Toggle("Open Gloamlog at login", isOn: Binding(get: { model.loginEnabled }, set: { model.setLogin($0) }))
                Text("Needed for reminders after a restart. Off until you turn it on.").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
                if let m = model.loginMessage {
                    HStack {
                        Text(m).font(Theme.font(12)).foregroundColor(Theme.warning).fixedSize(horizontal: false, vertical: true)
                        if m.hasPrefix("Approve") { Button("Open Login Items") { model.openLoginItems() } }
                    }
                }
                Toggle("Show in menu bar", isOn: $showMenuBar)
                HStack {
                    Text(model.notifState == .denied ? "Notifications are off for Gloamlog." : model.notifState == .allowed ? "Notifications: On" : "Notifications: not requested yet")
                    Spacer()
                    if model.notifState == .denied { Button("Open System Settings") { model.openNotificationSettings() } }
                    else if model.notifState == .unknown { Button("Allow") { Notifier.shared.requestAuthorization { _ in Notifier.shared.refreshState { s in model.notifState = s } } } }
                }
                if model.notifState == .denied {
                    Text("Gentle needs them. Strict still opens the window.").font(Theme.font(12)).foregroundColor(Theme.textSecondary)
                }
            }
        }
        .formStyle(.grouped).onAppear { Notifier.shared.refreshState { s in model.notifState = s } }
    }
}

struct StorageSettings: View {
    @ObservedObject var model: AppModel
    var body: some View {
        Form {
            Section("Logs are saved in") {
                Text(model.folderDisplay).font(.system(size: 12, design: .monospaced)).foregroundColor(Theme.textPrimary)
                    .textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                HStack {
                    Button("Choose folder…") { model.chooseFolder() }
                    Button("Show in Finder") { model.revealFolder() }
                    Button("Use default") { model.useDefaultFolder() }
                        .disabled(model.settings.storageFolder.standardizedFileURL.path == Settings.defaultFolder.standardizedFileURL.path)
                }
                if let s = model.storageSummary {
                    Text("\(Fmt.plural(s.logs, "log")) · \(s.skipped) skipped\(s.skipped == 1 ? " day" : " days")" + (s.unrecognized > 0 ? " · \(Fmt.plural(s.unrecognized, "file")) not recognised" : ""))
                        .font(Theme.font(12)).foregroundColor(Theme.textSecondary).monospacedDigit()
                }
                if let r = model.storageResult {
                    HStack {
                        Text(r.text).font(Theme.font(12)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
                        if !r.conflicts.isEmpty { Button("Show them") { model.reveal(r.conflicts) } }
                    }
                }
                if let p = model.folderProblem {
                    Text(p == .missing(p.path) ? "This folder can't be found." : "Gloamlog can't write to this folder.")
                        .font(Theme.font(12)).foregroundColor(Theme.danger)
                }
            }
            Section {
                Text("Tip: pick a folder in iCloud Drive or Dropbox to keep your logs on every Mac.")
                    .font(Theme.font(12)).foregroundColor(Theme.textSecondary)
            }
        }
        .formStyle(.grouped).onAppear { model.refreshSummary() }
    }
}

struct ModeRow: View {
    let mode: ReminderMode, title: String, detail: String
    @Binding var current: ReminderMode
    var body: some View {
        let on = current == mode
        Button { current = mode } label: {
            HStack(alignment: .top, spacing: Theme.s3) {
                Image(systemName: on ? "largecircle.fill.circle" : "circle").foregroundColor(on ? Theme.accent : Theme.textSecondary).padding(.top, 1)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.font(13, .semibold)).foregroundColor(Theme.textPrimary)
                    Text(detail).font(Theme.font(12)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }.contentShape(Rectangle())
        }
        .buttonStyle(.plain).accessibilityLabel("\(title). \(detail)").accessibilityAddTraits(on ? .isSelected : [])
    }
}
