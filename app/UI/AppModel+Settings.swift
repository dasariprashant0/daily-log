// AppModel+Settings.swift - owned by the Settings stream (M1 tasks S1-S5).
// This stub is the entry point every other stream may call; the Settings stream replaces the body with the real
// Window-based implementation and keeps the signature.
import SwiftUI

enum SettingsPane: String, CaseIterable, Identifiable {
    case general, reminders, page, storage, shortcuts, about
    var id: String { rawValue }
}

extension AppModel {
    /// The calendar the whole app uses. `Settings.weekStart` (nil = follow the system) sets the first weekday, so the
    /// month grid, Week review and heatmap all start the week where the user wants. AppModel.cal must be built from this.
    static func makeCalendar(weekStart: Int?) -> Calendar {
        var c = Calendar.current
        if let w = weekStart, (1...7).contains(w) { c.firstWeekday = w }
        return c
    }

    /// Opens the Settings window, optionally on a pane. Callable from the sidebar gear, menus, banners and the menu-bar popover.
    func openSettings(pane: SettingsPane? = nil) {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)   // stub: opens the existing Settings scene
    }
}
