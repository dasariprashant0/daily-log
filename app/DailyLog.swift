import SwiftUI
import ServiceManagement

// Five required sections, same headings as the markdown files on disk.
let sections: [(key: String, title: String, hint: String)] = [
    ("did", "📝 What I did", "Everything you worked on today…"),
    ("finished", "✅ Finished", "What got done and closed…"),
    ("started", "🚀 Started", "What you kicked off…"),
    ("pending", "⏳ Pending / blocked", "What's waiting on someone or something…"),
    ("todo", "📌 To do next", "What needs doing tomorrow…"),
]
let remindKey = "remindMinutes"
let defaultRemind = 16 * 60 + 55  // 4:55pm, weekdays

extension String { var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) } }

enum Store {
    static let dir = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("daily-log")
    static let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; f.locale = Locale(identifier: "en_US_POSIX"); return f
    }()
    static var today: String { fmt.string(from: Date()) }
    static func url(_ day: String) -> URL { dir.appendingPathComponent(day + ".md") }
    static func pretty(_ day: String) -> String {
        guard let d = fmt.date(from: day) else { return day }
        let f = DateFormatter(); f.dateFormat = "EEEE, d MMMM yyyy"; return f.string(from: d)
    }
    static func days() -> [String] {
        let files = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        return files.filter { $0.hasSuffix(".md") }.map { String($0.dropLast(3)) }.sorted(by: >)
    }
    // ponytail: a line starting with "## " inside your own text would split a section; use any other prefix.
    static func load(_ day: String) -> [String: String] {
        guard let text = try? String(contentsOf: url(day), encoding: .utf8) else { return [:] }
        var out = [String: String](), cur: String?, buf = [String]()
        func flush() { if let c = cur { out[c] = buf.joined(separator: "\n").trimmed } }
        for line in text.components(separatedBy: "\n") {
            if line.hasPrefix("## ") {
                flush(); buf = []
                let t = String(line.dropFirst(3)); cur = sections.first { $0.title == t }?.key
            } else { buf.append(line) }
        }
        flush(); return out
    }
    static func isLogged(_ day: String) -> Bool {
        let v = load(day); return sections.allSatisfy { !(v[$0.key] ?? "").isEmpty }
    }
    static func save(_ day: String, _ v: [String: String]) throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let body = "# \(day)\n\n" + sections.map { "## \($0.title)\n\((v[$0.key] ?? "").trimmed)\n\n" }.joined()
        try body.write(to: url(day), atomically: true, encoding: .utf8)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var firedDay = ""

    func applicationDidFinishLaunching(_ n: Notification) {
        try? SMAppService.mainApp.register()  // start at login so the reminder can fire
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.nag() }
        nag()
    }
    // Closing the window keeps the app alive in the background; that's what makes the nag work.
    func applicationShouldTerminateAfterLastWindowClosed(_ a: NSApplication) -> Bool { false }

    func nag() {
        let c = Calendar.current, now = Date()
        let weekday = c.component(.weekday, from: now)  // 1 = Sunday
        let mins = c.component(.hour, from: now) * 60 + c.component(.minute, from: now)
        let due = UserDefaults.standard.object(forKey: remindKey) as? Int ?? defaultRemind
        guard (2...6).contains(weekday), mins >= due, !Store.isLogged(Store.today) else { return }
        guard let w = NSApp.windows.first(where: { $0.canBecomeMain }) else { return }
        // First time today: always come to front. After that: only re-open if you closed/minimised it.
        if firedDay != Store.today || !w.isVisible || w.isMiniaturized {
            firedDay = Store.today
            if w.isMiniaturized { w.deminiaturize(nil) }
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

@main
struct DailyLogApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    var body: some Scene {
        Window("Daily Log", id: "main") {
            ContentView().frame(minWidth: 820, minHeight: 600)
        }.defaultSize(width: 980, height: 740)
    }
}

// ObservableObject + @StateObject instead of @State: @State is a macro, which needs Xcode's plugin.
final class Nav: ObservableObject {
    @Published var days = Store.days()
    @Published var sel = Store.today
}

struct ContentView: View {
    @StateObject private var nav = Nav()

    var body: some View {
        NavigationSplitView {
            List(selection: Binding<String?>(get: { nav.sel }, set: { if let v = $0 { nav.sel = v } })) {
                ForEach(Array(Set(nav.days + [Store.today])).sorted(by: >), id: \.self) { d in
                    Label(d == Store.today ? "Today" : Store.pretty(d),
                          systemImage: Store.isLogged(d) ? "checkmark.circle.fill" : "circle").tag(d)
                }
            }.navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            DayView(day: nav.sel) { nav.days = Store.days() }.id(nav.sel)
        }
    }
}

final class DayModel: ObservableObject {
    let day: String
    @Published var vals: [String: String]
    @Published var justSaved = false
    @Published var errorText = ""
    init(_ day: String) { self.day = day; vals = Store.load(day) }

    var filled: Int { sections.filter { !(vals[$0.key] ?? "").trimmed.isEmpty }.count }
    func save() -> Bool {
        do { try Store.save(day, vals); justSaved = true; errorText = ""; return true }
        catch { errorText = error.localizedDescription; return false }
    }
}

struct DayView: View {
    let onSave: () -> Void
    @StateObject private var m: DayModel
    @AppStorage(remindKey) private var remind = defaultRemind

    init(day: String, onSave: @escaping () -> Void) {
        self.onSave = onSave
        _m = StateObject(wrappedValue: DayModel(day))
    }
    var remindDate: Binding<Date> {
        Binding(get: { Calendar.current.date(bySettingHour: remind / 60, minute: remind % 60, second: 0, of: Date()) ?? Date() },
                set: { remind = Calendar.current.component(.hour, from: $0) * 60 + Calendar.current.component(.minute, from: $0) })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("Daily log").font(.system(size: 40, weight: .bold))
                Text(Store.pretty(m.day)).foregroundStyle(.secondary)
                Divider().padding(.vertical, 12)
                ForEach(sections, id: \.key) { s in
                    Text(s.title).font(.title2.bold()).padding(.top, 18)
                    Block(text: Binding(get: { m.vals[s.key] ?? "" }, set: { m.vals[s.key] = $0; m.justSaved = false }), hint: s.hint)
                }
                HStack(spacing: 14) {
                    Button("Save log") { if m.save() { onSave() } }
                        .buttonStyle(.borderedProminent).controlSize(.large).disabled(m.filled < sections.count)
                    Text(m.justSaved ? "Saved ✓" : "\(m.filled)/\(sections.count) filled").foregroundStyle(.secondary)
                    if !m.errorText.isEmpty { Text(m.errorText).foregroundStyle(.red) }
                    Spacer()
                    DatePicker("Remind me at", selection: remindDate, displayedComponents: .hourAndMinute)
                    Button("Open folder") { NSWorkspace.shared.open(Store.dir) }
                }.padding(.top, 28)
            }
            .padding(.horizontal, 56).padding(.vertical, 40)
            .frame(maxWidth: 780, alignment: .leading)
        }
    }
}

struct Block: View {
    @Binding var text: String
    let hint: String
    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: 15)).scrollContentBackground(.hidden)
            .frame(minHeight: 90).padding(6)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.05)))
            .overlay(alignment: .topLeading) {
                if text.isEmpty {
                    Text(hint).foregroundStyle(.tertiary).padding(.top, 14).padding(.leading, 11).allowsHitTesting(false)
                }
            }
    }
}
