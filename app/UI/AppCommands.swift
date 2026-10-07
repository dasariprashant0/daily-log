// AppCommands.swift - the app's menu commands (File/Edit/Log). Owned by the navigation stream; GloamlogApp.swift owns the scenes.
import SwiftUI

struct AppCommands: Commands {
    @ObservedObject var model: AppModel
    private var onDay: Bool { if case .day = model.selection { return true }; return false }
    private var canEdit: Bool { onDay && (model.editor?.showsEditor ?? false) }

    var body: some Commands {
        CommandGroup(replacing: .appInfo) { Button("About Gloamlog") { AppDelegate.showAbout() } }
        CommandGroup(replacing: .saveItem) {
            // Autosave is always on; ⌘S just flushes right now, as people expect.
            Button("Save Now") { model.flushEditor() }.keyboardShortcut("s").disabled(!canEdit)
            Button("Skip Day…") { model.requestSkip(day: onDay ? model.editor?.day : nil) }.keyboardShortcut("k", modifiers: [.command, .shift])
            Button("Remind Me Later") { model.snooze() }.keyboardShortcut("l", modifiers: [.command, .shift]).disabled(!model.isDue || !model.canSnooze)
            Divider()
            Button("Copy Page as Markdown") { model.copyPageMarkdown() }.disabled(!canEdit)
            Button("Restore Previous Version…") { if let d = model.editor?.day { model.sheet = .restore(d) } }.disabled(!onDay)
            Button("Open Log Folder in Finder") { model.revealFolder() }.keyboardShortcut("o", modifiers: [.command, .shift])
        }
        CommandGroup(replacing: .textEditing) {
            Button("Search Logs") { model.focusSearch() }.keyboardShortcut("f")
            Button("Next Search Result") { model.moveSearchCursor(1) }.keyboardShortcut("g")
            Button("Previous Search Result") { model.moveSearchCursor(-1) }.keyboardShortcut("g", modifiers: [.command, .shift])
        }
        CommandMenu("Log") {
            Button("Focus the Page") { model.focusEditor() }.keyboardShortcut("e").disabled(!canEdit)
            Button("Carry Over from Yesterday") { model.carryOver() }.keyboardShortcut("y", modifiers: [.command, .shift]).disabled(!model.carryAvailable)
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
