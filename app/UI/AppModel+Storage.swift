// AppModel+Storage.swift - storage folder choice (UX_SPEC 4.8) and the opt-in login item.
// Never deletes originals: "Move" copies first and removes only files that are byte-identical in the destination.
import SwiftUI
import AppKit
import ServiceManagement

struct StorageResult: Equatable {
    var text: String
    var conflicts: [URL] = []
}

extension AppModel {
    // MARK: summary
    func refreshSummary() { storageSummary = try? store.folderSummary() }

    func revealFolder() { NSWorkspace.shared.activateFileViewerSelecting([settings.storageFolder]) }
    func reveal(_ urls: [URL]) { NSWorkspace.shared.activateFileViewerSelecting(urls) }

    func retryFolder() { reload(); editor?.retryIfNeeded(); retryOrphans() }
    func recreateFolder() { do { try store.ensureFolder() } catch { }; reload(); editor?.retryIfNeeded(); retryOrphans() }

    // MARK: choose
    func chooseFolder() {
        let p = NSOpenPanel()
        p.canChooseDirectories = true; p.canChooseFiles = false; p.canCreateDirectories = true
        p.allowsMultipleSelection = false; p.prompt = "Choose"; p.message = "Choose where Gloamlog saves your logs."
        if p.runModal() == .OK, let url = p.url { changeFolder(to: url) }
    }
    func useDefaultFolder() { changeFolder(to: Settings.defaultFolder) }

    private func alert(_ title: String, _ body: String, _ buttons: [String]) -> Int {
        let a = NSAlert(); a.messageText = title; a.informativeText = body
        for b in buttons { a.addButton(withTitle: b) }
        return a.runModal().rawValue - NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
    }

    private func dayFiles(in dir: URL) -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? [])
            .filter { $0.hasSuffix(".md") && DayKey.isWellFormed(String($0.dropLast(3))) }
    }

    func changeFolder(to url: URL) {
        flushEditor { [weak self] in self?.performFolderChange(to: url) }      // what was typed lands in the OLD folder first
    }

    private func performFolderChange(to url: URL) {
        let new = url.standardizedFileURL, old = settings.storageFolder.standardizedFileURL
        if new.path == old.path { _ = alert("That's already your log folder.", "", ["OK"]); return }
        let fm = FileManager.default
        do { try fm.createDirectory(at: new, withIntermediateDirectories: true) } catch { }
        guard fm.isWritableFile(atPath: new.path) else {
            _ = alert("Gloamlog can't save to this folder.", "You may not have permission to write to \"\(new.lastPathComponent)\". Nothing was changed.", ["OK"]); return
        }
        let mine = dayFiles(in: old), theirs = Set(dayFiles(in: new))
        var result = StorageResult(text: "")
        if mine.isEmpty {
            apply(new); result.text = "Now saving to \(new.lastPathComponent)."
        } else if theirs.isEmpty {
            // Index: 0 Copy (default), 1 Move, 2 Leave them, 3 Cancel
            let c = alert("Move your \(mine.count) logs to \"\(new.lastPathComponent)\"?", "Copy keeps your originals where they are.",
                          ["Copy logs", "Move logs", "Leave them", "Cancel"])
            if c == 3 { return }
            if c == 2 { apply(new); result.text = "Now saving to \(new.lastPathComponent). Your old logs stayed where they were." }
            else {
                let r = transfer(mine, from: old, to: new, move: c == 1)
                apply(new); result = r
            }
        } else {
            // 0 Use this folder, 1 Use and copy mine over, 2 Cancel
            let c = alert("\"\(new.lastPathComponent)\" already has \(theirs.count) logs.", "Days that exist in both are never overwritten.",
                          ["Use this folder", "Use and copy mine over", "Cancel"])
            if c == 2 { return }
            if c == 1 { let r = transfer(mine, from: old, to: new, move: false); apply(new); result = r }
            else { apply(new); result.text = "Now saving to \(new.lastPathComponent)." }
        }
        storageResult = result
        refreshSummary()
    }

    private func apply(_ url: URL) {
        let day = editor?.day ?? today
        editor?.abandon()                           // already flushed: nothing of the old page may be written into the new folder
        settings.storageFolder = url
        store = AppModel.makeStore(dir: url, backupDir: backupDir)
        try? store.ensureFolder()
        reload()
        openDay(day, force: true)
    }

    private func transfer(_ files: [String], from: URL, to: URL, move: Bool) -> StorageResult {
        let fm = FileManager.default
        var copied = 0, conflicts = [URL](), failed = 0
        for name in files {
            let src = from.appendingPathComponent(name), dst = to.appendingPathComponent(name)
            if fm.fileExists(atPath: dst.path) { conflicts.append(dst); continue }
            do {
                try fm.copyItem(at: src, to: dst); copied += 1
                if move && fm.contentsEqual(atPath: src.path, andPath: dst.path) { try? fm.removeItem(at: src) }
            } catch { failed += 1 }
        }
        let images = transferAssets(from: from, to: to, move: move)
        var t = "\(move ? "Moved" : "Copied") \(Fmt.plural(copied, "log"))"
        t += images.copied > 0 ? " and \(Fmt.plural(images.copied, "image"))." : "."
        if !conflicts.isEmpty { t += " \(Fmt.plural(conflicts.count, "day")) already existed in the new folder and were left alone." }
        if failed + images.failed > 0 { t += " \(failed + images.failed) could not be copied and stayed where they were." }
        return StorageResult(text: t, conflicts: conflicts)
    }

    /// Pages reference images as assets/<file>: they move with the logs. Names carry a content hash, so an existing file
    /// of the same name is the same picture and is left alone. A symlinked assets/ that leaves the folder is not followed.
    private func transferAssets(from: URL, to: URL, move: Bool) -> (copied: Int, failed: Int) {
        let fm = FileManager.default
        let src = from.appendingPathComponent(AssetStore.folderName, isDirectory: true)
        guard let root = AssetStore.realPath(from), let real = AssetStore.realPath(src), real.hasPrefix(root + "/"),
              let names = try? fm.contentsOfDirectory(atPath: real) else { return (0, 0) }
        let dstDir = to.appendingPathComponent(AssetStore.folderName, isDirectory: true)
        var copied = 0, failed = 0
        for n in names where !n.hasPrefix(".") && AssetStore.allowedExtensions.contains((n as NSString).pathExtension.lowercased()) {
            let a = URL(fileURLWithPath: real).appendingPathComponent(n), b = dstDir.appendingPathComponent(n)
            do {
                try fm.createDirectory(at: dstDir, withIntermediateDirectories: true)
                if fm.fileExists(atPath: b.path) {
                    if move && fm.contentsEqual(atPath: a.path, andPath: b.path) { try? fm.removeItem(at: a) }
                    continue
                }
                try fm.copyItem(at: a, to: b); copied += 1
                if move && fm.contentsEqual(atPath: a.path, andPath: b.path) { try? fm.removeItem(at: a) }
            } catch { failed += 1 }
        }
        return (copied, failed)
    }

    // MARK: login item (opt-in)
    var loginStatus: SMAppService.Status { SMAppService.mainApp.status }
    var loginEnabled: Bool { loginStatus == .enabled || loginStatus == .requiresApproval }

    func setLogin(_ on: Bool) {
        guard live else { settings.launchAtLogin = on; return }
        do { if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() } }
        catch { loginMessage = "Couldn't change the login item: \(error.localizedDescription)" }
        settings.launchAtLogin = loginEnabled
        if loginStatus == .requiresApproval { loginMessage = "Approve Gloamlog in System Settings > General > Login Items." }
        else if loginMessage?.hasPrefix("Approve") == true { loginMessage = nil }
        objectWillChange.send()
    }
    func openLoginItems() { SMAppService.openSystemSettingsLoginItems() }
    func openNotificationSettings() {
        if let u = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") { NSWorkspace.shared.open(u) }
    }
}
