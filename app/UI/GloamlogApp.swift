// GloamlogApp.swift - @main: main Window, MenuBarExtra, Settings scene, menu commands.
import SwiftUI

@main
struct GloamlogApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel.shared
    @AppStorage("showMenuBar") private var showMenuBar = true

    var body: some Scene {
        Window("Gloamlog", id: "main") {
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
