// MenuBarView.swift - MenuBarExtra popover (.window style): state, next reminder, streak, last 7 days, actions, Settings.
import SwiftUI

extension AppModel {
    var menuIcon: (symbol: String, title: String) {
        if folderProblem != nil { return ("exclamationmark.triangle", "Gloamlog: can't save, folder unavailable") }
        switch todayStatus {
        case .logged: return ("checkmark.circle", "Gloamlog: today logged")
        case .skipped: return ("moon.zzz", "Gloamlog: skipped today")
        case .off: return ("circle.dashed", "Gloamlog: no log needed today")
        default: return isDue ? ("pencil.circle.fill", "Gloamlog: time to write up today") : ("book.closed", "Gloamlog: today not yet logged")
        }
    }
    var menuStateLine: String {
        if folderProblem != nil { return "Saving problem: folder unavailable" }
        switch todayStatus {
        case .logged: return "Logged today ✓"
        case .skipped: let r = skipReasons[today] ?? ""; return "Skipped today" + (r.isEmpty ? "" : " (\(r))")
        case .off: return "Not a workday"
        default: return isDue ? "Due now: \(reminderLabel)" : "Not logged yet"
        }
    }
    /// The line under the state in the popover: when the next reminder is due, and how firm it is.
    var menuReminderLine: String { "Next reminder: \(nextReminderLabel) · \(settings.mode == .strict ? "Strict" : "Gentle")" }
}

struct MenuBarView: View {
    @ObservedObject var model: AppModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Today · \(DayKey.format(model.today, "EEE d MMM", model.cal))").font(Theme.font(11)).foregroundColor(Theme.textSecondary)
                HStack(spacing: 6) {
                    Image(systemName: model.menuIcon.symbol).font(Theme.font(14)).foregroundColor(model.folderProblem != nil ? Theme.danger : (model.todayStatus == .logged ? Theme.accent : Theme.textPrimary))
                        .accessibilityHidden(true)
                    Text(model.menuStateLine).font(Theme.font(14, .semibold)).foregroundColor(Theme.textPrimary)
                }
                Text(model.menuReminderLine)
                    .font(Theme.font(12)).foregroundColor(Theme.textSecondary).fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine).padding(Theme.s3)
            divider
            VStack(alignment: .leading, spacing: Theme.s2) {
                StreakLine(model: model)
                WeekStrip(model: model)
            }.padding(Theme.s3)
            divider
            VStack(spacing: 2) {
                MenuButton(title: "Open Gloamlog", shortcut: "⌘O", primary: true) { open() }.keyboardShortcut("o")
                if model.isDue { MenuButton(title: model.snoozeLabel, disabled: !model.canSnooze) { model.snooze() } }
                MenuButton(title: model.canSkipToday ? "Skip today…" : "Today is already logged", disabled: !model.canSkipToday) {
                    open(); model.requestSkip(day: model.today)
                }
            }.padding(Theme.s2)
            divider
            VStack(spacing: 2) {
                MenuButton(title: "Settings…", shortcut: "⌘,") { model.openSettings() }
                MenuButton(title: "Quit Gloamlog", shortcut: "⌘Q") { NSApp.terminate(nil) }
            }.padding(Theme.s2)
        }
        .frame(width: 300).background(Theme.surface)
        .onAppear { model.openWindowAction = { openWindow(id: "main") }; model.refreshClock() }
    }

    private var divider: some View { Rectangle().fill(Theme.border).frame(height: 1) }
    private func open() {
        if model.mainWindow == nil { openWindow(id: "main") }
        model.showMainWindow(activate: true); model.openToday()
    }
}

struct MenuButton: View {
    let title: String
    var shortcut: String?
    var primary = false
    var disabled = false
    let action: () -> Void
    var body: some View {
        HoverReader { hovering in
            Button(action: action) {
                HStack {
                    Text(title).font(Theme.font(13, primary ? .semibold : .regular))
                    Spacer()
                    if let s = shortcut { Text(s).font(Theme.font(12)).foregroundColor(primary ? Theme.onAccent.opacity(0.85) : Theme.textSecondary) }
                }
                .foregroundColor(disabled ? Theme.textTertiary : (primary ? Theme.onAccent : Theme.textPrimary))
                .padding(.horizontal, 10).frame(height: 30)
                .background(Theme.rect().fill(primary && !disabled ? Theme.accent : (hovering && !disabled ? Theme.hover : Color.clear)))
                .contentShape(Rectangle())
            }.buttonStyle(.plain).disabled(disabled)
        }
    }
}
