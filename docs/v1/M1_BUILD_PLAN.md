# M1 Implementation Plan: Daily-usable core (0.4.0)

> **For agentic workers:** REQUIRED SUB-SKILL: use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task by task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** the owner can write any day, catch up missed days in bulk, change settings from a real window they can find, and trust that nothing is lost. Pass/fail is `docs/v1/PRD_V1.md` section 2, rows R1 to R9, run on the owner's Mac.

**Architecture:** evolve the existing layers (pure `app/Core` -> `AppModel` -> SwiftUI plus the WebKit editor bundle). Three streams build in parallel against frozen contracts (section 2) with disjoint file ownership (section 3); the orchestrator integrates, runs the walkthrough and gates the release.

**Tech stack:** Swift 5 mode, SwiftUI + AppKit, macOS 13+, Command Line Tools only (no Xcode, no SwiftPM, **no Swift macros**: no `@State`, `@Observable`, `#Preview`; use `ObservableObject`, `@StateObject`, `@Published`, `@AppStorage`, `@Binding`), no network, no third-party code. Tests: `bash tests/run-tests.sh` (pure core) and `bash app/Tools/editor-check/run.sh` (real windows and real WebKit; needs `dangerouslyDisableSandbox` from an agent shell).

Source of truth: `PRD_V1.md` (what and acceptance), `UX_FLOWS.md` (flows, copy, 40 Given/When/Then), `DESIGN_V4.md` (pixels, tokens, SwiftUI feasibility), `ARCHITECTURE.md` and `TRD.md` (module map, decisions), `UX_AUDIT_AND_BENCHMARKS.md` (defects and scenarios). Where they disagree: behaviour -> UX_FLOWS, pixels and tokens -> DESIGN_V4, requirements and acceptance -> PRD_V1, module names -> ARCHITECTURE.

---

## 0. Scope decisions

`TRD.md` budgets M1 at 129 h and `PRD_V1.md` at 26 to 34 h. The honest range for this plan is **65 to 90 agent-hours of work**, about **1 to 2 calendar days** with three parallel streams plus integration. What is cut from the architect's M1, and why:

| Cut (TRD id) | Why it is not needed to be "daily-usable" | Where it goes |
|---|---|---|
| T1.02 CI guards, T1.05 invariant scans, T1.07 bench and coverage | Valuable hygiene, no user-visible effect | after the owner's 5-day trial |
| T1.03 `FileOps` fault-injection seam | existing tests cover unwritable folders; kill test (C6) covers the data-loss claim R6 | M2 |
| T1.18 Settings import/export | not in R1-R9 | M5 |
| SQLite index (T4.x) | folder-stamp gating (C6, N1) removes the 30 s rescan; parse-everything cost is acceptable below ~3 years of logs | M4 |
| "My day ends at" setting, time-zone snapshot fix | logged as known issue K-1; fix when travelling matters | M2 |

Kept: recursive build (done), log start date (C1 done), month grid, date jump, catch-up, navigation UI, week-review fixes, Settings window with real entry points, kill test, real-window scenarios and evidence, walkthrough, docs.

Defaults decided (PRD open questions, owner may override): a week is a view over days; jots do not count toward logged (M2); first-run reminder style stays **Strict** because the owner asked to be forced, with 2 snoozes per day; "Back up now" deferred.

---

## 1. Already done (baseline commit)

- [x] Recursive build and test scripts (`find`), `AppCommands.swift` split from `GloamlogApp.swift`, stub files for each stream.
- [x] **C1** `Settings`: `logStartDate`, `appearance`, `weekStart`, `catchUpWindowDays` (tolerant decode, clamped). `Status.effectiveSince(setting:states:)`, `Streak.compute(..., since:)`, `Heatmap.weeks(..., since:)`. 603 tests pass.

---

## 2. Frozen contracts (do not change signatures; implement bodies)

```swift
// app/Core/Calendar/MonthGrid.swift  (stub exists; C2 implements)
struct MonthCell: Equatable { var day: String; var inMonth: Bool; var status: DayStatus; var isToday: Bool; var isScheduled: Bool }
enum MonthGrid {
    static func rows(year: Int, month: Int, states: [String: DayStatus], now: Date, calendar: Calendar,
                     weekdays: Set<Int>, logStart: String?) -> [[MonthCell]]   // 6 x 7, columns start at calendar.firstWeekday
}
// app/Core/Calendar/DateJump.swift  (stub exists; C3 implements)
enum DateJump { static func parse(_ input: String, now: Date, calendar: Calendar) -> String? }
// app/Core/Calendar/CatchUp.swift  (stub exists; C4 implements)
enum CatchUp {
    static func missing(states: [String: DayStatus], now: Date, calendar: Calendar, weekdays: Set<Int>,
                        logStart: String?, windowDays: Int) -> [String]       // oldest first; .missed and .partial; never today
    static func next(after day: String?, in list: [String]) -> String?
}
extension LogStore {
    func skipDays(_ days: [String], reason: String) throws -> [String]       // returns the days actually skipped
    func unskipDays(_ days: [String]) throws -> [String]                      // returns the days restored (pure skip markers only)
    func folderStamp() throws -> String                                       // C6: names+mtimes+sizes of *.md only; no content reads
}
// app/UI/AppModel+Settings.swift  (stub exists; stream S implements openSettings)
enum SettingsPane: String, CaseIterable, Identifiable { case general, reminders, page, storage, shortcuts, about }
extension AppModel {
    func openSettings(pane: SettingsPane? = nil)                              // opens the Settings window in front, < 1 s
    static func makeCalendar(weekStart: Int?) -> Calendar                     // AppModel.cal must always be built from this
}
// Navigation (stream N owns): enum Destination: Hashable { case day(String), catchUp, week, search }
```

Settings fields (done): `logStartDate: String?`, `appearance: AppAppearance (.system/.light/.dark)`, `weekStart: Int?`, `catchUpWindowDays: Int (7...365, default 30)`.

---

## 3. Streams and file ownership

Nobody edits a file they do not own. If you need a change in someone else's file, write it as a request in your final report; if it blocks you, wait for the owner stream (a compile error caused by another stream's half-finished file: wait 3 minutes and retry, up to 5 times). Nobody runs git; the orchestrator commits.

| Stream | Owns (may edit) | Must not touch |
|---|---|---|
| **C Core** | `app/Core/**`, `tests/**`, `app/Tools/kill-test/**` | `app/UI/**`, `editor-web/**`, docs |
| **N Navigation** | `app/UI/AppModel.swift`, `AppModel+Browse/+Day/+Editor/+Reminders.swift`, new `AppModel+Calendar.swift`, `+CatchUp.swift`, `MainView`, `Sidebar`, `PageView`, `PageHeader`, `WeeklyReviewView`, `SearchView`, `Heatmap`, `SkipSheet`, `Theme.swift`, `Components.swift`, `AppCommands.swift`, new `CalendarView`, `GoToDateView`, `CatchUpView`, `SessionBar`, `app/Tools/editor-check/ScenarioNav.swift` | Core, Settings files, `GloamlogApp.swift` |
| **S Settings** | `app/UI/AppModel+Settings.swift`, `GloamlogApp.swift`, `SettingsView.swift` (replace), new `SettingsWindow.swift`, `SettingsPane*.swift`, `SettingsTheme.swift`, `TemplateEditor.swift`, `Onboarding.swift`, `MenuBarView.swift`, `app/Tools/editor-check/ScenarioSettings.swift` | Core, Navigation files |
| **Orchestrator** | `docs/**`, `README.md`, `CHANGELOG.md`, `.github/**`, evidence, commits, `app/Tools/editor-check/main.swift`, `build.sh` | |

Streams C then N and S overlap: N and S compile against the stubs immediately; C replaces stub bodies behind frozen signatures, so UI work is never blocked.

Shared rules: test-first for anything in `app/Core`; every stream ends with a **real-window scenario** (not a mock) and screenshots saved under the scratchpad evidence dir the orchestrator names; report only what you verified and say plainly what you could not run.

---

## 4. Stream C: Core (tasks C2 to C6)

### Task C2: `MonthGrid`
**Files:** `app/Core/Calendar/MonthGrid.swift`, `tests/main.swift`. **Scope:** S. **Deps:** C1 (done).
**Acceptance:** 6 rows x 7 columns; first column weekday == `calendar.firstWeekday`; days contiguous; `inMonth` correct; `status` via `Status.resolve` with `since = Status.effectiveSince(setting: logStart, states: states)`; `isScheduled` from `weekdays`; today flagged; future days `.future`; days before the effective start `.off`.
- [ ] Write failing tests (all with the test harness `cal` = New York, `firstWeekday` 2): October 2026 -> first cell `2026-09-28` (`inMonth == false`), `2026-10-01` at row 0 column 3; Sunday-first calendar -> first cell `2026-09-27`; February 2028 has 29 in-month cells; March 2026 (DST) has no duplicate or missing day key across the 42 cells; a `.logged`/`.partial`/`.skipped` state maps through; weekend `isScheduled == false` and status `.off`; a day before `logStart` is `.off` even though scheduled and unwritten.
- [ ] Run `bash tests/run-tests.sh`; expect the new tests to FAIL (stub returns `[]`).
- [ ] Implement `rows`. Run again; expect all PASS.

### Task C3: `DateJump`
**Files:** `app/Core/Calendar/DateJump.swift`, `tests/main.swift`. **Scope:** S.
**Acceptance:** with `now` = Wed 2026-10-07 (NY): `yesterday` -> `2026-10-06`; `today` -> `2026-10-07`; `-3` and `3 days ago` -> `2026-10-04`; `last fri` and `fri` -> `2026-10-02`; `wed` -> `2026-10-07`; `last wed` -> `2026-09-30`; `2 oct`, `oct 2`, `2 October 2026`, `2026-10-02` -> `2026-10-02`; `10/2` -> `2026-10-02` for a US locale and `2026-02-10` for `en_GB`; `2 dec` -> `2025-12-02` (most recent past occurrence, never a future date); `tomorrow`, `2027-01-01`, `31 feb`, `garbage`, empty -> `nil`; case and surrounding whitespace ignored; dates before 2000-01-01 -> `nil`.
- [ ] Write the failing tests (table-driven, one assertion per row, the message names the input). - [ ] Run, see FAIL. - [ ] Implement: a small grammar first (keywords, `-n`, `n days ago`, weekday names, month names, ISO, numeric), then `DateFormatter` as a fallback per `calendar.locale`; no `NSDataDetector` unless it is deterministic in tests. - [ ] Run, see PASS.

### Task C4: `CatchUp` and batch skip
**Files:** `app/Core/Calendar/CatchUp.swift`, `app/Core/LogStore.swift` (only if needed), `tests/main.swift`. **Scope:** M.
**Acceptance:** `missing` lists scheduled days in `[today - windowDays, yesterday]`, oldest first, states `.missed` and `.partial` only; never today, skipped, logged, off, future; never before the effective log start; `windowDays` clamped to 7...365. `next(after:in:)` returns the first element strictly after the given day (first element for `nil`), `nil` when none. `skipDays` writes one skip marker per day through the existing `skip(_:reason:)` rules and returns only the days it changed (a day with writing is left alone, not an error); `unskipDays` removes markers only when the file is still a pure skip marker and returns the days restored; a skip -> undo round trip leaves the folder byte-identical.
- [ ] Failing tests: window edges (day exactly `windowDays` back included, one further excluded); a skipped run and a partial day; logStart cuts the list; `next` over empty/one/many; `skipDays` on 3 missed days + 1 written day returns 3 and leaves the written page untouched; undo restores; undo after the user typed into a skipped day leaves it alone; 30 days performance under 50 ms.
- [ ] Run -> FAIL. - [ ] Implement. - [ ] Run -> PASS.

### Task C5: Week review completeness
**Files:** `app/Core/WeeklyReview.swift`, `tests/main.swift`. **Scope:** S.
**Acceptance:** `WeeklyReview.summary(weekContaining:...)` returns an entry for **every scheduled day of the week** (also for weeks with zero files and for the current week's future days, marked `.future`), honours `calendar.firstWeekday`, and exposes `missingDays` (the scheduled, past, unwritten days of that week). Existing behaviour and tests stay green.
- [ ] Failing tests: a week with no files lists 5 entries (Mon-Fri) all `.missed`; a week starting on Sunday when `firstWeekday == 1`; the current week lists future days as `.future`; `missingDays` matches `CatchUp.missing` restricted to the week.
- [ ] Implement; run; PASS.

### Task C6: `folderStamp` and the kill test
**Files:** `app/Core/LogStore.swift`, `app/Tools/kill-test/main.swift`, `tests/run-kill-tests.sh`, `tests/main.swift`. **Scope:** M.
**Acceptance (stamp):** `folderStamp()` is a stable string over sorted `(name, mtime, size)` of the `YYYY-MM-DD.md` files only; unchanged folder -> identical stamp; add, edit, delete, touch -> different; `assets/` and non-markdown ignored; 3,650 files in under 50 ms; no file contents read. **Acceptance (kill):** `bash tests/run-kill-tests.sh` runs 40 rounds: a child process saves pages (2 KB bodies, backups on) in a loop; the parent SIGKILLs it at a random 5-300 ms; after each round every day file is a complete version that was written (never truncated or empty), at most one stray temp file exists and is cleaned by the next save, and backups are valid; prints `40/40 rounds clean`.
- [ ] Failing stamp tests. - [ ] Implement `folderStamp`. - [ ] Build the kill harness; run it; fix any real data-safety bug it finds in `LogStore` (add a regression test) - report such a finding prominently.

**Checkpoint C:** `bash tests/run-tests.sh` all pass, no warnings; `bash tests/run-kill-tests.sh` 40/40; stub bodies are gone.

---

## 5. Stream N: Navigation (tasks N1 to N8)

Read `UX_FLOWS.md` sections 1 to 3 and 5, `DESIGN_V4.md` navigation, sidebar, calendar, catch-up and toolbar sections. Use the skills ui-ux-pro-max:ui-ux-pro-max and antislop:antislop-ui when they are available to you.

### Task N1: Navigation model, any-date opening, refresh policy
**Files:** `AppModel.swift`, `AppModel+Browse.swift`, `AppModel+Day.swift`, `AppModel+Editor.swift`, new `AppModel+Calendar.swift`, `AppModel+CatchUp.swift`. **Scope:** L (split if you need).
- [ ] `Destination` gains `.catchUp`; `openDay(_:)` accepts any date from 2000-01-01 to today whether or not a file exists and **writes nothing until the first real edit** (existing guard); `step(_:)` walks **calendar days** (previous/next date), not the history list; `⌘]` on today does nothing.
- [ ] `cal` comes from `AppModel.makeCalendar(weekStart:)` and is rebuilt when `settings.weekStart` changes.
- [ ] Replace the 30 s full `reload()` with: a clock tick that only updates `now` and the day rollover; reload only when `store.folderStamp()` changed, on app activation, after saves/skips/restores, and after settings changes.
- [ ] Published `catchUpDays` (from `CatchUp.missing` using `settings.logStartDate`, `catchUpWindowDays`, `settings.weekdays`, `minWords`-derived states) and `monthGrid(year:month:)`; streak and heatmap use `Status.effectiveSince(setting: settings.logStartDate, ...)`.
- [ ] **Log-start pinning:** when a page is saved for a day earlier than the effective start and `settings.logStartDate == nil`, set `settings.logStartDate` to the previous effective start and save settings, so backfilling never creates a wall of "missed" days (M1-A9).
- **Verify:** scenario `nav.backfill-before-first-log`: fixture with logs from 1 Oct; write 12 Sep; assert catch-up list unchanged, streak unchanged, 13-30 Sep are `.off`.

### Task N2: Sidebar and calendar
**Files:** `Sidebar.swift`, new `CalendarView.swift`, `Heatmap.swift` (moves into the streak popover only), `Theme.swift`, `Components.swift`.
- [ ] Order: search; Today; Catch up (N) with a count badge; Review; month calendar (MonthGrid) with previous/next month, click opens the day, status marks per `DESIGN_V4.md`; Recent (7 newest pages); footer with streak and a **gear that calls `model.openSettings()`** (visible, labelled "Settings", ⌘, shown in its tooltip). VoiceOver label per row and per calendar cell ("Tuesday 6 October, not written").
- **Verify:** real screenshots (light, dark, minimum window size) of the sidebar with a 60-day fixture; clicking a past unwritten date opens an empty page with the template.

### Task N3: Toolbar and Go to date
**Files:** `MainView.swift`, new `GoToDateView.swift`.
- [ ] Unified toolbar: `<` `Today` `>`, the current date label, and **Go to date** (⇧⌘T) as a popover field using `DateJump.parse`, Return opens the day, an unreadable entry shows "Couldn't read that date" inline and keeps the text.
- **Verify:** scenario types `last fri`, `2 oct`, `-3`, `garbage` and asserts the opened day or the inline error.

### Task N4: Catch-up screen and session
**Files:** new `CatchUpView.swift`, `SessionBar.swift`, `SkipSheet.swift`, `AppModel+CatchUp.swift`.
- [ ] Oldest-first list with per-row Write (or Continue for partial) and Skip; multi-select, "Skip selected" with reason chips (Leave, Holiday, Sick, Other) and an **8 second Undo** (`skipDays`/`unskipDays`); "Next missed day" (⌘Return) starts a **session** on the normal editor with a bar "Catching up 3 of 5" and Skip day / Next; finishing the last day shows "All caught up".
- **Verify (R3, R4):** scenario on a fixture with 3 unwritten workdays: open Catch up, write the minimum words in each via the session, time it (the run must be well under the 2:00 budget in automation), see "All caught up"; skip 3 as "Leave", assert 3 markers, streak unchanged, Undo restores.

### Task N5: Week review
**Files:** `WeeklyReviewView.swift`, `AppModel+Browse.swift`.
- [ ] Every scheduled day of any week is listed with Open (also an all-missed week); the empty state offers "Catch up this week"; week start follows `settings.weekStart`; previous/next week arrows; "Copy as markdown" unchanged. Days before the log start are shown muted, not as missed.
- **Verify (R2):** scenario opens last week with no files, opens each of its 5 days from that screen, writes the minimum words, week reads 5 of 5.

### Task N6: Page header and Today notice
**Files:** `PageHeader.swift`, `PageView.swift`.
- [ ] Past-day header shows a relative label ("3 weeks ago") and the date; a quiet dismissible Today notice "N earlier days not written. Catch up"; the page "..." menu gains "Go to date...", "Catch up", and "Settings..." (calls `openSettings()`).

### Task N7: Menus and shortcuts
**Files:** `AppCommands.swift`.
- [ ] Per `UX_FLOWS.md` keyboard map: Go to Date ⇧⌘T, Previous/Next day ⌘[ ⌘], Today, Catch Up, Review; no shortcut collides with the editor's text shortcuts.

### Task N8: Scenarios and evidence
**Files:** `app/Tools/editor-check/ScenarioNav.swift`.
- [ ] Implement `runNavScenarios()` covering N1 to N6 with `check(name, ok, detail)`; save real screenshots (main window, calendar, catch-up, session, week review; light and dark; default and minimum size) to the evidence directory.

**Checkpoint N:** `bash app/build.sh` clean (no warnings); `bash app/Tools/editor-check/run.sh` all pass including the new scenarios; screenshots reviewed.

---

## 6. Stream S: Settings (tasks S1 to S5)

Read `UX_FLOWS.md` section 4 (catalogue) and `DESIGN_V4.md` Settings section. Apple's HIG: no toolbar gear; the entry points below are the plan.

### Task S1: Settings window and entry points
**Files:** `GloamlogApp.swift`, `AppModel+Settings.swift`, new `SettingsWindow.swift`.
- [ ] Replace the `SwiftUI.Settings` scene with `Window("Settings", id: "settings")`; `openSettings(pane:)` opens it in front in under 1 second (store an `openWindow` closure registered from a hidden view, fall back to activating an existing window); `CommandGroup(replacing: .appSettings)` gives "Settings..." ⌘,; the menu-bar popover item and the sidebar gear (stream N) both call `openSettings`. Remove the old scene once the new window opens in the scenario.
- **Verify (R5):** scenario calls `openSettings(pane: .reminders)` and asserts the window is key, on that pane, within 1 second.

### Task S2: Panes
**Files:** `SettingsPane*.swift` (one file per pane), `SettingsTheme.swift`, `TemplateEditor.swift`.
- [ ] Top tab bar (icons + labels, keyboard navigable): **General** (appearance System/Light/Dark, week starts on, open at login, show menu-bar item), **Reminders** (time, weekdays, style Strict/Gentle with the 2-snoozes rule, snooze length, notification status with a button to System Settings), **Page** (template editor, words-to-log stepper with plain-language help, carry-over headings, catch-up window days, **log start date** with "Use first log"), **Storage and backups** (folder with Show in Finder / Change... / Use default, counts from `folderSummary()`, backups folder path with Open, hint where "Restore previous version" lives), **Shortcuts** (read-only list of every in-app shortcut), **About** (version, licence, "Run setup again").
- [ ] Every control has a label, a help line where the effect is not obvious, and an accessibility label; panes are 840 pt wide max with row heights from `DESIGN_V4.md`.

### Task S3: Effects apply at once and persist
**Files:** `AppModel+Settings.swift`.
- [ ] `settings` changes apply immediately without Save: appearance -> `NSApp.appearance`; week start -> rebuild `cal` and refresh month/week views; reminder time/weekdays/style -> re-plan; catch-up window and log start -> recompute `catchUpDays`, streak and heatmap; persisted through `Settings.save`; per-pane "Reset to defaults".
- **Verify (R5):** scenario changes reminder time, style, appearance and week start, builds a **new** `AppModel` over the same defaults suite and asserts every value survived and the menu-bar popover text shows the new reminder time.

### Task S4: Onboarding and menu-bar touch-ups
**Files:** `Onboarding.swift`, `MenuBarView.swift`.
- [ ] Onboarding copy mentions where Settings lives and offers the log start date for people with existing logs; "Run setup again" from About reopens it; the popover shows the next reminder and "Settings...".

### Task S5: Scenarios and evidence
**Files:** `app/Tools/editor-check/ScenarioSettings.swift`.
- [ ] `runSettingsScenarios()` covers S1 to S4; real screenshots of every pane in light and dark.

**Checkpoint S:** `bash app/build.sh` clean; `bash app/Tools/editor-check/run.sh` all pass; screenshots reviewed.

---

## 7. Integration (orchestrator)

- [ ] **I1** Merge check: all three checkpoints green together; fix cross-stream seams (gear -> `openSettings`, `weekStart` -> `cal`, log-start pinning).
- [ ] **I2** Walkthrough (`PRD_V1.md` section 2, R1 to R9) as a timed scenario on a 60-day fixture with gaps, a skipped run, an image and a long page. Fixture only: the owner runs their own copy at I5. Screenshots of the **built app** (not the snapshot stub) in light and dark at default and minimum size, saved to `docs/v1/evidence/M1/`.
- [ ] **I3** Independent review: the Reality Checker agent reviews evidence against R1-R9 with a default of "needs work"; fix every P0/P1 with a regression test.
- [ ] **I4** Docs: README status and what's next, CHANGELOG known issues (K-1 time zone, K-2 notarisation), `FILE_STRUCTURE.md` and old docs marked superseded.
- [ ] **I5** `docs/v1/evidence/M1/OWNER_CHECKLIST.md`: one page, R1 to R9 with exact steps and the pass condition, plus "copy `~/Gloamlog` first".
- [ ] **I6** Commit in logical pieces, push, tag `v0.4.0` only after the owner marks the checklist.

---

## 8. Risks

| Risk | Impact | Mitigation |
|---|---|---|
| Settings window fails to open on the owner's macOS | High (R5) | explicit `Window` scene with a registered `openWindow` closure; scenario asserts it; owner check R5 is first on the list |
| Streams disagree on a contract | Medium | signatures frozen in section 2; changes only through the orchestrator |
| WebKit editor focus quirks inside the catch-up session | Medium | the session reuses the normal editor path (no second writer); scenario types into it |
| Estimate overrun (65-90 h) | Medium | cut order: C5 polish, N7 extras, S2 Shortcuts pane list; never cut R1-R9 |
| Real-world behaviours no agent can run (login item, notifications when closed, sleep/wake) | Medium | listed as unverified in the report; owner check covers R7 |

---

## 9. Self-review: coverage of the PRD

| PRD item | Task |
|---|---|
| R1 / M1-A1 any past date, nothing written until typing | N1, N2, N3 |
| R2 / M1-A5 week review lists every day | C5, N5 |
| R3 / M1-A3 catch up three days in 2:00 | C4, N4 |
| R4 / M1-A4 skip 3 with Leave, Undo | C4, N4 |
| R5 / M1-A6, A7 Settings from the window, persists | S1, S2, S3 |
| R6 / M1-A8 force-quit loses nothing | C6 (kill test) + existing editor-check quit-flush scenarios + owner check |
| R7 reminder opens today | existing planner + S2 Reminders pane; owner check |
| R8 search finds last week | existing search; N2 keeps the box |
| R9 copy week as markdown | existing; N5 keeps it |
| M1-A2 ⌘[ and ⌘] | N1, N7 |
| M1-A9 backfill before first log | C1 (done), N1 |
| M1-A10 no P0/P1 open | I3 |

Placeholder scan: the stub bodies in `app/Core/Calendar/*.swift` are intentional contract stubs, replaced by C2 to C4. Type check: `Destination`, `SettingsPane`, `CatchUp.missing`, `MonthGrid.rows`, `DateJump.parse`, `skipDays`, `unskipDays`, `folderStamp`, `makeCalendar` and `openSettings` are named identically in every task.
