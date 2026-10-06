// Settings.swift - persisted preferences.
//
// API:
//   Settings                 Codable struct; Settings() = defaults (Strict, 16:55, Mon-Fri, 15 min snooze, default sections)
//   Settings.load(from:)     / save(to:)   via any KeyValueStore (UserDefaults conforms; MemoryStore for tests)
//   Settings.normalized()    clamps invalid values (call after editing; load already does)
//   Settings.isWorkday(weekday:) / defaultFolder
//   ReminderMode             .strict | .gentle
// Weekdays use Calendar numbering: 1 = Sunday ... 7 = Saturday.
import Foundation

enum ReminderMode: String, Codable { case strict, gentle }

protocol KeyValueStore: AnyObject {
    func data(forKey key: String) -> Data?
    func setData(_ data: Data?, forKey key: String)
}
extension UserDefaults: KeyValueStore {
    func setData(_ data: Data?, forKey key: String) { set(data as Any?, forKey: key) }
}
final class MemoryStore: KeyValueStore {
    var values: [String: Data] = [:]
    func data(forKey key: String) -> Data? { values[key] }
    func setData(_ data: Data?, forKey key: String) { values[key] = data }
}

struct Settings: Codable, Equatable {
    static let storageKey = "dailylog.settings.v2"
    static let snoozeChoices = [5, 10, 15, 20, 30]
    static var defaultFolder: URL { URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("daily-log") }

    var reminderMinutes = 16 * 60 + 55            // minutes after midnight, local time
    var weekdays: Set<Int> = [2, 3, 4, 5, 6]      // Mon-Fri
    var mode: ReminderMode = .strict
    var snoozeMinutes = 15
    var storageFolder: URL = Settings.defaultFolder
    var launchAtLogin = true
    var sections: [SectionDef] = DefaultSections.all
    var onboarded = false
    var carryOverSectionID = "pending"            // where "Carry over" lands

    init() {}

    enum CodingKeys: String, CodingKey {
        case reminderMinutes, weekdays, mode, snoozeMinutes, storageFolder, launchAtLogin, sections, onboarded, carryOverSectionID
    }
    // Tolerant decoding: keys missing from older/newer saves fall back to defaults.
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        reminderMinutes = try c.decodeIfPresent(Int.self, forKey: .reminderMinutes) ?? reminderMinutes
        weekdays = try c.decodeIfPresent(Set<Int>.self, forKey: .weekdays) ?? weekdays
        mode = try c.decodeIfPresent(ReminderMode.self, forKey: .mode) ?? mode
        snoozeMinutes = try c.decodeIfPresent(Int.self, forKey: .snoozeMinutes) ?? snoozeMinutes
        storageFolder = try c.decodeIfPresent(URL.self, forKey: .storageFolder) ?? storageFolder
        launchAtLogin = try c.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? launchAtLogin
        sections = try c.decodeIfPresent([SectionDef].self, forKey: .sections) ?? sections
        onboarded = try c.decodeIfPresent(Bool.self, forKey: .onboarded) ?? onboarded
        carryOverSectionID = try c.decodeIfPresent(String.self, forKey: .carryOverSectionID) ?? carryOverSectionID
    }

    func isWorkday(weekday: Int) -> Bool { weekdays.contains(weekday) }

    func normalized() -> Settings {
        var s = self
        s.reminderMinutes = min(max(reminderMinutes, 0), 24 * 60 - 1)
        s.weekdays = weekdays.filter { (1...7).contains($0) }
        if s.weekdays.isEmpty { s.weekdays = [2, 3, 4, 5, 6] }
        if !Settings.snoozeChoices.contains(snoozeMinutes) { s.snoozeMinutes = 15 }
        if SectionDef.validationError(sections) != nil { s.sections = DefaultSections.all }
        return s
    }

    static func load(from store: KeyValueStore, key: String = storageKey) -> Settings {
        guard let d = store.data(forKey: key), let s = try? JSONDecoder().decode(Settings.self, from: d) else { return Settings() }
        return s.normalized()
    }
    func save(to store: KeyValueStore, key: String = Settings.storageKey) {
        store.setData(try? JSONEncoder().encode(normalized()), forKey: key)
    }
}
