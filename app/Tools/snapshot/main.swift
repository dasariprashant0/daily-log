// Headless snapshot harness (NOT shipped in the app). Renders UI views with sample data to PNG.
// Build+run: app/Tools/snapshot/run.sh  [outdir]
// Uses NSHostingView + bitmap cache so AppKit-backed controls draw; falls back to nothing if the sandbox has no display.
import SwiftUI
import AppKit

let base = ProcessInfo.processInfo.environment["TMPDIR"] ?? NSTemporaryDirectory()
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : base + "/dl-snap"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

// ---- sample data ----
let cal = Calendar.current
let tmp = URL(fileURLWithPath: base).appendingPathComponent("dl-snap-logs")
try? FileManager.default.removeItem(at: tmp)
try? FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
let drafts = URL(fileURLWithPath: base).appendingPathComponent("dl-snap-drafts")
try? FileManager.default.removeItem(at: drafts)

var comps = DateComponents(year: 2026, month: 10, day: 6, hour: 17, minute: 5)
let nowDate = cal.date(from: comps)!
let ds = UserDefaults(suiteName: "dailylog.snapshot")!
ds.removePersistentDomain(forName: "dailylog.snapshot")
var s = Settings(); s.storageFolder = tmp; s.onboarded = true
s.save(to: ds)

let store = LogStore(dir: tmp)
// The sandbox forbids Foundation's atomic-write temp file, so sample files are written non-atomically here only.
func put(_ day: String, _ text: String) { try? text.write(to: tmp.appendingPathComponent(day + ".md"), atomically: false, encoding: .utf8) }
let did = ["Drafted the pricing page copy and reviewed the signup form with Ana.", "Webinar landing page wireframes; fixed the tracking on the demo form.",
           "Reviewed Q3 campaign report and wrote the summary for Friday's sync.", "Interviewed two candidates for the content role."]
for back in 1...80 {
    guard let k = DayKey.adding("2026-10-06", -back, cal) else { continue }
    let wd = DayKey.weekday(k, cal)
    if wd == 1 || wd == 7 { continue }
    if back % 11 == 4 { continue }                       // missed
    if back % 9 == 3 { put(k, MarkdownFormat.serializeSkip(day: k, reason: back % 2 == 0 ? "Holiday" : "Leave")); continue }
    var e = DayEntry(date: k)
    e.texts = ["did": did[back % did.count], "finished": "Pricing table update shipped.\nForm fix merged.", "started": "Webinar landing page",
               "pending": back == 1 ? "Waiting on legal for the DPA\nPing Ana about the form" : "Waiting on design review",
               "todo": back == 1 ? "Review pricing page copy with Ana\nShip the webinar page" : "Follow up on open items"]
    put(k, MarkdownFormat.serialize(day: k, sections: store.sections.compactMap { d in e.texts[d.id].map { (d.title, $0) } }))
}
let model = AppModel(defaults: ds, draftsDir: drafts, live: false, clock: { nowDate })
// today: partially filled
model.editor.texts["did"] = "Reviewed the new pricing page and left comments on the hero copy.\nSynced with Ana about the signup form."
model.editor.texts["finished"] = "Pricing table update"

// ---- rendering ----
_ = NSApplication.shared
func snap<V: View>(_ v: V, _ w: CGFloat, _ h: CGFloat, _ name: String, dark: Bool = false, real: Bool = false) {
    let root = v.frame(width: w, height: h).environment(\.snapshotMode, !real).environment(\.colorScheme, dark ? .dark : .light)
    let host = NSHostingView(rootView: root)
    host.frame = NSRect(x: 0, y: 0, width: w, height: h)
    let win = NSWindow(contentRect: host.frame, styleMask: [.titled], backing: .buffered, defer: false)
    win.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    win.contentView = host
    host.layoutSubtreeIfNeeded()
    RunLoop.current.run(until: Date().addingTimeInterval(0.4))
    host.layoutSubtreeIfNeeded()
    guard let rep = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { print("no rep \(name)"); return }
    host.cacheDisplay(in: host.bounds, to: rep)
    if let d = rep.representation(using: .png, properties: [:]) { try? d.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png")); print("wrote \(name)") }
}

func composite(_ detail: AnyView) -> some View {
    HStack(spacing: 0) { SidebarView(model: model).frame(width: 240); detail.frame(maxWidth: .infinity) }
}

for dark in [false, true] {
    let t = dark ? "-dark" : ""
    snap(composite(AnyView(DayPage(model: model, editor: model.editor))), 1000, 760, "main-today\(t)", dark: dark)
    snap(SidebarView(model: model), 240, 760, "sidebar\(t)", dark: dark)
    snap(GeneralSettings(model: model), 520, 560, "settings-general\(t)", dark: dark)
    snap(SectionsEditor(model: model), 520, 420, "settings-sections\(t)", dark: dark)
    snap(StorageSettings(model: model), 520, 300, "settings-storage\(t)", dark: dark)
    snap(MenuBarView(model: model), 300, 400, "menubar\(t)", dark: dark)
    model.select(.week)
    snap(composite(AnyView(WeeklyReviewView(model: model))), 1000, 760, "weekly\(t)", dark: dark)
    model.select(.day(model.today))
}
model.searchText = "pricing"; model.runSearch("pricing", nil)
snap(composite(AnyView(SearchView(model: model))), 1000, 520, "search", dark: false)
model.searchText = ""
snap(SkipSheet(model: model, day: model.today), 500, 380, "skip-sheet")
snap(OnboardingView(model: model), 560, 480, "onboarding")

snap(composite(AnyView(DayPage(model: model, editor: model.editor))), 1000, 760, "main-today-realeditor", real: true)
