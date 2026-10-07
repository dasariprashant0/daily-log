// AppModel+Settings.swift - owned by the Settings stream (M1 tasks S1-S5).
// This stub is the entry point every other stream may call; the Settings stream replaces the body with the real
// Window-based implementation and keeps the signature.
import SwiftUI

enum SettingsPane: String, CaseIterable, Identifiable {
    case general, reminders, page, storage, shortcuts, about
    var id: String { rawValue }
}

extension AppModel {
    /// Opens the Settings window, optionally on a pane. Callable from the sidebar gear, menus, banners and the menu-bar popover.
    func openSettings(pane: SettingsPane? = nil) {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)   // stub: opens the existing Settings scene
    }
}
