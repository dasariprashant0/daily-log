# M1 Reality Check: independent review of Milestone 1 (0.4.0 candidate)

**Reviewer**: Reality Checker (independent of the builders; default verdict NEEDS WORK, moved only by evidence I inspected myself)
**Reviewed**: 2026-10-07, about 23:15 to 23:50 local, on the working tree as it was then (the tree was still changing, see E7)
**Judged against**: `PRD_V1.md` section 2 (R1-R9), M1 acceptance M1-A1..A10, requirements SET-4 and DOC-1, release gate 3.1, `UX_FLOWS.md`, `UX_AUDIT_AND_BENCHMARKS.md` D1-D24
**Owner's complaint being tested**: "why am i not able to add anything for previous days or weeks and why is there no settings options ... you haven't setup the flow for the real world scenario ... i don't actually think that this is even ready for me to use"

## 1. Verdict

**NEEDS WORK.** No P0 (data loss, cannot write, crash) found. 5 P1s block sign-off. About 14 P2s.

Does M1 now fix what the owner complained about? In the code and in the real-window harness, yes:

- Any past date opens from the sidebar calendar, Go to date, the toolbar arrows, Catch up rows and Week tiles. Opening writes nothing; the file appears at most 2.5 s after the first typing (`ScenarioNav.swift` R1 checks, run log lines "R1: nothing is written for a day that was only opened" and "R1: two seconds after typing, that day's file exists").
- Catch up lists the unlogged days with a sidebar count, runs a session ("Catching up 1 of 3"), ends on "All caught up. 3 logged.", and skips several days with a reason and an 8 s Undo.
- An empty past week shows all seven day tiles, each opens, and the empty state offers "Catch up this week".
- Settings is a real window with six panes, reachable from the sidebar gear and the menu-bar popover, and it opened in 14 ms (prewarmed) / 368 ms (cold) in the builder's run.
- Writing before the first log pins the log start, so no wall of "missed" days appears (M1-A9, checked end to end).

Why it is still NEEDS WORK (all detailed in section 6):

1. **P1-1** ⌘[ and ⌘] (M1-A2) are swallowed by the editor whenever the caret is in a bullet, a task item, a table or a code block, and they then edit the list instead of changing day. No keystroke test exists.
2. **P1-2** About will say "Version 0.3.0" (`app/build.sh:39-40`); SET-4 requires 0.4.0. The What's New sheet still says "0.3".
3. **P1-3** Release gate 3.1(b) is not met: none of the 41 screenshots is from the built `Gloamlog.app`, all 19 main-window shots are of a non-key window, the Go to date popover shot is unusable, there are no error or empty-state shots, and nothing is saved in `docs/v1/evidence/M1/` (it did not exist).
4. **P1-4** Release gate 3.1(a) is not met: no CI guard for network APIs, macros or third-party dependencies, CI runs neither the kill test nor the editor check, and there is no build log.
5. **P1-5** M1-A10 is not met: no walkthrough findings list, no REPORT.md, no OWNER_CHECKLIST.md, no frozen M1 tree. The M2 streams are editing M1's files (editor bundle, `tests/main.swift`, `Settings.swift`) while M1 is being reviewed.

What is solid (checked, not assumed): the pure-core tests are strong and adversarial (1271 assertions, I re-ran them: 0 failed); the kill test is mutation-tested (a deliberately non-atomic writer fails 12/12 rounds in `kill-mutant.log`, the real store passes 40/40 in `final-kill.log`); the harness drives the real WKWebView editor and the real window for R1, R2, R3, R4 and R9.

## 2. Method and limits

- **Read**: the three docs named above plus `M1_BUILD_PLAN.md`; all 19 main-window + 2 crop screenshots in `m1-evidence/nav/` and all 20 in `m1-evidence/settings/` (the 20 files in `settings/offscreen/`, from a forced-locked run, were not viewed); `app/UI` (AppModel*, MainView, Sidebar, CalendarView, GoToDateView, CatchUpView, SessionBar, SkipSheet, WeeklyReviewView, PageView, PageHeader, DayEditor, Settings*, Onboarding, MenuBarView, AppCommands, GloamlogApp, AppDelegate, Notifier, Theme, Components); `app/Core` (LogStore, Models, Settings, Streak, CatchUp, MonthGrid, DateJump, WeeklyReview, ReminderPlanner); the M1 test blocks in `tests/main.swift` (lines 1165-2076); `ScenarioNav.swift`, `ScenarioSettings.swift`, `Scenarios.swift`, `Screens.swift`, the kill test header; builder run logs (`s-full-run3.log`, `final-kill.log`, `kill-mutant.log`).
- **Ran**: `bash tests/run-tests.sh` once, outside the sandbox: **1271 passed, 0 failed**, 16 s including compile (`skipDays(30)` 11 ms, `folderStamp` over 3,650 files 18 ms). Nothing else.
- **Did not run**: the editor-check harness, `app/build.sh`, the kill test, the app. Builder logs are treated as claims: they say 339 harness checks passed, 0 failed, 0 skipped (settings: 106/0/0; run finished 23:26) and the kill test 40/40 rounds clean.
- **Pixel measurements** (contrast, window state) came from a small PNG reader I wrote against the screenshot files; numbers are in Appendix A.

## 3. Evidence quality findings

| # | Finding | Why it matters |
|---|---|---|
| E1 | The harness binary is the app **minus** `GloamlogApp.swift` (`run.sh`: `find ... ! -name GloamlogApp.swift`). The About shot shows "Development build" and a generic blue folder icon (`settings-about-light.png`, `-dark.png`), which only happens outside a bundle. | Gate 3.1(b) says screenshots come from the built `Gloamlog.app`. The scene lifecycle, ⌘, command, menu-bar item, Dock behaviour, Info.plist version and icon were never on screen. |
| E2 | All 19 main-window shots in `nav/` are of a **non-key window** (grey traffic lights; toolbar buttons 1.86:1 light / 2.2:1 dark). 7 of the 14 Settings window shots are non-key too (about-light, general-light, storage-light, shortcuts-light, reminders-dark, page-end-light, page-end-dark); the other 7 are key (red close button, blue accent). | Toolbar contrast, selected states and focus cannot be judged from the nav set, and the Settings set is inconsistent. I did **not** treat the washed-out toolbar as an app defect. |
| E3 | `go-to-date-light-popover.png` is unusable: background RGB(71,71,71), hint text 1.43:1, future-day numerals 1.74:1. Probably a vibrancy artifact of capturing the popover as its own window, but it means the only screen for "Go to date" (an M1 scope item) has no valid picture. There is no dark shot, no typed/resolved shot ("-> Fri 2 Oct 2026") and no error shot ("Couldn't read that date..."). | Gate (b) requires reviewed shots of every changed screen in light and dark and in normal, empty and error states. |
| E4 | Missing states: folder missing / unwritable banner on a page and on Catch up, Catch up new-user ("Nothing to catch up on yet") and standalone "You're all caught up", Today notice in dark, single-yesterday notice, month-picker popover, streak popover, "Write a log anyway" skipped page, first-run onboarding steps. | Same gate. M1-A8's "existing banner shows" has no picture. |
| E5 | Screenshots live in a `/private/tmp/.../scratchpad` folder. `docs/v1/evidence/` did not exist before this review. | The gate says "Saved in docs/v1/evidence/M<n>/". A temp folder is not evidence. |
| E6 | The nav set was written at 21:35. `Streak.swift` changed at 22:29, the `.app` was built at 22:30:44, and the Settings set was rewritten at 23:25. The nav shots in `m1-evidence/nav/` were not re-taken after that. | The pictures may not show the current UI. |
| E7 | The tree is a moving target. M2 streams K/E/U (see `M2_BUILD_PLAN.md` section 2) edit M1 files in the same tree: `app/Resources/editor/index.html` and `editor-web/src/main.js` changed at 23:24:47 (during the last full harness run, which started 23:24) and again at 23:32:22 and 23:36:23; `Settings.swift` gained `capture` at 23:15; `tests/main.swift` changed at 23:37 (after my test run). `app/Gloamlog.app` (22:30) has an older editor bundle than `app/Resources/editor/`. No git, no tag. | The owner would test whatever is built at that moment. The editor bundle is the thing R6 (no lost text) depends on, and it changed after the last harness run. |
| E8 | Harness caveats stated by the builders themselves: menu key equivalents "(⌘[ ⌘] ⌘↩) are not exercised" (`ScenarioNav.swift:8`); the Settings scenarios use `live: false` models, do not run the App lifecycle, and "⌘, ... and the real menu bar item are not exercised" (`ScenarioSettings.swift:4-10`); buttons are pressed through the accessibility tree, text is injected with `execCommand`. | These limits decide several verdicts below. |

## 4. R1 to R9 (the owner's rows)

All nine still need the owner's own check by definition. "PASS (harness)" means the flow as the row words it is proven in the real-window harness plus code; it is not a pass of the row.

| Row | Verdict | Evidence and caveats |
|---|---|---|
| R1 workday last month, via the calendar | **PASS (harness)** | `ScenarioNav.swift:286-303`: previous-month arrow, click the cell, template shown, nothing written after 2.2 s, file exists within 2.5 s of typing and holds title, template and text, badge 6 -> 5. Caveats: the harness focuses the editor through JS; a calendar click calls `openDay(k)` with `focus: false` (`AppModel.swift:263`), so the owner probably needs one click into the page before typing (P2-4). A day before the first log shows "Before your log start..." (expected). |
| R2 last week, open each workday, week reads 5 of 5 | **PASS (harness)** | `ScenarioNav.swift:420-448`; shots `week-empty-light/dark/min-light.png`, `week-full-light.png`. Tiles say "Write", not "Open" (cosmetic). |
| R3 three workdays, Catch up, 2:00 | **PASS (harness) for function; UNVERIFIED for the 2:00** | `ScenarioNav.swift:464-504`. The "timed 14.6 s" is JS-injected typing, not a human. A Strict reminder firing mid-session ends the session (P2-2) and the session bar can show the wrong day after clicking the calendar (P2-1). |
| R4 select 3, skip as Leave, Undo | **PASS (harness), selection gesture UNVERIFIED** | `ScenarioNav.swift:508-534`. The three rows are selected by assigning `catchSelection` (`:520`); the ⇧-click / ⌘-click handler `CatchUpView.swift:41-50` never ran. Undo exists for 8 s on the Catch up screen only. |
| R5 Settings from the window, change four things, Show in Finder, relaunch | **UNVERIFIED (partial)** | Executed: window opens key in 14 ms / 368 ms cold, six panes, Dark and Gentle clicked with real events, log start buttons, persistence through a **new `AppModel` over the same defaults suite**, popover Settings click. Not executed: the main-window gear click (only its presence is asserted, `ScenarioNav.swift:272`), ⌘,, "Show in Finder", the reminder-time and week-start controls (set through the model), a real relaunch. `revealFolder()` highlights the folder inside its parent (`AppModel+Storage.swift:16`), so Finder will not show the `.md` files without one more double-click (P2-11). About will read 0.3.0 (P1-2). |
| R6 force-quit after 2 s; ⌘Q right after typing | **UNVERIFIED in the app** | Supporting: autosave is ~0.9 s after typing and R1 proves the file exists by 2.5 s; `flushForQuit` is tested ("quit flush saves an edit made a moment ago", `Scenarios.swift:205-209`); `LogStore` survives SIGKILL (kill test 40/40, 3,043 saves, mutation-tested). Not covered: a real SIGKILL or ⌘Q of the app (`applicationShouldTerminate`). The kill test covers the store, not the web-debounce + autosave pipeline. |
| R7 reminder 2 min ahead, window closed | **UNVERIFIED** | No scenario. By code: Strict first fire posts a notification (needs the bundle and permission; the pane shows "Gloamlog hasn't asked to send notifications yet. [Allow]") and `openDay(today, focus: true)` (`AppModel+Reminders.swift:56-60`); a notification click opens Today (`Notifier.swift:63`); the menu-bar icon follows `todayStatus`. Reminders only fire while the app runs (the Reminders pane says so). The PRD's parallel notification spike has no recorded result. |
| R8 search a word from last week | **PASS (harness), speed UNVERIFIED** | `Scenarios.swift:245-254`: finds the saved page, opens that day, selects the match. Search was not changed in M1. "Under 1 second" not timed on a real folder. |
| R9 copy last week as markdown | **PASS (harness)** | `ScenarioNav.swift:450-456`: clipboard begins `# Week of 28 Sep`, holds each day under its date, contains none of 8 chrome strings (a weak blacklist). Header counts are slightly off (P2-12). |

## 5. M1-A1 to A10, SET-4, DOC-1, gate

| Item | Verdict | Evidence / why |
|---|---|---|
| M1-A1 empty page from the calendar, nothing written until typing, file 2 s after | **PASS** | As R1: `ScenarioNav.swift:286-303`; app scenario: a page that was only opened is never created (`Scenarios.swift:67-72`). |
| M1-A2 ⌘[ / ⌘] | **FAIL (keystroke path), PASS (button and model)** | Toolbar arrows and `step()` work through gaps and stop on today (`ScenarioNav.swift:305-319`), but the test is named "⌘[" while it presses a toolbar button (`:308`, `:310-316`). The bundle binds `Mod-[` / `Mod-]` to LiftListItem / SinkListItem, table NextCell / PrevCell and the code-block indent keys; `AppCommands.swift:3-6` admits the collision. In a bullet, ⌘[ un-bullets the line and does not navigate. See P1-1. |
| M1-A3 3 unwritten days, count drops, Next, All caught up | **PASS** | `ScenarioNav.swift:476-503`; shots `catch-up-light.png`, `session-light.png`, `catch-up-done-light.png`. The button reads "Next unlogged day" (UX_FLOWS D2 renames "missed"; documented and acceptable). ⌘↩ never exercised. |
| M1-A4 select 3, Skip, Leave, markers, streak, Undo | **PASS** | `ScenarioNav.swift:520-534` plus core tests (`tests/main.swift:1658-1767`: byte-identical undo, all-or-nothing, streak neutral). Selection set through the model; Undo only while the 8 s banner shows. |
| M1-A5 empty past week lists every day; offers Catch up this week | **PASS** | `week-empty-light.png` (seven tiles, "Catch up this week" + "Go to today"); `ScenarioNav.swift:429-431`. |
| M1-A6 Settings opens in front in < 1 s from the window, popover and ⌘, | **PASS for the controller and the popover; UNVERIFIED for the gear and ⌘,** | Log: "openSettings ... key within 1 s" (14 ms), cold 368 ms, popover click opens it key. The sidebar gear (`Sidebar.swift:212-216`) and `SettingsCommands` (`SettingsWindow.swift:159-165`) are one-line calls to the same door but were never clicked or keyed. |
| M1-A7 time, style, appearance, week start survive relaunch; popover shows time; week starts on chosen day | **PASS as a proxy, relaunch UNVERIFIED** | New model over the same suite: `ScenarioSettings.swift` S3 persistence block; "popover's reminder line carries the new time and style"; week start Monday and Sunday tested in the model and core, Monday in the Week review UI. |
| M1-A8 force-quit or ⌘Q loses nothing; unwritable folder shows the banner and keeps text | **UNVERIFIED in the app; PASS at model level** | See R6. Unwritable folder: `Scenarios.swift:194-203` asserts `errorText` and the editor text, not the banner; no banner screenshot (E4). |
| M1-A9 backfill before the first log: no wall of missed, streak unchanged | **PASS** | `ScenarioNav.swift:378-401` (pin saved to defaults, 13-30 Sep `.off`, heat map agrees, streak unchanged) plus core `tests/main.swift:1166`. |
| M1-A10 no P0/P1 open, regression test per fixed defect | **FAIL** | No walkthrough list exists; P1-1 to P1-5 are open. |
| SET-4 About shows 0.4.0 | **FAIL** | `app/build.sh:39-40` stamps 0.3.0; the harness shows "Development build". |
| DOC-1 docs match the app | **FAIL** | `CHANGELOG.md:10-11` still lists the owner's original complaint as a known issue; README says "v0.3, not ready"; `docs/ARCHITECTURE.md` line 3 says all code is in `app/Gloamlog.swift`; `FILE_STRUCTURE.md` untouched. K-1 (time zone) is not recorded anywhere. |
| Gate (a) automated checks | **FAIL** | No guard for network APIs / macros / third-party code (the M1 plan cut it, `M1_BUILD_PLAN.md` section 0, though PRD 3.1 says never cut the gate); `.github/workflows/ci.yml:18-20` runs only `run-tests.sh` and `build.sh`; no build log or warning check shown. |
| Gate (b) real screenshots, reviewed | **FAIL** | E1-E6. |
| Gate (c) owner checklist | **NOT STARTED** | `docs/v1/evidence/M1/OWNER_CHECKLIST.md` does not exist. |

## 6. Defects, ranked

### P0 (data loss, cannot write, crash)

None found. What I looked for: the autosave / flush / orphan paths (`DayEditor.swift`, `AppModel+Editor.swift`), the delete-on-empty path (`LogStore.save`, body empty -> backup then remove; user-initiated only and backed up), skip / unskip (`LogStore.skipDays`, all-or-nothing, never touches writing), log-start pinning (`AppModel.didSave`), folder-error paths, and crash sources (force unwraps, empty ranges in pickers, calendar symbol indexing). This is not proof of absence: R6 has not been run in the real app.

### P1 (blocks an acceptance criterion or the gate)

**P1-1. ⌘[ and ⌘] do not navigate in lists, tables and code blocks, and silently edit the page (M1-A2).**
- Where: `app/Resources/editor/index.html` (listItemKeymap `LiftListItem: ["Shift-Tab","Mod-["]`, `SinkListItem: ["Tab","Mod-]"]`; tableKeymap `Mod-[`, `Mod-]`, `Mod-Enter`; CodeMirror `Mod-[`, `Mod-]`, `Mod-Enter`); `app/UI/AppCommands.swift:3-6` (comment accepts it), `:35-38`, `:41`; `ScenarioNav.swift:8` (not exercised), `:308-316` (button + `step()` instead).
- Impact: this app's pages are headings plus bullets; with the caret in a bullet, ⌘[ lifts the item out of the list (an autosaved edit) instead of opening yesterday. The Shortcuts pane (`settings-shortcuts-*.png`) promises ⌘[ and ⌘] without a caveat.
- Fix: in `EditorWKWebView` (`app/UI/EditorSupport.swift:36`) override `performKeyEquivalent(with:)`: when `event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command` and `charactersIgnoringModifiers` is `[`, `]` or `\r`, `return NSApp.mainMenu?.performKeyEquivalent(with: event) ?? false`, else `super`. Add a harness check that sends a real ⌘[ event with the caret in a bullet and asserts the day changed and the page text did not.

**P1-2. Version and What's New say 0.3.**
- Where: `app/build.sh:39-40`; `app/UI/SettingsPaneAbout.swift:8-13` shows the plist version; `app/UI/MainView.swift:71` ("What's new in 0.3"), `AppModel.swift:35` (`dailylog.whatsNew.0.3`).
- Impact: SET-4 fails. The owner upgrading from 0.3 has already dismissed the 0.3 sheet, so nothing announces Catch up, the calendar or where Settings lives, which is the owner's whole complaint.
- Fix: set both plist strings to 0.4.0; add a `whatsNew.0.4` key and a short sheet (calendar, Catch up, Settings gear, ⌘, ).

**P1-3. Gate 3.1(b) evidence is not valid yet.** See E1-E6.
- Fix: freeze M1 first (P1-5). Build the app, launch it, activate it, wait for `isKeyWindow` before every capture, and re-shoot into `docs/v1/evidence/M1/`: Today with the notice, past day, calendar month and strip, Go to date (light and dark, empty, resolved, error), month picker, Catch up (normal, selected, empty, new user), skip sheet, session, Week (empty, full, section), all six Settings panes with the window key, menu-bar popover, onboarding, About showing 0.4.0, and the folder-missing / unwritable banner on a day page and on Catch up; light and dark; default and minimum size.

**P1-4. Gate 3.1(a) incomplete.**
- Where: `.github/workflows/ci.yml:18-20`; `M1_BUILD_PLAN.md` section 0 (CI guards cut).
- Fix: add a short guard script to CI (grep `app/Core app/UI` for `URLSession|NWConnection|import Network|@Observable|#Preview|#Macro`; fail if a `Package.swift` / `Podfile` appears); add `bash tests/run-kill-tests.sh` to CI; keep the `bash app/build.sh` output (warnings visible) with the evidence.

**P1-5. M1 is not closed.**
- Where: `docs/v1/evidence/M1/` (empty before this file); M2 edits listed in E7.
- Fix: commit and tag the M1 tree; move M2 work to its own branch or copy; re-run `run-tests.sh`, `run-kill-tests.sh` and the editor check on that exact tree; write the walkthrough findings, `REPORT.md` and the one-page `OWNER_CHECKLIST.md` (R1-R9 steps, "copy ~/Gloamlog first") before asking the owner to test.

### P2 (polish, or real but not blocking an acceptance row)

- **P2-1 Session bar can name a different day than the page, and the skip sheet never names a day.** `openDay` only ends a session when the target is outside it (`AppModel+Editor.swift:30`); opening another in-session day by calendar, Go to date or ⌘[ leaves `session.current` stale. `SessionBar.swift:18` (label), `:25-26` (‹), `:27` (Skip day acts on `session.current`). `SkipSheet.swift:33-50` shows a date only in list mode, so "Skip this day?" does not say which. Result: the owner can skip Fri 2 Oct while looking at Tue 6 Oct. No data is lost (skip refuses writing) but there is no Undo banner on this path. Fix: `session?.current = k` when `k` is in `session.days`; title the sheet "Skip Fri 2 Oct?".
- **P2-2 A Strict reminder pulls the owner out of Catch up.** `AppModel+Reminders.swift:56-60` calls `openDay(today, focus: true)`, which ends the session (`AppModel+Editor.swift:30`). UX_FLOWS 2.6(b) and RM2 say a forced window must never navigate away from what you are typing. The first-run default is still Strict (`Settings.swift:45`). Fix: when the open page is not Today (or a session is on), show the notice only.
- **P2-3 Notices still push the page down (audit D7).** `PageView.swift:99-102`, `:169`: no reserved 32 pt slot; the new Today catch-up line (`:141-153`) adds a second shifting banner (visible in `main-today-light.png`). Fix: reserve one 32 pt row or overlay the notice.
- **P2-4 Opening a day from the calendar, a Catch up "Write" or a week tile does not focus the editor.** `AppModel.swift:263` -> `openDay(k)` (focus false); `CatchUpView.swift:230`, `WeeklyReviewView.swift:99`, `CalendarView.swift:204`. The harness hides it by focusing through JS. Fix: pass `focus: true` from user-initiated routes. Check on the owner's Mac.
- **P2-5 Catch up copy and scope are not accurate.** Empty state says "Every working day since {log start} has a page or a skip" (`CatchUpView.swift:187-188`) although only the last N days were checked; the scope "Since log start" is really 365 days (`:110`); the skip sheet prints "Wed 23 Sep to Fri 25 Sep" for a non-contiguous selection (`SkipSheet.swift:37-40`). Fix: say "in the last 30 days"; compute the longest scope from `since`; list the days.
- **P2-6 Today notice is not "once a day".** It shows on every visit to Today until dismissed (`AppModel+CatchUp.swift:41`); the single-yesterday variant ("You haven't logged Thu 8 Oct. [Write it] [Skip day]", `PageView.swift:142-146`) and the dismiss have no assertion. Fix: add both to `ScenarioNav`; decide whether to auto-hide after the first view.
- **P2-7 Keyboard and VoiceOver reach is partial (XC-4, UX_FLOWS 5.1, A2).** Catch up row selection is mouse-only (⇧/⌘-click); ⌘A, S / Delete, Return, calendar arrow keys are not implemented (no `onKeyPress` / `keyboardShortcut` in `CatchUpView`, `CalendarView`, `WeeklyReviewView`). "Skip all N days..." in the menu is the keyboard route.
- **P2-8 Calendar edge days.** Days outside the shown month get no unlogged ring and 55% opacity (`CalendarView.swift:95`, `:100`; digits measure 2.1:1), yet they are clickable and counted by Catch up: in `week-empty-light.png` 28-30 Sep have no marks while the badge says 5. Fix: show the ring at full contrast, dim only the digit.
- **P2-9 Menu-bar popover has no Catch up row and no "Write {yesterday}"** (`MenuBarView.swift:31-62`; UX_FLOWS 3.8). J3 "yesterday from one click" works from the Today notice only.
- **P2-10 "✓ Copied ✓".** `WeeklyReviewView.swift:56` uses a checkmark icon and a "Copied ✓" label; visible in `week-sections-light.png`. Fix: label "Copied".
- **P2-11 Settings discoverability and Show in Finder.** The window entry is an unlabelled 14 pt gear (`Sidebar.swift:212-216`) for an owner whose complaint was not finding Settings; add the word "Settings". `revealFolder()` should open the folder (`NSWorkspace.shared.open`) so R5's "Finder shows plain YYYY-MM-DD.md files" holds without another click.
- **P2-12 Copied week header counts.** `WeeklyReview.summary` counts pre-log-start days and an unwritten today in `workdayCount`, so the header can read "Logged 3 of 5 workdays" in the first week (`WeeklyReview.swift:76`). The UI line uses `weekCounts()` and is right.
- **P2-13 Pre-existing or documented items still open**: audit D24 ("The editor isn't available." has no action, `PageView.swift:118-120`); D22 (Skip setup only on step 1, `Onboarding.swift:98-102`); images appear to crop rather than scale at narrow widths (compare `main-past-day-light.png` with `main-min-light.png`: the green block loses its left edge; cause not checked in the editor CSS); time shows "4:55 PM" (system picker) next to "4:55 pm" elsewhere (`Fmt.time` lowercases); the time zone snapshot K-1 (`AppModel.swift:45`, `:128`); the notification spike has no result.
- **P2-14 Behaviour the harness cannot see**: first-click focus (P2-4), ⇧/⌘-click (R4), hover states, the double-tap delay from combining `onTapGesture(count: 2)` with a single tap on Catch up rows (`CatchUpView.swift:240-241`).

## 7. Audit defects D1-D24

| D | Status | Evidence |
|---|---|---|
| D1 past days unreachable | **Fixed** | Calendar, Go to date, arrows, Catch up (R1, M1-A1). |
| D2 week dead end | **Fixed** | Seven tiles, "Catch up this week" (`week-empty-light.png`). |
| D3 streak punishes, repeated | **Partly** | Repairable: the streak is computed from files and "R3: the streak healed" passes. Not forgiving: one past miss still resets it (`Streak.swift:48`). Still shown in the footer, Today chip, streak popover, menu bar and the "All caught up" line. |
| D4 no route to Settings | **Fixed** | Sidebar gear, page "..." menu, menu-bar popover, ⌘,. The gear click is untested (section 8). |
| D5 Settings thin | **Fixed to the PRD M1 list** | 6 panes: appearance, week start, catch-up window, log start, backups, run setup again, per-pane reset. UX_FLOWS' 11 panes belong to later milestones. |
| D6 reminders die with the process | **Open (M5a)** | The Reminders pane says so honestly ("Reminders arrive while Gloamlog is running"). |
| D7 Strict default, banner shifts page | **Open** | P2-2, P2-3; `Settings.swift:45`, `PageView.swift:99-102`. |
| D8 quota framing | **Fixed** | "0 words. Counts as logged at 20." (`main-today-light.png`). |
| D9 no quick capture | **Open (M2)** | Out of M1 scope. |
| D10 no export | **Open (M3)** | Copy as markdown only. |
| D11 cannot move / merge / delete a page | **Open** | UX_FLOWS marks it Could. |
| D12 helpers only for today | **Partly** | Catch-up notice and session added; carry-over is still Today-only. |
| D13 past-day orientation | **Fixed** | Relative label, no streak chip on past days, arrows, "Before your log start" note (`main-past-day-light.png`). |
| D14 no toolbar | **Fixed** | Previous, Today, Next, Go to date (`main-today-light.png`). |
| D15 five empty headings, persisted | **Open** | R1 asserts the saved file contains "## What I did". |
| D16 weekly review thin | **Open (M3)** | The streak is no longer in the header. |
| D17 sync unsafe | **Open (M5b)** | Out of M1 scope. |
| D18 day boundary / time zone | **Open** | Planned as known issue K-1; not written in CHANGELOG yet. |
| D19 heatmap legibility | **Partly** | Calendar uses shapes; marks are 6 pt; edge-of-month days measure 2.1:1 (P2-8); the popover heat map is unchanged. |
| D20 30 s full rescan | **Fixed** | Folder-stamp gate; "three 30 s ticks ... do not re-read the folder" passes. |
| D21 jargon | **Partly** | "Review" renamed; "Skip day..." / "Skip this day" / "Skip day" and "N files not recognised" remain. |
| D22 onboarding | **Open** | P2-13. |
| D23 history rows | **Partly** | 7 newest plus the calendar; rows still show only date and glyph. |
| D24 error banner has no action | **Open** | `PageView.swift:118-120`. |

## 8. Do the assertions prove what their names claim?

| Name | What it actually proves | Gap |
|---|---|---|
| "M1-A2: ⌘[ from Mon 5 Oct opens Sun 4 Oct" (`ScenarioNav.swift:308`) | Toolbar button AXPress and `step()` | No key event, no caret in a list; the collision in P1-1 is invisible to it. |
| "R3 (timed) ... budget 120 s" (`:499`) | Automation speed with JS-injected text | Not a human time; says nothing about R3's 2:00. |
| "A3: the badge drops ... within 2 s of the save" (`:493`) | `catchUpDays` recomputed synchronously by `didSave`, after `writeDay` already waited up to 4 s | The real 2 s bound is R1's file check only. |
| "R4: the selection bar says 3 selected" (`:520-522`) | `catchSelection` assigned in code | `CatchUpView.click` never runs. |
| "sidebar: ... and Settings are in the window" (`:272`) | The gear exists in the AX tree | Never pressed. |
| "Today says so, once, quietly" (`:279`) | The text is present once | No dismiss, no once-a-day, no single-yesterday variant. |
| "R2: each tile is a button (also Sat and Sun)" (`:428`) | AX nodes exist | Only workday tiles are pressed. |
| "week start ... rebuilds the calendar" (`:355-358`, `ScenarioSettings.swift:474-481`) | Setting the model value | The Picker control is never driven; Week review checked for Monday only. |
| "persist" (`ScenarioSettings.swift` S3) | A new `AppModel` over the same defaults suite | Not a process relaunch; `live: false`. |
| "it is the front window of the app" (`ScenarioSettings.swift:289`) | `NSApp.orderedWindows.first === w` | True even when the app is not active (E2). |
| "R9: no app chrome" (`:455-456`) | 8 strings absent | Weak blacklist. |
| Core "log start: backfilling ..." (`tests/main.swift:1166`) | Streak and Status with a **given** pinned start | The pinning itself is only in `navBackfill` (good). |
| Kill test | `LogStore` atomicity under SIGKILL | Not the page-debounce + autosave pipeline, not ⌘Q. |

Flows with **no assertion at all**: ⌘[ ⌘] ⌘↩ ⇧⌘T ⌘2 ⌘3 ⌘, as key events; Go to date typed in the field (Return, "Open", live preview, inline error); month picker; one-week strip arrows; Catch up scope menu and "Skip all N days..."; session End, ‹ and "Skip day"; Today notice dismiss; "This week" and "Catch up this week" clicks; main-window gear; Show in Finder, Change..., Use default, backups Open; weekday toggles, reminder time, week start, catch-up window and words controls (all set via the model); Notifications Allow; menu-bar Open / Skip today / Quit; the confirm dialog behind "Reset to defaults...".

## 9. Cannot be verified without the owner's Mac

1. Real keystrokes with the WebKit editor focused: ⌘[ ⌘] ⌘↩ ⇧⌘T ⌘, (and what each does with the caret in a paragraph, a bullet, a task, a table, a code block).
2. Real mouse gestures: ⇧-click and ⌘-click selection, hover, the single-versus-double tap delay on Catch up rows, clicking the gear and a calendar cell and then typing without clicking.
3. A real force-quit from Activity Monitor and ⌘Q immediately after typing; no "recovered" dialog.
4. Notification permission for an ad-hoc-signed app, whether Strict brings the window forward, the menu-bar icon change, Focus modes, sleep and wake, and the notification spike (a notification surviving quit).
5. Login item approval (`SMAppService`), Gatekeeper "Open Anyway" for the new build, the first-launch settings migration on the owner's existing defaults.
6. The active-window look: accent colour, selected segments and toggles, focus rings, toolbar contrast, vibrancy of the Go to date and menu-bar popovers over the real wallpaper, Increase Contrast and Reduce Transparency.
7. The built `.app` itself: icon, About version, bundled licences, code signature, that the binary matches the final source (the repo's `.app` predates the last source and editor-bundle edits).
8. The owner's real `~/Gloamlog`: first-log date versus "last month", real folder size (reload cost, search under 1 s), iCloud placeholders or conflict copies, whether older gaps make "All caught up" misleading (P2-5).
9. Locale and clock: date-field order (the Settings and onboarding pickers showed D/M/YYYY on the builder's Mac), 12 or 24 hour display, system week start (the Settings pane reads "Sunday" for the builder's Mac).
10. Human timing: R3 in 2:00, R1 end to end, the five-day trial (R10).
11. Spaces and full-screen: Settings and the Strict window coming forward over a full-screen app or another Space.
12. VoiceOver and Full Keyboard Access across the new screens.
13. Time zone changes and DST with the app running (K-1).

## 10. Minimum path to READY FOR OWNER TEST

1. Freeze M1 (commit and tag); keep M2 on its own branch.
2. Fix P1-1 (`performKeyEquivalent`) and P1-2 (0.4.0 and a 0.4 What's New); fix P2-1 and P2-2 if cheap (both are small), since they sit in the R3 flow.
3. Add the CI guard and the kill test to CI (P1-4).
4. On the frozen tree: `run-tests.sh`, `run-kill-tests.sh`, `app/build.sh` (keep the log), editor check.
5. Build and launch the app, re-shoot the evidence list in P1-3 with the window key, save it in `docs/v1/evidence/M1/`, and have someone else review it.
6. Write `OWNER_CHECKLIST.md` (R1-R9, plus: ⌘[ in a bullet, click the gear, Show in Finder, force-quit test) and update README, CHANGELOG (including K-1) and the stale architecture docs.
7. Then hand the build to the owner. Expected: one more revision cycle after their first run, which is normal for a first implementation.

## Appendix A: measurements (from the screenshot files)

| Item | File | Result |
|---|---|---|
| Go to date popover body | `nav/go-to-date-light-popover.png` | background RGB(71,71,71); hint text 1.43:1; future-day digits 1.74:1; "Open" button label 4.52:1 |
| Calendar digit outside the month | `nav/main-today-light.png` | 2.13:1 (opacity 0.55) |
| Future-day digit in the month | same | 4.75:1 |
| Catch up badge | same | 4.85:1 |
| "Catch up" / "Later" links on the Today notice | same | 5.79:1 / 5.77:1 |
| Toolbar "Today" and date pill, non-key window | `nav/main-past-day-light.png`, `-dark.png` | 1.86:1 / 2.2:1 (not representative: window not key) |
| Non-working-day tile text | `nav/week-empty-light.png` | 2.92:1 |
| Weekday toggles, key window | `settings/settings-reminders-light.png` | blue = on, grey = off, clear |
| Window state of each shot | all | nav: 19 of 19 window shots non-key; settings: 7 key, 7 non-key |

## Appendix B: files

- This report: `docs/v1/evidence/M1/REALITY_CHECK.md`
- Evidence reviewed (temporary): `/private/tmp/claude-501/-Users-prashantdasari-Projects-personal/c6039c28-080c-4cd0-8889-b33a20b7d975/scratchpad/m1-evidence/{nav,settings}/`
- Builder logs read: `.../scratchpad/s-full-run3.log`, `final-kill.log`, `kill-mutant.log`, `final-tests.log`
- My test run output: `.../scratchpad/rc-test-run.log` (1271 passed, 0 failed)
