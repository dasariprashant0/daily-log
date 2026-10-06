// AppDelegate.swift - process lifecycle: start timers/observers, keep the app alive after the window closes,
// flush drafts on quit, standard About panel with the Info.plist version.
import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ n: Notification) { AppModel.shared.start() }
    func applicationWillTerminate(_ n: Notification) { AppModel.shared.flushEditor() }
    // Closing the window keeps the app alive; that is what makes the reminder work.
    func applicationShouldTerminateAfterLastWindowClosed(_ a: NSApplication) -> Bool { false }
    func applicationShouldHandleReopen(_ a: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { AppModel.shared.showMainWindow(activate: true) }
        return true
    }

    static func showAbout() {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? "0.2.0"
        let credits = NSAttributedString(
            string: "A calm end-of-day log. Plain markdown files on your Mac. No network, no account, no tracking.",
            attributes: [.font: NSFont.systemFont(ofSize: 11), .foregroundColor: NSColor.secondaryLabelColor])
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Daily Log", .applicationVersion: v, .version: info?["CFBundleVersion"] as? String ?? v, .credits: credits])
        NSApp.activate(ignoringOtherApps: true)
    }
}
