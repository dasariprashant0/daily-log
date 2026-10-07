# Gloamlog v0.3: UX audit, benchmarks, scenarios and gaps

2026-10-07. Scope: the v0.3 build (`app/Gloamlog.app`, source in `app/UI` and `app/Core`). Read-only audit: no source was changed and the app was not run. File references are relative to `app/UI/` or `app/Core/`; line numbers are for the checked-in v0.3 source.

The owner's verdict after trying v0.3, verbatim: "why am i not able to add anything for previous days or weeks and why is there no settings options for us to modification or whatever the settings is supposed usually give within the app. you haven't setup the flow for the real world scenario ... i don't actually thing that this is even ready for me to use"

**Bottom line.** The owner is right, and the README already says "not ready for everyday use yet". The writing surface is solid; the flow around it is not. Of the 12 things the owner asked for (4 usage modes, 4 outputs, 4 extras), v0.3 fully supports 1, partly supports 5 and misses or blocks 6. Past days are unreachable because navigation is built from files, not from a calendar. Settings cannot be reached from the window and holds roughly 15 controls. Everything that makes it "real world" (catch-up, capture, reminders when closed, review, export, safe sync) is absent.

## Evidence and method

- Screenshots: 9 renders in `/private/tmp/claude-501/-Users-prashantdasari-Projects-personal/c6039c28-080c-4cd0-8889-b33a20b7d975/scratchpad/shots-v03/` (light and dark; all viewed; a temporary scratchpad, so copy them if they should outlive this session). They come from the snapshot harness, which draws the editor as static text (`PageView.swift:48`) and has no Settings window, so editing behaviour, real images and the Settings window were assessed from code only.
- Code read: Sidebar, PageView, PageHeader, MainView, GloamlogApp, SettingsView, TemplateEditor, Onboarding, MenuBarView, WeeklyReviewView, Heatmap, SkipSheet, SearchView, AppModel (+Browse, +Day, +Editor, +Reminders, +Storage), DayEditor, Notifier; Core: Settings, Streak, Models, ReminderPlanner, CarryOver, WeeklyReview, Search, LogStore. Docs read: README, CHANGELOG, STRATEGY, EDITOR_CONTRACT, ROADMAP, UX_SPEC (3.3, 3.9), PRD.
- Not available: any person other than the owner, any session recording, any usage data (none is collected, by design). Severity is judged against the owner's own stated jobs, not measured frequency. One person's one-line feedback is a strong signal about direction and a weak one about priority order.
- Lenses: jobs-to-be-done and journey walkthrough (user research), hierarchy / consistency / accessibility (design critique), and the ui-ux-pro-max rule database. The database returned only generic matches (Empty States, Content Jumping, User Freedom) and none for notification frequency, so Apple's HIG is used instead.
- Contrast figures are computed from the hex tokens in `Theme.swift` with the WCAG formula, not measured on screen.
- Severity: **Blocker** = a stated core job cannot be done. **High** = done only through a hidden route, a trust or data risk, or behaviour that would make a real user turn the app off. **Medium** = frequent friction. **Low** = polish. `[inferred]` = reasoned from code, needs a test to confirm.

## 0. The yardstick: what the owner said they need

| Ref | Need | v0.3 | Note |
|---|---|---|---|
| U1 | Write once at end of day | Supported | The best-served job. |
| U2 | Jot through the day, tidy at the end | Partial | No capture surface; opening Today means five empty headings. |
| U3 | Next-morning catch-up for yesterday | Partial | Only through hidden routes; carry-over is today-only. |
| U4 | Catch up several days or a whole week | Blocked | See 1.1. |
| O1 | Weekly summary to paste into standups | Partial | Week view plus "Copy as markdown"; one calendar week, no standup shape. |
| O2 | Search old entries | Partial | Sidebar search works; template headings add noise; no date filter. |
| O3 | Monthly / yearly review | Missing | |
| O4 | Export / share | Missing | Clipboard only. |
| E1 | Sync across Macs via a shared folder | Partial | Folder choice only; no conflict or eviction handling. |
| E2 | Reminders when the app is closed | Missing | Process-bound. |
| E3 | Quick capture from anywhere | Missing | |
| E4 | Auto-fill from Claude Code and Git | Missing | Planned for 0.4. |

## 1. Heuristic audit of v0.3

### 1.1 Why you cannot add past days or weeks

Root cause: navigation is built from files that exist, not from a calendar. The core is not the limit (item 7); the UI has no door.

1. The only list of days is the sidebar `HistoryList`, built from `AppModel.historyDays`: every day that already has a file, minus today (`AppModel.swift:151-155`). A day you did not write has no file and therefore no row. In `real-6-mainview.png`, Fri 2 Oct, Mon 21 Sep and Thu 10 Sep (workdays under the default Mon-Fri schedule) simply are not there, and nothing says they exist.
2. Keyboard stepping is file-driven too: ⌘[ and ⌘] walk `[today] + historyDays` (`AppModel.swift:220-230`) and jump over gaps.
3. There is no toolbar (`MainView.swift:9-26`), no calendar, no date field, no "Go to date" or "New entry for..." command. The whole Log menu is Focus, Carry Over, Today, This Week, Previous/Next, Copy Week (`GloamlogApp.swift:51-61`).
4. Three back doors exist and none reads as "write a past day":
   - **This week, then "Open"** on a "Not logged yet" card (`WeeklyReviewView.swift:106-133`). A day with no file gets a card only if it is a scheduled workday (lines 110-112); a weekend, or a day before your first-ever file, gets none. If a week has nothing logged, skipped or written, the whole view is replaced by "Nothing logged this week yet" and one button, "Go to today" (`WeeklyReviewView.swift:12,49-54`). The dead end appears for exactly the week you want to catch up.
   - **The 12-week heatmap behind the "N day streak" chip** (`PageHeader.swift:31-72`). UX_SPEC 3.3 designed these cells as the way to open missed days; v0.3 moved them from the sidebar into a popover (CHANGELOG 0.3.0, "Declutter"). Nothing says a streak badge is a calendar, cells are 14 pt (`PageHeader.swift:66`), and the "missed" outline is 1.69:1 against the page in light mode, the faintest mark in the grid.
   - **Search hits and ⌘[**, which only reach days that already have files.
5. Weeks are not modelled. Skip takes a range ("Through a later date", `SkipSheet.swift:53-63`); writing does not. Carry-over, the midnight roll-over banner and reminders exist only for today (`AppModel+Day.swift:54`, `PageView.swift:153`, `ReminderPlanner.swift:94`).
6. When you do reach a fileless day (Sat 3 Oct in `real-5-blank-page.png`), no sidebar row is selected, the header still says "1 day streak" and "0 / 20 words to log this day", and nothing marks it as a back-filled day or offers a way back other than Today.
7. Not a data limit: `LogStore.save(day:body:)` accepts any well-formed date (`LogStore.swift:122,186`), and the streak is recomputed from files, so a back-filled Friday would repair the streak by itself. The product question was parked, not answered: PRD "open questions" asks whether a missed past day should be back-fillable.

Walkthrough, Monday 9:00, Friday missed, first-time user: open the app (Today, five empty headings) -> look for Friday: no row -> ⌘[ steps Today, Mon 5, Thu 1 and skips Friday -> "This week" shows the current week, Friday is in the previous one -> chevron back -> Friday appears as "Not logged yet / Open" only if that week has any other file, otherwise the dead end -> Open. Best case is three interactions (This week, chevron, Open) plus knowing the route. The streak-chip route is two (chip, then a 14 pt cell) but unlabelled. Discoverability for a newcomer is effectively nil.

### 1.2 Why Settings is hard to find and feels thin

Findability
- Nothing in the window leads to Settings: no toolbar or gear (`MainView.swift:9-26`), not in the sidebar (`Sidebar.swift:5-24`), not in the page "..." menu, which holds Skip, Copy, Open folder and Restore (`PageHeader.swift:122-131`). CHANGELOG "Known issues" admits it: nothing in the main window points to Settings.
- The routes that exist: app menu "Settings..." / ⌘, (the SwiftUI Settings scene, `GloamlogApp.swift:25`); the menu-bar popover (`MenuBarView.swift:57`), which exists only while "Show in menu bar" is on; a one-time button in the What's New sheet (`MainView.swift:57`). Onboarding says "change this later in Settings" without showing where.
- Apple's HIG says to put Settings in the App menu and to avoid a Settings button in a window toolbar. So the fix is not a gear in a toolbar; it is contextual links (reminder banner, template, storage messages, empty states each get "Change...") plus a "Settings..." item in the page "..." menu. This is a judgment call; the HIG does not forbid a menu item.

Thinness
- 3 panes, roughly 15 controls (`SettingsView.swift:7-121`, `TemplateEditor.swift:42-56`): reminder time, working days, Strict/Gentle, snooze length, login item, menu-bar toggle, notification status; words-to-log, template, carry-over headings; storage folder and three buttons.
- Missing for the owner's modes: a "my day ends at" hour, catch-up window and prompts, quick-capture shortcut, week start, summary/standup format, export defaults, backup retention (hard-coded 10 copies and 120 s: `LogStore.swift:94`, `AppModel.swift:39`), sync status and conflicts, Sources (Claude Code, Git) with per-project allow/deny, menu-bar versus Dock presence, a privacy/about/reset area, a shortcut list.
- Most of those settings are absent because their features are. Adding switches first would create dead settings. The HIG also says to minimise settings, ship strong defaults and keep task-specific options (grouping, filtering) in the view they change. Target about 6 panes of at most 8 controls.
- The default is the most demanding option: Strict reminders (`Settings.swift:44`), preselected in onboarding step 2.

### 1.3 Ranked defects

Ordered by severity, then by impact on the owner's modes. "Closed by" points to the gaps in section 4.

| ID | Severity | Defect | Evidence | Closed by |
|---|---|---|---|---|
| D1 | Blocker | Past or missed days cannot be opened from primary navigation; weeks cannot be caught up. | 1.1 items 1-3, 5; `real-6-mainview.png` | G1 |
| D2 | Blocker | The back doors dead-end: a fully missed week shows "Nothing logged this week yet" and "Go to today"; weekends and pre-first-entry days get no "Open"; the heatmap route is unlabelled. | `WeeklyReviewView.swift:12,49-54,111-112`; `PageHeader.swift:31-72` | G1 |
| D3 | High | A streak that punishes misses the user cannot repair, shown in five places (sidebar footer, page chip and its popover, week header, menu-bar popover). One missed Friday leaves "1 day streak, Best: 5" although Wed 30 Sep, Thu 1 Oct and Mon 5 Oct are logged. | `Streak.swift:40`; `Sidebar.swift:187-200`; `PageHeader.swift:21,55-72`; `WeeklyReviewView.swift:34`; `MenuBarView.swift:44`; `real-6` | G2 |
| D4 | High | No route to Settings from the window (see 1.2). | `MainView.swift:9-26`; `PageHeader.swift:122-131` | G5 |
| D5 | High | Settings is thin and lacks everything the owner's modes need (see 1.2). | `SettingsView.swift:7-121`; `TemplateEditor.swift:42-56` | G5 |
| D6 | High | Reminders live and die with the process: immediate notification only, 30 s timer, login item off by default, workdays only from the reminder time (default 16:55) to 23:00, today only (never "yesterday isn't written"). | `Notifier.swift:47`; `AppModel+Reminders.swift:11`; `AppModel.swift:104`; `ReminderPlanner.swift:55,94-96` | G3 |
| D7 | High | Strict is the default and escalates: window forced to front with Dock bounce, re-opened every 5 min, 2 snoozes. The in-page banner pushes the page down about 47 pt (layout shift) and puts "Skip day" next to snooze. | `Settings.swift:44`; `ReminderPlanner.swift:53-54,113-117`; `AppModel+Reminders.swift:54-58`; `PageView.swift:127-135`; `real-3` vs `real-1` | G3 |
| D8 | High | Quota framing: "0 / 20 words to log today". Fewer words is "partial", and partial breaks the streak, so a one-line jot never counts. "logged / partial / missed" leaks into the UI as jargon. | `PageHeader.swift:91`; `Streak.swift:40`; `real-1`, `real-3` | G2 |
| D9 | High | No quick capture: no global shortcut, menu-bar compose box, Shortcuts action, URL scheme or Service. The menu-bar popover is read-only status. | grep for hotkey/AppIntent/URL-scheme/Services over `app/UI`, `app/Core`, `Info.plist` finds nothing; `MenuBarView.swift:25-70` | G4 |
| D10 | High | No export of any kind: the clipboard is the only output (page, week). No save panel, PDF or share sheet. | grep for NSSavePanel/ShareLink/PDF finds nothing; `AppModel+Browse.swift:68-73`; `Sidebar.swift:166` | G6 |
| D11 | High | A page cannot change date, be moved, merged or deleted. Typing into the wrong day is fixable only in Finder. | `Sidebar.swift:163-173`; `PageHeader.swift:122-131` | G7 |
| D12 | Medium | Helpers exist for today only: carry-over (sourced from the last logged day, 14-day lookback), roll-over banner, nag. No "Yesterday" row, no catch-up prompt. | `AppModel+Day.swift:54`; `CarryOver.swift:27,45-55`; `PageView.swift:153` | G1 |
| D13 | Medium | Past-day orientation: opening a fileless day selects no sidebar row; the header keeps "1 day streak" and "words to log this day"; no Prev/Next-day buttons, no "4 days ago" cue. | `real-5-blank-page.png`; `PageHeader.swift:14-24,91` | G1 |
| D14 | Medium | No toolbar, so no Today / Previous / Next / Calendar / New / Search affordance. The HIG gives the toolbar frequent commands, navigation and search. | `MainView.swift:9-26`; HIG Toolbars | G1 |
| D15 | Medium | Every new day is five empty headings (about 420 pt of a 760 pt window). Empty ones persist in saved files, so search matches "Finished" on every day. | `real-1-new-day.png`; `Search.swift:7-9,34`; `WeeklyReviewView.swift:130` (pruned only for display) | G10 |
| D16 | Medium | Weekly review: one calendar week, Day/Section only, copy only. No range ("last 5 working days"), no standup shape, no month or year; streak mixed into the header. | `WeeklyReviewView.swift:21-47`; `AppModel+Browse.swift:52-73` | G6 |
| D17 | Medium | Folder sync is unsafe `[inferred]`: conflict copies are counted as "not recognised" and ignored; dotted names (iCloud placeholders for evicted files) are skipped, so an evicted day looks missed; no file coordination or watcher, only polling every 30 s and on activation. | `LogStore.swift:134-136`; `SettingsView.swift:100,115`; grep for NSFileCoordinator/NSFilePresenter finds nothing | G9 |
| D18 | Medium | Day boundary `[inferred]`: `Calendar.current` is captured once, while a time-zone change event is observed and re-run through the same stored calendar; no "my day ends at" setting. | `AppModel.swift:41`; `AppModel+Reminders.swift:14` | G8 |
| D19 | Medium | Heatmap legibility: 14 pt cells; missed outline 1.69:1 (light) and 2.27:1 (dark), partial fill 1.91:1, all under the 3:1 expected for non-text marks. The cell users most need to notice is the faintest. | `PageHeader.swift:66`; `Theme.swift:19,34` (computed) | G1 |
| D20 | Medium | Full rescan every 30 s `[inferred]`: tick -> reload() reads and parses every day file (skipped days twice). Fine for months of logs; risky for years, and it touches cloud-evicted files. | `AppModel+Reminders.swift:11,39`; `AppModel.swift:158-169,246`; `LogStore.swift:150-158` | G9 |
| D21 | Low | Jargon and unclear labels: "This week" opens a weekly review; "Carry over" without an object; "words to log"; "N files not recognised"; "Skip day", "Skip day..." and "Skip this day". | `Sidebar.swift:99`; `PageHeader.swift:164`; `SettingsView.swift:100` | G5 |
| D22 | Low | Onboarding asks questions a new user cannot answer yet (template, Strict/Gentle, minimum words); "Skip setup" only on step 1; the sheet cannot be dismissed; notification permission is requested on Continue with no explanation; no import or catch-up invitation (ui-ux-pro-max "User Freedom": provide Skip and Back). | `Onboarding.swift:41,58,64,117-134` | G11 |
| D23 | Low | History rows are date plus glyph only; months older than the newest two collapse; finding "the day I did X" means opening pages or searching. | `Sidebar.swift:116,144-175` | G10 |
| D24 | Low | Error banner with no way out: "The editor isn't available." has no action. | `PageView.swift:113-115` | G5 |

### 1.4 Design critique lens

- **First impression.** Calm, confident type, restrained green; it reads as "a page for today". What draws the eye on every screen is the 32 pt date and the green streak chip: the streak, not the writing and not any way to move through time.
- **Hierarchy.** Date, streak chip, "N / 20 words", rule, carry-over strip, then five headings. Gamified status precedes content; the empty headings take about 420 pt; the nag banner shifts everything by about 47 pt (ui-ux-pro-max "Content Jumping", High).
- **Consistency.** The streak appears in five places; "skip" has three phrasings; status is drawn three ways (sidebar glyph, week text, heatmap shape), consistently by design (`Heatmap.swift:1-3`). The week view labels its action "Open"; the heatmap cells carry only hover tooltips.
- **Accessibility.** Text tokens pass 4.5:1 in both themes (secondary 5.5-8.1, tertiary 4.5-6.0 on page, sidebar and hover; the only pair under 4.5 is tertiary on the dark accent tint at 3.95, with no use found). Labels and Reduce Motion are handled throughout. The weak spots are the heatmap marks (D19) and the 14 pt cells.
- **Dark mode.** Parity is good. The light mint image block in the dark screenshots is the snapshot stub; check a real image in dark mode before judging.
- **Dead ends** (ui-ux-pro-max "Empty States": offer a useful action): the week dead end offers "Go to today", which is the wrong action.

### 1.5 What works and should be kept

- Autosave, versioned backups, restore, quit flush and "orphan" handling: data safety better than most journal apps.
- Plain markdown, one file per day, folder choice including iCloud, no network.
- Consistent, calm visual system with light/dark parity, broad VoiceOver labelling, Reduce Motion support.
- Reminder logic is careful (grace periods, snooze caps, wake handling, no log text in notifications, `Notifier.swift:42`); it needs a different default and a different delivery mechanism, not a rewrite.
- Week "Copy as markdown" by day or by section is a good seed for the standup output; carry-over of "To do next" is a real time-saver.
- Skip semantics (neutral, undoable, range) are right; extend them to "day off".

## 2. Benchmarks

Public documentation read 2026-10-07; no hands-on trials. "Thin" marks claims resting on search summaries, forum threads or third-party write-ups.

### 2.1 By topic

| Topic | What the benchmarks do | Take for Gloamlog |
|---|---|---|
| Go to any date | Day One calendar view and ⌘4; Apple Journal's Insights calendar; Obsidian Calendar plugin; Notion Calendar `.` jumps to any date, J/K by week; Logseq g n / g p (thin) | A calendar popover plus a typeable "Go to date"; Prev/Next that crosses gaps |
| Create past entries | Day One right-click a date, or change an entry's date; Apple Journal "Entry Date" field; Obsidian Calendar creates a note for any date; Logseq: create a page named like the date (clumsy) | Clicking an empty date starts that day; "Change date..." on every page |
| Backfill missed days | Obsidian Calendar names backfill as a purpose; Day One users batch-journal every few days and hit friction; no benchmark offers a "missed days" list | Original design: a Catch-up list (Write / Skip / Day off). Validate it |
| Calendar / timeline | Day One calendar and On This Day; Apple Insights calendar and All Entries; Logseq journals feed; Obsidian per-day "meter" dots | Month popover with a content meter; a sidebar timeline that shows gaps |
| Streaks when days are missed | Streaks 2-Day Rule; Apple counts days or weeks and warns before a streak lapses; Lally et al. | Forgiving, repairable by back-fill, forward-looking warning only |
| Quick capture | Day One menu-bar entry with a global shortcut; Things Quick Entry; Apple Journal share sheet; Reflect deep link; Logseq: still a feature request (thin) | Global shortcut plus small box; URL scheme / Shortcuts action |
| Week / month / year review | Obsidian Periodic Notes (weekly, monthly, yearly pages); Apple Insights (stats and streaks); Day One On This Day (same date in past years, not a review); "brag document" cadence. No built-in periodic review found in Reflect, Bear or Logseq | Generated from the days, in a standup shape; month and year views |
| Export | Day One PDF/JSON/Markdown; Apple Journal PDF; Bear Markdown/PDF/HTML and more | Markdown and PDF for any range; share sheet |
| Reminders | Day One per device, Mac must be on; Apple schedule plus streak notification; HIG on notifications | Local scheduled notifications, gentle by default |
| Settings window | Apple HIG; Things (4 short panes); Apple Journal (small); Day One (tabs) | About 6 panes, few controls, strong defaults, contextual entry points |

### 2.2 Per product

**Day One** (strong: vendor guides; one forum thread)
- Calendar view marks days with entries; on macOS, right-click any date to create an entry there ([calendar guide](https://dayoneapp.com/guides/tips-and-tutorials/calendar-view-in-day-one/)). An entry's date can be moved to any past or future day, which the vendor presents as the way to create past entries from memory or photos ([change date](https://dayoneapp.com/guides/tips-and-tutorials/change-the-date-time-of-an-entry/)).
- Even here it hurts: a user who journals "all at once every few days" complained that once a date has entries the New Entry button disappears and only right-click remains ([forum, Apr 2024](https://forums.dayoneapp.com/forums/topic/make-it-easy-to-add-entries-to-past-dates/)). That is Gloamlog's batch catch-up mode.
- Capture: Menu Bar Quick Entry, global shortcut ⌃⇧D, customisable ([menu bar entry](https://dayoneapp.com/guides/day-one-for-mac/menu-bar-quick-entry/), [shortcuts](https://dayoneapp.com/guides/tips-and-tutorials/keyboard-shortcuts/)). Reminders are per device, do not sync, and the Mac must be on ([reminders](https://dayoneapp.com/guides/tips-and-tutorials/reminders/)).
- Export: PDF, JSON, Markdown/plain text; date-range on iOS, selection or filters on macOS ([export](https://dayoneapp.com/guides/tips-and-tutorials/exporting-entries/)). Settings tabs include General, Appearance, Reminders, Journals, Sync, Advanced ([settings guide](https://dayoneapp.com/guides/settings/accessing-the-preferences-in-day-one-for-macos/), thin). On This Day shows entries from the same date in past years and the guide mentions no weekly, monthly or yearly review ([guide](https://dayoneapp.com/guides/tips-and-tutorials/on-this-day-view/)). I found no primary documentation of its streak rules.

**Apple Journal, Mac** (strong: Apple's Journal for Mac user guide)
- Add button; capture from other apps through the share sheet ([write](https://support.apple.com/guide/journal/write-in-your-journal-dev7c1a9b879/mac)); the entry date is editable while composing ([edit](https://support.apple.com/guide/journal/edit-or-delete-an-entry-dev7c1z9b800/mac)); find a day by clicking it on the Insights calendar ([view and search](https://support.apple.com/guide/journal/view-and-search-journal-entries-dev153edfa89/mac)).
- Schedule notifications by days and time, with an optional Streak Notification before a streak lapses; the streak counts consecutive days or weeks ([habit](https://support.apple.com/guide/journal/build-a-journaling-habit-dev19b1e375f/mac)). Export through File > Export to PDF; deleted entries stay in Recently Deleted for 30 days ([export](https://support.apple.com/guide/journal/print-and-export-entries-dev883fc2329/mac)). Settings are tiny: title, location, "Always Use Moment Date" ([settings](https://support.apple.com/guide/journal/dev03b24db0f/mac)).

**Obsidian: Daily Notes, Calendar, Periodic Notes** (strong: official help and READMEs)
- The Daily Notes help page documents opening or creating today's note (named `YYYY-MM-DD` by default) via ribbon, command palette or hotkey, and no way to pick another date ([help](https://help.obsidian.md/plugins/daily-notes)). Used alone it would fail the owner much as v0.3 does; the Calendar plugin below fills the gap.
- The Calendar plugin opens or creates the note for any clicked date, calls this "helpful for when you need to backfill old notes", shows a per-day meter of how much was written, and opens weekly notes from week numbers ([README](https://github.com/liamcain/obsidian-calendar-plugin)).
- Periodic Notes adds weekly and monthly notes ([README](https://github.com/liamcain/obsidian-periodic-notes)); a maintained fork adds yearly notes and a sidebar calendar, with format, folder and template set per period ([fork](https://github.com/philoserf/obsidian-periodic-notes), thin).
- Sync lesson: iCloud and OneDrive can offload files, so keep the folder downloaded, and never sync one vault through two services ([help](https://obsidian.md/help/sync-notes)).

**Notion Calendar (formerly Cron)** (strong for navigation; not a journal)
- `.` jumps to any date, J/K move by week ([changelog](https://www.cron.com/changelog)); a menu-bar view of upcoming events has its own Settings tab ([help](https://www.notion.com/help/notion-calendar-settings)). Cheap to copy.

**Reflect** (thin)
- Daily notes with a calendar panel (third-party reviews); ⌘D opens the daily note; a documented URL `reflect://reflect?command=append-to-daily-note&text=...` appends to today ([deep links](https://reflect.academy/deep-links)). I could not verify a global hotkey.

**Bear** (limited relevance: a notes app with no daily-note model)
- Free export to txt, Markdown, TextBundle, bearnote, RTF; Pro adds HTML, DOCX, PDF, JPG, ePub; File > Export Notes covers everything ([FAQ](https://bear.app/faq/export-your-notes/)).

**Logseq journals** (medium: forum evidence)
- A journals feed of days; g n / g p step between days ([forum](https://discuss.logseq.com/t/please-add-a-next-and-previous-day-link-in-journal-entries/10853), thin). To add an old date you create a page named like the date, use a plugin or drop a file in the folder; one user importing old diaries found this slow ([forum](https://discuss.logseq.com/t/how-to-quickly-add-a-journal-page-years-before/6748)). Capturing to today's journal is still a feature request ([request](https://discuss.logseq.com/t/quick-capture-to-todays-journal-page/18705), title only).

**Streaks** (strong for streak policy)
- 2-Day Rule: one missed day is marked skipped and the streak survives; a second consecutive miss resets it ([Streaks 10](https://crunchybagel.com/now-available-streaks-10/)). A small indicator appears only when missing today would break the streak ([Streaks 4.2](https://crunchybagel.com/now-available-streaks-4-2/)). I found no primary evidence about retroactive check-in.

**Things** (strong for capture only)
- Quick Entry is a global shortcut (⌃Space), on by default, configurable under Settings > Quick Entry; an Autofill variant attaches the link from Safari, Mail or Finder ([support](https://culturedcode.com/things/support/articles/2249437/)). I found no catch-up or backfill model, so Things informs capture and Settings only.

### 2.3 Apple Human Interface Guidelines

Read from Apple's documentation data for the same pages.
- [Settings](https://developer.apple.com/design/human-interface-guidelines/settings), macOS: a Settings item in the App menu; avoid Settings buttons in a window's toolbar; a non-customisable toolbar of panes with the active one marked; window title follows the pane; restore the last pane; dim minimise and zoom. Generally: minimise settings, give defaults that suit most people, keep task-specific options (filtering, reordering, showing or hiding) in the view they affect, do not duplicate system settings.
- [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars): frequent commands, navigation and search; every toolbar item also exists as a menu command.
- [Sidebars](https://developer.apple.com/design/human-interface-guidelines/sidebars): navigation to top-level areas; let people hide it; keep critical actions off the bottom edge, which windows often push out of view; at most two levels.
- [Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications): do not send several notifications for the same thing, even unanswered; do not tell people to perform tasks; keep sensitive content out.

### 2.4 Research that bears on the design

- Missing one opportunity did not materially affect habit formation in a 12-week study of 96 people (Lally et al. 2010, [abstract](https://onlinelibrary.wiley.com/doi/abs/10.1002/ejsp.674)). A single miss should not zero a streak.
- Diary-method research argues frequent in-the-moment reports beat later recall, which is distorted by recall bias (Bolger, Davis, Rafaeli 2003, [paper](https://www.semanticscholar.org/paper/Diary-methods:-capturing-life-as-it-is-lived.-Bolger-Davis/0eef73cb7bf0d51bdd92c4da1a77893e54147042)). Back-filled pages are legitimate but less reliable: mark them, and offer memory aids (calendar, Git, Claude Code), never a block.
- The "brag document" practice recommends a short update about every 2 weeks, or one annual pass, for reviews and promotion ([Julia Evans](https://jvns.ca/blog/brag-documents/)). This supports month and year review plus pinned highlights.

### 2.5 Patterns to adopt and to avoid

Adopt
- A1. A calendar that creates, where clicking an empty date starts that day (Day One, Obsidian Calendar). Make it the primary click, not a context-menu item.
- A2. A typeable "Go to date" and a Today key (Notion Calendar); Prev/Next that crosses gaps.
- A3. Editable page date and a Recently Deleted safety net (Day One, Apple Journal).
- A4. A content meter instead of a binary "logged" (Obsidian Calendar): presence without shame.
- A5. A forgiving, repairable streak with a forward-looking warning (Streaks, Apple Journal).
- A6. Capture outside the main window: global shortcut and small box (Day One, Things), share sheet (Apple), URL scheme (Reflect).
- A7. Settings as the HIG describes: App-menu item, few panes, strong defaults, options in context.
- A8. Export to Markdown and PDF for a date range (Day One, Apple Journal, Bear).
- A9. Weekly, monthly and yearly pages generated from the days (Periodic Notes).
- A10. Reminders stored per device and honest about whether the Mac must be on (Day One).

Avoid
- X1. Hiding "new entry" once a date has content, or leaving creation to right-click (Day One Mac forum).
- X2. "Create a page named like the date" as the backfill route (Logseq).
- X3. A streak that resets with no repair path, repeated on every screen.
- X4. A Settings gear in the window toolbar (HIG); use contextual links.
- X5. Repeating a prompt that was ignored (HIG notifications; Strict re-opens every 5 minutes).
- X6. Trusting folder sync without handling offloaded or conflicted files (Obsidian help).
- X7. Quota framing: "0 / 20 words to log today".

### 2.6 Limits of this evidence

- Everything is public documentation or forum text read once; nothing was installed or tried. Vendor behaviour may have changed since.
- Reflect, Logseq and the Day One settings tabs rest partly on search summaries (marked thin). Bear and Things are included only for the parts that apply.
- No benchmark offers a "missed days" list. The Catch-up list in G1 is a design inference from the owner's four modes, not a copied pattern; test it with the owner before building more than a first cut.
- HIG pages are guidance, not rules; where this document departs from them it says so.

## 3. Scenario catalogue (20)

Status is v0.3 behaviour: OK, Partial, Blocked, Missing, or Unverified (reasoned from code, not run).

**S1. End-of-day single write.** OK, apart from D6 and D7. At 5 pm the notification or menu-bar click opens Today with the cursor already in the page; about 40 words; closing the window is enough; nothing re-opens afterwards; "logged" never needs a button; no banner shifts the page.

**S2. Jot through the day, tidy at the end.** Partial. A global shortcut or menu-bar box appends a timestamped bullet to Today without raising the main window, merging through the open editor and never overwriting it. The evening view shows the raw bullets at the top, easy to move under headings. Today is not nagged or counted until the user decides.

**S3. Next-morning catch-up for yesterday.** Partial, hidden. The first launch of the day shows one calm line beside Today: "Yesterday (Tue 6 Oct) isn't written: Write / Skip / Day off". The page opens with the template and carry-over from the last logged day. Saving before a grace cut-off (default noon) keeps the streak.

**S4. Catch up a whole week at once.** Blocked. A Catch-up list shows every missed workday of the last few weeks, grouped by week, each with Write / Skip / Day off and progress "2 of 5". "Write the week" offers one scratch page with a heading per weekday that saves into the day files. When Sources are on, a draft per day is pre-filled from Claude Code and Git. Back-dated pages carry a subtle "written later" mark.

**S5. Laptop closed over the weekend.** Partial. Saturday and Sunday are never flagged when they are non-workdays. Friday's miss sits in Catch-up on Monday. Waking the Mac at 9:00 gives at most one digest, not one nag per missed day. The streak counts workdays only and survives a back-filled Friday.

**S6. Holiday week.** Partial. Select Mon-Fri on the calendar, past or future, then "Mark as holiday / leave" with a reason, in one action. Days show as "off", not "skipped"; no reminders; streak neutral; the weekly summary prints "Holiday" and the standup copy omits it; undo is one click.

**S7. Travelling across time zones.** Unverified, likely bug. Today follows the Mac's current zone without a relaunch. A page open across the change keeps its date and offers "Start today's page". No day is lost or doubled crossing the date line. Reminder time follows the local clock. "Day ends at" is read in the local zone.

**S8. Writing yesterday after midnight.** Partial. With "My day ends at 3:00 am", Today still means yesterday until then, so typing at 00:40 lands on the same page. Without it, the roll-over banner offers "Keep writing Tuesday / Start Wednesday" and never moves text between days. A fresh launch at 00:40 asks which day.

**S9. Editing a day from last month.** Partial: reachable only if the day already has a file (sidebar month list, search); otherwise blocked. Search, the calendar or "Go to date" opens it; the sidebar row selects; edits autosave with a backup; the header says "Tue 9 Sep, 4 weeks ago"; streak, heatmap and reviews update at once; Prev/Next steps across gaps.

**S10. Two Macs edit the same day offline.** Partial (last writer wins; the overwritten text stays under "Restore previous version", `PageView.swift:142-145`; sync-service conflict copies are ignored). After sync a duplicate such as "2026-10-06 2.md" or "(conflicted copy)" is detected and a banner reads "Two versions of Tue 6 Oct": Keep both (append the other under a divider) / Keep this / Keep other, with a preview. Nothing is dropped silently. An evicted iCloud file shows "still downloading", never "missed".

**S11. A day with three sessions of notes.** Partial. Morning, afternoon and evening additions land on one page with capture timestamps. The template is not re-applied. The word count and logged state cover the whole page. Sections collapse. Capture and the open editor writing in the same second never lose text.

**S12. Huge pages (5,000+ words, 30 images).** Unverified. Opens in under a second; autosave never stalls typing; pasted images are downscaled (for example to 2,048 px) and capped to the column width with click to enlarge; summary copies turn images into links; a size warning appears for synced folders; search stays responsive.

**S13. Migrating from a Notion or Obsidian vault.** Missing. An import wizard takes a folder or zip, reads dates from file names (`YYYY-MM-DD.md`), front matter or created date, and previews "142 days, 7 conflicts, 5 undated" before writing. It copies, never moves; never overwrites an existing day (offers append under a divider); keeps images in `assets/`. An Obsidian daily-notes folder can also be used in place without damaging YAML front matter.

**S14. Deleting or merging days.** Missing. "Move to another date..." merges when the target exists (appended under a divider). "Delete day..." sends it to Recently Deleted for 30 days (Apple Journal pattern). Multi-select then "Merge into one page" suits a trip. Every action is undoable; streak and reviews recompute.

**S15. Working on a Sunday.** Partial. A non-workday opens and saves like any day, with no "not a workday" dead end. Writing counts toward totals without creating an obligation. The weekly summary includes it. No reminder or nag fires that day.

**S16. Part-time or 4-day week.** Partial. Settings take working days as a weekly pattern or "N days per week". The streak is measured against that pattern, or as a weekly goal ("4 of 4 days"). Changing the pattern does not rewrite past streaks (today history is re-evaluated, UX_SPEC 3.3 rule 5). A one-off swap day is one click.

**S17. Monday standup summary.** Partial. From launch to clipboard in under 10 seconds: Review, "Last working day" or "Last 5 working days", shaped as Yesterday / Today / Blockers from the template headings, as plain bullets, Markdown or Slack-friendly text. Empty sections and days are dropped, carried-over items listed once, holidays omitted.

**S18. Monthly and yearly review.** Missing. The month view shows days written, items under "Finished" grouped by week, and pinned highlights. The year view shows per-month summaries plus highlights. It flags "6 days missing, catch up first". Export to Markdown or PDF. The cadence suits a brag-document habit (every couple of weeks, or once a year).

**S19. Reminder while the app is not running.** Missing. A system notification arrives at 4:55 pm even if Gloamlog was quit or the Mac restarted; saving the day cancels it; waking the Mac gives one notification, not a burst; no window is forced forward; Settings says plainly what works when the app is closed.

**S20. Find a decision from six months ago and share it.** Partial. ⌘F searches across years with date, heading and snippet, plus date-range and heading filters; empty template headings never match; "Copy results" or export as Markdown for a retro; opening a hit lands on the match.

## 4. The 12 biggest gaps between v0.3 and a daily-usable app

Ordered by impact on the owner's four modes, then by effort. Effort is a rough size, not an engineering estimate: S = days, M = one to two weeks, L = longer.

**G1. Reach and write any date; catch up days and weeks.** Effort M. Closes D1, D2, D12, D13, D14, D19; S3, S4, S5, S9, S15.
- Smallest useful version: a toolbar with Prev / Today / Next and a Calendar button (month popover, every date clickable, content meter, missed workdays clearly outlined); ⌘J "Go to date" (unused in today's menus) accepting "last friday", "2 oct", "-3"; a sidebar "Catch up" row with a count, listing missed workdays of the last 4 weeks with Write / Skip / Day off; the Week view always shows seven day cards with Open (remove the dead-end empty state, include weekends); past-day header "Fri 2 Oct, 4 days ago" without the streak chip; Prev/Next that crosses gaps.
- Done when: from a cold launch any date in the last two years opens in two interactions or fewer, a first-time user does it unprompted in a five-task test, and a back-filled day updates streak and heatmap immediately.

**G2. Replace the quota and the fragile streak.** Effort S to M. Closes D3, D8; S3, S6, S15, S16.
- Smallest: remove "N / 20 words to log today" for a quiet word count and "Saved"; "logged" means any text (threshold default 1, still configurable); show the streak in one place only, or as "this week: 3 of 4"; back-fill repairs it; one grace day or weeks-based counting; "Day off" distinct from "Skipped"; a calm "missing tomorrow would break your streak" hint instead of retrospective guilt.
- Done when: a Friday back-filled on Monday restores the streak, no screen shows a quota, and a one-line jot counts.

**G3. Reminders that work when the app is closed, gentle by default, with a morning digest.** Effort M. Closes D6, D7; S1, S5, S19.
- Smallest: schedule local notifications with calendar triggers, re-planned on save, launch and settings change, so they can fire while the app is not running (engineering to confirm; Day One only promises that the computer is on); default Gentle; Strict becomes opt-in "Persistent" with a warning; optional 9:00 "Yesterday isn't written" digest; Settings states what happens when the app is closed; the in-window banner reserves its space or becomes a toast so the page never jumps.
- Done when: quit the app, wait for 4:55, and the notification still arrives; saving the day cancels it; no window is ever forced forward by default.

**G4. Quick capture from anywhere.** Effort M. Closes D9; S2, S11.
- Smallest: a user-configurable global shortcut and a menu-bar item open a small floating box; Return appends "- 14:32 text" under a "Notes" heading on Today, with the main window closed or open and never overwriting it; a Shortcuts action and a `gloamlog://append?text=` URL for scripts; a Services entry. Global-shortcut registration needs an engineering check.
- Done when: capture takes three seconds or less from any app, works with the main window closed, and never loses text if Today is open.

**G5. Settings: findable, HIG-shaped, and filled with what the jobs need.** Effort M. Closes D4, D5, D21, D24.
- Smallest: keep ⌘, and the App-menu item; add "Settings..." to the page "..." menu and contextual "Change..." links in the reminder banner, template, storage messages and empty states; about six panes (General, Reminders, Page, Capture and Sources, Storage and Sync, Review and Export), each with at most about 8 controls; window title follows the pane; last pane restored.
- Done when: five of five first-time users find Settings and change the reminder time in under 15 seconds. Most of the new contents depend on G1, G3, G4, G6, G8, G9 and G12 existing.

**G6. Review and export for any range.** Effort M to L. Closes D10, D16; S17, S18, S20.
- Smallest: a Review view with a range picker (Last working day / Last 5 working days / This week / This month / custom) and a format picker (Standup, By day, By section); copy as Markdown, plain text or Slack-friendly; File > Export... to Markdown file or folder and PDF for a range; share sheet; a month view with counts, "Finished" items by week and pinned highlights.
- Done when: Monday standup text is on the clipboard in under 10 seconds and a month exports to a file the owner can paste into a review.

**G7. Day management: change date, move, merge, delete with undo.** Effort S to M. Closes D11; S9, S14.
- Smallest: page "..." menu gets "Change date..." (merge prompt when the target exists) and "Delete day" to Recently Deleted for 30 days, reusing the existing backups; multi-select in the sidebar to merge.
- Done when: a page typed into the wrong day moves in two clicks and can be undone.

**G8. Day boundary and time zones.** Effort S. Closes D18; S7, S8.
- Smallest: confirm the `Calendar.current` snapshot problem with a test, then use an auto-updating calendar; add "My day ends at" (default 3:00 am); test across DST and zone changes.
- Done when: changing the Mac's time zone with the app running moves "Today" correctly, and typing at 00:40 lands on the page the user considers today.

**G9. Safe folder sync.** Effort M to L. Closes D17, D20; S10, S12.
- Smallest: detect conflict copies by name pattern and show a resolve banner (keep both / pick one); treat evicted-file placeholders as "downloading", never "missed"; use file coordination and a directory watcher instead of full rescans; incremental indexing so `reload()` stops parsing every file every 30 s; a Storage pane showing sync state and the "keep downloaded" advice.
- Done when: a two-Mac offline edit of one day ends with both versions retrievable and nothing silently lost, and 2,000 logs do not cause periodic stalls.

**G10. Page ergonomics and search quality.** Effort M. Closes D15, D23; S11, S12, S20.
- Smallest: a new day starts with one "Notes" area and the template becomes an optional insert, or empty headings are not saved; search ignores empty headings and gains a date range; sidebar rows show the first line; pasted images are downscaled and capped to the column width.
- Done when: searching "Finished" returns only days that have something under it, and a one-line day does not need heading cleanup.

**G11. Bring your history: import and first-run.** Effort M. Closes D22; S13.
- Smallest: import from a folder (Obsidian daily notes, dated `.md`, Notion export) with a preview, copy-only, no overwrite; first run asks one question (folder), defaults the rest, and offers Skip on every step and "Do you have past notes?".
- Done when: a 100-day vault imports with a correct preview and no changed existing days.

**G12. Sources: Claude Code and Git auto-fill, built for catch-up first.** Effort L. Closes E4; S4.
- Smallest: "Draft from activity" for any past day: Claude Code sessions and Git commits for that date, read-only, redacted, per-project allow/deny, inserted as editable bullets with evidence links. It matters most on back-filled days, where memory is weakest (2.4). Already planned as the STRATEGY product pillar for 0.4.
- Done when: a missed day can be drafted in under a minute and the owner edits rather than writes.

**Suggested slicing.** A "usable daily" release is G1, G2, G3, a minimum G5, G7 and G8, plus a range-aware copy from G6. A "daily and safe" release adds G4, the rest of G6, G9 and G10. A "history and auto-fill" release carries G11 and G12. This moves Sources (STRATEGY 0.4) after the daily-use basics, because no amount of auto-fill helps if yesterday cannot be opened. First check: give the owner a prototype of G1 and run a five-task test (open last Friday, back-fill a whole week, mark a holiday week, go to 3 months ago, change a page's date) before building the rest.
