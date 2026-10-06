// DailyLogApp.swift - @main: main Window, MenuBarExtra, Settings scene, menu commands.
import SwiftUI

@main
struct DailyLogApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel.shared
    @AppStorage("showMenuBar") private var showMenuBar = true

    var body: some Scene {
        Window("Daily Log", id: "main") {
            MainView(model: model)
        }
        .defaultSize(width: 1000, height: 760)
        .windowResizability(.contentMinSize)
        .commands { AppCommands(model: model) }

        MenuBarExtra(isInserted: $showMenuBar) {
            MenuBarView(model: model)
        } label: {
            Image(systemName: model.menuIcon.symbol).accessibilityLabel(model.menuIcon.title)
        }
        .menuBarExtraStyle(.window)

        SwiftUI.Settings { SettingsView(model: model) }
    }
}

struct AppCommands: Commands {
    @ObservedObject var model: AppModel
    private var onDay: Bool { if case .day = model.selection { return true }; return false }

    var body: some Commands {
        CommandGroup(replacing: .appInfo) { Button("About Daily Log") { AppDelegate.showAbout() } }
        CommandGroup(replacing: .saveItem) {
            Button(model.editor.hasFile && model.editor.day != model.today ? "Save Changes" : "Save Log") { model.saveCurrent() }
                .keyboardShortcut("s").disabled(!onDay)
            Button("Skip Day…") { model.requestSkip(day: onDay ? model.editor.day : nil) }.keyboardShortcut("k", modifiers: [.command, .shift])
            Button("Remind Me Later") { model.snooze() }.keyboardShortcut("l", modifiers: [.command, .shift]).disabled(!model.isDue || !model.canSnooze)
            Divider()
            Button("Open Log Folder in Finder") { model.revealFolder() }.keyboardShortcut("o", modifiers: [.command, .shift])
        }
        CommandGroup(replacing: .textEditing) {
            Button("Search Logs") { model.focusSearch() }.keyboardShortcut("f")
            Button("Next Search Result") { model.moveSearchCursor(1) }.keyboardShortcut("g")
            Button("Previous Search Result") { model.moveSearchCursor(-1) }.keyboardShortcut("g", modifiers: [.command, .shift])
        }
        CommandMenu("Log") {
            Button("Jump to First Empty Section") { model.focusFirstEmpty() }.keyboardShortcut("e").disabled(!onDay)
            Button("Next Section") { model.moveFocus(1, from: model.focusRequest?.sectionID) }.keyboardShortcut(.downArrow, modifiers: [.command, .option]).disabled(!onDay)
            Button("Previous Section") { model.moveFocus(-1, from: model.focusRequest?.sectionID) }.keyboardShortcut(.upArrow, modifiers: [.command, .option]).disabled(!onDay)
            Button("Carry Over from Yesterday") { model.carryOver() }.keyboardShortcut("y", modifiers: [.command, .shift]).disabled(model.carryCard == nil)
            Divider()
            Button("Today") { model.openToday() }.keyboardShortcut("1")
            Button("This Week") { model.select(.week) }.keyboardShortcut("2")
            Button("Previous Day or Week") { model.step(-1) }.keyboardShortcut("[")
            Button("Next Day or Week") { model.step(1) }.keyboardShortcut("]")
            Divider()
            Button("Copy Week as Markdown") { model.copyWeek() }.keyboardShortcut("c", modifiers: [.command, .shift]).disabled(model.selection != .week)
        }
    }
}
