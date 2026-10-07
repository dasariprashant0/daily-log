// LegacyMigration.swift - one-time carry-over from the app's earlier name (Daily Log, bundle id local.dailylog.app).
// Foundation only. Every location is a parameter, so tests never touch the real home folder.
//
// Why: renaming the app changes its bundle identifier, and macOS keeps preferences per identifier. Without this the
// first launch after the rename would forget onboarding, the template and the log folder, and orphan the backups.
// It only ever copies or moves; it never deletes, and never overwrites a value the new app already has.
import Foundation

enum LegacyMigration {
    static let oldDefaultsDomain = "local.dailylog.app"
    static let oldSupportFolder = "Daily Log"
    static let newSupportFolder = "Gloamlog"
    /// Keys carried over: everything under our own prefix plus the two UI toggles.
    static let keyPrefix = "dailylog."
    static let extraKeys = ["showMenuBar", "yesterdayExpanded"]

    /// Copies keys the new domain does not have yet. Returns how many were copied.
    @discardableResult
    static func migrateDefaults(from old: UserDefaults?, to new: UserDefaults) -> Int {
        guard let old = old else { return 0 }
        var copied = 0
        for (key, value) in old.dictionaryRepresentation() where key.hasPrefix(keyPrefix) || extraKeys.contains(key) {
            if new.object(forKey: key) == nil { new.set(value, forKey: key); copied += 1 }
        }
        return copied
    }

    /// Moves "<support>/Daily Log" to "<support>/Gloamlog" when only the old folder exists (the backups live there).
    @discardableResult
    static func migrateSupportFolder(in support: URL, fm: FileManager = .default) -> Bool {
        let old = support.appendingPathComponent(oldSupportFolder, isDirectory: true)
        let new = support.appendingPathComponent(newSupportFolder, isDirectory: true)
        guard fm.fileExists(atPath: old.path), !fm.fileExists(atPath: new.path) else { return false }
        return (try? fm.moveItem(at: old, to: new)) != nil
    }

    /// Both steps against the real locations. Cheap and idempotent, so it is safe to call on every launch.
    static func run(into defaults: UserDefaults = .standard, fm: FileManager = .default) {
        migrateDefaults(from: UserDefaults(suiteName: oldDefaultsDomain), to: defaults)
        if let support = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            migrateSupportFolder(in: support, fm: fm)
        }
    }
}
