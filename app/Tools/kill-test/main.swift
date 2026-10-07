// Kill test for LogStore (task C6, data-safety claim R6). NOT part of the app; build and run with tests/run-kill-tests.sh.
//
// One executable, two modes:
//   parent (default)  runs N rounds (default 40, --rounds N). Each round starts a child process, waits until the child is in its
//                     save loop, SIGKILLs it after a random 5-300 ms, then checks the folder; finally it performs "the next save"
//                     with a fresh LogStore (what the next launch does) and checks again. Prints "N/N rounds clean" when every round passed.
//   --child ...       saves 2 KB pages round-robin over 5 days, forever, with backups on and no throttle (every overwrite is backed
//                     up), appending "start v day" before and "ack v day" after each save() to a progress file with one write(2) per line.
//
// Page v of day D is a pure function of (D, v) and starts with the line "kt v D", so the parent can rebuild the exact text of any
// version and compare byte for byte. After every kill:
//   1. every day file equals some complete version v that was written: never truncated, empty, torn or foreign;
//   2. acked(D) <= v <= started(D): an acknowledged save is never lost or rolled back, and nothing is invented;
//   3. a day with an acknowledged save still has its file (no day file vanished);
//   4. at most ONE stray temp file exists in the whole tree (the kill can interrupt only one write); and after the next save
//      by a fresh LogStore there is NONE;
//   5. backups: every backup is a complete version, named validly, versions never decrease with the name, the newest is never newer
//      than the day file, and there are at most LogStore.maxBackupsPerDay + 1 per day right after a kill (a kill between "backup
//      written" and "old ones pruned" leaves one extra) and at most maxBackupsPerDay for the day the next save touches.
import Foundation

let days = ["2026-10-05", "2026-10-06", "2026-10-07", "2026-10-08", "2026-10-09"]
let fm = FileManager.default

func pageBody(day: String, version: Int) -> String {
    var body = "kt \(version) \(day)\n\n"
    var i = 0
    while body.utf8.count < 2000 { body += "word\(version)x\(i) "; i += 1 }
    return body + "\n\nend \(version) \(day)"
}
func pageText(day: String, version: Int) -> String { MarkdownFormat.serialize(day: day, body: pageBody(day: day, version: version)) }
/// The version a page claims in its header line ("# day", blank, "kt v day"), if it has one.
func claimedVersion(_ text: String, day: String) -> Int? {
    let lines = text.components(separatedBy: "\n")
    guard lines.count > 2, lines[0] == "# \(day)", lines[2].hasPrefix("kt ") else { return nil }
    let parts = lines[2].split(separator: " ")
    return parts.count == 3 && parts[2] == Substring(day) ? Int(parts[1]) : nil
}

// MARK: child
func runChild(storage: String, backups: String, progress: String, ready: String, start: Int) -> Never {
    let store = LogStore(dir: URL(fileURLWithPath: storage), backupDir: URL(fileURLWithPath: backups), minBackupInterval: 0)
    let fd = open(progress, O_WRONLY | O_APPEND | O_CREAT, 0o644)
    func log(_ line: String) { let b = Array((line + "\n").utf8); _ = b.withUnsafeBufferPointer { write(fd, $0.baseAddress, $0.count) } }
    fm.createFile(atPath: ready, contents: Data())
    var v = start
    while true {
        let day = days[v % days.count]
        log("start \(v) \(day)")
        do { try store.save(day: day, body: pageBody(day: day, version: v)) } catch { log("error \(v) \(day) \(error)"); exit(3) }
        log("ack \(v) \(day)")
        v += 1
    }
}

// MARK: parent
struct Progress { var started = [String: Int](), acked = [String: Int](), saves = 0, errors = [String]() }
func readProgress(_ path: String) -> Progress {
    var p = Progress()
    guard let data = fm.contents(atPath: path), let text = String(data: data, encoding: .utf8) else { return p }
    var lines = text.components(separatedBy: "\n")
    lines.removeLast()                                   // whatever follows the last newline is a line the kill cut short
    for line in lines {
        let f = line.split(separator: " ", maxSplits: 2).map(String.init)
        guard f.count == 3, let v = Int(f[1]) else { p.errors.append("unreadable progress line '\(line)'"); continue }
        switch f[0] {
        case "start": p.started[f[2]] = max(p.started[f[2]] ?? 0, v)
        case "ack": p.acked[f[2]] = max(p.acked[f[2]] ?? 0, v); p.saves += 1
        case "error": p.errors.append("child save failed: \(line)")
        default: p.errors.append("unreadable progress line '\(line)'")
        }
    }
    return p
}

let backupName = try! NSRegularExpression(pattern: "^[0-9]{8}-[0-9]{6}\\.md$")
func isBackupName(_ n: String) -> Bool { backupName.firstMatch(in: n, range: NSRange(n.startIndex..., in: n)) != nil }

/// Entries that are not a day file (storage) / not a backup day folder or backup file (backups): leftover temp files.
func strays(storage: URL, backups: URL) -> [String] {
    var out = [String]()
    for n in (try? fm.contentsOfDirectory(atPath: storage.path)) ?? [] where !days.contains(where: { n == $0 + ".md" }) { out.append("Logs/\(n)") }
    for d in (try? fm.contentsOfDirectory(atPath: backups.path)) ?? [] {
        guard days.contains(d) else { out.append("backups/\(d)"); continue }
        for n in (try? fm.contentsOfDirectory(atPath: backups.appendingPathComponent(d).path)) ?? [] where !isBackupName(n) { out.append("backups/\(d)/\(n)") }
    }
    return out
}

/// Checks 1, 2, 3 and 5. `started`/`acked` are cumulative over all rounds. `maxBackups` is the allowed number per day.
func verify(storage: URL, backups: URL, started: [String: Int], acked: [String: Int], maxBackups: Int = LogStore.maxBackupsPerDay + 1) -> [String] {
    var problems = [String]()
    for day in days {
        let file = storage.appendingPathComponent(day + ".md")
        var current: Int?
        if let data = fm.contents(atPath: file.path) {
            guard let text = String(data: data, encoding: .utf8) else { problems.append("\(day): file is not UTF-8"); continue }
            if let v = claimedVersion(text, day: day), text == pageText(day: day, version: v) {
                current = v
                if v < (acked[day] ?? 0) { problems.append("\(day): LOST an acknowledged save, file has v\(v), v\(acked[day]!) was acknowledged") }
                if v > (started[day] ?? 0) { problems.append("\(day): file has v\(v) which was never started (last started v\(started[day] ?? 0))") }
            } else {
                problems.append("\(day): file is not a complete version (\(data.count) bytes, starts \(String(text.prefix(30)).debugDescription))")
            }
        } else if acked[day] != nil {
            problems.append("\(day): file is missing although v\(acked[day]!) was acknowledged")
        }
        let dir = backups.appendingPathComponent(day)
        var last = 0
        let names = ((try? fm.contentsOfDirectory(atPath: dir.path)) ?? []).filter(isBackupName).sorted()
        if names.count > maxBackups { problems.append("\(day): \(names.count) backups, more than \(maxBackups)") }
        for n in names {
            guard let data = fm.contents(atPath: dir.appendingPathComponent(n).path), let text = String(data: data, encoding: .utf8),
                  let v = claimedVersion(text, day: day), text == pageText(day: day, version: v) else {
                problems.append("\(day): backup \(n) is not a complete version"); continue
            }
            if v < last { problems.append("\(day): backup \(n) holds v\(v), older than the previous backup's v\(last)") }
            last = v
        }
        if let c = current, last > c { problems.append("\(day): newest backup v\(last) is newer than the day file v\(c)") }
    }
    return problems
}

func runParent(rounds: Int) -> Never {
    let tmp = URL(fileURLWithPath: ProcessInfo.processInfo.environment["TMPDIR"] ?? NSTemporaryDirectory(), isDirectory: true)
    let root = tmp.appendingPathComponent("dl-kill-\(UUID().uuidString.prefix(8))")
    let storage = root.appendingPathComponent("Logs"), backups = root.appendingPathComponent("backups")   // backups outside the log folder, like the app
    let store = LogStore(dir: storage, backupDir: backups, minBackupInterval: 0)
    try! store.ensureFolder(); try! fm.createDirectory(at: backups, withIntermediateDirectories: true)
    let exe = Bundle.main.executablePath ?? CommandLine.arguments[0]
    var started = [String: Int](), acked = [String: Int](), next = 1, clean = 0, totalSaves = 0, strayRounds = 0
    print("kill test: \(rounds) rounds, folder \(root.path)")
    for round in 1...rounds {
        let ready = root.appendingPathComponent("ready").path, progress = root.appendingPathComponent("progress-\(round).log").path
        try? fm.removeItem(atPath: ready)
        let child = Process()
        child.executableURL = URL(fileURLWithPath: exe)
        child.arguments = ["--child", storage.path, backups.path, progress, ready, String(next)]
        var problems = [String]()
        do { try child.run() } catch { print("round \(round): cannot start the child: \(error)"); exit(2) }
        let deadline = Date().addingTimeInterval(10)
        while !fm.fileExists(atPath: ready) && Date() < deadline && child.isRunning { usleep(300) }
        let delay = Double.random(in: 0.005...0.300)
        Thread.sleep(forTimeInterval: delay)
        if child.isRunning { kill(child.processIdentifier, SIGKILL) } else { problems.append("the child exited by itself before the kill") }
        child.waitUntilExit()
        if problems.isEmpty && !(child.terminationReason == .uncaughtSignal && child.terminationStatus == SIGKILL) {
            problems.append("child did not die from SIGKILL (reason \(child.terminationReason.rawValue), status \(child.terminationStatus))")
        }
        let p = readProgress(progress)
        problems += p.errors
        for (d, v) in p.started { started[d] = max(started[d] ?? 0, v) }
        for (d, v) in p.acked { acked[d] = max(acked[d] ?? 0, v) }
        totalSaves += p.saves
        next = (started.values.max() ?? 0) + 1
        problems += verify(storage: storage, backups: backups, started: started, acked: acked)
        let left = strays(storage: storage, backups: backups)
        if left.count > 1 { problems.append("\(left.count) stray temp files after one kill (at most 1 expected): \(left)") }
        if !left.isEmpty { strayRounds += 1 }
        // the next save, by a fresh store (= the next launch), must clean any stray up
        let fresh = LogStore(dir: storage, backupDir: backups, minBackupInterval: 0)
        let day = days[next % days.count]
        do { try fresh.save(day: day, body: pageBody(day: day, version: next)) } catch { problems.append("the next save failed: \(error)") }
        started[day] = next; acked[day] = next; next += 1
        let after = strays(storage: storage, backups: backups)
        if !after.isEmpty { problems.append("the next save left stray temp files behind: \(after)") }
        problems += verify(storage: storage, backups: backups, started: started, acked: acked)
        let kept = ((try? fm.contentsOfDirectory(atPath: backups.appendingPathComponent(day).path)) ?? []).filter(isBackupName).count
        if kept > LogStore.maxBackupsPerDay { problems.append("\(day): the next save left \(kept) backups, more than \(LogStore.maxBackupsPerDay)") }
        let line = String(format: "round %2d  killed after %3d ms  saves %4d  stray after kill %d  ", round, Int(delay * 1000), p.saves, left.count)
        if problems.isEmpty { clean += 1; print(line + "clean") } else { print(line + "PROBLEM"); for x in problems { print("    - \(x)") } }
    }
    print("\(totalSaves) saves acknowledged in total, a stray temp file was left by the kill in \(strayRounds) rounds")
    print("\(clean)/\(rounds) rounds clean")
    try? fm.removeItem(at: root)
    exit(clean == rounds ? 0 : 1)
}

// MARK: entry
let args = CommandLine.arguments
if args.count >= 7, args[1] == "--child", let start = Int(args[6]) {
    runChild(storage: args[2], backups: args[3], progress: args[4], ready: args[5], start: start)
}
var rounds = 40
if let i = args.firstIndex(of: "--rounds"), i + 1 < args.count, let n = Int(args[i + 1]), n > 0 { rounds = n }
runParent(rounds: rounds)
