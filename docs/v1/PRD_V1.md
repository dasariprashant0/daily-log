# PRD v1: Gloamlog, ready for daily use

**Status**: Draft for owner review  **Author**: Alex (PM)  **Owner**: Prashant Dasari  **Date**: 2026-10-07  **Version**: 1.0
**Decision needed (before the M1 build starts)**: approve M1 scope, the definition of ready (section 2) and the release gate (3.1); answer or accept the defaults in section 8.
**Baseline**: v0.3.0 checkpoint. Step 0, before any milestone: commit it, as requested. The working folder was not detected as a git repository when this was written, so confirm where the repo lives first.
**Supersedes** the build order in `README.md` ("What's next"), `docs/ROADMAP.md` and the release table in `docs/STRATEGY.md`. `docs/PRD.md` (v0.2) is history. Unchanged: local-only, plain markdown, no network, no telemetry, macOS 13+, builds with Command Line Tools only (no macros, no third-party dependencies).

**Summary**: v0.3 has a good editor and engine but assumes you write each day on that day. Real use is messier: you forget, jot and catch up. v1 is six milestones, each a complete build the owner can install and check alone (only M1 is a prerequisite), ordered by value. M1 makes the app usable every day; M2 to M6 add quick capture, reviews and export, search at scale, closed-app reminders and sync, then Sources. Nothing is "done" until it passes the release gate. Effort is about 120-170 agent-hours in total, about 30 for M1.

## 1. Problem, user, jobs-to-be-done

The owner, after trying v0.3 (verbatim):

> "why am i not able to add anything for previous days or weeks and why is there no settings options for us to modification or whatever the settings is supposed usually give within the app. you haven't setup the flow for the real world scenario ... i don't actually thing that this is even ready for me to use, forget about launching in the real world. please commit the current progress and start building the app for real"

**User**: the owner, a Mac professional on one or more Macs who writes a work log, runs Claude Code and Git daily, and has to account for the work (standups, weekly updates, reviews). One real user (n=1) and no telemetry, so everything here is a hypothesis tested by their own use. Other Claude Code users are a later audience (`docs/STRATEGY.md`); "forget about launching" means they are not a v1 target.

**Problem**: the app serves someone who opens it at 16:55 and writes that day. The owner's real week has gaps (leave, travel, busy days), write-ups happen next morning or in batches, thoughts arrive all day, and the app cannot open a date that has no file. Cost of not solving it: the log is not kept, so the weekly summary, search and review have nothing to work with.

**Why it fails today** (from reading the code; not yet reproduced on the owner's Mac):

| Owner's complaint | Cause found | Fixed in |
|---|---|---|
| Cannot add anything for previous days | Sidebar history lists only days that already have a file (`AppModel.historyDays`); there is no calendar or date picker; ⌘[ and ⌘] step only between days that have files (`AppModel.step`) | M1 |
| ...or weeks | A past week with nothing logged shows only "Nothing logged this week yet" and "Go to today", which hides the per-day Open buttons (`WeeklyReviewView`); days before the first log count as neutral and are hidden | M1 |
| No settings | A standard Settings scene (app menu, ⌘, and the menu-bar popover); nothing in the main window points to it; three small tabs (General, Page, Storage); it may also fail to open on the owner's macOS (unverified) | M1 |
| No real-world flow | Designed around writing each day on its day: no catch-up, no morning prompt, no backfill, no capture during the day | M1, M2 |
| "Not even ready to use" | 580+ core tests and 130+ editor checks, but almost no real use, so unknown defects are expected | M1 walkthrough |

**Jobs to be done** (the owner chose all four in each group):

| # | Job, in the owner's words | When it happens | Proof it works | Milestone |
|---|---|---|---|---|
| J1 | One write-up at end of day | Reminder at the end of the workday | Page logged, nagging stops | M1 (verify), M5 |
| J2 | Jot notes through the day | Mid-meeting or mid-task | Saved in 3 seconds without leaving the current app | M2 |
| J3 | Catch up next morning | Yesterday is empty | Yesterday written from one click | M1 |
| J4 | Catch up several days at once | Back from leave or travel | 3 days done or skipped in under 2 minutes | M1 |
| J5 | Weekly summary to paste | Standup or weekly update | One click, pastes cleanly where I need it | M1 (verify), M3 |
| J6 | Search old entries | "When did I last touch X?" | Found in under a second, even after years | M1 (verify), M4 |
| J7 | Monthly or yearly review | Review or appraisal time | One screen of what I finished, by month | M3 |
| J8 | Export or share | Send to a manager, archive | Markdown, PDF or Share menu in two clicks | M3 |
| J9 | Sync across Macs via a shared folder | Using a second Mac | Same pages and settings on both | M5 |
| J10 | Reminders when the app is closed | App quit or Mac restarted | Reminder still arrives | M5 |
| J11 | Quick capture from anywhere | Any app in front | Key, type, Return | M2 |
| J12 | Auto-fill from Claude Code and Git | Cannot recall the day | Suggested bullets from real activity | M6 |

## 2. Definition of "ready for daily use"

Ready means every row passes on the owner's own Mac, using the built app and a copy of their real log folder. Pass or fail, no "mostly". R1 to R9 are the M1 sign-off; R10 is the five-day trial that follows. Quick capture, sync, closed-app reminders, review formats and Sources are not part of "ready"; each later milestone has its own owner check.

| # | Do this on your Mac | Pass if |
|---|---|---|
| R1 | Pick a workday from last month that has no page, using the calendar in the main window (no menu digging). Write 2 or 3 sentences. | The page opens with your template, nothing is written until you type, and 2 seconds later that date's `YYYY-MM-DD.md` is in the log folder. |
| R2 | Open last week in Week review and open each of its 5 workdays from that screen. Write about 20 words (your minimum, Settings > Page) in each. | Every day opens, even with no page, and the week reads 5 of 5 logged. |
| R3 | With 3 workdays unwritten (use a fixture folder, or move your log start date back in Settings > Page), open Catch up and write about 20 words in each (a sentence or two you already know), moving with "Next missed day". Time it. | 2:00 or less from clicking Catch up to the third day logged; the list ends on "All caught up". |
| R4 | In Catch up, select 3 days and skip them as "Leave". | 3 skip markers, streak unchanged, the days leave the list, Undo brings them back. |
| R5 | Click Settings in the main window (not ⌘, or the menu). Change reminder time, reminder style, appearance and week start; in Storage and Backups click Show in Finder; quit and relaunch. | Settings opens in front in under 1 second; every change survives; Finder shows plain `YYYY-MM-DD.md` files; the same window opens from the menu-bar item and ⌘,. |
| R6 | Type in today's page, wait 2 seconds, force-quit in Activity Monitor. Type again and press ⌘Q at once. Relaunch. | All text is there both times, with no "recovered" dialog. |
| R7 | Set the reminder 2 minutes ahead and close the window. Follow the reminder and write the day up. | The reminder appears and opens today's page; once you pass the minimum words the menu-bar item shows logged and the nagging stops. |
| R8 | Search a word you wrote last week. | Hit and snippet appear in under 1 second; clicking opens the day at that text. |
| R9 | Open last week, Copy as markdown, paste into Notes or your standup tool. | Reads well: only your writing, no app chrome. |
| R10 | Use Gloamlog as your only work journal for 5 workdays. | 5 of 5 workdays logged or skipped, no lost text, no blocking annoyance left open, and you would keep using it. |

## 3. Milestone plan

### 3.1 Release gate (applies to every milestone, no exceptions)

A milestone is done only when all three items are attached to its report (`docs/v1/evidence/M<n>/REPORT.md`). The builder never declares done; the PM does.

- **(a) Automated checks pass** on the final build: `bash tests/run-tests.sh`, `bash app/Tools/editor-check/run.sh`, `bash app/build.sh` with no new warnings, and CI green. Every new rule in `app/Core/` has a test; every code path that writes user files has a kill test (write, kill -9, relaunch, compare); a guard shows no network APIs, macros or third-party dependencies.
- **(b) Real screenshots of every changed screen, reviewed.** Taken from the built `Gloamlog.app` running on a fixture folder (about 60 days with gaps, a skipped run, an image, a long page), in light and dark, in normal, empty and error states, at the default and the minimum window size. Mockups and the snapshot harness do not count (it stubs the editor). Saved in `docs/v1/evidence/M<n>/` and reviewed by someone other than the builder against the acceptance criteria and `docs/DESIGN_SYSTEM.md` (clipped text, contrast, missing states, copy errors, focus order). Fixes are re-shot.
- **(c) The owner's hands-on checklist for that milestone**, run on the owner's Mac with the built app and a copy of their folder (copy `~/Gloamlog` first). The PM writes the one-page checklist from the acceptance criteria before the build starts, so it cannot bend to fit the build. The owner marks each item Pass or Fail; a Fail is fixed, or consciously deferred and listed in the CHANGELOG known issues.

Also required: CHANGELOG and README status updated, version tagged, and no open P0 (data loss, cannot write, crash) or P1 (blocks an acceptance criterion) before the next milestone starts.

### 3.2 Order, value and effort

Agent-hours are hands-on time for an AI coding agent to build, test, screenshot and fix once. They exclude the owner's check (about 45 minutes per milestone) and waiting. Range is +/-40%.

| M | Name | Version | After it the owner can | Why here | Agent-h | Confidence in estimate |
|---|---|---|---|---|---|---|
| M1 | Daily-usable core | 0.4.0 | Write any day, catch up in bulk, set the app up, trust it | Nothing else matters while daily use is blocked | 26-34 | 70% |
| M2 | Quick capture | 0.5.0 | Jot from any app in 3 seconds | Feeds the end-of-day write-up; the second daily habit | 12-18 | 75% |
| M3 | Reviews and export | 0.6.0 | Paste a week, review a month or year, export, share | The payoff that makes writing worthwhile | 18-26 | 65% |
| M4 | Search at scale | 0.7.0 | Find anything across years | Value grows with data; basic search already works | 8-16 | 60% |
| M5 | Reminders when closed, and sync | 0.8.0 | Be reminded with the app closed; use two Macs | Protects the habit; riskier to build, so after the visible wins | 26-36 | 50% |
| M6 | Sources | 0.9.0 | See suggested bullets from Claude Code and Git | Biggest unknown; the manual flow must be trusted first | 30-42 | 40% |

Order is advisory after M1. After the five-day trial, re-rank M2 to M6 by what actually cost you the most (missed days point to M5 first; paste pain points to M3 first). 1.0.0 is cut by the owner after four weeks of daily use; notarisation and distribution are a separate plan.

### M1: Daily-usable core (0.4.0, 26-34 agent-h)

**Owner can then:** write any day, catch up days in bulk, change settings from a real window, and trust that nothing is lost. **Depends on:** nothing. **Parallel spike (2 agent-h):** schedule one local notification, quit the app, and see whether it fires on the owner's Mac; the result decides the M5 design.

**In scope**
- Date navigation: a month calendar visible in the main window with status marks, "Go to date", Previous and Next calendar day (buttons, ⌘[ and ⌘]); any date up to today, including dates before the first log.
- Catch up: a sidebar row "Catch up (N)" listing unwritten scheduled days (default last 30, adjustable), a "Next missed day" flow, skip several days at once with one reason, and a quiet notice on Today when earlier days are unwritten.
- Log start date: days before it are never "missed", so backfilling an old day cannot create a wall of missed days (default: first log; changeable in Settings).
- Week review: every scheduled day of any week is listed and opens for writing, empty weeks included.
- Settings window with visible entry points (gear in the main window, menu-bar popover, app menu and ⌘,). Groups: General, Reminders, Page, Storage and Backups, Shortcuts (list), About. New options: appearance, week start, catch-up window, log start date, backups access, run setup again. Every change applies at once.
- Walkthrough: run section 2 on a fixture and on a copy of the owner's folder, time-boxed to the first 4 agent-h, then re-size M1 from the findings. Fix every P0 and P1; log P2s as issues.
- Doc hygiene: README status and "What's next", CHANGELOG known issues; mark `ARCHITECTURE.md`, `TRD.md` and `FILE_STRUCTURE.md` as v0.1 history, or update them.

**Out of scope:** capture, new review types, export, search changes, sync, closed-app reminders, Sources, notarisation, future-dated pages.

**Acceptance (Given/When/Then)**
- M1-A1: Given a workday three weeks ago with no page, when I click that date in the calendar, then an empty page opens with my template and nothing is written until I type; two seconds after typing, that day's file exists with my text.
- M1-A2: Given today is Wednesday and Tuesday has no page, when I press ⌘[, then Tuesday opens; ⌘] returns to Wednesday; ⌘] on today does nothing.
- M1-A3: Given 3 unwritten workdays, when I open Catch up, then exactly those 3 are listed and the sidebar row shows 3; after I write the minimum words in one, the count drops to 2 within 2 seconds and "Next missed day" opens the next; with none left it says "All caught up".
- M1-A4: Given the Catch up list, when I select 3 days, choose Skip, enter "Leave" and confirm, then 3 skip markers are written, the days leave the list, the streak is unchanged, and Undo restores them.
- M1-A5: Given a past week with no entries, when I open it in Week review, then every scheduled day is listed with Open, and the empty state offers "Catch up this week", not only "Go to today".
- M1-A6: Given the main window, when I click Settings, then the Settings window opens in front in under 1 second; the same window opens from the menu-bar popover and from ⌘,.
- M1-A7: Given I change reminder time, reminder style, appearance (System, Light, Dark) and week start, when I quit and relaunch, then each is as I left it, the menu-bar popover shows the new reminder time, and Week review starts on the chosen day.
- M1-A8: Given I typed in a page, when the app is force-quit 2 seconds later, or I press ⌘Q right after typing, then relaunch shows all my text; with an unwritable folder, the existing banner shows and my text stays on screen.
- M1-A9: Given my log starts on 1 Oct and I write 12 Sep, when I view the heatmap and Catch up, then 13 to 30 Sep are not shown as missed and the streak is unchanged.
- M1-A10: Given the walkthrough list, when M1 is submitted, then no P0 or P1 is open, and each fixed defect has a regression test or a stated reason it cannot.

**Owner's hands-on check:** section 2, R1 to R9 (R10 follows as the five-day trial).

### M2: Quick capture (0.5.0, 12-18 agent-h)

**Owner can then:** press a key in any app, type a thought, press Return, and find it in today's page. **Depends on:** M1 (Settings, Shortcuts tab).

**In scope**
- A global shortcut (proposed default ⌃⌥J; changeable or off in Settings > Shortcuts) opens a small capture panel over any app, including full-screen apps. Return saves, Esc cancels, ⇧Return adds a line break; focus returns to the previous app.
- Saves a time-stamped bullet under a "Jots" heading at the bottom of today's page (created when needed). Safe when today's page is open and being edited, and when the window is closed (the app must be running).
- A "Jot" field in the menu-bar popover and a menu command, for when no shortcut is set.
- If the log folder is unavailable, the note is kept on this Mac and added when the folder returns.
- A day with only jots shows the template above them; jots do not count toward "logged" by default (Q1).

**Out of scope:** capture into other days, selected-text or screenshot capture, URL scheme or Shortcuts action, voice, mobile, capture while Gloamlog is not running.

**Acceptance**
- M2-A1: Given Gloamlog is running with its window closed, when I press the shortcut in another app (including a full-screen one), then a small panel appears over it with the cursor in a text field; Esc closes it, returns focus to the previous app and writes nothing.
- M2-A2: Given the panel, when I type "call with Sam about pricing" and press Return, then the panel closes and today's page ends with `## Jots` and `- 14:32 call with Sam about pricing` (the current time), saved within 2 seconds.
- M2-A3: Given today's page is open with text I just typed, when I capture a note, then my text is untouched, the note appears in the open page, and undo still works.
- M2-A4: Given a day that has only jots, when I open it, then I see the template headings above the jots, nothing extra is written until I type, and the day reads "started", not "logged".
- M2-A5: Given the menu-bar popover, when I type in "Jot" and press Return, then the result is the same as M2-A2.
- M2-A6: Given the log folder is unavailable, when I capture a note, then the panel says it is kept on this Mac, and the note is added to today's page once the folder returns.
- M2-A7: Given Settings > Shortcuts, when I record a new combination, then it works at once and the old one stops; a combination another app already owns shows an error; "Off" removes it.

**Owner's hands-on check**
- [ ] Press the shortcut inside the apps you really use (browser, a full-screen app, your editor); the panel appears over them.
- [ ] Jot 3 notes during a real morning; open today's `.md` file in Finder and see them with times.
- [ ] Type in today's page, then jot from the shortcut: nothing you typed is lost.
- [ ] Rename the log folder, jot, rename it back: the note arrives.
- [ ] Change the shortcut in Settings; the old one stops working.

### M3: Reviews and export (0.6.0, 18-26 agent-h)

**Owner can then:** paste last week into a standup, look back over a month or a year, and export or share it. **Depends on:** M1 (week start).

**In scope**
- One Review screen for Week, Month, Year and a custom range (the Week review generalised): counts of logged, skipped and not-written scheduled days; grouped by Day or by Section; quick buttons "Last week" and "This month". Jots are their own group and are left out of copied summaries unless switched on.
- Year view: 12 month rows with counts; click a month to open it.
- Copy as Markdown, Plain text or Rich text from any review and from a single page.
- Export a range as a Markdown file (with an `assets/` folder holding only the images it uses) or as a PDF; Share through the macOS Share menu.

**Out of scope:** AI summaries, charts or dashboards, custom report templates, Notion or Obsidian integrations, scheduled exports, HTML export (Could).

**Acceptance**
- M3-A1: Given Week review, when I press "Last week", then last week opens with counts and grouping by Day or Section; an empty week shows an empty state with a Catch up link, never a blank page.
- M3-A2: Given Review > Month (September), when it opens, then I see counts of logged, skipped and not-written scheduled days, and the text of every day grouped by template heading, each item dated, plus "Other notes".
- M3-A3: Given Review > Year, when it opens, then 12 month rows with counts appear within 2 seconds for 250 pages, and a click opens that month.
- M3-A4: Given any review, when I Copy as Rich text and paste into Notes or Mail, then headings and bullets keep their structure; Plain text pastes into a chat box with no `##` or `**`; Markdown pastes into a GitHub issue as headings and bullets.
- M3-A5: Given a month whose pages contain images, when I Export as Markdown, then I get one `.md` plus an `assets/` folder with only the images used, and it renders in a Markdown viewer; Export as PDF shows images and dates with selectable text.
- M3-A6: Given the Share button, when I choose Mail or AirDrop, then the macOS share sheet opens with the exported file; nothing is sent until I confirm in the share target.
- M3-A7: Given a range containing skipped days, when I turn "Include skipped days" on or off, then the review and every export change accordingly.

**Owner's hands-on check**
- [ ] Copy last week into the place you really paste it (standup tool, chat, email) in each format; keep the one that reads right.
- [ ] Open last month and read it: is it what you would show a manager?
- [ ] Export last month as PDF and as Markdown; open both.
- [ ] Open Year 2026 and click through two months.
- [ ] Share one week to yourself by Mail or AirDrop.

### M4: Search at scale (0.7.0, 8-16 agent-h)

**Owner can then:** find a phrase from a year ago in under a second. **Depends on:** nothing beyond M1's data.

**In scope**
- Benchmark first: a synthetic 5-year corpus (1,300 pages of about 500 words) and the owner's real folder. If today's scan already meets M4-A1, build only the off-main-thread search, filters and notice below (the low end of the estimate).
- Otherwise: a background index with a disposable cache outside the log folder, updated on save and on external change, usable while it builds.
- Filters: date range (this month, this year, custom) and heading (extends the existing heading filter). Index status and "Rebuild search index" in Settings > Storage.
- Unreadable or not-yet-downloaded files are skipped with a visible "N files could not be searched" notice.

**Out of scope:** semantic or AI search, tags and mentions, OCR of images, saved searches, a Spotlight plugin (Spotlight already finds the `.md` files).

**Acceptance**
- M4-A1: Given the 5-year corpus, when I search for two words, then the first results show within 300 ms (95th percentile, warm), and typing in the search box never stalls (no main-thread block over 100 ms).
- M4-A2: Given the first launch after upgrade, when the index builds, then the app is usable at once, search shows partial results with "Indexing 40%", and the build finishes within 20 seconds for the 5-year corpus.
- M4-A3: Given I save a page or change a file in another editor, when I search for a new word, then it is found within 5 seconds, with no relaunch.
- M4-A4: Given filters "This year" and heading "Finished", when I search, then only Finished sections from this year match.
- M4-A5: Given an unreadable file in the folder, when I search, then results still arrive with a notice naming the file, and nothing crashes.
- M4-A6: Given I choose Rebuild search index, then results for the same query are identical before and after, and deleting the cache by hand loses no data.

**Owner's hands-on check**
- [ ] Search 3 phrases you remember from weeks ago on your real data; compare speed and results with Spotlight.
- [ ] Type in a page while a rebuild runs: no stutter.
- [ ] Filter to a month, then to "Finished".
- [ ] Open Settings > Storage: the index status makes sense.

### M5: Reminders when closed, and sync (0.8.0, 26-36 agent-h, two slices)

**Owner can then:** (5a) be reminded with Gloamlog quit or the Mac restarted; (5b) use one log on two Macs without losing text. **Depends on:** M1. 5a and 5b ship separately, 5a first.

**In scope, 5a (10-14 agent-h)**
- Schedule the end-of-day reminder with macOS itself for the next 14 scheduled days, so it fires when Gloamlog is not running; re-plan on launch, settings change, logging, skipping and day change; cancel when the day is logged or skipped.
- Notification actions: Open, Snooze, Skip today. Settings > Reminders shows "Next reminder: Thu 8 Oct, 16:55" and a clear state when notifications are denied. A "Remind on this Mac" toggle.
- Strict style while closed (forcing a window) is Could, only after a spike on a launch helper; Strict keeps working while the app runs.
- Limits stated in the UI: nothing fires while the Mac sleeps (it arrives on wake); Focus modes can silence it.

**In scope, 5b (16-22 agent-h)**
- Guided "Sync across Macs" setup: choose a shared folder (iCloud Drive first), folder health, and a "join from another Mac" path that skips onboarding.
- An external change to the open page never silently overwrites (keep mine, take theirs, keep both). Conflict copies (iCloud "name 2.md", Dropbox "conflicted copy", Syncthing "sync-conflict") are detected, shown, and merged under a labelled heading, with the extra file moved to backups, never deleted.
- iCloud days not yet downloaded are detected, counted and downloadable.
- Portable settings (template, carry-over headings, minimum words, workdays, reminder time and style) travel in a small file in the log folder; folder path, login item, menu bar, shortcut and "Remind on this Mac" stay per Mac.

**Out of scope:** any Gloamlog-run sync service, live co-editing or automatic text merging, iOS or Windows clients, syncing backups or window state, email or SMS reminders.

**Acceptance**
- M5-A1: Given the reminder is set 2 minutes ahead and Gloamlog is quit, when the time arrives, then a macOS notification appears, and clicking it opens Gloamlog on today's page.
- M5-A2: Given today is logged or skipped, or is not a scheduled day, when the reminder time passes with Gloamlog quit, then no notification appears.
- M5-A3: Given I change the time, days or style, when I open Settings > Reminders, then it shows "Next reminder: <date, time>" and only that time fires, with no stale one.
- M5-A4: Given the notification, when I choose Snooze, then it returns after the snooze minutes; when I choose Skip today, today is marked skipped without a window opening.
- M5-A5: Given notifications are off in System Settings, when I open Settings > Reminders, then a warning says closed-app reminders cannot reach me, with a button that opens System Settings.
- M5-A6: Given a page open on Mac B that I am editing, when a newer version of that day arrives from Mac A, then I get a choice (keep mine, take theirs, keep both) and nothing is overwritten silently; an untouched open page updates within 10 seconds.
- M5-A7: Given a conflict copy of a day exists (such as "2026-10-07 2.md"), when Gloamlog sees it, then it shows "1 conflict" with both versions, "Merge both" appends the other version under a labelled heading, and the extra file moves to backups; nothing is deleted.
- M5-A8: Given I change the template on Mac A, when Mac B syncs, then B shows the same template with a one-line notice; folder path, login item, menu bar, shortcut and "Remind on this Mac" are not shared.
- M5-A9: Given iCloud has not downloaded some days, when Gloamlog opens the folder, then it says "N days are still in iCloud" with Download all, and after the download they appear in the sidebar, calendar and search.
- M5-A10: Given a second Mac, when I choose "Join from another Mac" and pick the shared folder, then my settings arrive and onboarding is skipped.

**Owner's hands-on check**
- [ ] 5a: Quit with ⌘Q, set the reminder 2 minutes ahead, wait: the notification arrives; click it and today's page opens.
- [ ] 5a: Restart the Mac without opening Gloamlog; the next scheduled reminder still arrives (if not, the helper path is needed).
- [ ] 5a: Log today, quit, wait past the reminder time: nothing arrives.
- [ ] 5b: Write today on Mac A; on Mac B (app open) the text appears without a relaunch.
- [ ] 5b: Edit the same day on both Macs with Wi-Fi off, then reconnect: a conflict is offered and nothing is lost.
- [ ] 5b, one Mac only: copy a file named "2026-10-07 2.md" into the folder and edit a page in TextEdit while it is open: the same behaviours.

### M6: Sources (0.9.0, 30-42 agent-h)

**Owner can then:** open any day, see suggested bullets from Claude Code sessions and Git commits, insert the right ones, and edit them. **Depends on:** M1 (catch-up days gain suggestions). **Before it starts (owner, 15 minutes):** run the read-only structure checks in `docs/research/CLAUDE_INTEGRATION.md` Appendix A and send the output; nothing in that research was verified against real transcripts.

**In scope**
- Sources are off by default; each source and each folder is opted in; allow and deny lists per project; a plain explanation of exactly what is read. The first scan will trigger normal macOS folder-access prompts.
- Git: commits by the owner's identity on that day in allowed repos (repo, short hash, subject, time).
- Claude Code: per allowed project and day, number of sessions, active time span, the first line of up to 3 prompts and a count of files touched, read-only from the local session files with a defensive parser (unknown or broken lines are skipped and counted).
- Redaction of secrets (keys, tokens, `password=`, `.env` content) before anything is shown or inserted.
- A "Suggested from your work" strip on any day with a preview, Insert per item and Insert all; inserted as editable bullets with evidence (repo and hash, or project). Days inside Claude Code's retention window (about 30 days) can be filled during catch-up; older days say why there is nothing.

**Out of scope (v1):** `claude -p` drafting, an MCP server, Claude Desktop Chat or Cowork capture, hooks and skills, LLM summaries, other agents or editors, GitHub API, calendar or Slack sources, any network call.

**Acceptance**
- M6-A1: Given Sources is off (the default), when I use Gloamlog, then nothing outside the log folder is read and no prompt or nag appears.
- M6-A2: Given Git is on for `~/Projects`, when I open a day with commits in 2 repos, then the strip lists those commits (repo, short hash, subject, time), only mine, none from other authors or denied repos.
- M6-A3: Given Claude Code is on for one allowed project, when I open a day I worked in it, then the strip shows sessions, active time span, the first line of up to 3 prompts and the files-touched count; denied projects never appear.
- M6-A4: Given a session contains a fake secret (an `sk-` key, an AWS key, `password=...`), when the strip renders and I insert, then it shows "[redacted]" and the page never contains it (fixture test plus the owner's visual check).
- M6-A5: Given 8 suggestions, when I Insert 3 of them, then exactly those 3 appear as editable bullets with evidence, nothing else is written, and inserting them again does not duplicate.
- M6-A6: Given a corrupt line or a newer transcript format, when the day is scanned, then the rest still shows, the strip says "3 records skipped", and nothing crashes.
- M6-A7: Given a catch-up day 10 days ago, when I open it, then the strip shows that day's activity; for a day older than Claude Code keeps, it says so instead of staying silent.

**Owner's hands-on check**
- [ ] Before the build: run the Appendix A structure checks and send the output.
- [ ] Turn on Git for `~/Projects` only; open a day with commits in two repos: the list matches `git log` (author, count).
- [ ] Turn on Claude Code for one project; on 3 recent days note how many suggested bullets you would have written, and how many are missing or wrong.
- [ ] Find a secret you know was pasted into a session: it must show as redacted.
- [ ] With Sources off, nothing outside the log folder is read (a short file-access trace is attached to the report).

## 4. Requirements

Priority is MoSCoW: M must, S should, C could, W won't (in v1). Acceptance IDs point to section 3.

| ID | Requirement | Pri | M | Acceptance |
|---|---|---|---|---|
| NAV-1 | Open and write any date up to today, including before the first log; month calendar with status marks visible in the main window | M | M1 | M1-A1; reachable without opening a menu |
| NAV-2 | Previous and Next calendar day by button and ⌘[ ⌘] | M | M1 | M1-A2 |
| NAV-3 | Week review lists and opens every scheduled day of any week | M | M1 | M1-A5 |
| CUP-1 | Catch up list with count, next-missed-day flow and "All caught up"; window adjustable | M | M1 | M1-A3 |
| CUP-2 | Skip several days at once with one reason, undoable | M | M1 | M1-A4 |
| CUP-3 | Log start date: days before it are never missed | M | M1 | M1-A9 |
| CUP-4 | Quiet notice on Today when earlier days are unwritten (dismissible, once a day) | S | M1 | Shown with 2 unwritten days, absent with none |
| SET-1 | Settings window from the main window, menu-bar popover, app menu and ⌘, | M | M1 | M1-A6 |
| SET-2 | Groups General, Reminders, Page, Storage and Backups, Shortcuts, About; changes apply at once and persist | M | M1 | M1-A7 |
| SET-3 | Appearance (System, Light, Dark) and week start (System, Mon, Sun) | S | M1 | M1-A7 |
| SET-4 | Backups access and restore, About with version and licences, run setup again | S | M1 | Each opens from Settings; About shows 0.4.0 |
| SET-5 | Show in Dock; page to open at launch | C | M1 | Switch survives relaunch |
| DAT-1 | No typed text lost on quit, force-quit, sleep or folder trouble | M | M1 | M1-A8 |
| DAT-2 | Walkthrough defects (P0, P1) fixed with regression tests | M | M1 | M1-A10 |
| DOC-1 | README, CHANGELOG and stale architecture docs brought up to date | S | M1 | Docs match the app |
| CAP-1 | Global shortcut opens the capture panel over any app; changeable, off, conflict-checked | M | M2 | M2-A1, A7 |
| CAP-2 | Return appends a time-stamped bullet under Jots in today's page | M | M2 | M2-A2 |
| CAP-3 | Safe with today's page open or the window closed | M | M2 | M2-A3 |
| CAP-4 | Menu-bar Jot field and menu command | S | M2 | M2-A5 |
| CAP-5 | Notes kept and retried when the folder is unavailable | S | M2 | M2-A6 |
| CAP-6 | Jots do not count as logged by default; template shown above jots | S | M2 | M2-A4 |
| REV-1 | Review for week, month, year and custom range; counts; group by day or section | M | M3 | M3-A1, A2 |
| REV-2 | Year view with 12 months and drill-down, fast for 250 pages | S | M3 | M3-A3 |
| EXP-1 | Copy as Markdown, Plain text, Rich text from reviews and a page | M | M3 | M3-A4 |
| EXP-2 | Export Markdown with assets | M | M3 | M3-A5 |
| EXP-3 | Export PDF | S | M3 | M3-A5 |
| EXP-4 | Share menu; include or exclude skipped days | S | M3 | M3-A6, A7 |
| FND-1 | Benchmarked search: warm query under 300 ms on 5 years; never blocks the UI | M | M4 | M4-A1 |
| FND-2 | Background index, incremental, disposable cache, usable while building | M | M4 | M4-A2, A3, A6 |
| FND-3 | Date-range and heading filters | S | M4 | M4-A4 |
| FND-4 | Unreadable files skipped with a notice; rebuild in Settings | S | M4 | M4-A5, A6 |
| REM-1 | Reminders arrive when Gloamlog is not running | M | M5a | M5-A1 |
| REM-2 | Re-planned on changes; none after logged, skipped or non-workday; next reminder shown | M | M5a | M5-A2, A3 |
| REM-3 | Denied-permission state explained with a fix button; actions Open, Snooze, Skip | M | M5a | M5-A4, A5 |
| REM-4 | "Remind on this Mac" toggle (S); Strict while closed (C, after a spike) | S | M5a | Toggle works per Mac |
| SYN-1 | Guided shared-folder setup, folder health, join from another Mac | S | M5b | M5-A10 |
| SYN-2 | External change never silently overwrites the open page | M | M5b | M5-A6 |
| SYN-3 | Conflict copies detected and merged without deleting anything | M | M5b | M5-A7 |
| SYN-4 | Not-downloaded iCloud days detected and downloadable | M | M5b | M5-A9 |
| SYN-5 | Portable settings in the folder; per-Mac settings stay local | S | M5b | M5-A8 |
| AUT-1 | Sources off by default; per-source and per-folder opt-in; allow and deny | M | M6 | M6-A1 |
| AUT-2 | Git commits for a day, my identity, allowed repos | M | M6 | M6-A2 |
| AUT-3 | Claude Code activity per project and day, read-only, defensive parser | M | M6 | M6-A3, A6 |
| AUT-4 | Secrets redacted before display and insert | M | M6 | M6-A4 |
| AUT-5 | Suggestion strip with preview, Insert, Insert all, no duplicates, editable | M | M6 | M6-A5 |
| AUT-6 | Catch-up days within retention get suggestions; older days explain | S | M6 | M6-A7 |
| AUT-7 | "Add a source" contributor guide | C | M6 | A contributor can add a stub source from the guide |
| AUT-8 | `claude -p` drafting, MCP server, Desktop Chat capture | W | none | Not built in v1 |
| XC-1 | The app makes no network request; guard in CI | M | all | Guard passes; owner's network check |
| XC-2 | Plain markdown files, backward compatible; the app never deletes a user file | M | all | Tests and kill tests |
| XC-3 | Builds with Command Line Tools; no macros, no third-party dependencies | M | all | `bash app/build.sh` clean |
| XC-4 | Keyboard reachable, VoiceOver labels, state never by colour alone, light and dark | S | all | Screenshot review |

## 5. Success measures

No telemetry. Personal measures are read from the log folder (file names and dates) or by hand, and nothing leaves the Mac.

| Measure | Target | When |
|---|---|---|
| Five-day trial (R10) | 5 of 5 workdays logged or skipped, 0 lost text, owner says "keep using it" | After M1 |
| Catch-up speed | 3 missed days in 2:00 or less (stopwatch) | M1 sign-off, repeat after 4 weeks |
| Habit | 85% or more of scheduled workdays logged or skipped, over any 4 weeks | From M1 |
| Catch-up share | Share of logged days written after their day. Information only, no target | From M1 |
| Data safety | 0 lost or overwritten texts. Any incident is a stop-ship | Always |
| Blockers | 0 open P0 or P1 for 2 consecutive weeks | Before M5 starts |
| Closed-app reminders | The reminder arrived on 5 of 5 days with Gloamlog quit | After M5a |
| Sources usefulness | On 10 sampled days, 60% or more of the bullets you would have written were suggested; at most 1 wrong or leaky item | After M6 |
| Clean-clone build | README to running app in 5 minutes or less, timed by someone (or an agent) who has not seen the repo | Each milestone |
| CI | Green on main; each milestone adds tests for its new Core rules | Each milestone |
| Outside issues or PRs | At least 1 from someone other than the owner within 8 weeks of the first public post | After any public post |
| Stars | Lagging and easy to inflate. No target before M1 plus 4 weeks of daily use. After a public post, 50 in 90 days is a fair start; 300 would match the best tools in its niche (`docs/STRATEGY.md`) | After any public post |

**Stop signal**: if R10 fails twice, or the owner keeps skipping days "because the app is in the way", stop building M2 onward and fix the blocker. Features do not repair a habit the app is blocking.

## 6. Risks and what to cut

| Risk | Likelihood | Impact | Mitigation and early action |
|---|---|---|---|
| Unknown defects (little real use) inflate M1 | High | High | Time-box the walkthrough to the first 4 agent-h and re-size M1 from it; P2s never enter M1 |
| Data loss in new write paths (capture, merge, sync) | Medium | High | All writes go through `LogStore` (atomic, backup before overwrite); a kill test per writer; never delete a user file; owner copies the folder before each check |
| Closed-app reminders unreliable for an ad-hoc signed app (permission, Focus) | Medium | High | 2 agent-h spike during M1: schedule one notification, quit, see if it fires on the owner's Mac; design M5a from the result |
| Sync edge cases (iCloud placeholders, conflict copies, two Macs) are hard to automate | High | Medium | Fixture tests for file names and placeholders; single-Mac simulation; one real two-Mac check before sync is called done |
| Claude Code transcript format unverified, changes between versions, may hold secrets | High | Medium | Owner's 15-minute structure check first; defensive parser with fixtures; redaction; opt-in per project; M6 is last |
| Global shortcut or floating panel misbehaves with Spaces, full-screen or other apps' shortcuts | Medium | Medium | Owner checks it in the apps they really use; the menu-bar Jot field is the fallback |
| Real screenshots impossible without Screen Recording permission for the capturing app | Medium | Medium | Owner grants it once; otherwise the owner supplies screenshots at the hands-on check; the gate is not waived |
| Ad-hoc signing: Gatekeeper prompt on a second Mac | High | Low | Document "Open Anyway", or build from source on each Mac; notarisation is a later plan |
| Owner time (about 45 minutes per check) is the bottleneck; milestones pile up as "built, not done" | Medium | Medium | One-page checklist per milestone; batch M2 and M3 checks if needed; do not start a new milestone while one awaits its check |

**If time is short, cut in this order** (first to go is first): 1. M6 Sources moves to "next"; nothing depends on it. 2. M5b extras: keep conflict detection and not-downloaded handling (they protect data), drop portable settings and the join flow. 3. M3: drop PDF, Year view and Share; keep Week and Month review, the copy formats and Markdown export. 4. M4: drop filters and the index; keep off-main-thread search and the notice. 5. M2: drop the menu-bar field and offline retry; keep shortcut, panel and the safe append. 6. M1 Shoulds: appearance and week start, About, the morning notice, doc hygiene.

**Never cut:** the M1 Musts, the data-safety checks, the release gate. Cut scope, never the gate.

## 7. Non-goals

- Anything that sends data off the Mac by itself: accounts, a Gloamlog sync server, telemetry, analytics, crash reporting. The Share menu acts only when you choose a target.
- Distribution work: notarisation, Homebrew, landing page, demo GIF, public launch posts. A separate plan after M1 plus four weeks of daily use; it needs your Apple Developer enrolment.
- AI features: LLM summaries, `claude -p` drafting, an MCP server, Claude Desktop Chat or Cowork capture, semantic search.
- Team features: shared logs, manager views, leaderboards, social features.
- Tags and mentions, a template gallery, Notion or Obsidian integrations, localisation, an iOS or iPad companion, Windows or Linux.
- A separate weekly note, future-dated pages or task planning, calendar or Slack or Jira sources, screen recording or time tracking.
- Replacing the editor, changing the file format, or a database as the source of truth: plain markdown files stay the product.
- New gamification beyond the existing streak and heatmap.

## 8. Open questions for the owner

Each has a default that applies if you do not answer, so no work waits on you.

| # | Question (needed by) | Recommended default |
|---|---|---|
| Q1 | Do jotted notes count toward "logged", and should Jots sit at the bottom of the page? (before M2) | No, they do not count: the end-of-day write-up is what makes a day logged, so the reminder still fires. Jots sit at the bottom under a "Jots" heading; one Settings switch makes them count. |
| Q2 | For "previous weeks": do you want a separate weekly note (one free-form entry per week), or is a week just a view over its days? (before M1 sign-off) | A week is a view over daily pages; no separate weekly note in v1. Revisit after M3 if you want somewhere to write about a week as a whole. |
| Q3 | Where do you paste the weekly summary (chat, email, Notion, a doc, a ticket) and in what shape? (before M3) | Offer Markdown, Plain text and Rich text, grouped by Section, jots excluded, skipped days as one line; adjust after you try the real destination. |
| Q4 | Which sync service will you use, and can you test with a second Mac? (before M5b) | iCloud Drive as the first-class path (guided setup, not-downloaded files); Dropbox and Syncthing work as plain folders with conflict-copy detection. Sign off with single-Mac simulation, plus one real two-Mac check before calling sync done. |
| Q5 | Is a macOS notification enough when Gloamlog is closed, or must the Strict style (forced window) also work? (before M5a) | A notification is enough; Strict works while the app runs. Revisit only if you miss reminders because of it. |
| Q6 | Which Claude surfaces do you use daily, and where do your Git repos live? (before M6) | Claude Code in the terminal and the Desktop Code tab; one scan root, `~/Projects`, with each project opted in; Desktop Chat is out of scope. |

**Needs from you**: about 45 minutes per milestone for the hands-on check, and a copy of your log folder before each. Screen Recording permission for the terminal or agent app that captures screenshots (one time). For M5, a second Mac if you have one; for M6, the Appendix A structure check.
