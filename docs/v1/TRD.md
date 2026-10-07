# Gloamlog v1: technical requirements and decisions

Status: proposal for owner review. Written 2026-10-07 against the v0.3 checkpoint in this repository. Nothing here is built.

Supersedes `docs/TRD.md` and `docs/ARCHITECTURE.md` (both describe the single-file v0.1 app). Companions: `docs/v1/PRD_V1.md` (what and when), `docs/v1/DESIGN_V4.md` (screens), `docs/v1/UX_AUDIT_AND_BENCHMARKS.md` (evidence), and `docs/v1/ARCHITECTURE.md` (module and type plan, formats, harness, migration). `docs/v1/UX_FLOWS.md` is the behaviour authority for flows, copy and the settings catalogue; this document follows it, and section 2 lists every place where the two differ.

Tags: **[code]** read from the source. **[measured]** measured on the owner's Mac for this document (macOS 27.0.1, arm64, Command Line Tools only, `swiftc` 6.4 in Swift 5 mode, `-O`, warm cache; Appendix A). **[verify]** depends on OS or sync-provider behaviour that could not be exercised here; a spike task exists. **[PRD]** and **[DESIGN]** cite the sibling documents.

Units: hours are focused engineering hours for one developer who knows this codebase, including tests and review. They are not the PRD's agent-hours (section 0.3 compares the two).

## 0. Summary

### 0.1 Verdict: evolve, do not rewrite

The foundation is sound and stays: one markdown file per day, pure `app/Core` functions behind an assert-based runner, a token-guarded editor bridge (`EditorBridge`), versioned backups outside the folder (`LogStore`), a pure reminder planner (`ReminderPlanner.decide`). The owner's verdict on v0.3 comes from five gaps at the edges and underneath, none of which needs a new foundation:

1. **Navigation is built from files that exist, not from the calendar** (`AppModel.historyDays`, `Sidebar.HistoryList`). `AppModel.openDay` already opens any well-formed date; the app has no door to it. Fix: calendar, catch-up planner, log start date (D-A, D-B).
2. **Every data path rescans everything.** The 30 s tick calls `reload()`, which runs `LogStore.fileStates` (read and parse every file) on the main thread: 605 ms at 2,609 days. One search takes 1.1 s. The sidebar month grouping costs 65 ms per evaluation at 10 years. All measured. Fix: an in-memory snapshot fed by a disposable SQLite cache (D-A, D-H).
3. **The writer model is implicit.** `DayEditor.write()` is last-writer-wins with a backup. That is fine with one writer and unsafe once a capture hotkey, a folder watcher and a second Mac exist. Fix: one writer (`DayWriter`), the editor's save/reconcile logic extracted into a pure `PageSync` state machine, compare-and-swap saves (D-C, D-D, D-J).
4. **Sync is unmodelled.** iCloud stubs (`.name.icloud`) are skipped as dotfiles, so an evicted day looks missing; conflict copies are "not recognised"; change detection is polling only (D-C).
5. **Settings are flat, unversioned, thin and unreachable**, and reminders die with the process (D-E, D-F).

### 0.2 Decisions

| ID | Question | Decision in one line | Primary hours |
|---|---|---|---|
| D-A | Date index, calendar model | `DayIndexSnapshot` value type in memory (about 0.5 MB at 10 years); produced by a scan (M1) then by a SQLite cache outside the folder (M4); diffed by size and mtime with a content-hash check; launch never parses day files; months grouped once; a stored `logStartDate` replaces "earliest file". Files stay the only truth. | 54 |
| D-B | Any day, catch-up | Calendar, Go to date (2000-01-01 to today), pure `CatchUp` planner (scheduled weekdays minus logged and skipped, from the stored log start date, default 30-day window, jots-only days listed), oldest-first session with "Next unlogged day", Today line, batch skip with undo. Opening never writes. Future pages stay out of the UI (PRD), supported behind a hidden flag. | 29 |
| D-C | Watching and sync | FSEvents plus a polling fallback; stubs and dataless files are never read or overwritten; settle-before-read; temp+fsync+rename; compare-and-swap saves; conflicts are a user choice (keep mine, take theirs, keep both), never automatic text merging (PRD). | 59 |
| D-D | Capture, single writer | Everything that mutates a day goes through `DayWriter`. Open page: one editor transaction through the additive contract call `appendToSection` (caret, typing and undo untouched). Closed page: append on disk. A write-ahead journal makes a note durable before the panel closes. Hotkey: Carbon `RegisterEventHotKey` (no permission). | 54 |
| D-E | Reminders when closed | Keep the in-process planner; add a rolling window of 14 scheduled days of `UNCalendarNotificationTrigger` requests that macOS delivers while the app is closed. LaunchAgent helper deferred. | 20 |
| D-F | Settings | Keep the flat legacy keys, add `schemaVersion` and nested groups, pane-keyed field table for reset, export, import and diff; stay on `UserDefaults`; open Settings from an explicit `Window` scene. | 34 |
| D-G | Review, export | `PeriodReview` for week, month, year, range from headings and tasks; own Markdown-to-HTML; PDF through a `WKWebView` print operation; `ditto` for zips; `NSSharingServicePicker`. | 55 |
| D-H | Search at scale | Same SQLite file: `instr()` over folded section text finds candidates (3 ms at 10 years), the existing `Search.hits` verifies and snippets, Swift ranks. No FTS5. | 20 |
| D-I | Sources | Add-on module behind an `ActivitySource` protocol; off by default; per-source and per-project consent; suggestions only. PRD M6; scheduled after everything else ("M-later"). | 82 (later) |
| D-J | Errors, data safety | 18 numbered invariants, each with a named test; fault-injection seam; kill tests; pure `PageSync` with model-based fuzzing; spill file for unsaved text. | 13 (+T2.04, T5b.3, T5b.4) |
| D-K | Performance | Budget table (section 7), bench harness with synthetic 1, 5, 10 and 20-year corpora, in-process signposts. | 5 |
| D-L | UI scenario harness | Extend `app/Tools/editor-check`: `AppDriver` over the real window, real editor and real folder; presses controls through accessibility identifiers; in-process screenshots (no Screen Recording permission). | 39 |
| D-M | Release | Ad-hoc is enough for the owner's own builds; Developer ID plus notarisation for anything downloaded; no auto-update (Homebrew first, opt-in "Check for updates" later); CI gains a CLT-only job and guards. | 28 |

Everything not listed as a primary decision above is in section 10's task table. Totals: 424 h through M7 (excluding Sources and other later work), 173 h later.

### 0.3 Milestones, mapped to the PRD

Milestone names and versions are the PRD's. "M-later" in this document is PRD M6 (Sources) plus the deferred items in section 10.3.

| PRD milestone | Version | TRD tasks | TRD hours | PRD agent-hours | Ratio |
|---|---|---|---|---|---|
| M1 Daily-usable core | 0.4.0 | T1.01 to T1.21 | 132 | 26 to 34 | 4.4 |
| M2 Quick capture | 0.5.0 | T2.01 to T2.07 | 64 | 12 to 18 | 4.3 |
| M3 Reviews and export | 0.6.0 | T3.01 to T3.07 | 58 | 18 to 26 | 2.6 |
| M4 Search at scale | 0.7.0 | T4.01 to T4.07 | 54 | 8 to 16 | 4.5 |
| M5a Reminders when closed | 0.8.0 | T5a.1 to T5a.4 | 20 | 10 to 14 | 1.7 |
| M5b Sync | 0.8.0 | T5b.1 to T5b.10 | 74 | 16 to 22 | 3.9 |
| M7 Release (PRD: separate plan) | 1.0.0 | T7.01 to T7.05 | 22 | not estimated | |
| M6 Sources (M-later) | 0.9.0 | L1 to L4 | 82 | 30 to 42 | 2.3 |

The ratios (1.7 to 4.5) are the plan's own scale, not a claim about how fast an agent works. The TRD adds what the PRD's release gate requires and its estimates leave out: fault injection and kill tests (T1.03, T1.04), the scenario harness that produces the gate's real screenshots (T1.19), the safe-write machinery (T2.04, T5b.3, T5b.4) and the index (T4.01 to T4.03).

### 0.4 Cut lines

| Cut | Contents | Hours | What the owner can do after it |
|---|---|---|---|
| A: usable | T1.01, T1.06, T1.08 to T1.17 | 79 | Write any past day from a calendar, catch up in bulk, change settings from a real window. Answers the verbatim complaint. |
| A+: verified | A plus T1.19 (harness) and T1.20 (walkthrough fixes) | 105 | The PRD's R1 to R9 sign-off with real screenshots as evidence. |
| M1 complete | All of M1 | 132 | Adds fault injection, kill tests, CI guards, bench baselines, settings import and export. |
| B: daily driver | M1 plus T2.01 to T2.07 | 196 | Adds Jots. |

Cuts follow the PRD's own rule: scope is cut, the release gate is not.

## 1. Evidence

### 1.1 What the code does today

| # | Finding | Where [code] | Consequence |
|---|---|---|---|
| F1 | Every 30 s tick and every app activation re-reads and re-parses every day file (skipped days twice) on the main thread. | `AppModel.tick()` calls `refreshClock()` calls `reload()` calls `LogStore.fileStates`; `AppModel+Reminders.swift` | 605 ms per call at 2,609 days [measured]; about 60 ms at one year. Touches cloud-evicted files. |
| F2 | Search reads and parses everything for every query, on the main thread after `flushEditor`. | `LogStore.search`, `AppModel.runSearch` | 1.09 to 1.19 s per query at 10 years [measured]; with all documents already in memory the matcher alone still costs 815 ms. |
| F3 | The sidebar groups months with an O(months x days) filter inside `body`. | `Sidebar.HistoryList`, `MonthHeader` | 65 ms per evaluation at 10 years, 217 ms at 20 [measured]; `body` re-runs on every published change. |
| F4 | The sidebar lists only days that already have a file. No calendar, no date entry. Unlogged days are reachable only through the 12-week popover or the Week view's Open button, and a week with nothing logged is a dead end. | `AppModel.historyDays`, `AppModel.step`, `PageHeader.StreakChip`, `WeeklyReviewView` | The owner's complaint. Audit D1, D2. |
| F5 | Opening any day already works. `openDay` accepts any well-formed key; `DayEditor` writes only after a real edit. | `AppModel.openDay`, `DayEditor` | The fix is navigation and detection, not storage. |
| F6 | Settings: 3 tabs, about 15 controls, reachable only from menus (the app menu and ⌘, come from the `SwiftUI.Settings` scene; the menu-bar popover and the What's New sheet call `NSApp.sendAction(Selector(("showSettingsWindow:")))`), with no button in the window. Tunables are hard-coded: reminder cutoff 23:00, 2 strict snoozes, 5-minute re-open, 10 backups per day, 120 s backup throttle, 14-day carry-over lookback. | `SettingsView.swift`, `ReminderPlanner`, `LogStore.maxBackupsPerDay`, `AppModel.backupInterval`, `CarryOver.lookbackDays` | Owner complaint. The PRD doubts the selector works on the owner's macOS. |
| F7 | Reminders exist only while the process runs. `Notifier.post` uses `trigger: nil`. `docs/UX_SPEC.md` 7.8 specifies a rolling `UNCalendarNotificationTrigger` window that was never built. | `Notifier.swift`, `AppModel+Reminders.swift` | Quit the app, no reminder. |
| F8 | External changes are found only by polling (tick, activation). Policy: our version wins, theirs goes to backups, with a notice. | `DayEditor.checkExternalChange`, `DayEditor.write` | Notes appended on another Mac or by another tool are replaced in the file and kept only in backups. |
| F9 | `dayFiles()` skips names that start with "." and counts conflict copies as unrecognised. | `LogStore.dayFiles` | An evicted iCloud day (`.name.icloud`) looks unlogged and could be re-created; duplicates are ignored. |
| F10 | Writes are `String.write(atomically:)`: no fsync, no compare-and-swap. An emptied page deletes its file (after a backup). | `LogStore.write`, `LogStore.save` | Deletion propagates through a synced folder; backups are per Mac. |
| F11 | The calendar is captured once: `let cal = Calendar.current`. Time-zone events only trigger `refreshClock`. | `AppModel.swift` | Day labels stale after a zone change (audit D18). |
| F12 | The words rule has no notion of Jots. Status is `DayDocument.status(minWords:)`. | `Models.swift`, `MarkdownBody.words` | PRD Q1 (jots do not count by default) needs a new input to the rule, and UX_FLOWS 1.6 needs a jots-only day to read "started", not "empty". |
| F13 | `tests/run-tests.sh` has 51 test blocks. Inside the agent's Bash sandbox 231 checks pass and 28 test blocks throw (20 `folderNotWritable`, 8 other I/O errors), because the sandbox denies the folder writes they need (the writable check and temp-file renames). | `tests/run-tests.sh` header, run [measured] | Needs a `--pure` subset that runs everywhere. |
| F14 | FSEvents cannot start inside the sandbox (`FSEventStreamStart` returns false), `RegisterEventHotKey` needs a window-server connection, WebKit needs a real window server. | probe [measured], `editor-check/run.sh` | Watcher, hotkey and scenario tests run in a normal terminal; logic is tested through fakes. |
| F15 | The owner's Mac has no `~/Library/Mobile Documents/com~apple~CloudDocs` and no `~/Library/CloudStorage` [measured]. | `ls` | Sync cannot be exercised end to end here. Spikes need a Mac with iCloud Drive or Dropbox (T5b.9). |

### 1.2 Measurements that drive decisions

Corpus: 10 years, Monday to Friday, 2,609 day files of about 770 bytes each. Real pages with 100 to 300 words are larger, so scale CPU costs by 2 to 4 for them. Details and reproduction in Appendix A.

| What | Today | With the proposed design |
|---|---|---|
| `LogStore.listDays` (readdir only) | 6.7 ms | same |
| `LogStore.fileStates` (read and parse all) | 605 ms | not called at launch; stat diff of all files 26 ms; snapshot load from the cache 0.2 ms |
| `LogStore.search` | 1,086 to 1,192 ms | 2 to 3 ms candidates with `instr()` (13,045 sections), then verify |
| Cold index build (read, parse, fold, insert) | n/a | 1.5 s for 2,609 days (1.8 s with FTS5), in the background, newest first |
| Index size | n/a | 3.2 MB for folded section text only; 9.7 MB with an FTS5 trigram index on top (we do not need FTS5). Keeping the plain text for snippets and the raw body for reviews as well is about 7 MB (estimate). |
| `Streak.compute` | 11 ms | unchanged |
| `WeeklyReview.summary` for a week | 8.7 ms | unchanged |
| Sidebar months grouping | 65 ms per `body` at 10 y | 0.6 ms (group once) |
| Year roll-up by heading, SQL `GROUP BY` | n/a | 1.2 ms |

The PRD's M4 starts with "benchmark first; if the scan already meets M4-A1, build only off-main search". It does not: 1.1 s against the 300 ms target. The measured corpus has twice the pages and half the bytes of the PRD's 5-year corpus (about 1,300 pages of 500 words, roughly 3 KB each); the scan cost has a per-file part and a per-byte part, so the PRD corpus lands at roughly 1 to 2 s. Either way the scan misses by a factor of three or more, and the index is justified.

### 1.3 Environment facts

macOS 27.0.1 (26A434), arm64, Command Line Tools at `/Library/Developer/CommandLineTools`, SDK 27.0, `swiftc` 6.4. `notarytool`, `stapler`, `lipo`, `llvm-cov`, `llvm-profdata` are present; `codesign`, `ditto`, `hdiutil` are system tools. System SQLite 3.54.0 with FTS5 and the trigram tokenizer; `import SQLite3` compiles with plain `swiftc`. Frameworks present: PDFKit, WebKit, UserNotifications, ServiceManagement, Carbon, CoreServices, ImageIO. The deployment target stays macOS 13: the `-target arm64-apple-macos13.0` flag is the availability gate (anything newer needs `#available`), so CI must always build with it.

## 2. Alignment with the sibling documents

| Topic | PRD_V1 / DESIGN_V4 says | This TRD | Why |
|---|---|---|---|
| Milestones | M1 to M6, versions 0.4 to 0.9 | Adopted. M6 Sources is "M-later". Release work is M7 (PRD calls it a separate plan). | Same order, one vocabulary. |
| Future pages | Out of scope; future cells inert | Inert in the UI. `openDay` and `Status.resolve` already support them; hidden `allowFutureDays` flag, default off. | The brief asks the design to cover future days; the cost is near zero and the PRD stays true. |
| Text merging | M5b out of scope: "automatic text merging" | Not built. Conflicts are a user choice. A clean three-way merge for append-only conflicts is designed and deferred (L8). | Respect the PRD; keep the hook. |
| Settings file in the folder | PRD SYN-5: a small file in the log folder. UX_FLOWS 2.9: "a small hidden settings file" | `gloamlog-settings.json`: a non-dot name (T5b.8) with the file system hidden flag set, so Finder does not show it [verify, S-7]. | iCloud Drive is reported to skip dotfiles; the flag gives the hidden look without that risk. If the flag does not survive a provider, the file is merely visible. |
| Index | M4: benchmark first | Measured; the scan fails; index in M4; ScanIndex off-main in M1. | Section 1.2. |
| Settings window | PRD: `Settings` scene, fallback `Window` if `sendAction` fails. UX_FLOWS 4: system scene first, a plain `Window` if nothing appears within 300 ms [verify] | Explicit `Window("Settings", id: "settings")` is primary; ⌘, and every entry point call `openSettings(pane:)`. The system scene and its selector are dropped. If S-3 shows the system scene works, trying it first is a few lines in `openSettings`. | Deterministic from any button, no 300 ms probe, only macOS 13 APIs. |
| Folder watching | `DispatchSource` or `NSMetadataQuery` | FSEvents. | A directory `DispatchSource` sees entry changes, not in-place writes; `NSMetadataQuery` covers iCloud containers, not arbitrary folders. |
| PDF | PRD and UX_FLOWS 1.7: "Save as PDF" through WebKit `createPDF` | Print operation first, sliced `createPDF` as fallback; one spike decides (S-8, T3.06). The user-visible result is the same item, "Save as PDF…", with selectable text. | `createPDF` yields one tall page; the print path honours CSS page breaks. |
| Jots | `## Jots` at the bottom, `- 14:32 text`, hotkey ⌃⌥J, jots-only day shows the template above. UX_FLOWS adds: such a day reads "started" (◐) and stays in Catch up as "1 jot, not tidied" with [Tidy up]; text starting `[]` becomes a to-do | Adopted exactly; requires a words-rule input, a jot count, a write-time rule and the `[]` shorthand (D-D). | PRD M2-A2 to A4, UX_FLOWS 2.5 and 1.5. |
| Catch-up window | Default last 30 days | 30 (my first draft said 14). | PRD. |
| Vocabulary | UX_FLOWS D2: the UI says "unlogged", never "missed", "overdue" or "behind"; the session button is "Next unlogged day"; an empty week reads "Nothing logged this week yet." (the PRD said "missed" and "unwritten", DESIGN_V4 "not written") | Adopted in every user-visible string. In code the status case stays `.missed` (the existing test blocks pin it); new code says `unlogged`. | One word everywhere, no churn in tests. |
| Open range | UX_FLOWS 1.4: 1 Jan 2000 to today; a day before the log start opens and saves normally | `DayKey.isOpenable` is 2000-01-01 through today; with the hidden `allowFutureDays` flag on it extends to 2200-12-31. | My first draft allowed 1900 to 2200; the narrower range turns a typo date into a refusal instead of an empty page. |
| Log start date | UX_FLOWS 1.6: stored, default the first page's date, never moved by backfilling | Stored in `page.logStartDate`, fixed at the first snapshot that has a page (or by onboarding); `Status.resolve`, `Streak.compute` and `Heatmap.weeks` take it as `since`. | A derived date would shift whenever an older page is written (M1-A9). |
| Editor contract | UX_FLOWS 5.5 [Contract]: `appendToSection(heading, markdown)` beside `insertMarkdown` | Adopted, plus one optional flag, `unlessPresent`, that makes journal replay idempotent. It replaces my first draft's `keepHistory` option. | One transaction inside the section keeps caret, typing and undo without a text compare-and-swap loop (D-D). |
| Keep both | PRD and DESIGN 9: the other version under a labelled heading. UX_FLOWS 2.9: only the lines found only in the other version, under "From other copy (time)" | UX_FLOWS: `BothVersions.merge` is a line-level set difference and rewrites nothing else; every version also stays in safety copies. | Jots from two Macs are separate stamped lines, so they merge without loss and without a duplicated page. |
| Back up now, Restore from backup | UX_FLOWS 4: two untagged (M1) rows in Backup and restore | Deferred to L13 (8 h). Safety copies, "Copies per day" and Restore previous version stay in M1. Open question O-9. | Per-save safety copies already protect every page; a whole-folder copy is also possible in Finder. |
| Login item starts hidden | UX_FLOWS 4, General (an M1 row) | Moved to M5a: one launch-mode check (login item or notification launch means no window) is built in T5a.3 and decided by spike S-5; until then the login item behaves as in v0.3. | One mechanism serves both; the hours sit inside T5a.3 and T5a.4. |
| Settings export and import | Not in UX_FLOWS Advanced | Kept in Advanced (T1.18, 4 h). | The brief asks for it; it can be cut without touching anything else. |
| Evidence | Gate: real screenshots from the built app, no mockups; kill tests | Harness captures in-process (no Screen Recording permission); kill-test harness (T1.04). | Gate (a) and (b). |
| Day boundary | Not designed (design doc, open decision 5) | `dayStartsAtHour` supported in the clock, default 0, no UI until asked. | Audit G8; one line in the clock. |
| URL scheme, Services, Shortcuts action | M2 out of scope | Deferred (L5). | PRD. |
| Sources | M6 | D-I and L1 to L4, after all else. | Brief and PRD agree. |

## 3. Requirements

### 3.1 Technical requirements

| ID | Requirement | Traces to |
|---|---|---|
| TR-01 | Any day from 2000-01-01 to today opens (future days only behind the hidden `allowFutureDays` flag, up to 2200-12-31); opening never creates or rewrites a file. | NAV-1, INV-01, UX_FLOWS 1.4 |
| TR-02 | The "unlogged" baseline is a stored `logStartDate` (default: the first page, then fixed), not the earliest file; backfilling an older day never moves it and never changes Catch up or the streak. | CUP-3, M1-A9 |
| TR-03 | Catch-up, calendar marks, badge, streak, heatmap, Year table are computed from the snapshot; none reads a day file. | NAV-1, CUP-1, REV-2 |
| TR-04 | Batch skip writes one marker per scheduled day, never over writing, and is undoable. | CUP-2 |
| TR-05 | The main thread is never blocked more than 16 ms by index, search, export or sync work. | FND-1 |
| TR-06 | Launch to an editable today page does not depend on the number of days. | NFR |
| TR-07 | The index is a disposable cache outside the folder; deleting it changes nothing visible. | FND-2, INV-09 |
| TR-08 | Settings are typed, versioned, reset per pane, exportable and importable; old settings always load. | SET-1 to SET-5 |
| TR-09 | Settings opens in front in under 1 s from every entry point. | M1-A6 |
| TR-10 | Exactly one component writes day files. | INV-04 |
| TR-11 | A jot is durable (journal fsync) before the panel closes; at-least-once delivery. | CAP-2, CAP-5 |
| TR-12 | Jots do not count toward "logged" unless switched on; a jots-only day is "started" and stays in Catch up ("1 jot, not tidied"); it shows the template above its jots without writing it. | CAP-6, M2-A4 |
| TR-13 | The global hotkey needs no permission; conflicts are reported. | CAP-1 |
| TR-14 | The folder is watched; an untouched open page updates within 10 s of an external change. | SYN-2, M5-A6 |
| TR-15 | Non-local, partial or unreadable files are never read as empty, never overwritten. | SYN-4, INV-08 |
| TR-16 | Conflict copies are detected, shown and merged by appending only the lines found only in the other copy under "From other copy (time)"; extra files move to backups. | SYN-3 |
| TR-17 | Saves are compare-and-swap; a mismatch pauses autosave for that page and offers keep mine, take theirs, keep both. | SYN-2 |
| TR-18 | Writes are temp file in the same folder, fsync, rename. | INV-03 |
| TR-19 | Closed-app reminders are macOS notification requests for the next 14 scheduled days, re-planned on every relevant change. | REM-1, REM-2 |
| TR-20 | Review periods: week, month, year, range; counts; group by day or section; Jots separate. | REV-1 |
| TR-21 | Export: Markdown with only the images used, PDF with selectable text, Share; skipped days and Jots toggles. | EXP-2 to EXP-4 |
| TR-22 | Search first results within 300 ms (p95, warm) on 5 years; usable while indexing; partial results labelled. | FND-1, FND-2 |
| TR-23 | Sources are off by default, read-only, suggestions only. | AUT-1 |
| TR-24 | No network API outside one opt-in file (later); a CI guard enforces it. | XC-1 |
| TR-25 | Builds with Command Line Tools, Swift 5 mode, macOS 13 target, no macros, no dependencies; CI proves it with a CLT-only job. | XC-3 |

### 3.2 Non-functional requirements

- **Compatibility.** macOS 13+; `ObservableObject`, `@StateObject`, `Box<T>`, `@FocusState`, `@AppStorage` only (no `@State`, `@Observable`, `#Preview`); the folder format stays additive (INV-13).
- **Privacy.** No network, no telemetry. New local data: the index (text of your logs, same sensitivity as the logs and backups; directory 0700, files 0600, excluded from Time Machine, deletable, can be disabled), the capture journal (pending notes, 0600), a recovery spill (only when a save fails). Exports go only where the user chooses.
- **Safety.** Section 6.
- **Performance.** Section 7.
- **Accessibility.** Every new control has a label and an `accessibilityIdentifier` (the harness presses by it); state is never colour alone; Reduce Motion honoured [DESIGN 12, 13].
- **Testability.** Section 8: every new rule in `app/Core` has a test that runs headless; UI behaviour is exercised by the scenario harness; sandbox-safe subset exists.

## 4. Decisions

Each decision gives context, the choice, the alternatives with a verdict, risks, and consequences. The module, type and file plan, formats and migration steps for each are in `docs/v1/ARCHITECTURE.md` section 5 under the same letter.

### D-A. Date index and calendar data model

Tasks: T1.06, T1.08, T1.09, T1.12 (M1); T4.01 to T4.03 (M4). Hours: 54.

**Context.** The calendar, catch-up list, badge, streak, heatmap and Year table need a status for every day for 10 or more years. Today that costs a full read and parse (F1) and an O(n²) sidebar (F3). Evicted cloud files would be downloaded by reading them. The log folder must stay the only source of truth.

**Decision.**
1. Hold a value type in memory: `DayIndexSnapshot`, a dictionary of `DayRecord` (day, kind log or skip, availability local, stub, dataless or unreadable, size, content hash, `words`, `jotWords`, `jotCount`, `hasContent`, skip reason, 140-character preview, conflict count) plus a sorted day list and months grouped once. About 0.5 to 1 MB at 10 years. Status for any `minWords` and Jots setting is derived on read, so changing the rule never re-parses a file.
2. Two producers behind one protocol, `DayIndexing`. `ScanIndex` (M1): today's scan, moved off the main thread, tagged with a generation so a stale result cannot overwrite a fresher one. `SQLiteDayIndex` (M4): the same snapshot loaded from a cache in 0.2 ms. A parity test runs both over the same corpora and requires identical states and hits.
3. The cache is SQLite through the system library (`import SQLite3`), at `~/Library/Application Support/Gloamlog/index/<folder-hash>/index.sqlite`, outside the folder. Tables: `days`, `sections` (heading, normalised heading, plain text, folded text), `tasks`, `conflicts`. A row is current when the file's size and mtime match (a cheap pre-filter); any difference sends the file through a content-hash comparison, and the hash decides whether the row changed. A change that keeps both size and mtime is invisible until the watcher (M5b) or "Rebuild search index" sees it. A `parser` column forces re-parse when `MarkdownBody` rules change.
4. Invalidation triggers: launch (stat diff of all files, 26 ms at 2,609 days), the 30 s tick (stat diff only, off the main thread), the folder watcher (M5b) with the sweep relaxed to 5 minutes, app activation, the app's own saves (`noteLocalWrite`), folder change, parser or schema version bump, and a manual "Rebuild search index".
5. The 30 s tick no longer parses files on the main thread. It advances the clock and runs the stat diff on `dl.index` (26 ms at 10 years; a file is parsed only if its size or mtime changed), which keeps UX_FLOWS 2.9's "re-read every 30 s" true. With the watcher on (M5b) the sweep relaxes to 5 minutes.
6. Calendar: `MonthGrid` is a pure function from a snapshot to 6x7 cells; `since` for `Status.resolve`, `Streak.compute` and `Heatmap.weeks` becomes the stored `logStartDate` (PRD CUP-3, D-B 6); months are grouped once per snapshot generation, not in `body`.
7. Cold build runs in the background, newest first, in chunks of 100 days, publishing a snapshot after each chunk. The indexer never reads stub or dataless files; it keeps their last-known row.

| Alternative | Verdict | Reason |
|---|---|---|
| Keep scanning on the main thread (today) | Rejected | 605 ms per call at 10 years, every 30 s, and it hydrates evicted files. |
| Scan off-main, memory only | Used for M1 (`ScanIndex`), and as the fallback if SQLite cannot open | Fixes stalls cheaply; every launch still pays about 0.6 s CPU at 10 years and still reads evicted files. |
| JSON or plist sidecar | Rejected | Parse and rewrite O(n) per change; no queries; hand-rolled invalidation. |
| Index inside the log folder | Rejected | It would sync between Macs and conflict with itself; adds a hidden file iCloud may skip [verify]; breaks INV-13. |
| Core Data, SwiftData | Rejected | Model compiler and macros are not in Command Line Tools. |
| Spotlight (`NSMetadataQuery`, `mdfind`) | Rejected as the source | Depends on the user's Spotlight settings, cannot see dataless text, knows nothing of headings or word counts. |
| SQLite with FTS5 | Rejected for now | `instr()` over folded text already answers in 3 ms at 13,045 sections; FTS5 triples the file (9.7 MB against 3.2 MB). Upgrade path kept (L10). |
| SQLite tables with `instr()` | Chosen | Compiles with plain `swiftc` [measured]; snapshot load 0.2 ms; build 1.5 s at 10 years; also serves reviews and search. |

**Risks.** Corruption or schema drift: any open error deletes and rebuilds, and `ScanIndex` serves meanwhile. The cache duplicates log text: same sensitivity as the logs and their backups; 0700 and 0600, excluded from Time Machine, deletable and switchable in Settings, Storage and sync. SQLite's C API is verbose: one 150-line wrapper. Older system SQLite on macOS 13: only core SQL (`instr`, `GROUP BY`) is used and a runtime probe falls back to the scan. A WAL left behind by a crash: the cache is disposable and `PRAGMA quick_check` failure triggers a rebuild.

**Consequences.** Launch time no longer depends on corpus size (TR-06). INV-09 gets a test that proves it. M4's work shrinks to swapping the producer, because M1 already moved the UI onto the snapshot.

### D-B. Opening and creating any day; catch-up; batch operations

Tasks: T1.10, T1.11, T1.13 to T1.15 (M1). Hours: 29 (plus the calendar share of D-A).

**Context.** `AppModel.openDay` already accepts any well-formed date and `DayEditor` writes only on a real edit (F5). The missing parts are a door (calendar, Go to date), a definition of "unlogged", and a way to clear a backlog fast. PRD scope: any date up to today; future pages out of scope.

**Decision.**
1. Navigation per DESIGN section 1 and 3: calendar in the sidebar (one-week strip under 640 pt height), toolbar Previous, Today, Next, Go to date (⇧⌘T), ⌘[ and ⌘] step calendar days, not days with files. `Destination` gains `.catchUp(CatchScope)`, `.session(CatchSession)`, `.review(ReviewScale, Date)`.
2. `DayKey.isOpenable(_:)` bounds days to 2000-01-01 through today (UX_FLOWS 1.4), or through 2200-12-31 when `allowFutureDays` is on; a key outside that range still opens when a page for it exists (an old or future-dated file stays reachable from search). The bound guards typo dates without restricting real use. Opening writes nothing (INV-01), including a day before the log start, which opens and saves normally and shows "Before your log start. It won't appear in Catch up."
3. "Unlogged" is a pure function, `CatchUp.missing(snapshot:today:options:calendar:)` (the function keeps its name, the UI word is "unlogged"): a day is listed if it is a scheduled weekday (`settings.weekdays`, the same set the streak uses), on or after `logStartDate`, inside the window, before today, and neither logged nor skipped. Started-but-short days are listed with "11 of 20 words"; a day with only jots is listed as "1 jot, not tidied" with [Tidy up], which opens the page at its Jots heading. Default window 30 days; options 14, 30, 60, 90 or since log start; older days collapse under "Older".
4. `CatchSession` walks the list oldest first and wraps once. The session bar button is "Next unlogged day" on ⌘↩, and ⌥⌘↓ is bound as well because the editor may swallow ⌘↩ [verify, T1.14]. It flushes the editor before advancing, keeps a day in the list if it is still under the minimum, never moves by itself, and ends on "All caught up. 3 logged, 1 skipped."
5. Batch skip: `LogStore.skipDays(_:reason:)` writes one marker per day, refuses any day with writing (`.hasContent`), and returns written and refused. The UI keeps an in-memory undo for 8 s (DESIGN 4) that calls `unskip` on exactly those days.
6. `logStartDate` is stored, not derived (UX_FLOWS 1.6). `page.logStartDate: String?` is nil only until the first snapshot that has a page (or onboarding, or the first page written) fixes it to that page's date; backfilling an older day afterwards never moves it. `Status.resolve`, `Streak.compute` and `Heatmap.weeks` take it as `since`, replacing `states.keys.min()`. Days before it are `.off` for Catch up and neutral for the streak but still open, save and show their mark in the calendar, so backfilling an old day never creates a wall of unlogged days (M1-A9). The upgrade from v0.3 fixes it to the earliest page on first launch. Settings > Page offers [Move earlier…] and [Start fresh from today].
7. Future pages: supported by the core (`Status.resolve` returns `.future`); calendar cells stay inert per PRD; flag `allowFutureDays` (hidden, default off) enables them for later. Future pages are never counted and never used by carry-over.
8. `dayStartsAtHour` (0 to 6, default 0) shifts the effective "now" in one place, so night-owl writing at 00:40 stays on the same day. No UI until requested (audit G8).
9. The calendar is re-read on `NSSystemTimeZoneDidChange` (F11): `AppModel.cal` becomes a computed auto-updating calendar.
10. **Today line** (`catchUp.todayLine`, default on): one dismissible line per day while days are unlogged, fed by the same `AppModel.catchUp` list as the badge. When exactly one day is unlogged and it is the previous scheduled day: "You haven't logged Thu 8 Oct." with [Write it] and [Skip day]; otherwise "You have 5 unlogged days." with [Catch up] and [Later]. A due reminder notice outranks it (UX_FLOWS 2.6, rule a).
11. **A Strict re-open never navigates away** (UX_FLOWS 2.6, rule b). Today `AppModel+Reminders.swift` `perform(.bringToFront)` calls `openDay(today, focus: true)`, which would pull the user out of a catch-up session or a half-written page. It becomes "bring the window forward once, show the reminder notice, move nothing". `ReminderPlanner.decide` and its tests are untouched; only the executor changes (folded into T1.14).

| Alternative | Verdict | Reason |
|---|---|---|
| A separate weekly note file | Rejected | PRD Q2: a week is a view over days. |
| "Write the week" scratch page that splits into day files | Deferred (L9) | A pure splitter plus a preview is cheap, but the walk-through already meets "3 days in 2 minutes". |
| Create empty marker files for unlogged days | Rejected | Breaks "never create a file without a real edit", pollutes a synced folder. |
| Derive "unlogged" from file mtimes | Rejected | Unreliable across sync and restores. |
| Open only days that have files, plus a date picker | Rejected | That is the v0.3 failure with a picker bolted on. |

**Risks.** A new user with an old log sees a wall of unlogged days: mitigated by the stored log start date and the window. A stray old file (a page for 2019 by mistake) fixes the log start too early: the Settings > Page controls and the onboarding picker exist for that. DST and time zones: all stepping goes through `DayKey` (calendar based), INV-18 forbids `86400`. A changed `weekdays` set re-evaluates history (existing rule, UX_SPEC 3.3).

**Consequences.** Catch-up, badge, notice, Week fixes and the calendar share one list; the Year table and Review counts reuse the snapshot.

### D-C. File watching and shared-folder sync

Tasks: T5b.1 to T5b.7, T5b.9, T5b.10 (M5b). Hours: 59 (T5b.8 portable settings counts under D-F).

**Context.** The owner will use iCloud Drive or Dropbox. Providers add stubs, dataless files, partial downloads and conflict copies, and change files under a running app. Today: polling, dotfile blindness, last-writer-wins (F8, F9, F10). The owner's Mac has no cloud folder to test with (F15).

**Decision.**
1. **Watch** with FSEvents file-level events on the storage folder, coalesced for 300 ms. Event flags are not trusted: after the debounce the path is stat-ed. A polling source (30 s stat sweep, 26 ms at 10 years) is the fallback for network volumes and for when `FSEventStreamStart` fails. "Rescan folder" is always available.
2. **Classify every name once** (`FileNameClassifier`): day file, iCloud stub (`.name.md.icloud`), conflict copy (iCloud "name 2.md", Dropbox "conflicted copy", Syncthing "sync-conflict", generic day-prefix), temp, asset, other. Conflict copies stop being "unrecognised".
3. **Never read what is not local.** Stub files and files flagged `SF_DATALESS` are not read by the indexer; their last-known row stays and the day shows an "in iCloud" mark. Opening one asks the system to download it (`startDownloadingUbiquitousItem`, or a bounded background read) with a 20 s watchdog; the page is read-only until local; `LogStore.save` refuses with `LogError.notLocal`. "N days are still in iCloud" with Download all [PRD M5-A9].
4. **Settle before reading.** A changed path must show the same size and mtime on two checks 200 ms apart (maximum 5 s) before it is parsed. A zero-byte or non-UTF-8 file is `unreadable`: the last good row is kept, it is never treated as an empty day and never overwritten.
5. **Atomic, durable writes.** Temp file in the same folder with a dot-prefixed unique name, `F_FULLFSYNC`, `rename`. The temp name can never be a day name (INV-03).
6. **Compare-and-swap saves.** `LogStore.save(day:body:expecting:)` compares the file's current size and content hash with what the page was built from. On mismatch `PageSync` enters Conflicted: autosave is paused for that page, its text is spilled to a local recovery file, and a banner ("This page changed on another Mac while you were writing.") offers Keep mine, Take theirs, Keep both [DESIGN 9, UX_FLOWS 2.9]. Keep both adds only the lines found only in the other version under "From other copy (4:40 pm)" (`BothVersions.merge`, a line-level set difference; nothing else is rewritten). Both versions are backed up first. An untouched page reloads quietly within 10 s with "Updated from another Mac. [Undo]" [PRD M5-A6].
7. **Conflict copies**: detected by name and listed (Settings row, sidebar chip, launch notice "1 conflict in ~/Gloamlog. [Review…]"). The review sheet shows "This Mac, 5:02 pm, 63 words" beside "Other copy, 4:40 pm, 71 words" with the differing lines marked, and offers [Merge both] (the same `BothVersions.merge`), [Keep this Mac's] and [Use other copy]; whichever is chosen, the extra file moves to the backups folder, never deleted [PRD M5-A7, UX_FLOWS 2.9].
8. **No automatic text merging in v1** (PRD). The three-way merge for append-only conflicts is designed (`CollectionDifference` based, small) and deferred as L8, so the hook exists.
9. The synced folder holds only `YYYY-MM-DD.md`, `assets/<day>-<hex>.<ext>` and, from M5b, `gloamlog-settings.json`. No hidden files.
10. **Folder kind** (local, iCloud Drive, CloudStorage provider, network, removable) selects the watcher mode and warnings; "Verify folder" reports zero-byte, non-UTF-8, stubs, conflict copies, unrecognised names and a write test.

| Alternative | Verdict | Reason |
|---|---|---|
| `DispatchSource` on the directory | Rejected | Sees entries added, removed or renamed, not in-place writes by editors and sync daemons. |
| `NSMetadataQuery` | Rejected | Built for iCloud containers and Spotlight scopes, not arbitrary provider folders. |
| Polling only | Fallback | 26 ms per sweep is cheap, but latency; used when FSEvents is unavailable. |
| FSEvents | Chosen | File-level events on local volumes, including iCloud Drive and CloudStorage [verify]. |
| `NSFileCoordinator` around every read and write | Partly | Used where it matters (hydrating an iCloud path); plain atomic rename for writes, like other plain-file editors. Revisit if the spike shows partial reads. |
| Automatic merge of conflicting text | Deferred | PRD excludes it; formatting normalisation between editors would also cause false conflicts. |
| CRDT or operational transform | Rejected | Wrong size for one person and plain files. |
| A Gloamlog sync service | Rejected | Product "will not do" list. |

**Risks.** Provider behaviour differs by macOS release and provider; the owner's Mac cannot reproduce it, so M5b ships against fakes plus a spike on a Mac with iCloud Drive and Dropbox [verify]. FSEvents cannot start in the agent sandbox (F14), so real-watcher tests run in a normal terminal. Editor normalisation: the page loaded from a legacy-formatted file differs from the file even before the user types, so comparisons are against the file as loaded (`diskBody`), not the normalised editor text. An emptied page deletes its file and the deletion syncs; mitigation is the existing backup before delete, which is per Mac.

**Consequences.** The 30 s polling in `DayEditor.checkExternalChange` becomes a fallback. `PageSync` (D-D) carries the conflict states, so they are testable without a window.

### D-D. Quick capture and the single-writer model

Tasks: T2.01 to T2.05 (M2). Hours: 54.

**Context.** PRD M2: a global key opens a panel, Return appends `- 14:32 text` under `## Jots` at the end of today's page, safe while the page is open and when the window is closed (the app must be running), notes survive an unavailable folder. Jots do not count as logged by default and a jots-only day shows the template above them without writing it; it reads "started" and stays in Catch up as "1 jot, not tidied".

**Decision.**
1. **One writer.** Only `DayEditor` (autosave), `DayWriter` (captures, journal replay) and the existing `AppModel+Day` actions (skip, unskip, restore) call mutating `LogStore` APIs. A static test enforces it (INV-04). Everything runs on the main thread; background code only reads.
2. **Routing** (`DayWriter.route`):

| State of the target day | Route |
|---|---|
| An editor exists for the day (current or orphan) and is loaded | `bridge.appendToSection(token, heading: "Jots", markdown: line, unlessPresent: true)`: one editor transaction inside the section, so caret, selection, text typed a moment ago and undo are untouched. The call returns the normalised page, which `PageSync` takes as a programmatic edit; autosave then writes it. A stale token (the page was swapped meanwhile) re-routes once; after that the note stays in the journal. |
| An editor exists but is not loaded yet | Queue in `DayEditor.pendingAppends`; applied right after `didLoad`. |
| No editor for the day | Read the file, apply the placement, `LogStore.save(expecting:)`, retry on mismatch. |
| Folder unwritable, not local, or stale | The journal entry stays; "1 note waiting" in the UI; retried on folder return, activation, wake and launch. |

   **Why `appendToSection`.** `setMarkdown` calls Milkdown's `replaceAll(text, true)`, which builds a new `EditorState` and so clears the undo stack [code: `editor-web/src/main.js`, `@milkdown/utils`]; PRD M2-A3 requires that undo still works after a capture. A whole-text replace with compare-and-swap (my first draft: `replace(expecting:, keepHistory:)`) would work, but it needs a retry loop whenever the user types between the read and the replace, and it cannot join the existing jots list. UX_FLOWS 5.5 asks for the better primitive: `appendToSection(heading, markdown)` finds the section in the live ProseMirror document, adds the list item at its end (joining the last list when there is one, creating the heading at the end of the page when there is none), dispatches one transaction that maps the selection and stays in the undo history, and returns the normalised markdown. It is additive, it is the only editor-contract change in v1, and it removes the retry loop: the remaining failure modes are "editor not loaded" (queue) and "token stale" (re-route once). `insertMarkdown(.end)` is not used for capture because it cannot join the list.
3. **Journal.** `CaptureJournal` appends one JSON line per note to `~/Library/Application Support/Gloamlog/capture/journal.jsonl` (0600, `O_APPEND`, `F_FULLFSYNC`) before the panel shows "Added". An entry is acknowledged only after a save whose text contains the rendered line succeeds. Replay at launch is at-least-once; an identical line already present in the target section is not added twice.
4. **Jots rules.** `MarkdownBody` recognises a "Jots" block (heading, any level, runs to the next heading of the same or higher level; a leading `HH:mm` is not a word). The words rule gets a second count: `words` excludes Jots, `jotWords` counts them, `jotCount` counts the lines, and `jotsCountTowardLogged` (default false) decides. A write-time rule strips an untouched template when the only other content is the Jots block, so a jots-only day is written as `## Jots` plus bullets; `DayEditor` shows the template above them without marking the page edited (M2-A4). A jots-only day is "started" (`.partial`) whatever the switch says (UX_FLOWS 1.6), and `CatchUp` lists it as "1 jot, not tidied". Text that starts with `[]` is written as `- [ ] text` without a time stamp (`capture.todoShorthand`, default on); continuation lines are indented two spaces.
5. **`PageSync`.** The decision logic of `DayEditor.write`, `userChanged`, `programmaticEdit`, `checkExternalChange` and `finish` moves into a pure state machine in `app/Core` (events in, actions out); `DayEditor` becomes the adapter that executes actions and feeds results back. It is the safest place for the new capture and conflict states and the only way to fuzz the interplay without a window (T2.04).
6. **Hotkey.** Carbon `RegisterEventHotKey`: no Accessibility or Input Monitoring permission, because it does not observe keystrokes. Default ⌃⌥J [PRD], recorder in Settings, Shortcuts, conflicts reported (`eventHotKeyExistsErr`), combinations without ⌘ or ⌃ refused (⌥-only combinations were restricted on newer macOS [verify]).
7. **Panel.** `NSPanel` subclass, `.nonactivatingPanel`, `.fullScreenAuxiliary`, `.canJoinAllSpaces`, level `.floating`, hosting a SwiftUI view [DESIGN 8, 14]. Menu-bar popover gets a Jot field; Page menu gets "Jot...".

| Hotkey mechanism | Permission | Verdict |
|---|---|---|
| Carbon `RegisterEventHotKey` | none | Chosen. |
| `NSEvent.addGlobalMonitorForEvents` | Accessibility and Input Monitoring | Rejected: a prompt, and it cannot consume the event. |
| `CGEventTap` | Input Monitoring | Rejected. |
| A shortcut the user assigns in System Settings to a Service or to a Shortcuts action | none | Zero-code fallback; Services and URL scheme are L5. |
| Menu-bar Jot field | none | Also built (PRD CAP-4). |

| Writer model alternative | Verdict | Reason |
|---|---|---|
| Capture appends to the file on disk and the editor reloads | Rejected | Races with autosave; the editor's version silently erases the note (the research doc's W1). |
| Capture goes only through the editor | Rejected | Needs a loaded editor; fails when the window is closed or the page is not today's. |
| An inbox file read by the app (external-process model, research doc D6) | Reserved for external processes (L14) | The journal is the same idea for in-process capture; the record shape is compatible. |
| Route by state (chosen) | Chosen | One writer, no race, works with the window closed. |

**Risks.** Panel focus and Spaces behaviour in full-screen apps [verify, S-4]. A note undone within 0.6 s of capture, before its save is acknowledged, is added again by replay at the next launch (accepted). A crash between the file write and the journal acknowledgement duplicates a note once (accepted: at-least-once beats loss). The editor-contract change needs a rebuild of the committed bundle (`npm ci --ignore-scripts && npm run build` in `editor-web`; Node is needed only for this task) and a bridge check that undo still works after an append. A page whose Jots heading was renamed by hand gets a new `## Jots` section at its end and the old one stays as written (accepted).

**Consequences.** Conflict handling (D-C) and capture share `PageSync`, so one fuzz suite covers both. The "Jots" convention changes the words rule, which touches the index schema (D-A: two word counts and the jot count).

### D-E. Reminders that fire when the app is closed

Tasks: T5a.1 to T5a.4 (M5a). Hours: 20.

**Context.** `Notifier.post` fires immediately and only while the process runs (F7). The PRD wants the end-of-day reminder to arrive with the app quit, cancelled when the day is logged or skipped, with Open, Snooze and Skip actions, "Next reminder" shown in Settings, and honest limits (Mac asleep, Focus).

**Decision.**
1. Keep `ReminderPlanner.decide` for the running app (Strict re-open, snooze counts). It stays pure and tested.
2. Add `ReminderScheduler` (pure): from now, settings and the snapshot it plans a request for each of the next 14 scheduled days that is not logged or skipped and whose fire time is in the future, and, if the morning notification is on (default off), a request on scheduled mornings that says "You have N unlogged days", with N projected from today's count plus the scheduled days that will have passed. A pure `NudgeState` (nudges sent since the last visit to Catch up) implements UX_FLOWS 2.6 rule (c): after three nudges in a row with no visit to Catch up, only Mondays are planned until Catch up is opened. Notification text never holds page text or streak numbers (rule e). Stable identifiers (`gl.rem.<day>.eod`) make re-planning idempotent; a diff against `getPendingNotificationRequests` adds and removes the minimum.
3. Re-plan on launch, wake, settings change, day change, time-zone change, save, skip and unskip, a file appearing for today (watcher), and a notification-permission change.
4. The running app posts its own immediate notification with the same identifier, which replaces the pending calendar request, so there is one notification.
5. Click opens the app on the notification's day (`userInfo`). The delegate is set before `applicationDidFinishLaunching` returns, so a launch caused by a click still delivers the response.
6. Actions: Open (foreground), Snooze, Skip today. Handling them with the app closed depends on macOS launching it in the background and on suppressing the SwiftUI window at launch [verify, T5a.4]. The same launch-mode check makes the login item start hidden (UX_FLOWS 4, General: "starts it hidden so reminders and jots work after a restart"). Fallback: Snooze becomes a pre-scheduled follow-up request, Skip today stays in-app.
7. Strict while closed (forcing a window) is Could and needs a launch helper (L7), deferred.

| Mechanism | Works with app quit | Works after reboot | Signing and permission | Verdict |
|---|---|---|---|---|
| Rolling `UNCalendarNotificationTrigger` requests | yes (delivered by the system) | yes if the system keeps pending requests [verify] | Notification permission; bundle identifier; app in /Applications [verify for ad-hoc] | Chosen. |
| LaunchAgent via `SMAppService.agent` running the app binary with `--remind-check` | yes | yes | Needs Login Items approval; shows as "unidentified developer" when ad-hoc [verify]; same bundle id keeps notification permission | Deferred (L7): only adds "check the file at fire time". |
| Login item (`SMAppService.mainApp`, exists) | only while the app stays running | yes if enabled | Approval | Kept, opt-in; complements the above. |
| Hand-written plist in `~/Library/LaunchAgents` | yes | yes | Probably triggers a Background Items notice [verify] | Rejected: duplicate of `SMAppService`. |

**Limits stated in the UI.** A notification scheduled on this Mac fires even if you logged the day on another Mac while this app was closed (the app cancels it only when it runs and sees the file). Nothing fires while the Mac sleeps (it arrives on wake [verify]); Focus can silence it; the schedule runs out after 14 scheduled days without opening the app.

**Risks.** Ad-hoc signing and notification authorisation (bundle identity, translocation, /Applications requirement) [verify, T5a.4 on the owner's Mac, the PRD's parallel spike]. Time-zone travel with a request already scheduled: re-plan on the zone-change event while running.

**Consequences.** `Notifier` moves to `app/Platform` and gains a small protocol so scenarios can replace it with a recorder.

### D-F. Settings architecture

Tasks: T1.16 to T1.18 (M1), T2.06, T5b.8. Hours: 34.

**Context.** `Settings` is a flat Codable struct with hand-written tolerant decoding, stored as JSON in `UserDefaults` under `dailylog.settings.v2`, no version number, about ten fields. Extras live in `@AppStorage` and plain defaults keys (`showMenuBar`, `yesterdayExpanded`, `dailylog.whatsNew.0.3`). Tunables are constants (F6). The Settings scene is opened by a selector the PRD doubts works.

**Decision.**
1. **Keep the flat legacy fields** (`reminderMinutes`, `weekdays`, `mode`, `snoozeMinutes`, `storageFolder`, `launchAtLogin`, `template`, `carryOverHeadings`, `minWords`, `onboarded`) exactly as they are: zero churn in about 20 call sites and the 51 test blocks. **New settings live in one nested group per pane** (`general`, `reminders`, `page`, `catchUp`, `appearance`, `capture`, `sync`, `backup`, `notifications`, `sources`, `advanced`), each with its own tolerant decoder. View state such as the review scale or the export format stays in plain remembered `UserDefaults` keys (section 5), not in `Settings`.
2. Add `schemaVersion` inside the JSON (missing means 2, the shipped format). Same storage key, so no key migration and downgrade is safe (old builds ignore unknown keys). `SettingsMigrator` runs ordered steps on the decoded dictionary before decoding; frozen JSON fixtures of every shipped version guard it (INV-15).
3. A **field table** (`SettingsField`: key, pane, scope portable or machine, label, getter as string, reset closure) is the single source for per-pane reset, export, import preview diff and the catalogue in section 5. A test checks every field has a pane, a default and a round trip.
4. **Panes** follow DESIGN 7: General, Reminders, Page, Appearance, Storage and sync, Backup, Shortcuts, Sources (hidden until M6), Notifications, Advanced, About. `model.settingsPane` is the tab selection.
5. **Opening**: an explicit `Window("Settings", id: "settings")` scene is primary. Every entry point (gear in the sidebar footer, ⌘, through `CommandGroup(replacing: .appSettings)`, menu-bar popover, page menu, Dock menu, banner and chip links) calls `model.openSettings(pane:)`, which sets the pane and opens the window through a stored `openWindow` closure (as `openWindowAction` already does for the main window). The `Settings` scene and the `showSettingsWindow:` selector are dropped.
6. **Effects**: `SettingsEffects.diff(old, new)` returns the side effects (re-plan reminders, reload states, refresh carry-over, reload an untouched page, re-register the hotkey, apply activation policy and appearance, restart the watcher); `AppModel.settingsChanged` applies them. This replaces the inline conditions in `AppModel.settingsChanged(old:)`.
7. **Export and import**: JSON envelope with `format`, `schemaVersion`, `exportedAt`, `app`, `portable`, optional `machine`. Import validates, shows a diff, applies atomically, never changes the storage folder or turns on a network feature (INV-14). Machine-specific values (folder, login item, menu bar, Dock, hotkey, "Remind on this Mac", index) never travel through the folder file (M5b) and are excluded from export unless ticked.
8. `UserDefaults` stays the store (already abstracted by `KeyValueStore`/`MemoryStore` for tests).

| Alternative | Verdict | Reason |
|---|---|---|
| Fully nested, versioned rewrite of `Settings` | Rejected | Churn in call sites and tests for no user value. |
| One flat struct, keep growing | Rejected | About 70 fields, no per-pane reset, no groups to decode tolerantly. |
| JSON file in Application Support instead of `UserDefaults` | Rejected | Loses cfprefsd caching and the `KeyValueStore` test seam; export/import already gives a file. |
| SwiftUI `Settings` scene plus `showSettingsWindow:` | Rejected | Unreliable selector (PRD, DESIGN 14); cannot be opened from arbitrary code on all macOS releases. |
| Settings in the log folder (all of them) | Rejected | Machine-specific values would fight each other; only portable ones travel (D-C, M5b). |

**Risks.** Eleven toolbar tabs may overflow the window [DESIGN 7, verify]; the pane list is data, so shortening a title is trivial. A changed `Window` scene must not break ⌘, muscle memory: the command is rebound, not removed.

**Consequences.** Every constant in F6 becomes a setting with a default equal to today's value, so behaviour does not change until the owner changes it.

### D-G. Review roll-ups and export

Tasks: T3.01 to T3.06, T4.06. Hours: 55.

**Context.** Today only a week exists (`WeeklyReview.summary`, 2 test blocks with about 30 checks) and the clipboard is the only output (D10 in the audit). PRD M3: Review for week, month, year and range with counts, grouped by day or section, Jots separate; Year view of 12 months; Copy as Markdown, Plain or Rich; export Markdown with only the images used, PDF with selectable text, Share; toggles for skipped days and Jots.

**Decision.**
1. `PeriodReview` (pure) takes a period, a `SectionProvider`, the snapshot and settings and returns counts (scheduled, logged, started, skipped, unlogged, words), heading groups in template order plus "Jots" and "Other notes", per-item dates, and task statistics. `.week` delegates to the existing `WeeklyReview` so its tests keep pinning behaviour; the new month, year and range code gets its own tests. The provider reads files in M3 and the index in M4 (T4.06).
2. Roll-ups come from headings and tasks. Headings: `MarkdownBody.partition` already splits a page by owning heading. Tasks: `contentLines` already reports `checked`. Completed = checked tasks outside carried-over blocks, plus checked tasks inside them (completed that day); open at the end = unchecked items under the carry-over headings on the last logged day of the period; duplicates removed with `itemKey`.
3. The Year view uses the snapshot only (counts per month): no file reads, instant. Month and range read at most a month or a year of pages (about 60 ms for 260 pages, extrapolated from 605 ms per 2,609 pages).
4. `MarkdownHTML` is a small renderer for the Markdown the editor writes (EDITOR_CONTRACT, "Markdown it writes"): ATX headings, paragraphs, bullet, ordered and task lists, quotes, fenced code, rules, GFM tables, bold, italic, strike, code, links, images. Everything is HTML-escaped; only http, https and mailto links survive; images resolve through `AssetStore.resolve` and are embedded as `data:` URIs (downscaled with ImageIO) for HTML and PDF, and stay relative for Markdown exports.
5. Copy formats on any page or review: Markdown, Plain (markers stripped), Rich (`public.html` plus RTF derived from it, with the Markdown as the plain-text flavour, so chat boxes and plain editors paste Markdown while Mail and Notes paste formatted text; UX_FLOWS 1.7). Toggles: skipped days (on), Jots (off).
6. Export: a single Markdown file plus an `assets/` folder holding only referenced images; a zip made with `/usr/bin/ditto -c -k --keepParent` whose layout is a valid Gloamlog folder (day files at the root, `assets/` beside them) so relative links work and Gloamlog can open it; PDF through a `WKWebView` print operation to a file; Share through `NSSharingServicePicker` on a lazily written temporary file, so nothing is written until chosen.

| Alternative | Verdict | Reason |
|---|---|---|
| Own `MarkdownHTML` | Chosen | About 250 lines, deterministic, Core-testable, escapes everything. |
| `AttributedString(markdown:)` to RTF | Rejected as the only path | Inline styling only; headings and lists arrive as intents we would have to draw ourselves. |
| Render through the editor bundle in a second web view | Rejected | Runs the 1.1 MB bundle again; not testable headless. |
| `WKWebView.createPDF` only | Fallback | One tall page unless sliced; slicing cuts through lines. |
| Print operation (`WKWebView.printOperation`) | Chosen, after a spike | Honours CSS page breaks and real pagination. |
| Third-party PDF or zip libraries | Rejected | No dependencies. |
| `ShareLink` | Acceptable | Picker chosen for programmatic file URLs; DESIGN allows either. |

**Risks.** A print operation needs a window and can stall headless: the spike (T3.06) sets timeouts and the fallback. Hostile Markdown in exports: tests with script tags, `javascript:` links and raw HTML. Large images: downscaled. Export failures show "Couldn't save ... Try again" [DESIGN 5].

**Consequences.** The same HTML path feeds Rich copy and PDF. The review core stays pure; the provider hides where text comes from.

### D-H. Search at scale

Tasks: T4.04, T4.05. Hours: 20 (index work counts under D-A).

**Context.** A query costs 1.1 s at 10 years and runs on the main thread (F2). PRD M4-A1: first results within 300 ms (p95, warm) on 5 years, no main-thread block over 100 ms.

**Decision.**
1. Candidates come from the cache: `SELECT day, ord, ... FROM sections WHERE instr(folded, ?) > 0 [AND instr(...)]... [AND day BETWEEN ? AND ?] [AND norm IN (...)] ORDER BY day DESC, ord LIMIT 2000`. Words are folded exactly as at index time (`folding(options: [.caseInsensitive, .diacriticInsensitive])`) and AND-ed per section, matching today's rule (the heading text counts). 2.6 to 3.1 ms at 13,045 sections [measured].
2. Verify and snippet with the existing matcher, refactored to take sections (`Search.hits(day:sections:query:heading:)`), so `SearchHit` values, snippets and match ranges are the ones the existing search test (1 block, about 18 checks) already pins, extended with the new corpora. Plain text for snippets is stored in the cache, so evicted days remain searchable.
3. Rank in Swift: heading contains all words +2, exact phrase +1, recency up to +0.5 (exponential, 365 days). Sort Newest (default, DESIGN 6) or Oldest. No BM25.
4. Filters: date range (All time, This month, This year, Custom), heading (template headings plus the most frequent headings in the cache), an unreadable-files notice. 200 hits per page, "Show 200 more", total from `count(*)`.
5. Runs off the main thread, cancelled by generation token; `sqlite3_interrupt` as a backstop.
6. While the cold build runs, results are partial and say so ("Indexing 40%"); if SQLite is unavailable, a background scan with progressive results (the current matcher, off-main).
7. `instr()` is a byte-level substring test, so CJK and any script work without a tokenizer.

| Alternative | Verdict | Reason |
|---|---|---|
| FTS5 `unicode61` | Rejected | Token semantics differ from today's substring search; weak for CJK. |
| FTS5 `trigram` | Deferred (L10) | 1.6 ms against 2.6 ms measured does not matter at this size; the file triples. |
| In-memory inverted index | Rejected | More code, startup cost, no persistence. |
| Cache every `DayDocument` and keep the matcher | Rejected | 815 ms per query in memory (the matcher itself is slow). |
| Spotlight | Rejected | See D-A. |

**Risks.** A false negative at the candidate stage that today's matcher would find (Unicode edge cases across word boundaries): parity tests run the cache path and `LogStore.search` over the existing corpora plus diacritics, emoji, combining marks and CJK, and fail on any missing hit.

**Consequences.** The search UI gains scope controls and index status without changing the sidebar field.

### D-I. Sources (Claude Code, Git): an add-on module

Tasks: L1 to L4 (M-later, PRD M6). Hours: 82. Design reference: `docs/research/CLAUDE_INTEGRATION.md` sections 0, 2, 3 (inbox), 5, 6, 7.

**Context.** STRATEGY pillar 2 and PRD M6: suggested bullets from Claude Code sessions and Git commits, per-project consent, read-only, redacted, inserted only on click. The research doc's formats and privacy rules were never verified against real transcripts (its own section 0.1).

**Decision.**
1. A module, not a feature: `app/Core/Sources/` (Foundation-only logic, tested headless) and `app/UI/Sources*.swift`. Nothing outside the module knows what a transcript is.
2. `protocol ActivitySource` (the Source protocol): `id`, `title`, `permissions` (what the user must grant: folders to read, a program to run), `availability()`, and `digest(for:window:context:)` returning a `SourceDigest` (projects, items with time and evidence, scan diagnostics, hidden-project and redaction counts). `SourceRegistry` lists `GitSource` and `ClaudeCodeSource`; adding a source is adding one file and one registry line (PRD AUT-7).
3. Permissions are explicit data, shown before enabling: per source and per folder, plus the research doc's `ProjectPolicy` (deny, allow, never-send, longest prefix wins). Off by default; a hidden project is dropped as soon as its working directory is known and never persisted.
4. Git: `Process` on `/usr/bin/git` with an argument array, no shell, minimal environment, `-C <repo> log --since --until --author=<identity>`; repos discovered by a shallow stat-only walk under user-chosen roots (research doc 2.6 for the path rules).
5. Claude Code: the defensive zero-copy JSONL reader, record folding and digest from research doc section 2 (2.6 to 2.9); fixtures per observed version; a canary banner when fewer than 80% of lines parse.
6. Redaction in three layers (minimise, redact before display, redact before insert), research doc 6.4; counts and offsets persisted, never content.
7. The result is a suggestion strip under the catch-up session bar; Insert writes through `DayWriter` like any other append (`appendToSection` on the heading chosen in Settings > Sources, with `unlessPresent`, so a row already on the page reads "Added" and is never inserted twice), with evidence (repo and short hash, or project) in the text (UX_FLOWS 2.10).
8. Out of v1 (PRD): `claude -p` drafting, MCP server, hooks, Desktop Chat capture, any network call. The capture journal's record shape is a superset of the research doc's inbox record, so L14 (MCP and hook channels) can append later without rework.

| Alternative | Verdict | Reason |
|---|---|---|
| Agent SDK `listSessions` | Rejected | Needs Node or Python at runtime. |
| OTLP receiver in the app | Rejected | Heavy; telemetry variables collide with managed settings. |
| SessionEnd hooks as the source | Deferred (L14) | Opt-in hint, not a source of truth. |
| Reading `history.jsonl` | Fallback | Survives the 30-day transcript purge; prompts only. |
| A helper process for scanning | Rejected | Not needed at this size; a utility-QoS queue suffices. |

**Risks.** Transcript format drift and secrets in transcripts (research doc 2.3, 6.4). macOS folder prompts when repositories sit in Documents or Desktop (TCC; expected on first scan). Work-account data (research doc 6.7). The owner's 15-minute structure check (research doc Appendix A) must precede L3.

**Consequences for M1 to M5.** Reserve only: the strip slot under the session bar, a hidden Sources pane, `InboxRecord` compatibility. Nothing else is built early.

### D-J. Error handling and data safety

Tasks: T1.03 to T1.05 (13 h), plus T2.04, T5b.3, T5b.4 counted elsewhere.

**Principles.** Fail visibly, keep the text on screen, retry, never fall back silently to another folder, never destroy previous bytes. The product's promise is "never lose it" (STRATEGY pillar 3); the PRD makes any lost or overwritten text a stop-ship.

**Decision.**
1. Eighteen invariants (section 6) are the contract; each names its test.
2. `FileOps`, a small protocol under `LogStore` for read, write, rename, remove and fsync, with a test double that injects failures at named points (`FaultPlan`): fail after the temp write, fail at rename, short write, disk full, permission denied. T1.03 retrofits the existing save, backup and restore paths and adds failure-path tests (today most failure paths are untested).
3. Kill tests (PRD gate (a)): `app/Tools/kill-test` runs a write path in a child process, SIGKILLs it at randomised points, then relaunches a verifier that checks the file is the old or new version, never partial, backups intact, the journal replayable.
4. `PageSync` (pure) is fuzzed with random sequences of typing, programmatic edits, external changes, saves, day switches and crashes against a simulated disk, asserting that every string ever typed or captured exists in the file, a backup, the journal or the spill file.
5. Spill file: when a save fails, the page's unsaved text is also written to `~/Library/Application Support/Gloamlog/unsaved/<day>-<time>.md` (local, never synced), so a crash while the folder is unwritable loses nothing. Today the text survives only in memory (`AppModel.orphans`).
6. Failure taxonomy and the exact UI behaviour for each are in `ARCHITECTURE.md` 5.J.
7. Static guards in the test run: single writer (INV-04), no network symbols (INV-16), no `86400` (INV-18), no macros, golden listing of the folder after a scripted run (INV-13).

**Risks.** The `FileOps` seam touches the most important code. It is a pure refactor guarded by the existing 51 test blocks and the editor-check scenarios, done first and alone (T1.03).

### D-K. Performance budgets and how they are measured

Tasks: T1.07 (and the signpost helper inside T4.03). Hours: 5. Budgets are in section 7.

**Decision.** A bench harness (`tests/bench.swift`, `tests/run-bench.sh`) builds synthetic corpora (1, 5, 10, 20 years; configurable page size; seeded) and times each budgeted operation, printing a table and JSON; `tests/budgets.json` holds the limits; CI runs it nightly and fails at 1.5 times a budget; scenario timings (open a day, hotkey to panel) come from the UI harness. In the app, `OSSignposter` intervals wrap index refresh, search, save, open day and export; with `GLOAMLOG_PERF=1` they also print one line each to stderr (local only). No telemetry. Baselines from this document's measurements are recorded as the first bench run.

### D-L. UI scenario test harness

Tasks: T1.19, T2.07, T3.07, T4.07, T5b.10. Hours: 39.

**Context.** `app/Tools/editor-check` already runs the real editor in a real `WKWebView` through `EditorBridge`, drives `AppModel`, `DayEditor` and `LogStore` against a temp folder (`Scenarios.swift`), and composites real screenshots (`Screens.swift`). The PRD gate demands real screenshots of every changed screen from the built app and says mockups and the snapshot harness do not count, because the snapshot harness stubs the editor.

**Decision.** Extend it; do not replace it.
1. `AppDriver` hosts the real `MainView`, `SettingsWindow` and the jot panel in real windows, with the real `AppModel` (`live: true`), a real `LogStore` on a temp copy of a fixture folder, an injected clock, a recording notifier, a fake hot-key center and the real editor bundle.
2. It presses controls by `accessibilityIdentifier` through the in-process accessibility tree and types through the same JS path `Scenarios.typeText` already uses. If SwiftUI does not expose the tree in process, fall back to a test-only frame registry (`.testID(_:)` publishes frames; synthetic mouse events go through `window.sendEvent`). A 2 h spike decides (T1.19).
3. Screenshots are taken in process (`cacheDisplay` of the hosting view composited with `WKWebView.takeSnapshot`, as `Screens.swift` does), so no Screen Recording permission is needed (PRD risk row 7).
4. Each scenario writes a PNG per step, `report.json` and an `index.html` contact sheet; `--evidence M1` copies them into `docs/v1/evidence/M1/`.
5. Placement is configurable: `offscreen`, `corner`, `center`; borderless windows, `.accessory` activation, `orderFrontRegardless`, no focus theft. A render probe (pixel variance of the editor area, `document.visibilityState`) stops with a clear message if WebKit did not paint, because a window entirely off-screen may not paint [verify]. The default placement is whatever the spike shows works.
6. Deterministic: injected clock, `en_US_POSIX`, fixed sizes (1000x760 and the 860x600 minimum), Reduce Motion override, seeded fixture corpus (about 60 days with gaps, a skip run, an image, a long page, as the PRD gate lists).
7. It needs a window server, so it runs in a normal terminal or on a CI runner with a GUI session, never in the agent sandbox (F14).

| Alternative | Verdict | Reason |
|---|---|---|
| XCUITest | Rejected | Needs Xcode. |
| Out-of-process Accessibility scripting | Rejected | The harness would need the Accessibility permission; flaky. |
| `screencapture` | Rejected | Screen Recording permission (PRD risk). |
| `Tools/snapshot` (stubbed editor) | Kept for fast SwiftUI renders; not evidence | The PRD says it does not count. |
| Model-only scenarios (`Scenarios.swift` style) | Kept | Fast and precise; the new harness adds the UI layer on top. |

### D-M. Release engineering

Tasks: T1.01, T1.02 (M1), T7.01 to T7.05 (M7). Hours: 28. The PRD treats notarisation and distribution as a separate plan after four weeks of daily use; this section is that plan's technical part.

**Decision.**
1. **Build.** `app/build.sh` keeps one `swiftc` call but takes its sources from `find` (subfolders), reads the version from a `VERSION` file into `Info.plist.in`, and always passes `-target <arch>-apple-macos13.0`. From M7 it builds arm64 and x86_64 and joins them with `lipo`. Resources and the prebuilt editor bundle are unchanged.
2. **Ad-hoc is enough for the owner's own Macs.** A locally built app has no quarantine attribute, so Gatekeeper never sees it. Ad-hoc builds change identity on every rebuild.

| Capability | Ad-hoc signed | Developer ID, hardened runtime, notarised |
|---|---|---|
| Run on the Mac that built it | yes | yes |
| Run after download on another Mac | blocked until System Settings, Privacy and Security, Open Anyway (the right-click bypass is gone on macOS 15+, STRATEGY) | passes Gatekeeper |
| Local notifications | works if the app has a bundle id and runs from /Applications [verify, T5a.4] | stable |
| Login item (`SMAppService.mainApp`) | works with user approval (used today) | stable; shows the developer name |
| LaunchAgent (`SMAppService.agent`) | works with approval, listed as unidentified developer [verify] | stable |
| Files and Folders grants (iCloud Drive, Documents, Desktop) | tied to the code identity, which for ad-hoc is the binary hash, so likely re-prompted after each rebuild [verify] | persist across updates |
| FSEvents, `RegisterEventHotKey`, Services, WebKit | no dependency on signing | same; WebKit needs no extra entitlement under the hardened runtime [verify] |
| Cost | none | Apple Developer Program, 99 USD per year (owner action) |

3. **Notarisation path** (M7): `codesign --force --options runtime --timestamp --sign "Developer ID Application: ..."`, `ditto -c -k --keepParent` to zip, `xcrun notarytool submit --wait --keychain-profile ...`, `xcrun stapler staple`, then `spctl --assess --type execute -vv` and `codesign --verify --deep --strict` in the script. `notarytool` and `stapler` are present in Command Line Tools [measured]. No entitlements are expected (not sandboxed). Signing identity and credentials live in CI secrets or the owner's keychain, never in the repo.
4. **Auto-update policy: none by default.** The app promises no network; an updater would break it. Distribution is Homebrew (own tap first, because the official cask needs notability, STRATEGY) and the GitHub Releases page. An opt-in "Check for updates" button, plus an off-by-default weekly toggle, is deferred (L6): one HTTPS GET to the GitHub Releases API with an ephemeral session, no identifiers, shows a link, never downloads or installs; it lives in the only file allowed to import networking, enforced by the CI guard. Sparkle is rejected (third-party code, network, key management).
5. **CI** (`.github/workflows`): keep build and test; add (a) a job that compiles with `DEVELOPER_DIR=/Library/Developer/CommandLineTools` so a macro cannot slip in (CONTRIBUTING says CI cannot catch this today; it can), (b) no-network and no-macro greps, (c) a check that the committed editor bundle equals a fresh `npm ci && npm run build`, (d) the `--pure` test subset on every push, the full suite where a normal runner allows, (e) a scenario job on a macOS runner with a GUI session (non-blocking until stable for 10 runs), (f) a nightly bench, (g) the release job: tag, build, notarise when secrets exist, checksum, upload.

| Alternative | Verdict | Reason |
|---|---|---|
| Sparkle | Rejected | Third-party, network, signing keys. |
| Mac App Store | Rejected | Sandbox conflicts with an arbitrary log folder and `~/.claude` reads. |
| Weekly auto-check on by default | Rejected | Breaks the no-network promise. |
| Zip for the cask, DMG for people | Both cheap | `hdiutil create` is a system tool. |
| Ad-hoc releases only | Acceptable for the owner, not for others | Gatekeeper friction on every download. |

## 5. Settings catalogue

Panes follow DESIGN 7. Scope: **P** portable (travels in `gloamlog-settings.json` once sync is set up and in settings export), **M** this Mac only. "Today" values are the current behaviour, so defaults change nothing until the owner changes them. Legacy flat keys keep their JSON names; new keys live in the nested group named after their pane (`general`, `reminders`, `page`, `catchUp`, `appearance`, `capture`, `sync`, `backup`, `notifications`, `sources`, `advanced`); a key shown without a prefix below belongs to its pane's group, and a prefixed key names its group.

**General**

| Key | Type, range | Default | Scope | Notes |
|---|---|---|---|---|
| `launchAtLogin` | Bool | false (opt-in) | M | `SMAppService.mainApp`; approval message exists |
| `showMenuBar` | Bool | true | M | moves out of `@AppStorage` |
| `showInDock` | Bool | true | M | off means accessory activation policy; disabled while `showMenuBar` is off, so one way back always remains |
| `openAtLaunch` | today, lastPage | today | M | DESIGN General |
| `weekStartsOn` | system, mon, sun | system | P | overrides `calendar.firstWeekday` for week views and the grid |
| `dayStartsAtHour` | Int 0 to 6 | 0 | P | clock shift; no UI in v1 |
| `allowFutureDays` | Bool | false | M | hidden flag; PRD keeps future pages out |
| `onboarded` | Bool | false | M | internal, never exported |

**Reminders**

| Key | Type, range | Default | Scope | Notes |
|---|---|---|---|---|
| `reminderMinutes` | Int 0 to 1439 | 1015 (16:55) | P | |
| `weekdays` | Set of 1 to 7 | Mon to Fri | P | also the days Catch up and the streak expect |
| `mode` | strict, gentle | strict | P | open question O-1: audit D7 suggests gentle |
| `snoozeMinutes` | 5, 10, 15, 20, 30 | 15 | P | |
| `strictMaxSnoozes` | Int 0 to 5 | 2 | P | was `ReminderPlanner.maxStrictSnoozes` |
| `strictReopenMinutes` | Int 2 to 30 | 5 | P | was `reopenInterval` |
| `nagUntilMinutes` | Int 0 to 1439 | 1380 (23:00) | P | was `cutoffMinutes` |
| `remindWhenClosed` | Bool | true | M | "Remind on this Mac" (PRD REM-4) |
| `catchUpNudge`, `catchUpNudgeMinutes` | Bool, Int | false, 570 (09:30) | P | "Morning notification": "You have N unlogged days" (N projected); after 3 ignored nudges only Mondays |
| `catchUp.todayLine` | Bool | true | P | "Catch-up line on Today": one dismissible line a day while days are unlogged (D-B 10) |

**Page**

| Key | Type, range | Default | Scope | Notes |
|---|---|---|---|---|
| `minWords` | Int 1 to 500 | 20 | P | the logged rule |
| `logStartDate` | day or none | none until the first snapshot with a page fixes it | P | stored, never derived (UX_FLOWS 1.6); [Move earlier…] and [Start fresh from today] |
| `catchUp.windowDays` | 14, 30, 60, 90, sinceLogStart | 30 | P | PRD default 30 |
| `catchUp.includeStarted` | Bool | true | P | days under the minimum are listed (hidden; UX_FLOWS 1.5 always lists them) |
| `template` | markdown | five headings | P | |
| `carryOverHeadings` | list of strings | To do next, Pending / blocked | P | |
| `carryLookbackDays` | Int 1 to 60 | 14 | P | was `CarryOver.lookbackDays` |
| `carryOnPastDays` | Bool | false | P | offer carry-over while catching up |
| `capture.jotsCountTowardLogged` | Bool | false | P | PRD Q1 |
| `capture.jotsHeading` | text | Jots | P | |
| `capture.timestamp` | none, 24h | 24h | P | `HH:mm` prefix |
| `capture.todoShorthand` | Bool | true | P | text starting `[]` becomes `- [ ] text` |
| `page.spellcheck` | Bool | true | P | "Check spelling while typing", applied to the editor on load and on change (T1.17) |
| `autosaveDelayMs` | Int 300 to 3000 | 600 | P | hidden; `DayEditor.scheduleSave` |

**Appearance**

| Key | Type, range | Default | Scope | Notes |
|---|---|---|---|---|
| `appearance.theme` | system, light, dark | system | M | `NSApp.appearance`; editor follows via `pushTheme` |
| `appearance.accent` | gloamlog, system | gloamlog | M | |
| `appearance.showStreak` | Bool | true | P | footer and page chip |
| `appearance.font`, `.textSize`, `.pageWidth` | system, serif, mono; 14 to 20; 600, 720, 900, full | system, 16, 720 | P | UX_FLOWS "Could": editor CSS variables, L11 |

**Storage and sync**

| Key | Type, range | Default | Scope | Notes |
|---|---|---|---|---|
| `storageFolder` | URL | `~/Gloamlog` | M | never imported |
| `sync.indexEnabled` | Bool | true | M | off means the scan path |
| `sync.watchMode` | auto, poll, off | auto | M | |
| `sync.pollSeconds` | Int 10 to 300 | 30 | M | |
| `sync.downloadOnOpen` | Bool | true | M | request iCloud download when a stub day is opened |
| `sync.portableFile` | Bool | false | M | on after "Set up sync" |
| actions | | | | Choose folder, Show in Finder, Use default, Rebuild search index, Rescan folder, Verify folder, Set up sync, Join from another Mac, Download all, Review conflicts |

**Backup**

| Key | Type, range | Default | Scope | Notes |
|---|---|---|---|---|
| `backup.folder` | URL | Application Support/Gloamlog/backups | M | |
| `backup.enabled` | Bool | true | M | "Keep safety copies". Off stops only the routine, throttled copies; copies that protect a superseded version (external change, conflict choice, restore, emptied page) are always made (INV-02, INV-07) |
| `backup.perDay` | 5, 10, 20, 50 | 10 | M | was `LogStore.maxBackupsPerDay` |
| `backup.minIntervalSeconds` | Int 0 to 900 | 120 | M | was `AppModel.backupInterval` |
| actions | | | | Show in Finder, Restore previous version; later: Back up now, Restore from backup into a new folder (L13), Recover a deleted day and Import logs (Could) |

**Shortcuts**

| Key | Type, range | Default | Scope | Notes |
|---|---|---|---|---|
| `capture.hotkey` | key code and modifiers, or off | ⌃⌥J | M | Carbon; needs ⌘ or ⌃ |
| menu shortcuts | read-only list | | | |

**Notifications**

| Key | Type, range | Default | Scope | Notes |
|---|---|---|---|---|
| `notifications.sound` | Bool | true | M | |
| `notifications.dockBadge` | Bool | false | M | days to catch up |
| `notifications.menuBarCount` | Bool | false | M | |
| `notifications.syncConflicts` | Bool | true | M | M5b |
| actions | | | | Allow or Open System Settings, Send a test notification |

**Sources** (hidden until M6)

| Key | Type, range | Default | Scope | Notes |
|---|---|---|---|---|
| `sources.claude.enabled`, `.roots`, `.idleCapMinutes` | Bool, paths, Int | false, `~/.claude`, 10 | M | |
| `sources.git.enabled`, `.roots`, `.identities` | Bool, paths, emails | false, none, git config | M | |
| `sources.policy` | deny, allow, never-send path lists | empty | M | research doc 6.3 |
| `sources.insertHeading` | text | What I did | P | the template's first heading; target of Insert |
| `sources.showPrompts`, `.includeBranch`, `.insertTime`, `.keepDigest` | Bool | true, false, false, true | M | first line of prompts (local display only), branch names in evidence, "(2h 55m)" on inserted lines, daily summary of counts and labels; action: Clear Sources data (never pages) |

**Advanced**

| Key | Type, range | Default | Scope | Notes |
|---|---|---|---|---|
| `advanced.perfLog` | Bool | false | M | stderr timings, local only |
| `advanced.flags` | map of Bool | `useSQLiteIndex` true, `useFolderWatcher` true, `closedAppReminders` true | M | kill switches |
| `advanced.checkForUpdates` | off, manual, weekly | off | M | L6 |
| actions | | | | Run setup again, Rescan folder, Reset settings (all or this pane), Export settings, Import settings, Copy diagnostics (versions and counts, no page text), open log folder, backups, settings file |

**Remembered view state (not Settings):** review scale, grouping, skipped and Jots toggles (the audit's HIG point: task-specific options live in the view they change); export format, include images, paper size and an optional author line in the export sheet; catch-up scope segment.

## 6. Data-safety invariants

"Today" says whether a test or mechanism already exists.

| ID | Invariant | Enforced by | Test (type, where) | Today |
|---|---|---|---|---|
| INV-01 | Opening a day never creates or rewrites a file. | `DayEditor` edit gate, `LogStore.save` identical-content skip | Scenarios "only opened is not created", "opening yesterday did not rewrite" exist; add calendar, catch-up, walk-through | yes, extend |
| INV-02 | Before a day file is overwritten or deleted its previous bytes are copied to the backup folder (outside the synced folder), except identical content, skip markers, title-only files. With `backup.enabled` off only the routine throttled copies stop; copies that protect a superseded version are still made. | `LogStore.backUpCurrent` | 8 backup test blocks exist; add merge, conflict and restore paths | yes, extend |
| INV-03 | Every day-file write is atomic and durable: temp file in the same folder, dot-prefixed, never a valid day name, fsync, rename; a failed or killed write leaves the old file intact. | `SyncSafeIO.writeAtomic` | fault injection (T1.03), kill tests (T1.04) | partly (atomic only) |
| INV-04 | Single writer: only `DayEditor`, `DayWriter` and `AppModel+Day` call mutating `LogStore` APIs. | static scan | runner reads `app/**/*.swift` (T1.05) | no |
| INV-05 | The editor's text is never replaced while it holds typing the writer has not seen: every programmatic replacement is a compare-and-swap on the exact text, and every programmatic append is a single editor transaction on the live document (`appendToSection`). | `EditorBridge.replace(expecting:)`, `PageSync` | scenarios (carry-over, external change) exist; `PageSync` fuzz | partly |
| INV-06 | A captured note is never lost: durable in the journal before "Added", kept until a save containing it succeeds, replayed at launch (at-least-once). | `CaptureJournal` | unit with injected failures, fuzz with crash events, kill test, scenario | new |
| INV-07 | A superseded version always survives: an external or conflicting version is backed up, or merged under a heading, before it is replaced; conflict copies move to backups, never deleted. | `PageSync`, conflict resolver | unit, fuzz, scenario | partly |
| INV-08 | Non-local, partial or unreadable files are never treated as empty days and never overwritten; writes refuse with `.notLocal`. | `FileNameClassifier`, `SyncSafeIO` | unit with fake stubs and dataless flags; placeholder scenario | no |
| INV-09 | The index is a cache: deleting it changes nothing visible; no write decision reads it. | module boundary | parity test, delete-and-rebuild test, static scan | new |
| INV-10 | Skip never overwrites writing. | `LogStore.skip`, `skipDays` | existing test; add batch | yes, extend |
| INV-11 | Day keys from file names or input are validated by shape and calendar round trip before a path is built; asset paths cannot leave the folder. | `DayKey`, `AssetStore.resolve` | existing; add fuzz for `DateJump` and the classifier | yes, extend |
| INV-12 | Unsaved text is never discarded without asking, and is spilled to a local recovery file within 5 s of a failed save. | `DayEditor`, `PageSync` | quit-flush and orphan scenarios exist; add spill test | partly |
| INV-13 | The synced folder gains nothing but `YYYY-MM-DD.md`, `assets/<day>-<hex>.<ext>` and, from M5b, `gloamlog-settings.json`. | golden listing test | scripted run, list folder (T1.05) | new |
| INV-14 | Settings import never changes the storage folder, deletes data or enables a network feature; invalid input is rejected whole. | `SettingsTransfer` | unit | new |
| INV-15 | Migrations are idempotent and never delete old keys or folders. | `SettingsMigrator`, `LegacyMigration` | frozen fixtures per version; `LegacyMigration` tests exist | partly |
| INV-16 | No network: no `URLSession`, `NSURLConnection`, `CFNetwork` or `Network` use outside one opt-in file; the editor CSP stays default-deny; the binary does not link `Network.framework`. | CI guard | grep and `otool -L` (T1.02) | partly (CSP) |
| INV-17 | Exports never modify sources and contain only the chosen scope; exported assets are only those referenced. | `ExportPlan` | unit on bundle listing | new |
| INV-18 | All day arithmetic goes through `DayKey` (calendar based); no `86400`. | static scan | grep plus DST tests | partly |

## 7. Performance budgets

Corpus assumption for budgets: 3,650 days (10 years, daily), average page 2 KB, 13,000 to 20,000 sections. "Today" is [measured] on the 2,609-day, 770-byte corpus. Where the PRD states a number, the PRD number is the contract and the TRD number is the internal target.

| Operation | Today | Budget at 10 years | At 20 years | Contract | Measured by |
|---|---|---|---|---|---|
| Launch to an editable today page (warm) | not measured | 800 ms, independent of day count | 800 ms | TR-06 | scenario timer from `AppModel.init` to `editor.loaded` |
| Snapshot available after launch | 605 ms (`fileStates`) | 30 ms from cache, 60 ms with stat diff | 120 ms | | bench |
| Refresh with no changes | 605 ms | 60 ms | 120 ms | | bench |
| Refresh after one changed file | 605 ms | 20 ms | 20 ms | | bench |
| Cold index build | n/a | 5 s in the background | 10 s | PRD M4-A2: 20 s for 5 years | bench |
| Search, first page, 3 or more characters, warm | 1,100 ms | 50 ms p95 | 100 ms | PRD M4-A1: 300 ms | bench |
| Main-thread block while typing in search | up to 1.1 s | 16 ms | 16 ms | PRD: 100 ms | scenario with a run-loop stall detector |
| Sidebar and calendar `body` evaluation | 65 ms at 10 y, 217 ms at 20 y | 4 ms | 4 ms | | bench of grouping and `MonthGrid` |
| Catch-up list computation | n/a | 10 ms | 20 ms | | bench |
| Open any day to editor swap complete | not measured | 150 ms | 150 ms | | scenario timer |
| Autosave write including backup copy and fsync | not measured | 30 ms | 30 ms | | bench with a temp folder |
| Jot hotkey to panel visible | n/a | 120 ms | 120 ms | | scenario timer |
| Jot Return to journal durable | n/a | 20 ms | 20 ms | | bench |
| Watcher event to UI update, untouched page | polling up to 30 s | 3 s | 3 s | PRD M5-A6: 10 s | scenario |
| Week review build | 8.7 ms | 30 ms | 30 ms | | bench |
| Month review (about 22 pages) | n/a | 150 ms | 150 ms | | bench |
| Year table | n/a | 50 ms (snapshot only) | 50 ms | PRD M3-A3: 2 s | bench |
| PDF export of a month | n/a | 5 s | 5 s | | scenario |
| Memory, app process without web content | not measured | 120 MB resident | 200 MB | | harness `task_info` |
| Idle CPU | wakes every 30 s and rescans | under 0.2% average; the 30 s stat sweep reads no file contents | same | | harness sample over 60 s |

**How measurement works.** `tests/bench.swift` generates seeded corpora (1, 5, 10, 20 years, configurable page size) in a temp folder, times each operation with `DispatchTime`, prints a table and JSON, and exits non-zero when any value exceeds 1.5 times `tests/budgets.json`. `tests/run-bench.sh` compiles `app/Core` and the bench file. The UI harness reports its own timers. In the app, `OSSignposter` wraps index refresh, search, save, open day and export, and `GLOAMLOG_PERF=1` prints one line per interval to stderr. Nothing leaves the Mac. CI runs the bench nightly and uploads the JSON as a trend artifact; budgets are re-baselined deliberately in a commit, never silently.

## 8. Test strategy

### 8.1 Layers

| Layer | What | Tool | Runs | Today, then target |
|---|---|---|---|---|
| L1 Pure unit | `app/Core` functions | `tests/main.swift` runner (`test`, `expect`) | anywhere, including the agent sandbox with `--pure` | 51 blocks, about 500 check lines, then about 170 blocks |
| L2 Core integration | real files, SQLite, `ditto`, journal, kill points | same runner, `ioTest` wrapper | normal terminal | 28 of the 51 blocks need IO today |
| L3 Fuzz and property | `PageSync`, `CapturePlacement`, `CatchUp`, classifier, `DateJump` | seeded generators in the runner, 2,000 cases, under 10 s | anywhere | 0, then 6 suites |
| L4 Kill tests | write paths killed at random points | `app/Tools/kill-test`, `tests/run-kill-tests.sh` | normal terminal | 0, then 5 |
| L5 Platform integration | real FSEvents, hotkey registration, notification plan application | `tests/run-platform-tests.sh` | normal terminal with a GUI session | 0, then about 15 checks |
| L6 Bridge checks | the editor in real WebKit | `app/Tools/editor-check/run.sh --bridge-only` | normal terminal | about 50 checks in `main.swift`, exist |
| L7 UI scenarios | `AppDriver` flows with screenshots | `editor-check` `--scenarios` | normal terminal, CI with a GUI session | about 80 checks in `Scenarios.swift` today (133 with the bridge checks, matching the changelog's "130+"), then about 20 scenarios |
| L8 Bench | budgets | `tests/run-bench.sh` | local and nightly CI | 0, then about 20 metrics |
| L9 Static guards | single writer, no network, no macros, no `86400`, golden folder listing | runner and `grep` | every push | 0, then 6 |
| L10 Owner checks | the PRD's hands-on checklist per milestone | a person | owner's Mac | per milestone |

### 8.2 Gaps in today's coverage

- Failure paths of `LogStore` (write fails, rename fails, backup fails mid-prune) are mostly untested; no fault injection exists.
- `DayEditor` and `AppModel` logic is only exercised through the WebKit scenarios, which cannot run in the agent sandbox; the decision logic has no unit tests.
- Nothing tests time zones or DST for `AppModel`'s calendar; nothing tests `Notifier`.
- No test of concurrency (background refresh against a main-thread save).
- No scale test, no performance regression guard, no coverage measurement (`llvm-cov` and `llvm-profdata` are in Command Line Tools [measured]; `tests/coverage.sh` is part of T1.07).
- No property-style test of the Markdown round trip against the editor (the editor-web fixtures cover it on the JS side only).
- Accessibility is only checked by eye; the harness will fail a scenario when a control it must press has no identifier.

### 8.3 Targets and rules

- New `app/Core` files: at least 90% line coverage by `llvm-cov`; the writer and sync files (`PageSync`, `DayWriter`, `CaptureJournal`, `SyncSafeIO`) at least 95% of lines and every branch in the invariants table exercised.
- A bug fix lands with the test that failed. A scenario that flakes twice in 20 runs is quarantined with an issue, not retried silently.
- Fixtures are generated or frozen in `tests/fixtures/` (settings of each version, folder listings with stubs and conflict names, export bundles); never real logs.
- Definition of done for a task: its named tests exist and pass; `tests/run-tests.sh --pure` passes in the agent sandbox; the full suite passes in a normal terminal; UI tasks add or update a scenario with reviewed screenshots; no new warning from `app/build.sh`; guards green.

### 8.4 Example cases for the new components

- `CatchUp.missing`: Monday morning with Friday unlogged and a weekend off lists Friday only; a skip marker removes a day; a started day (8 of 20 words) is listed as started; a jots-only day is listed as "1 jot, not tidied" and a page written before `logStartDate` changes nothing; days before `logStartDate` never appear; DST weeks and a Sunday-first calendar give the same days; today is excluded even after midnight when `dayStartsAtHour` is 3 and it is 01:00.
- `MonthGrid`: February in a leap year; first weekday Monday and Sunday; 6 rows always; a day with a conflict and a stub shows both marks.
- `FileNameClassifier`: `2026-10-07.md`, `.2026-10-07.md.icloud`, `2026-10-07 2.md`, `2026-10-07 (Alex's conflicted copy 2026-10-08).md`, `2026-10-07.sync-conflict-20261008-101530-ABC.md`, `.gloamlog-tmp-1`, `2026-13-40.md`, `assets`, `notes.md`.
- `CapturePlacement`: `[]` becomes a to-do without a time stamp; no Jots block yet; Jots block in the middle of the page; page whose last line is a list; text starting with `#` or `- `; multi-line note; the template page that is untouched; a page whose heading is `### Jots`.
- `appendToSection` (editor-check bridge scenario): no Jots heading (created at the end), Jots in the middle, last block a list (joined), caret and selection unchanged, text typed a moment before kept, one undo removes exactly the appended line, `unlessPresent`, a stale token refused.
- `BothVersions.merge`: lines only in the other version are appended in order under "From other copy (4:40 pm)"; identical bodies and an empty other version change nothing; jots from two Macs in the same minute both survive; nested bullets keep their indentation.
- `CaptureJournal`: kill after the journal write and before the file write (replay delivers once); kill after the file write and before the ack (replay does not duplicate an identical line); folder unwritable (note stays, count shown); two Macs capturing the same minute.
- `PageSync` fuzz: random events against a simulated disk; assert no typed or captured text is ever missing from file, backups, journal or spill.
- `SQLiteDayIndex`: parity with `ScanIndex` on every existing corpus; delete the file mid-run; bump the parser version; rename and delete files; stub appears for an indexed day (row kept, availability changes).
- `SearchService`: parity with `LogStore.search`; filters; cancellation; diacritics, emoji, CJK; 3,000-hit pagination.
- `ReminderScheduler`: three ignored nudges leave only Mondays, a Catch up visit resets that, the projected count; skip markers remove requests; logging today removes today's request; weekday change; 14-day horizon; DST boundary; identical plan produces an empty diff.
- `MarkdownHTML`: hostile input (`<script>`, `javascript:` links, raw HTML, huge nesting); tables with escaped pipes; images with spaces in names.
- `SettingsMigrator`: every frozen JSON from v0.1 keys to the current schema loads to the expected `Settings`; unknown keys are ignored; out-of-range values are clamped.

## 9. Spikes and verification gates

Everything marked [verify] has a task. S-1 to S-3 run in M1 because they change designs. The hours are included in the named task, not added to it.

| ID | Question | Decides | Where | Hours |
|---|---|---|---|---|
| S-1 | Can the harness press SwiftUI controls through the in-process accessibility tree by identifier? If not, use the frame registry. | D-L harness design | T1.19 | 2 |
| S-2 | Does a window entirely off-screen paint WebKit and answer `takeSnapshot`? Which placement is the default? | D-L placement | T1.19 | 1 |
| S-3 | Does `showSettingsWindow:` open Settings on macOS 27? (Reproduces the PRD's doubt.) | confirms D-F `Window` choice | T1.17 | 0.5 |
| S-4 | `RegisterEventHotKey` in a real `NSApplication`: status for ⌃⌥J, behaviour of ⌥-only combinations, panel over a full-screen app and across Spaces | D-D hotkey rules, panel flags | T2.05 | 2 |
| S-5 | Quit-and-fire: schedule a calendar notification, quit, reboot; does it arrive for the ad-hoc build in /Applications? Do Snooze and Skip actions launch the app in the background? Does the window appear? | D-E fallback for actions | T5a.4 | 3 |
| S-6 | FSEvents flags and latency for atomic replace, in-place write, delete on a local folder | D-C debounce | T5b.1 | 1 |
| S-7 | On a Mac with iCloud Drive: stub naming and dataless behaviour on this macOS, conflict-copy names, whether dotfiles sync, `startDownloadingUbiquitousItem`, the privacy prompt. With Dropbox or another CloudStorage provider: dataless files, conflict names. | D-C classifier, file name of the settings file | T5b.9 | 4 |
| S-8 | PDF: print operation against sliced `createPDF` on a 10-page month | D-G | T3.06 | 2 |
| S-9 | Hardened runtime plus WebKit; Gatekeeper on a second Mac; stapling | D-M | T7.02 | 2 |
| S-10 | The owner's structure-only check of Claude Code files (research doc Appendix A) | L3 | owner, 15 minutes | 0.25 |

## 10. Milestones, ordered tasks, later work

### 10.1 Task list

Order inside a milestone is build order. "Dep" lists the tasks that must exist first. Hours include tests. Every task's tests are those named in the matching ARCHITECTURE.md section.

**M1 (0.4.0) Daily-usable core: 132 h**

| ID | Task | Decision | Dep | Hours |
|---|---|---|---|---|
| T1.01 | Recursive build and test layout (`find`), `app/Platform/`, `tests/run-tests.sh --pure`, update the four scripts | D-M | | 3 |
| T1.02 | CI guards: CLT-only compile job, no-network and no-macro greps, committed editor bundle equals a fresh build | D-M | T1.01 | 3 |
| T1.03 | `FileOps` seam and fault injection in `LogStore`; failure-path tests | D-J | T1.01 | 4 |
| T1.04 | Kill-test harness (`app/Tools/kill-test`, `tests/run-kill-tests.sh`) for save, backup, restore | D-J | T1.03 | 5 |
| T1.05 | Invariant tests and static scans (INV-04, 09, 13, 16, 18) | D-J | T1.03 | 4 |
| T1.06 | Clock fixes: stop the 30 s full reload, auto-updating calendar, `dayStartsAtHour` | D-A | T1.01 | 5 |
| T1.07 | Bench harness, `budgets.json`, `tests/coverage.sh`; record baselines | D-K | T1.01 | 5 |
| T1.08 | `DayIndexSnapshot` (with `jotCount`), `ScanIndex` off-main, stored `logStartDate` (fixed at the first snapshot) as `since` in `Status.resolve`, `Streak.compute` and `Heatmap.weeks`, months grouped once | D-A | T1.06 | 8 |
| T1.09 | `MonthGrid` (pure) and tests | D-A | T1.08 | 3 |
| T1.10 | `DateJump` parser (natural dates through `NSDataDetector` plus a small grammar) | D-B | | 3 |
| T1.11 | `CatchUp` planner, `LogStore.skipDays`, undo, tests | D-B | T1.08 | 6 |
| T1.12 | Sidebar, toolbar, calendar, Today, Catch up, Review rows, Recent, footer with gear | D-A | T1.09, T1.11 | 12 |
| T1.13 | Go to date popover, Go menu, grid keyboard navigation, VoiceOver labels | D-B | T1.10, T1.12 | 4 |
| T1.14 | Catch-up screen, `CatchSession` bar (Next unlogged day on ⌘↩ with ⌥⌘↓), Today line, badge, Strict re-open no longer navigates away | D-B | T1.11, T1.12 | 11 |
| T1.15 | Week review fixes (every scheduled day, empty-week actions), past-day header and relative label | D-B | T1.08 | 5 |
| T1.16 | Settings core: `schemaVersion`, groups, `SettingsMigrator`, field table, `SettingsEffects`, per-pane reset | D-F | T1.01 | 8 |
| T1.17 | Settings window (`Window` scene), all panes except Sources, `openSettings(pane:)`, every entry point, spell-check switch | D-F | T1.16 | 11 |
| T1.18 | Settings export and import, Advanced actions | D-F | T1.16 | 4 |
| T1.19 | UI scenario harness v1 (`AppDriver`, contact sheet, evidence copy) with scenarios: open a past day, catch up three days, skip three days with undo, change settings | D-L | T1.12 to T1.17 | 14 |
| T1.20 | Walkthrough (first 4 h) and P0 and P1 fixes | | all above | 12 |
| T1.21 | Doc hygiene: mark old docs superseded, README status, CHANGELOG | | | 2 |

**M2 (0.5.0) Quick capture: 64 h**

| ID | Task | Decision | Dep | Hours |
|---|---|---|---|---|
| T2.01 | Jots model: block detection, `words` and `jotWords`, `jotsCountTowardLogged`, write-time template strip, template above jots, `CapturePlacement` | D-D | T1.16 | 8 |
| T2.02 | `CaptureJournal` (write-ahead, replay, ack) with fault tests | D-D | T1.03 | 5 |
| T2.03 | `DayWriter` routing, `pendingAppends`, ack after save, "n notes waiting"; editor-contract call `appendToSection` (JS, bundle rebuild, `docs/EDITOR_CONTRACT.md`, bridge test, undo check) | D-D | T2.01, T2.02 | 17 |
| T2.04 | `PageSync` pure state machine extracted from `DayEditor`; spill file; fuzz | D-D | T1.03 | 14 |
| T2.05 | `HotKey`, recorder, jot panel, menu-bar Jot field, Page menu command | D-D | T2.03 | 10 |
| T2.06 | Shortcuts pane and the Jots switch | D-F | T2.05 | 3 |
| T2.07 | Scenarios and kill tests: capture with the page open, window closed, folder gone, journal replay | D-L | T2.05 | 7 |

**M3 (0.6.0) Reviews and export: 58 h**

| ID | Task | Decision | Dep | Hours |
|---|---|---|---|---|
| T3.01 | `PeriodReview`, file-backed `SectionProvider`, task statistics | D-G | T1.08 | 12 |
| T3.02 | Review UI: Week tiles, Month, Year table, Range, toggles | D-G | T3.01 | 10 |
| T3.03 | `MarkdownHTML` renderer | D-G | | 6 |
| T3.04 | Copy formats: Markdown, Plain, Rich (HTML and RTF) | D-G | T3.03 | 4 |
| T3.05 | Export: Markdown plus assets, zip through `ditto`, export sheet, Share | D-G | T3.01 | 10 |
| T3.06 | `PDFExporter`: spike, print operation, fallback | D-G | T3.03 | 10 |
| T3.07 | Scenarios: month review, export bundle, PDF page count | D-L | T3.02 to T3.06 | 6 |

**M4 (0.7.0) Search at scale: 54 h**

| ID | Task | Decision | Dep | Hours |
|---|---|---|---|---|
| T4.01 | `IndexDB` SQLite wrapper, corruption recovery | D-A | T1.01 | 5 |
| T4.02 | `SQLiteDayIndex`: schema, diff refresh, parser version, cold build, parity with `ScanIndex`, bench | D-A | T4.01, T1.08 | 14 |
| T4.03 | Wire it in: swap the producer, progress UI, Rebuild, kill switch, signposts | D-A | T4.02 | 7 |
| T4.04 | `SearchQuery`, `SearchService`, matcher refactor, tests | D-H | T4.02 | 12 |
| T4.05 | Search UI: scope row, sticky headers, pagination, banners | D-H | T4.04 | 8 |
| T4.06 | Index-backed `SectionProvider` for reviews | D-G | T4.02, T3.01 | 3 |
| T4.07 | Scenarios: 5- and 10-year search, rebuild, partial results | D-L | T4.05 | 5 |

**M5a (0.8.0) Reminders when closed: 20 h**

| ID | Task | Decision | Dep | Hours |
|---|---|---|---|---|
| T5a.1 | `ReminderScheduler` (pure plan and diff) with tests | D-E | T1.08 | 5 |
| T5a.2 | Apply to the notification center, re-plan triggers, "Next reminder", denied state, "Remind on this Mac" | D-E | T5a.1 | 6 |
| T5a.3 | Actions Open, Snooze, Skip today and click-to-open day | D-E | T5a.2 | 6 |
| T5a.4 | Spike matrix on the owner's Mac (S-5) | D-E | T5a.2 | 3 |

**M5b (0.8.0) Sync: 74 h**

| ID | Task | Decision | Dep | Hours |
|---|---|---|---|---|
| T5b.1 | `FolderEventSource`, FSEvents source, polling source, coalescing; tests with a fake source | D-C | T1.01 | 8 |
| T5b.2 | Watcher to index to open page; untouched page reloads within 10 s | D-C | T5b.1, T4.03 | 6 |
| T5b.3 | `SyncSafeIO`: temp, fsync, rename; settle gate; bounded reads; dataless and stub detection | D-C | T1.03 | 8 |
| T5b.4 | Compare-and-swap save, `PageSync` Conflicted state, keep mine, take theirs, keep both | D-C | T2.04, T5b.3 | 10 |
| T5b.5 | Stub and dataless handling: count, Download all, hydrate on open, refuse writes | D-C | T5b.3 | 8 |
| T5b.6 | Conflict copies: detection, review sheet, merge both, move to backups | D-C | T5b.4 | 10 |
| T5b.7 | Folder kind, Verify folder, sync chip, Storage and sync rows | D-C | T5b.2 | 5 |
| T5b.8 | Portable settings file and "Join from another Mac" | D-F | T1.16, T5b.7 | 8 |
| T5b.9 | Spikes on a Mac with iCloud Drive and Dropbox (S-7) | D-C | T5b.1 | 4 |
| T5b.10 | Scenarios: external change, conflict, conflict copy, stub | D-L | T5b.4 to T5b.7 | 7 |

**M7 (1.0.0) Release: 22 h**

| ID | Task | Decision | Dep | Hours |
|---|---|---|---|---|
| T7.01 | Universal binary, `Info.plist.in`, `VERSION`, hardened runtime, entitlements | D-M | T1.01 | 4 |
| T7.02 | `app/release.sh`: sign, notarise, staple, verify, zip or dmg (needs Apple Developer enrolment, S-9) | D-M | T7.01 | 6 |
| T7.03 | CI release job, checksums, Homebrew tap and cask | D-M | T7.02 | 6 |
| T7.04 | CI scenario job (macOS runner with a GUI session), nightly bench | D-M | T1.19, T1.07 | 4 |
| T7.05 | README network statement, SECURITY.md, CHANGELOG | D-M | | 2 |

Totals: M1 132, M2 64, M3 58, M4 54, M5a 20, M5b 74, M7 22 = 424 h. By decision (primary): D-A 54, D-B 29, D-C 59, D-D 54, D-E 20, D-F 34, D-G 55, D-H 20, D-J 13, D-K 5, D-L 39, D-M 28, walkthrough and docs 14.

### 10.2 Order, dependencies, owner needs

- **Critical path to "usable":** T1.01, T1.06, T1.08, then T1.09 and T1.11 in parallel, then T1.12, T1.13, T1.14, with T1.16 and T1.17 in parallel on the settings side. Cut line A, 79 h.
- **Before any writer work** (M2, M5b): T1.03 (the `FileOps` seam) and T2.04 (`PageSync`) land first and alone, each guarded by the existing tests and scenarios. T5b.4 depends on T2.04 and, through T5b.3, on T1.03.
- **M3 and M5a are independent** of the index and of each other; M5b needs M4's index wiring (T4.03) for the watcher to update cheaply.
- **Re-rank after the five-day trial** (PRD): the order of M2 to M5 is advisory; unlogged days point to M5a, paste pain to M3.
- **From the owner:** a copy of the log folder before each milestone check; Screen Recording permission is not needed for the evidence screenshots (in-process capture); a second Mac with iCloud Drive or Dropbox for T5b.9; Apple Developer Program enrolment for T7.02 (99 USD per year); the 15-minute Claude Code structure check before L3.

### 10.3 Later work (M-later)

| ID | Item | Decision | Hours |
|---|---|---|---|
| L1 | `ActivitySource` protocol, registry, `ProjectPolicy`, `Redactor`, consent UI, suggestion strip (PRD M6) | D-I | 20 |
| L2 | Git source: repo discovery, `git log`, identity filter | D-I | 14 |
| L3 | Claude Code source: JSONL reader, fold, digest (research doc section 2) | D-I | 36 |
| L4 | Sources fixtures, tests, docs, "Add a source" guide | D-I | 12 |
| L5 | Services menu entry and `gloamlog://` URL scheme (confirm-only by default) | D-D | 4 |
| L6 | Opt-in "Check for updates" (the only networking file) | D-M | 6 |
| L7 | LaunchAgent helper (`--remind-check` through `SMAppService.agent`) for Strict while closed and conditional reminders | D-E | 10 |
| L8 | Clean three-way merge for append-only conflicts, `autoMergeClean` setting | D-C | 12 |
| L9 | Paste-and-split multi-day entry | D-B | 8 |
| L10 | FTS5 trigram upgrade if a corpus passes about 100,000 sections | D-H | 5 |
| L11 | Editor text size, font and page width variables (editor-web; UX_FLOWS Appearance, Could) | | 6 |
| L12 | Localisation of dates and labels (`DayKey.format` is English only) | | 12 |
| L13 | Whole-folder backup and restore (DESIGN Backup pane) | D-M | 8 |
| L14 | MCP and hook inbox channels (research doc sections 3 and 4) | D-D | 20 |

Later total 173 h, of which Sources 82.

## 11. Risks, open questions

### 11.1 Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Sync behaviour differs from the design on real providers; the owner's Mac has none to test with | High | High | Fakes plus S-7 on another Mac before M5b ships; conflict handling is a user choice, never automatic; kill switches |
| The `PageSync` extraction changes the riskiest code | Medium | High | Characterisation tests from the existing scenarios first; extract alone; fuzz; spill file; behind the existing editor-check run |
| The index and the scan disagree | Medium | Medium | Parity test over every corpus; delete-and-rebuild test; `useSQLiteIndex` kill switch |
| Hotkey or panel misbehaves with Spaces, full-screen apps, other apps' shortcuts | Medium | Medium | S-4; menu-bar Jot field as fallback; recorder reports conflicts |
| The editor bundle cannot be rebuilt on the owner's Mac, or `appendToSection` misbehaves on some documents | Low | Medium | Node is needed only for T2.03; `editor-web` has page tests and the bridge check covers undo; the fallback `insertMarkdown(.end)` keeps notes safe, with a second adjacent list |
| Ad-hoc notification registration fails or Actions cannot launch the app | Medium | High | S-5 in M1 as the PRD asks; fallback to pre-scheduled follow-ups; Strict stays in-app |
| In-process screenshots or presses do not work as assumed | Medium | Medium | S-1, S-2 first; fallbacks designed (frame registry, on-screen corner placement) |
| macOS 27 behaviour differs from what this design assumes (the SDK is newer than my reference knowledge) | Medium | Medium | Every OS-dependent claim is tagged [verify] with a spike; deployment target stays 13 so older behaviour is the baseline |
| Scope: 424 h is large for the owner's time | High | Medium | Cut lines in 0.4; M5b and M3 are the first to trim (PRD section 6) |
| Settings window change breaks muscle memory or a macOS convention | Low | Low | ⌘, is rebound, not removed; S-3 |
| Index and journal add local copies of log text | Low | Medium | 0700 and 0600, Time Machine exclusion, delete buttons, kill switch, stated in the privacy copy |
| Print-operation PDF stalls headless | Medium | Low | Timeouts and the sliced fallback (S-8) |
| Time estimates are too low | Medium | Medium | Ranges are plus or minus 40% (PRD); re-size M1 after the walkthrough (T1.20) |

### 11.2 Open questions, with defaults that apply if unanswered

| # | Question | Default |
|---|---|---|
| O-1 | Keep Strict as the default reminder style? (audit D7 recommends Gentle) | Keep; the PRD did not change it. One default flip in `Settings`. |
| O-2 | Do you want "My day ends at" in the UI? | No UI; the clock supports it. |
| O-3 | Should future pages be openable later? | Flag only, off. |
| O-4 | Is a clean automatic merge of append-only conflicts wanted after you have used sync? | No (L8 stays deferred). |
| O-5 | Which provider: iCloud Drive or Dropbox? | iCloud Drive first-class, others as plain folders (PRD Q4). |
| O-6 | Paper size for PDF | System region default. |
| O-7 | Is ⌃⌥J acceptable as the Jot hotkey? | Yes; changeable. |
| O-8 | Apple Developer enrolment date | Not blocking until M7. |
| O-9 | Do you want "Back up now…" and "Restore from backup…" in Settings during M1? (UX_FLOWS lists them; this plan defers them as L13) | Deferred. Say yes and L13 moves into M1: +8 h, cut line A unchanged. |

## Appendix A. Measurements and how to reproduce them

Machine: macOS 27.0.1 (26A434), arm64, `swiftc` 6.4 with `-swift-version 5 -O -target arm64-apple-macos13.0`, warm page cache, single run each, the agent's Bash sandbox. Corpus: generated Monday to Friday pages, 10 years ending 2026-10-06, 2,609 files, 1,955 KB total, average 767 bytes, five headings with bullets, tasks and a short paragraph (the default template's headings), written non-atomically (the sandbox forbids the temp-file rename).

| Operation | Time |
|---|---|
| `LogStore.listDays` | 6.7 ms |
| `LogStore.fileStates(minWords: 20)` | 605.1 ms |
| `Streak.compute` | 11.1 ms |
| `Heatmap.weeks(12)` | 0.8 ms |
| `LogStore.search("pricing")`, 4,546 hits | 1,086.2 ms |
| `LogStore.search("zzzqqq")`, no hits | 1,192.1 ms |
| `LogStore.allDocuments` | 252.0 ms |
| `MarkdownBody.words` over all documents in memory | 339.4 ms |
| `Search.hits` over all documents in memory | 814.5 ms |
| `MarkdownBody.sections(of:)` over all documents | 100.2 ms |
| `stat` every file (size and mtime), no changes | 25.8 ms |
| `WeeklyReview.summary` for one week | 8.7 ms |
| SQLite index build: read, parse, fold, insert (no FTS5) | 1,495.8 ms; 13,045 sections; 3,216 KB |
| SQLite index build with an FTS5 trigram table | 1,826.6 ms; 9.7 MB |
| `instr()` scan, "pricing" / "signup form" / "zzzqqq" / "pri" | 2.6 to 3.1 ms / 2.8 / 2.0 / 2.2 |
| FTS5 trigram query, same four | 1.6 / 0.9 / 0.0 / 0.3 ms |
| Load all `days` rows (size, mtime, words, skipped) | 0.2 ms |
| Year roll-up by heading with `GROUP BY` | 1.2 ms |
| Sidebar months grouping, current logic, 1 / 3 / 10 / 20 years | 2.1 / 12.1 / 65.4 / 216.8 ms |
| Same, grouped once | 0.17 / 0.39 / 0.63 / 1.26 ms |

The measuring programs were throwaway scratch files compiled against `app/Core/*.swift`; T1.07 turns them into `tests/bench.swift`. `import SQLite3` needs no flags. The system library reports SQLite 3.54.0 with `ENABLE_FTS5`.

## Appendix B. Environment and sandbox findings

- `tests/run-tests.sh` inside the agent's Bash sandbox: 231 checks pass, 28 test blocks throw (20 `folderNotWritable`, 6 Cocoa write errors "Operation not permitted", 2 `io`) because the sandbox denies the folder writes they need; the repository header already says to run it outside the sandbox.
- `FSEventStreamStart` returns false in the sandbox; no events are delivered.
- `RegisterEventHotKey` returned `eventInternalErr` (-9868) from a headless command-line process (no window-server connection), so the probe says nothing about behaviour inside the app; S-4 tests it in a real `NSApplication`.
- These compile with plain `swiftc` at the macOS 13 target: CoreServices FSEvents, Carbon hot keys, `SMAppService.agent(plistName:)`, `UNCalendarNotificationTrigger`, `URLResourceKey.ubiquitous*`, `NSFileCoordinator`, `SF_DATALESS` (0x40000000), SQLite3.
- `Bundle.main.bundleIdentifier` is nil for a bare executable, so a notification helper must be the app bundle's own binary started with an argument, not a separate command-line tool.
- `~/Library/Mobile Documents/com~apple~CloudDocs` and `~/Library/CloudStorage` do not exist on this Mac.
- `llvm-cov`, `llvm-profdata`, `notarytool`, `stapler`, `lipo` are in the Command Line Tools; `pdftotext` is not (PDF assertions use PDFKit).

