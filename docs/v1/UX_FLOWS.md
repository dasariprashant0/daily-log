# Gloamlog v1: UX flows, screens and settings

**Status**: design, not built. Reconciled with `docs/v1/PRD_V1.md`, `docs/v1/UX_AUDIT_AND_BENCHMARKS.md` and `docs/v1/DESIGN_V4.md` (section 6 lists every difference). Where this file and `DESIGN_V4.md` differ, this file wins on behaviour and copy, that one on pixels and tokens.
**Replaces** the navigation, settings and flow parts of `docs/UX_SPEC.md` (five-section era). Reused from it: Strict/Gentle rules (its section 5), skip sheet, carry-over, folder-change dialogs, VoiceOver, contrast and reduced-motion rules. Page and file rules stay in `docs/EDITOR_CONTRACT.md`.
**Platform**: macOS 13+, SwiftUI without macros (`ObservableObject`, `@StateObject`, `@AppStorage`; no `@State`, no `@Observable`), the WebKit editor bundle for the page, local-first, no network.
**Tags**: [M1] to [M6] = PRD milestone that ships it. [Core] needs a change in `app/Core`. [Contract] needs a change in the editor contract. [Verify] is unproven on a real Mac. [Could] is outside the PRD, offered for later.

## 0. Why v0.3 fails, and what this design decides

Evidence is in the audit (D1 to D24). In short: the sidebar lists only days that already have a file and ⌘[ ⌘] step through that list, so a gap day such as Fri 2 Oct in `real-6-mainview.png` cannot be opened; Settings is three tabs with no entry in the window; reminders live only while the process runs.

| # | Decision | Why |
|---|---|---|
| D1 | Any past date opens from the sidebar calendar, Go to date, Catch up and ⌘[ ⌘]. Opening never writes a file | The owner's complaint; PRD R1, M1-A1 |
| D2 | UI word for a gap: "unlogged" (code status stays `.missed`). Never "missed", "overdue", "behind". The PRD's "Next missed day" button reads "Next unlogged day" | Neutral; matches "You have 3 unlogged days" |
| D3 | A backfilled day is an ordinary logged day. The streak is computed from files, so it heals. No "late" label | Honest; nothing to explain |
| D4 | Catching up is the normal page plus a thin session bar. No second writing surface | One editor, one writer, fewer data-loss paths |
| D5 | Strict applies to today only. Past days are nudged gently, never forced forward | Strict is for one clear task |
| D6 | Jots go under one heading ("Jots") at the page bottom and do not count toward "logged" unless a setting says so; a jots-only day reads "started" | PRD Q1: the reminder must still ask for the write-up |
| D7 | Closed-app reminders are system-scheduled notifications for the next 14 working days, re-planned on every change | PRD M5a; Strict needs the app running |
| D8 | Sync is the user's own folder. Nothing is overwritten or deleted silently; conflicts merge under a labelled heading; extra files go to safety copies | PRD M5b, XC-2 |
| D9 | Sources are off by default, read-only, local, and suggest editable lines. No network path of any kind | PRD M6 and non-goals |
| D10 | Settings is a window of 11 panes with a visible entry in the main window and deep links from notices | PRD R5 |

## 1. Information architecture and navigation

### 1.1 Map
```
Gloamlog.app
├─ Main window (one Window scene, min 860 x 600, default 1000 x 760)
│  ├─ Sidebar: Search, Today, Catch up (N), Review, calendar, Recent, footer (streak, sync chip, Settings)
│  ├─ Toolbar (per destination, 1.3)            ├─ Notice slot (every destination, 1.8)
│  └─ Detail: Day page | Catch up (+ session) | Review (Week, Month, Year, Range) | Search results
├─ Jot panel (global shortcut) and menu bar popover (jot field, state, Catch up, actions)
└─ Settings window (⌘, / footer button / page menu / popover): 11 panes. Sheets: Go to date, Skip, Restore, conflict view, Onboarding
```

### 1.2 Sidebar, top to bottom
| Item | Shows | Notes |
|---|---|---|
| Search your logs | field, ⌘F | Esc clears; results replace the detail pane and the previous destination returns (kept) |
| Today ⌘1 | ○ not started, ◐ started, ✓ logged, − skipped, moon not a working day | v0.3 glyphs |
| Catch up (N) ⌘2 [M1] | N = unlogged days in the window; badge hidden at 0, row stays | one count, reused by notice, menu bar, notification |
| Review ⌘3 [M1] | opens at the last scale used (Week first time); Week, Month, Year are ⌘3, ⌘4, ⌘5 in the Go menu | one row, so the calendar fits |
| Calendar [M1] | month grid, number plus shape mark: ✓ ◐ ○ − · [9]; ‹ › change month, the title is a month and year picker; click a cell opens that day; ⇧-click or drag selects a range (opens Catch up scoped to it) | `MonthGrid`, reused at 36 pt in Go to date. Under 640 pt window height it becomes a one-week strip |
| Recent | the 7 newest pages (not today); a jots-only day shows ◐ and "1 jot" | replaces month groups; the calendar and Year review cover older days |
| Footer | streak ("No streak yet", "12 day streak"; click = 12-week map), sync chip (hidden unless there is something to say), Settings gear | streak also as a chip on Today only; hidden when Show streak is off |

### 1.3 Toolbar, menus, entry points
| Destination | Left | Right |
|---|---|---|
| Day page | ‹ [Today] ›, [date ▾] = Go to date | Share ▾ [M3] (Copy as Rich text, Markdown, Plain text; Show in Finder; Share…), Jot [M2], ⋯ (Skip day…, Copy page as markdown, Open folder, Restore previous version…, Settings…, [Could] Change date…, Delete day…) |
| Catch up | none | none (controls sit in the view) |
| Review | ‹ › and [Week\|Month\|Year\|Range] | Export ▾ (Copy as Rich text, Markdown, Plain text; Save as Markdown…; Save as PDF…; Share…) |
Go to date: ⇧⌘T. Today also on ⌘T. ⌘[ ⌘] = previous/next calendar day (period in a review); ⌘] on today does nothing (M1-A2). Every toolbar item has a menu command. Jot also from the Dock menu (Today, Jot, Catch Up, Settings…). The Settings button is a sidebar footer item, not a toolbar button, because the HIG advises against a Settings button in a window toolbar.

### 1.4 Opening and creating any date [M1]
1. Routes: calendar cell; ‹ › and ⌘[ ⌘] (one calendar day, gaps included); Go to date; Recent; Catch up and Review rows; search hit; notification; menu bar "Write Thu 8 Oct".
2. Go to date takes `2026-10-02`, `2 oct`, `yesterday`, `last fri`, `-3` (`NSDataDetector` plus an integer rule; the resolved date shows before Return) beside the same grid at any year. Bad input: "Couldn't read that date. Try 2 Oct, last friday or 2026-10-02."
3. Opening writes nothing. The template shows in the editor only; the first real edit creates `YYYY-MM-DD.md`; leaving it untouched leaves no file.
4. Range: 1 Jan 2000 to today. A day before the log start date opens and saves normally, shows "Before your log start. It won't appear in Catch up.", and does not touch Catch up or the streak (1.6).
5. Header on a past day: relative label ("2 days ago") before the word line, no banner, no nag. Non-working day: opens, chip "Not a workday", counts if logged, never nags. Skipped day: the skipped page (kept) with [Write a log anyway] [Undo skip].
6. Future day [Could; PRD §7 excludes it]: the hidden flag `allowFutureDays` (no Settings row) is off. Off: future cells dimmed, inert, tooltip "Upcoming"; Go to date says "That day hasn't happened yet." On: opens with "This day hasn't happened yet. What you write here waits for it."; ignored by streak, Catch up and reminders until that day, then the normal rule applies. Planned leave needs no page: Skip day… "Through a later date" (kept) already covers future days.
7. [Could] Change date… moves a page to another day (merge prompt if the target has one); Delete day… sends it to safety copies, recoverable in Settings > Backup and restore (audit G7).

### 1.5 Catch up [M1]
**Unlogged** = a working day on or after the log start date, before today, inside the window (default 30 days), with no page or a page below the minimum words (jots-only pages included), and not skipped. Today is never listed. One list feeds the badge, the screen, the Today line, the menu bar row, the notification and the session.

**One day, next morning**: when exactly one day is unlogged and it is the previous working day ("Friday" on a Monday), Today shows one line "You haven't logged Thu 8 Oct. [Write it] [Skip day]". Write it opens that page; afterwards From yesterday draws on it.

**Several days or a whole week**: Catch up screen (3.4).
- Scope control (Last 14 | Last 30 | Since log start) changes this view only; Settings > Page sets the default window. Rows group by week with "0 of 4 logged". **Order is oldest first, the same as the session**, so the first row is the first day you will write.
- Row: glyph, date, hint ("11 of 20 words", "1 jot, not tidied", "3 Claude sessions · 2 commits" [M6]), a primary action (Write, Continue, Tidy up = open at the Jots heading) and Skip, always visible. Return = primary, S or Delete = Skip, ⌘A selects all, ⇧-click and ⌘-click select several and a bar shows "3 selected [Skip…] [Clear]".
- Skip… ▾: Skip selected, Skip all N days. The skip sheet in list mode (reason chips Holiday, Leave, Sick, Day off, Other; one confirmation), then "Skipped 3 days as Leave. Undo" for 8 s; each skipped page keeps Undo skip (M1-A4).
- [Start catching up] opens the oldest row in a session. Empty: "You're all caught up." New user: "Nothing to catch up on yet. Days before your first page don't count." [Open calendar] [Log start date…]. Older gaps stay in the calendar.

**Fast multi-day mode = the session bar** (3.2) above the day page: `[End] Catching up 3 of 5 · Wed 7 Oct [‹] [Skip day] [Next unlogged day]` and a 3 pt progress line.
- [Next unlogged day] (⌘↩ [Verify the editor lets it through], fallback ⌥⌘↓) is always enabled: it opens the next unlogged day after this one, wrapping once. A day left under the minimum stays in the list. It never moves you by itself; at the minimum the line reads "Logged, 24 words" and nothing else changes.
- [Skip day] opens the skip sheet, then advances. Esc or [End] returns to the list. Everything autosaves, so leaving mid-session needs no confirmation.
- At the end the page area shows "All caught up. 3 logged, 1 skipped." with [Review this week] [Go to today] (and "Your streak is 9 days." when it is above 1). Target (PRD R3): 3 days of about 20 words in 2:00 or less.
- Not designed, on purpose: inline quick-fill rows or one scratch page for the whole week (audit S4). A second writer needs its own kill test; add only if the target fails.

### 1.6 What backfilling does to status and streak
Streak, calendar, badge and Recent recompute from files within 2 s of each save (`didSave`).
| Action on a past day | Day | Streak and best | Calendar, heat map | Catch up | Reminders |
|---|---|---|---|---|---|
| Reach the minimum words | logged | recomputed from files: the gap closes, the streak can jump | ✓ | −1 | none |
| Write fewer words, or only jots | started | unchanged (still a gap) | ◐ | stays | none |
| Skip one day or several | skipped | neutral, never breaks | − | −n | none |
| Undo skip | unlogged | breaks again if a past working day | ○ | +n | none |
| Empty a logged page | unlogged | gap returns | ○ | +1 | none |
| Write on a non-working day | logged | +1 | ✓ | none | none |
| Write before the log start date [Core] | logged | no effect | ✓ | none | none |
| Change minimum words or working days | re-evaluated | re-evaluated | updated | recounted | re-planned |
The log start date is stored (default: the first page's date). Backfilling earlier never moves it (M1-A9). No screen says "late"; the relative label ("6 days ago") is the only cue.

### 1.7 Reviews, copy and export [M1 week; M3 the rest]
- Reach: Review row (⌘3 to ⌘5); the calendar's month title; page ⋯ "Open week review"; menu bar "Copy this week's summary" (copies without opening the window).
- One screen: toolbar ‹ › and [Week|Month|Year|Range] (Range = two date fields); controls row [Last week] [This month], checkboxes Skipped days (on) and Jots (off), Group by Day or Section. The checkboxes apply to every copy and export; scale, grouping and both checkboxes are remembered view state, not Settings. Future periods are disabled.
- Counts line everywhere: "Logged 19 of 22 · 2 skipped · 1 not logged". Never "missed".
- Week [M1]: every working day is a tile that opens its day, empty weeks included; empty state "Nothing logged this week yet." with [Catch up this week] (a session limited to that week) and [Go to today]. Month and Range [M3]: by Section by default (template order, each item dated, then "Other notes"); the Finished heading, if the template has one, opens expanded, the others collapsed with counts. Year [M3]: a 12-row table (Logged, Skipped, Not logged); a row opens that month. Defaults (PRD Q3): Section, jots excluded, skipped days one line ("Skipped · Leave").
- Export ▾ copies or saves exactly what is shown: Rich text (Markdown rides on the pasteboard too, so chat, Mail and Notes paste formatted text and plain editors get Markdown), Markdown (⇧⌘C, kept), Plain text (no `#` or `**`), Save as Markdown (+ `assets/` with only the images used), Save as PDF (WebKit `createPDF`), Share… (system share sheet; nothing leaves until a target is chosen). Names `Gloamlog 2026-W41.md`, `Gloamlog 2026-10.pdf`. Whole archive: Settings > Backup and restore.

### 1.8 Notice slot [M1]
Notices sit above the page title on every destination (v0.3 shows reminders on a day page only). Day pages reserve one 32 pt line for them, so the first notice never moves the text under the caret; a second stacks only while the caret is outside the editor. At most two show, in this order: folder or sync problem; save error; conflict; end-of-day reminder when due; catch-up line (once a day, hidden while the reminder shows); rollover ("It's now Saturday…"); information. Errors and warnings with actions never auto-dismiss; information goes after 4 s, 8 s when it carries Undo. A notice never takes focus.

## 2. Flows

### 2.1 Mode A: write once at the end of the day
1. Reminder at the set time (2.6). Strict: notification, window forward once (if Gloamlog is already in front, only the notice shows). Gentle: one notification.
2. Open Today (⌘1 or the notification). Template headings show unsaved, the caret is in the first line, "From Thu 1 Oct · 4 items" offers Carry over.
3. Write. Autosave about 600 ms after a change. At the minimum the line reads "Logged, 24 words"; the notice and pending notification clear; the menu bar icon shows ✓.
4. Nothing to write: [Skip day] (reason chips). No Save button; ⌘S only flushes.

### 2.2 Mode B: jot through the day, tidy at the end [M2]
1. Any app in front: ⌃⌥J, or the menu bar jot field, or Jot in the toolbar. Type, Return. The panel closes in under a second; the previous app keeps focus (2.5).
2. `- 14:32 Fixed signup bug, waiting on Ana` lands under "Jots" at the bottom of today's page. The day reads "started": jots are not words (D6), so the reminder still fires.
3. Tidy: drag lines into headings or retype. [Could] a slim notice "You have 3 jots. [Move under What I did] [Keep where they are]" at reminder time.
4. Not tidied by morning: Catch up lists the day as "3 jots, not tidied" with [Tidy up].

### 2.3 Mode C: next morning, yesterday [M1]
1. Open Gloamlog (login item, menu bar, Dock). Today shows "You haven't logged Thu 8 Oct. [Write it] [Skip day]"; the popover offers "Write Thu 8 Oct".
2. Write it opens Thu 8 with the template (jots at the bottom if any; Sources strip [M6]). At the minimum the line reads "Logged".
3. ⌘T or [Today]. From yesterday now draws on the day just written.

### 2.4 Mode D: several days or a whole week [M1]
1. Entry: the Today line "You have 5 unlogged days. [Catch up]", sidebar Catch up (⌘2), the popover row, the morning notification, Week review "Catch up this week", or a calendar range.
2. Glance at the list (3.4), press [Start catching up]; the oldest day opens with the session bar.
3. Write about 20 words, press [Next unlogged day]. No work that day: [Skip day]. In the list, select several and Skip… once.
4. The end state (1.5). Calendar, badge, streak and map updated as each day crossed the minimum.

### 2.5 Quick capture, "jot" [M2]
- Entry points: global ⌃⌥J (record another or Off in Settings > Shortcuts; a combination another app owns is refused); the popover jot field; Page > Jot… and the toolbar button; Dock menu. [Could] Services "Add to Gloamlog", a `gloamlog://jot?text=` URL and a Shortcuts action, capture into another day.
- Panel (3.7): floating above any app, Space and full-screen app; takes the keyboard without activating Gloamlog or raising its window; focus returns to the previous app on close. Return adds, ⇧Return adds a line break, Esc cancels and writes nothing, empty Return does nothing. [Verify] Carbon `RegisterEventHotKey` on an ad-hoc-signed app (no Accessibility permission) and a non-activating `NSPanel` over full-screen apps.
- Line: `- <time> <text>` under `## Jots` at the end of today's page; heading created when missing. Time is 24-hour `HH:mm` (Settings > Page can turn it off). Text starting `[]` becomes `- [ ] text` without time; extra lines indent two spaces.
- Page has no file yet: only the Jots section is written. Opening it shows the template headings above the jots, written only when you type (M2-A4); empty headings are never persisted (audit D15) [Contract].
- Page open in the editor: one editor transaction appends inside the Jots section, so caret, selection, text typed a moment ago and undo are untouched (M2-A3); autosave then writes it. [Contract] `appendToSection(heading, markdown)` beside `insertMarkdown`; one retry if the page changed in between.
- Page not open (other day, other screen, window closed): flush today's page if it is the open one, then append through `LogStore` (atomic, safety copy first).
- Feedback: "Added to Today" for 600 ms, VoiceOver "Added to today's log", header count "1 jot".
- Folder unavailable: the jot waits in a local queue (Application Support, never synced); "Saved on this Mac. It will be added when your log folder is back."; added once, in order; sidebar "1 jot waiting".
- Counting [Core]: a leading time stamp is not a word; jot text counts only if Settings > Page "Jots count toward logging a day" is on.

### 2.6 Reminders: Strict, Gentle, catch-up nudges, closed app
| Surface | Today, Strict | Today, Gentle | Unlogged days (both modes) |
|---|---|---|---|
| Notification | once at the time: Open, Snooze, Skip today [M5a] | same | if switched on (default off): once on working days at 9:30, "You have 5 unlogged days"; Catch up, Tomorrow [M5a] |
| Window | forward once at first fire (if Gloamlog is already in front, only the notice shows); re-open every 5 min if closed, no keystroke stealing | never | never |
| Notice | reminder notice on every screen while due | same | one catch-up line on Today per day [M1] |
| Menu bar | icon pencil, "Due now: 4:55 pm" | same | row "5 unlogged days · Catch up" |
| Dock | one bounce (not with Reduce Motion) | none | optional badge N (off) |
| Snooze | 2 a day | unlimited | "Later" hides the line and the next notification once |
| Stops | logged, skipped, non-working day, after 11 pm | same | Catch up empty |
Rules: (a) today's reminder outranks the catch-up line; (b) a Strict re-open never navigates away from the page or screen you are typing in: the notice appears, nothing moves; (c) after 3 nudges in a row with no visit to Catch up, nudges drop to Mondays until you open it; (d) logging or skipping today cancels its pending notification; (e) notification text never holds page text or streak numbers and never gives an order (HIG): "Today isn't logged yet" / "It's 4:55 pm. Open Gloamlog when you're ready."

**Closed app [M5a]** (PRD Q5: a notification is enough; Strict needs the app): on launch, settings change, logging, skipping and midnight, plan the next 14 working days with macOS (`UNCalendarNotificationTrigger`), each cancelled when its day is logged or skipped. The optional morning notification carries a projected count (unlogged now plus days that will have passed). Settings > Reminders shows "Next reminder: Fri 9 Oct, 4:55 pm" and, when notifications are off, a warning with [Open System Settings]. The UI states the limits: nothing fires while the Mac sleeps (it arrives on wake); a Focus can silence it. [Verify] first, 2 h: schedule, quit, see it fire on an ad-hoc-signed build, and whether a Snooze action works with the app not running.

### 2.7 Onboarding
**New user**, 4 steps (Back/Continue, capsules; Esc does not dismiss; [Skip setup] on every step applies the defaults from there on):
1. **Your logs**: "I'm new" (folder radios: This Mac `~/Gloamlog`, iCloud Drive if present, Another folder; checkbox "Let me fill in recent days" sets the log start 14 days back, default today) or "I already have logs".
2. **Your page**: template cards (Daily review, Standup, Blank) and the words rule.
3. **Reminder**: time, days, Strict or Gentle. Leaving the step asks macOS for notification permission, after one line says why.
4. **All set**: open at login (off), jot shortcut with [Try it] [M2], "Fill in from your work: set up later in Settings" [M6]. [Open Gloamlog] or [Start writing]; when days are unlogged, a text button "Catch up on 5 days first".
**Existing logs** (3.11): step 1 lists the folders found (default, iCloud `Gloamlog`, the old folder setting) with counts and date range, [Choose another folder…], and "Log starts [3 Jan ▾]" (default the first page; nothing is moved or rewritten; unrecognised files are counted). Step 2 adds "Your pages stay as they are. The template only fills new days." A v0.3 user (settings exist) skips to What's new, then Today with the catch-up line. On a second Mac, "Join from another Mac…" [M5b]: pick the shared folder, settings arrive, setup ends. A folder dropped from Finder onto the window later offers "Use this folder?".
**Long gap**: after 40 days away Catch up shows the window only, plus "Your last page was 40 days ago. [Start fresh] [Show 60 days]". Start fresh moves the log start date to today; nothing is written to the folder.

### 2.8 Weekly summary, export, share [M1 verify; M3]
1. Fast path: menu bar "Copy this week's summary" (rich text; no window opens), or Review > Week > Export ▾ > Copy as Rich text. Paste into the standup tool, Mail or Notes. A chat box that shows raw markup: Copy as Plain text.
2. Month or year: Review > Month or Year, tick Skipped days and Jots as wanted, then Export ▾ > Copy…, Save as Markdown… (only the images used go to `assets/`) or Save as PDF…. [Could] quick ranges "Last working day" and "Last 5 working days", and a Standup shape (Yesterday, Today, Blockers) for Monday standups (audit S17).
3. Send: Export ▾ > Share… opens the system share sheet; nothing leaves until a target is chosen. Result line "Saved 5 days and 2 images." [Show in Finder]; failure "Couldn't save “Week 41.md”. The folder may be read-only or the disk full." [Try again] [Choose another place…].

### 2.9 Sync through a shared folder, and conflicts [folder M1; sync M5b]
- Model: the folder is the database. Gloamlog runs no sync ("Your folder provider moves the files"); writes are atomic; the folder is re-read on switching to the app, every 30 s and on external change; no page is ever deleted.
- Setup (Settings > Storage and sync): This Mac, iCloud Drive, Dropbox, Another folder…, the provider named from the path; [Set up sync…] and [Join from another Mac…] [M5b]. Changing folder keeps the v0.3 copy, move and use-existing dialogs; days in both are never overwritten and are listed. Sidebar sync chip: Synced, Syncing, "2 to review", Folder unavailable.
- Shared through the folder [M5b]: pages, `assets/`, a small hidden settings file (template, carry-over headings, minimum words, working days, reminder time and style, log start date). Per Mac: folder path, login item, menu bar, shortcuts, "Remind on this Mac", safety copies. Sections say "Shared across your Macs" or "This Mac only".
- iCloud placeholders (`.2026-10-05.md.icloud`) are counted, never treated as missing: "5 days are still in iCloud. [Download all]"; calendar cells show a download mark; search says "N files could not be searched".
- Open page changed elsewhere, no edits here: reloads within 10 s with "Updated from another Mac. [Undo]". With edits here: autosave pauses for that page, your text stays on screen, and the notice reads "This page changed on another Mac while you were writing. [Keep mine] [Take theirs] [Keep both]". Keep both adds lines found only in the other version under "From other copy (4:40 pm)"; every version stays in safety copies.
- Conflict copies (`2026-10-05 2.md`, "… conflicted copy …", `.sync-conflict-`): the chip, Settings and a launch notice say "1 conflict in ~/Gloamlog. [Review…]". The conflict view (a 720 x 520 sheet: "This Mac, 5:02 pm, 63 words" beside "Other copy, 4:40 pm, 71 words", differing lines marked) offers [Merge both] (appends the other version as above and moves the extra file to safety copies), [Keep this Mac's] and [Use other copy]. Nothing is deleted, nothing is ignored.
- Jots from two Macs are separate time-stamped lines, so Keep both merges them without loss. Folder missing or read-only: the v0.3 banners; typed text stays; jots queue.

### 2.10 Sources: Claude Code and Git [M6]
1. Off by default. Settings > Sources, or the strip's "Turn on…", opens "Let Gloamlog read your Claude Code and Git activity?" ([Choose projects…] [Turn on] [Not now]). Nothing is read before Turn on; each project and repository is ticked by you; hidden ones are skipped before any text is read.
2. Any day shows a strip "Suggested from your work · 4 items" under the header (same pattern as From yesterday, so it works at every width). Expanded (3.9): your commits (repo, short hash, subject), Claude sessions (project, time, count), the first line of up to 3 prompts, files touched. [Insert] per row, [Insert all].
3. Insert adds an ordinary bullet with its evidence in the text, `Add pricing table (acme-site 3f2a9c1)`, under the heading set in Settings, through the safe-append path of 2.5; it counts as words. A row whose evidence is already on the page shows "Added" and is never inserted twice.
4. Catch up: an unlogged day inside Claude Code's retention (about 30 days) shows the same strip; older days say "Claude Code no longer keeps sessions this old." On screen: "Read-only. Nothing leaves this Mac. 4 values hidden (2 emails, 2 tokens)."

## 3. Screen inventory and wireframes
Marks are shapes, never colour alone: ✓ logged, ◐ started (below the minimum, or jots only), ○ unlogged, − skipped, · not a working day, [9] today. Pixel layout and tokens are in `DESIGN_V4.md`.

### 3.1 Main window: Today, morning after a week away
```
┌──────────────────────────┬──────────────────────────────────────────────────────────┐
│ ● ● ●                    │ ‹ [Today] ›  [Fri 9 Oct ▾]               [Share ▾] [Jot] │
│ ⌕ Search your logs       ├──────────────────────────────────────────────────────────┤
│ ○ Today             ⌘1   │ You have 5 unlogged days.       [Catch up] [Later]    x  │
│   Catch up     (5)  ⌘2   │                                                          │
│   Review            ⌘3   │ Friday, 9 October                                      ⋯ │
│ October 2026    ‹  ›     │ [No streak yet]  0 words. Counts as logged at 20.        │
│  M  T  W  T  F  S  S     ├──────────────────────────────────────────────────────────┤
│ 28 29 30  1  2  3  4     │ ▸ From Thu 1 Oct · 4 items               [Carry over]    │
│  ✓  ✓  ✓  ✓  ◐  ·  ·     │                                                          │
│  5  6  7  8 [9]          │ What I did                                               │
│  ○  ◐  ○  ○              │ Write about your day, or press / for commands            │
│ RECENT                   │                                                          │
│ ◐ Tue 6 Oct   1 jot      │ Finished                                                 │
│ ◐ Fri 2 Oct              │                                                          │
│ ✓ Thu 1 Oct              │ Started                                                  │
│ ✓ Wed 30 Sep             │                                                          │
│ ✓ Tue 29 Sep             │ Pending / blocked                                        │
│                          │                                                          │
│ No streak yet    [gear]  │                                                          │
└──────────────────────────┴──────────────────────────────────────────────────────────┘
```
Day-page states, same layout. Word line: "0 words. Counts as logged at 20." / "12 words. Counts as logged at 20." / "Logged, 63 words"; past days add "2 days ago". Not started; started; logged; skipped (skipped page); not a working day; before the log start; reminder due (notice "It's 4:55 pm. Time to write up today. [Remind me in 15 min · 2 left] [Skip day]"); rollover; folder problem (3.12).

### 3.2 A past day inside a catch-up session
```
┌─ Wed 7 Oct, inside a catch-up session ─────────────────────────────────────┐
│ [End]  Catching up 3 of 5 · Wed 7 Oct    [‹] [Skip day] [Next unlogged day]│
│ ████████████████████████████████████████████────────────────────────────── │
│ Wednesday, 7 October                                           2 days ago  │
│ 12 words. Counts as logged at 20.                                    Saved │
│ ▸ Suggested from your work · 5 items                          [Insert all] │
│ What I did                                                                 │
└────────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Go to date (popover from [date ▾], ⇧⌘T)
```
┌─ Go to date ───────────────────────────────┐
│ [last fri              ]  → Fri 2 Oct 2026 │
│   October 2026                    ‹  ›     │
│   M   T   W   T   F   S   S                │
│  28  29  30   1   2   3   4                │
│   5   6   7   8  [9] 10  11                │
│ [Today]                         [Open]     │
└────────────────────────────────────────────┘
```
Cell states (sidebar and here): ✓ logged, ◐ started, ○ unlogged working day, − skipped, no mark for an off day or a day before the log start, [9] today, filled = the open page, shaded = selected range, dimmed and inert = future. Keys in 5.1; the sidebar calendar is one tab stop.

### 3.4 Catch up
```
┌─ Catch up ─────────────────────────────────────────────────────────────────┐
│ Catch up                                           [Start catching up]     │
│ You have 5 unlogged days.   (Last 14 | Last 30 | Since log start) [Skip… ▾]│
│ Week of 28 Sep                                                0 of 1 logged│
│ ◐ Fri 2 Oct   11 of 20 words                          [Continue]   Skip    │
│ Week of 5 Oct                                                 0 of 4 logged│
│ ○ Mon 5 Oct   3 Claude sessions · 2 commits               [Write]   Skip   │
│ ◐ Tue 6 Oct   1 jot, not tidied                          [Tidy up]   Skip  │
│ ○ Wed 7 Oct                                                [Write]   Skip  │
│ ○ Thu 8 Oct                                                [Write]   Skip  │
├────────────────────────────────────────────────────────────────────────────┤
│ 3 selected          [Skip…]   [Clear]        ⇧-click or ⌘-click to select  │
└────────────────────────────────────────────────────────────────────────────┘
```
A day that reaches the minimum keeps its row, turns ✓ "Logged, 24 words", and leaves the list when you leave the screen; a skipped row fades out. Footer bar only with a selection.

### 3.5 Reviews
```
┌─ Review · Week, a past week with nothing logged ───────────────────────────────┐
│ [Week|Month|Year|Range]  ‹ ›                                   [Export ▾]      │
│ Week of 14 to 20 Sep              Logged 0 of 5 · 0 skipped · 5 not logged     │
│ [Last week] [This month]   [x] Skipped days  [ ] Jots   Group by (Day|Section) │
│  Mon 14    Tue 15    Wed 16    Thu 17    Fri 18      day tiles, each opens     │
│  Write     Write     Write     Write     Write       its day (Sat, Sun dimmed) │
│ Nothing logged this week yet.            [Catch up this week] [Go to today]    │
└────────────────────────────────────────────────────────────────────────────────┘
┌─ Review · Month ───────────────────────────────────────────────────────────────┐
│ [Week|Month|Year|Range]  ‹ ›                                   [Export ▾]      │
│ September 2026                    Logged 19 of 22 · 2 skipped · 1 not logged   │
│ [Last month] [This month]  [x] Skipped days  [ ] Jots   Group by (Day|Section) │
│ ▾ Finished                                                         12 items    │
│     Tue 29   Pricing table update shipped                                      │
│     Mon 28   Form fix merged                                  Show 10 more     │
│ ▸ What I did                                                       17 items    │
│ ▸ Other notes                                                       3 items    │
└────────────────────────────────────────────────────────────────────────────────┘
┌─ Review · Year ────────────────────────────────────────────────────────────────┐
│ 2026         Logged 141 of 196 · 9 skipped · 46 not logged · best streak 31    │
│ Month        Logged   Skipped   Not logged                                     │
│ September        19         2            1            a row opens that month   │
│ August           20         1            0                                     │
└────────────────────────────────────────────────────────────────────────────────┘
```
Export ▾: Copy as Rich text, Markdown, Plain text; Save as Markdown…; Save as PDF…; Share…. The button flashes "Copied ✓" for 2 s.

### 3.6 Search
```
┌─ Search ───────────────────────────────────────────────────────────────────────┐
│ Search: "pricing"                                   6 matches in 4 days        │
│ [All time ▾]  [All headings ▾]            Indexing 40%, results may be partial │
├────────────────────────────────────────────────────────────────────────────────┤
│ 2026 · October                                                                 │
│  Thu 1 Oct    What I did   …drafted the pricing page copy and…                 │
│               To do next   …review pricing page with Ana…                      │
│ 2026 · September                                                               │
│  Wed 23 Sep   Finished     …shipped pricing table update…                      │
│ 2 files could not be searched. [Show them]                                     │
└────────────────────────────────────────────────────────────────────────────────┘
```
Saved pages only (kept). Results group by year and month with sticky headers, 200 shown then "Show 200 more". ⌘G / ⇧⌘G move the hit, Return opens the day at the text, Esc clears. No match: "No matches for "pricing". Try a shorter word." (with a restricted scope: "…in this year." [Search all time]). The date menu and index state ship in M4; the heading menu is v0.3.

### 3.7 Jot panel [M2]
```
┌────────────────────────────────────────────────────────┐
│ Jot to Today                                      14:32│
│ call with Sam about pricing                            │
│ Return adds · ⇧Return new line · Esc cancels           │
└────────────────────────────────────────────────────────┘
```

### 3.8 Menu bar popover
```
┌──────────────────────────────────────────┐
│ Today · Fri 9 Oct                        │
│ ○ Not logged yet · Reminder 4:55 pm      │
│ ┌──────────────────────────────────────┐ │
│ │ Jot a line for today…              ↩ │ │
│ └──────────────────────────────────────┘ │
│ 5 unlogged days                [Catch up]│
│ No streak yet    S  S  M  T  W  T  F     │
│                  ·  ·  ○  ◐  ○  ○  ◉     │
├──────────────────────────────────────────┤
│ Open Gloamlog                         ⌘O │
│ Write Thu 8 Oct                          │
│ Copy this week's summary                 │
│ Jot…                                ⌃⌥J  │
│ Skip today…                              │
├──────────────────────────────────────────┤
│ Settings…                             ⌘, │
│ Quit Gloamlog                         ⌘Q │
└──────────────────────────────────────────┘
```
State lines (kept): "Logged today ✓", "Not logged yet", "Due now: 4:55 pm", "Skipped today (Holiday)", "Not a workday", "Saving problem: folder unavailable". The Catch up row hides at 0; "Write Thu 8 Oct" shows whenever the previous working day is unlogged; the field stays open after Return ("Added", 600 ms) so several jots go in a row; icons per state as v0.3.

### 3.9 Suggested from your work (strip, expanded) [M6]
```
┌─ Suggested from your work · Mon 5 Oct ─────────────────────────────────────┐
│ ▾ 4 items from Claude Code and Git        4 values hidden   [Insert all]   │
│   Add pricing table (acme-site 3f2a9c1)                         [Insert]   │
│   Docs pass (acme-site a81be07)                                 [Insert]   │
│   Worked in acme-site, 2h 55m over 3 sessions                   [Insert]   │
│   Prompt: "Add a pricing table to the landing page"             [Insert]   │
│ Lines go under [What I did ▾] as ordinary bullets you can edit.            │
└────────────────────────────────────────────────────────────────────────────┘
```

### 3.10 Settings window (toolbar tabs, left and right arrows move between panes; catalogue in section 4)
```
┌─ Settings ───────────────────────────────────────────────────────────────────────────┐
│ ● ● ●                                Reminders                                       │
│ General Reminders Page Appearance Storage Backup Shortcuts Sources Notif. Adv. About │
├──────────────────────────────────────────────────────────────────────────────────────┤
│   END OF DAY                                                                         │
│    Remind me at [4:55 pm]               Next reminder: Fri 9 Oct, 4:55 pm            │
│    On these days [M][T][W][T][F][ ][ ]   also used by Catch up and the streak        │
│    When it fires  (•) Strict   ( ) Gentle                                            │
│    Snooze for [15 min ▾]    [x] Remind on this Mac                                   │
│   UNLOGGED DAYS (Strict never applies to past days)                                  │
│    [x] Catch-up line on Today      [ ] Morning notification at [9:30 am]             │
└──────────────────────────────────────────────────────────────────────────────────────┘
```
If 11 tabs overflow, "Storage and sync" shortens to "Storage" [Verify]. The "Backup and restore" tab is labelled "Backup".

### 3.11 Onboarding: the two steps that change
```
┌─ Step 1 of 4 · Your logs (existing logs found) ──────────────────────┐
│ ( ) I'm new: start a fresh log                                       │
│ (•) I already have logs: use a folder I have                         │
│     Found ~/Gloamlog · 128 pages, 3 Jan to 5 Oct. Nothing is changed.│
│     Log starts [3 Jan ▾]   Days before it never count as unlogged.   │
│ [Skip setup]                                              [Continue] │
└──────────────────────────────────────────────────────────────────────┘
┌─ Step 4 of 4 · All set ──────────────────────────────────────────────┐
│ [ ] Open Gloamlog at login                                           │
│ Jot from any app    [ ⌃⌥J ]  [Try it]                                │
│ Fill in from your work: set up later in Settings.                    │
│ [Catch up on 5 days first]                  [Open Gloamlog]          │
└──────────────────────────────────────────────────────────────────────┘
```
Steps 2 and 3 are the v0.3 template/words and reminder screens with the changes in 2.7.

### 3.12 Empty and error states
| State | Where | Copy | Actions |
|---|---|---|---|
| No pages yet | Today, Recent | template + "Write about your day, or press / for commands"; "Pages you write appear here." | |
| Nothing unlogged | Catch up | "You're all caught up." "Every working day since 1 Sep has a page or a skip." | Go to today, Review this week |
| Empty period | Review | "Nothing logged this week yet." / "…in October yet." / "No pages in 2026 yet." | Catch up this week, Go to today |
| No match, partial | Search | "No matches for "pricing". Try a shorter word." / "2 files could not be searched." | Clear search, Show them |
| Folder missing, unwritable, save failed | notice (kept) | "Your log folder can't be found." / "Gloamlog can't save to this folder." / "Couldn't save this page." | Choose folder…, Try again, Create it again, Copy my text |
| Changed elsewhere, conflict copy | notice | "This page changed on another Mac while you were writing." / "1 conflict in ~/Gloamlog." | Keep mine, Take theirs, Keep both / Review… |
| iCloud not downloaded | notice, Settings | "5 days are still in iCloud." | Download all |
| Jot waiting, shortcut refused | panel, Settings | "Saved on this Mac. It will be added when your log folder is back." / "⌃⌥J is already used by another app." | Record another…, Off |
| Notifications off, login needs approval | Reminders, General | "Notifications are off for Gloamlog. Reminders can't reach you." / "Approve Gloamlog in System Settings > General > Login Items." | Open System Settings, Open Login Items |
| Date unreadable, future | Go to date | "Couldn't read that date. Try 2 Oct, last friday or 2026-10-02." / "That day hasn't happened yet." | |
| Sources | strip | "Turn on Sources to see what you worked on." / "No activity found for Mon 5 Oct." / "Gloamlog can't read this folder. Allow access in System Settings > Privacy & Security > Files & Folders." / "Claude Code's file format may have changed, so this list may be incomplete." | Turn on…, Open System Settings |
| Editor unavailable, raw text only | notice (kept) | v0.3 strings | Try again, Show in Finder |

## 4. Settings catalogue
A window of 11 panes (about 840 wide, toolbar tabs, window title follows the pane, last pane restored). Every change applies at once and persists; there is no Save button; helper text sits under the row; a row that cannot apply stays visible, disabled, with the reason. PRD's "Storage and Backups" = Storage and sync + Backup and restore. Tags show the milestone; untagged rows are M1. Each pane keeps to about 8 controls except Storage and sync (HIG: minimise settings, strong defaults; task options such as the Catch up scope live in their view).

**General**
| Control | Default | What it does |
|---|---|---|
| Open Gloamlog at login | Off | Starts it hidden so reminders and jots work after a restart; "Approve in System Settings > General > Login Items" when macOS asks |
| Show in menu bar / Show in Dock | On / On | Off Dock = menu bar only; disabled while the menu bar item is off |
| When Gloamlog opens | Today | Today · The page I was on |
| Week starts on | System | System · Monday · Sunday (Saturday Could): calendar, reviews, map |

**Reminders**
| Control | Default | What it does |
|---|---|---|
| Remind me at | 4:55 pm | End-of-day time; row "Next reminder: Fri 9 Oct, 4:55 pm" [M5a] |
| On these days | Mon to Fri | Working days: reminders, Catch up and the streak all use them; at least one; changing re-evaluates all history now |
| When it fires | Strict | Strict: forward once, re-open every 5 min until logged or skipped, 2 snoozes (needs the app running). Gentle: one notification, any number of snoozes |
| Snooze for | 15 min | 5, 10, 15, 20, 30 |
| Stop reminding after | 11:00 pm | 9 pm to midnight [Could] |
| Remind on this Mac | On | Per Mac; with the app quit it still arrives [M5a]; warning when notifications are off |
| Catch-up line on Today | On | One dismissible line a day while days are unlogged [M1] |
| Morning notification | Off | One notification at 9:30 am (time is adjustable) on working days, only when Catch up is not empty [M5a] |

**Page**
| Control | Default | What it does |
|---|---|---|
| A day counts as logged after | 20 words | 1 to 500; headings, empty markers, images do not count (kept) |
| Log start date | first page, then fixed | Days before it are never unlogged; [Move earlier…] [Start fresh from today] |
| Catch-up window | 30 days | 14, 30, 60, 90 or since the log start; the scope control in Catch up overrides it for that view |
| Jots count toward logging a day | Off | On = jot text counts as words [M2] |
| Jots heading, time stamp, "[] makes a to-do" | Jots, 24-hour, On | The heading jots go under; `14:32` stamp or none [M2] |
| New day template | Daily review | Markdown editor; Start from… Daily review, Standup, Blank; Reset (kept) |
| Carry over headings | To do next, Pending / blocked | Feed From yesterday; Show the strip: On (kept) |
| Insert Sources under | first template heading | Target heading of Insert [M6] |
| Check spelling while typing | On | The page's spell checker |

**Appearance**
| Control | Default | What it does |
|---|---|---|
| Theme | System | System · Light · Dark. Reduce Motion, Increase Contrast and Reduce Transparency follow macOS (no controls) |
| Accent | Gloamlog green | Gloamlog green · System accent |
| Show streak | On | Off hides the footer streak and the Today chip; Catch up stays |
| Page font, Text size, Page width | System, 16 pt, 720 pt | System · Serif · Mono; 14 to 20; 600, 720, 900, Full [Contract, Could] |

**Storage and sync**
| Control | Default | What it does |
|---|---|---|
| Log folder | ~/Gloamlog | Path, Choose folder…, Show in Finder, Use default; copy, move, use-existing dialogs (kept); "128 logs · 3 skipped days" |
| Search index [M4] | status | "Indexed 1,302 pages"; [Rebuild search index] |
| Sync across Macs [M5b] | status | [Set up sync…] [Join from another Mac…]; Synced / Syncing / "2 to review"; rows "1 conflict" [Review…] and "5 days are still in iCloud" [Download all]; "Gloamlog doesn't run sync. Your folder provider moves the files." |
| Share settings through the folder [M5b] | On | Writes the small hidden settings file; per-Mac items are listed |

**Backup and restore**
| Control | Default | What it does |
|---|---|---|
| Keep safety copies / Copies per day | On / 10 | Before every overwrite, outside the log folder so they never sync; 5, 10, 20, 50 |
| Location | ~/Library/Application Support/Gloamlog/backups | Show in Finder; Restore previous version… for the open page (kept) |
| Back up now… | button | Copies pages and `assets/` to a place you choose; "Last backup: 2 days ago" |
| Restore from backup… | button | Always into a new folder, never over the current one |
| Recover a deleted day… / Import logs… [Could] | button | Days with safety copies but no page / merge dated `.md` from a folder, never overwriting a day |

**Shortcuts**
| Control | Default | What it does |
|---|---|---|
| Jot from anywhere | ⌃⌥J | Record, or Off; "Already used by another app" when taken [M2] |
| Keyboard reference | table | Read-only list of 5.1 |

**Sources** [M6; tab hidden before]
| Control | Default | What it does |
|---|---|---|
| Fill in my log from my work | Off | Master; consent sheet on first turn-on |
| Claude Code | Off | Folder `~/.claude` (detected); projects table Include or Hide, none included until ticked; "Hidden projects are skipped before any text is read." |
| Git | Off | Scan folder (default ~/Projects), repositories ticked one by one; only commits by your identity |
| Show first line of my prompts | On | Local display only |
| Include branch names, Insert time spent | Off, Off | Adds the branch to the evidence, "(2h 55m)" to lines |
| Keep a daily summary | On | Counts and labels only, so history outlives Claude Code's 30-day clean-up |
| Clear Sources data | button | Deletes summaries, never pages. Redaction is locked on. Status "Last scan 2 s ago · 41 files · 0 skipped" |

**Notifications**
| Control | Default | What it does |
|---|---|---|
| Permission | status | Allow, or Open System Settings when denied (kept) |
| Play a sound | On | The default notification sound, once per notification |
| Dock badge, Menu bar count | Off, Off | Number of days to catch up |
| Notify me about sync conflicts | On | [M5b] |
| Send a test notification | button | "Nothing fires while the Mac sleeps; a Focus can silence it." Notifications never hold page text or the streak |

**Advanced**: Run setup again… (pages and settings untouched) · Rescan folder · Open log folder, safety copies, settings file · Copy diagnostics (version, macOS, counts, folder type; no page text) · Reset settings… (confirms; pages never touched).
**About**: icon, name, version and build, "No network requests, no account, no telemetry.", MIT licence, third-party licences, What's new, Report an issue (opens the browser only when clicked).

**Discoverability rules**
1. ⌘, and the app menu "Settings…" open the window; so does the gear in the sidebar footer (always visible, tooltip "Settings (⌘,)"), the page ⋯ menu, the menu bar popover and the Dock menu. All go through one `openSettings(pane:)`.
2. If the system Settings scene does not appear within 300 ms (the PRD doubts it opens on the owner's macOS: `showSettingsWindow:` is macOS 14, macOS 13 uses `showPreferencesWindow:`), open a plain `Window("Settings", id: "settings")` with the same panes [Verify]. It must open in front in under a second (M1-A6).
3. Every notice that names a setting ends in a link to its pane: reminder notice "Change reminder" (Reminders), folder notices "Choose folder…" (Storage and sync), notifications off (Notifications), empty Catch up "Log start date…" (Page), empty Sources strip (Sources).
4. The last pane is remembered. Onboarding's last line and What's new point to Settings. [Could] a search field in Settings that selects the pane and highlights the control.

## 5. Keyboard, copy, accessibility, acceptance

### 5.1 Keyboard map
Every shortcut is a menu item. Changes from v0.3: ⌘2 was This week; ⌘[ ⌘] step calendar days; new rows marked *.
| Menu | Items |
|---|---|
| Gloamlog | Settings… ⌘, |
| File | Save Now ⌘S · Export… ⇧⌘E (opens the Export menu) * · Copy as Markdown ⇧⌘C · Open Log Folder ⇧⌘O |
| Edit | Search Logs ⌘F · Next / Previous Result ⌘G / ⇧⌘G |
| Go * | Today ⌘T and ⌘1 · Catch Up ⌘2 · Week, Month, Year ⌘3, ⌘4, ⌘5 · Previous / Next Day ⌘[ ⌘] · Go to Date… ⇧⌘T · Next Unlogged Day ⌘↩ (fallback ⌥⌘↓), Previous ⌥⌘↑ |
| Page | Focus Page ⌘E · Carry Over ⇧⌘Y · Skip Day… ⇧⌘K · Remind Me Later ⇧⌘L · Jot… ⌃⌥J * (shows the recorded hotkey; none when Off) · Restore Previous Version… · Settings… |
| View | Show / Hide Sidebar ⌃⌘S |
Calendar (one tab stop, also in Go to date): ←→ move 1 day, ↑↓ 7 days, Home/End week start/end, PageUp/PageDown month, ⌥PageUp/⌥PageDown year, Return opens, T today, ⇧ or drag selects. Catch up: ↑↓ move, Return primary, S or Delete skip, ⌘A all, Esc clears the selection or ends the session. Jot panel: Return adds, ⇧Return line break, Esc cancels. Settings: ←→ change pane.

### 5.2 Key copy strings
Voice: plain, calm, second person, sentence case, verbs on buttons, no exclamation marks, no emoji, no blame; a notification never gives an order. Examples are en-US.
| Where | String |
|---|---|
| Catch up | "You have 5 unlogged days." / "You have 1 unlogged day." / "You're all caught up." |
| Today line | "You haven't logged Thu 8 Oct." [Write it] [Skip day] · "You have 5 unlogged days." [Catch up] [Later] |
| Rows, session | "11 of 20 words" · "1 jot, not tidied" · [Write] [Continue] [Tidy up] Skip · "Catching up 3 of 5 · Wed 7 Oct" · [Next unlogged day] · "All caught up. 3 logged, 1 skipped." |
| Skip | "Skip these 3 days?" / "No reminders, and your streak stays as it is. You can undo this any time." / [Skip 3 days] [Cancel] · "Skipped 3 days as Leave." Undo |
| Word line, past label | "12 words. Counts as logged at 20." · "Logged, 63 words" · "2 days ago" · "Before your log start. It won't appear in Catch up." |
| Notifications | "Today isn't logged yet" / "It's 4:55 pm. Open Gloamlog when you're ready." [Open] [Snooze 15 min] [Skip today] · "You have 5 unlogged days" / "Catch up when you have a few minutes." [Catch up] [Tomorrow] |
| Jot | "Jot to Today" · "Jot a line for today…" · "Added to Today" · "1 jot, not tidied" · "1 jot waiting" |
| Review | "Week of 5 to 11 Oct 2026" · "Logged 4 of 5 · 1 skipped · 2 not logged" · "Skipped · Leave" · [Catch up this week] · "Copied ✓" |
| Sources, onboarding | "Let Gloamlog read your Claude Code and Git activity?" / "Read-only. It stays on this Mac. Hidden projects are skipped before any text is read." [Choose projects…] [Turn on] [Not now] · "We found 128 logs in ~/Gloamlog" · "Catch up on 5 days first" · "Everything here is in Settings (⌘,)." |

### 5.3 Accessibility requirements (WCAG 2.2 AA; PRD XC-4)
- Status is shape plus text, never colour alone, in the calendar, Recent, rows, tiles, map and popover strip. Marks reach 3:1 (v0.3's unlogged outline measures 1.69:1); text 4.5:1 in light and dark; Increase Contrast adds 1 pt borders.
- Calendar: container "Calendar, October 2026"; cells are buttons "Friday 2 October, started, 11 of 20 words" / "…, not logged" / "…, skipped, Leave" / "…, today"; rotor "Days to catch up"; cells at least 28 x 30; Go to date 36 x 32.
- Catch up: each row one element "Monday 5 October, not logged, 3 Claude sessions"; Write and Skip are separate stops; progress announces politely ("Tuesday 6 October logged. 3 unlogged days left."). Session bar: a group "Catching up, 3 of 5"; [Next unlogged day] states the date it opens.
- Jot panel: label "Jot to Today", field focused on open, result announced; the popover field is the VoiceOver and keyboard route when the global shortcut is off [Verify with a non-activating panel].
- Reviews: title is a heading, weeks and sections subheadings; "Copied" and "Saved" announced. Settings: native controls, helper text as hints, tabs reachable by arrows, recorder says "Press the new shortcut. Escape cancels."
- Focus and keys: a visible focus ring on every control, custom calendar cells, tiles and rows included (never removed); sheets focus the first control and return focus on dismiss; every button, tile, cell and row is in Full Keyboard Access order; no hover-only controls; Tab visits text fields only when Full Keyboard Access is off.
- Motion and transparency: Reduce Motion removes slides, bounce and the Dock bounce (opacity change at most 100 ms); Reduce Transparency makes the sidebar flat. Targets: rows 28 pt or more, buttons 24 pt tall, 28 pt hit.
- Text size up to 20 pt must not clip sidebar rows (truncate tail, tooltip carries the full text).

### 5.4 Acceptance checks (Given / When / Then; IDs in brackets are PRD checks they refine)
Navigation
- **N1** Given Fri 2 Oct is a workday with no page, when I click it in the calendar, then an empty page opens with my template and no file exists; 2 s after I type a line `2026-10-02.md` exists. (M1-A1)
- **N2** Given Thu 8 has no page and today is Fri 9, when I press ⌘[, then Thu 8 opens; ⌘] returns; ⌘] on today does nothing. (M1-A2)
- **N3** When I press ⇧⌘T and type "last fri", then the resolved date shows and Return opens it; "banana" shows the unreadable-date copy and opens nothing; "-3" opens three days ago.
- **N4** Given the window is 600 pt high, then the calendar is a one-week strip and Go to date still reaches any day; with future pages off, a future cell opens nothing and its tooltip says "Upcoming".
- **N5** Given my log starts on 1 Oct, when I open 12 Sep and type, then it saves, Catch up and the streak do not change, and the footnote shows. (M1-A9)

Catch up
- **C1** Given 5 unlogged days, when I open Catch up (⌘2), then 5 rows show oldest first, the badge reads 5 and Today says "You have 5 unlogged days." (M1-A3)
- **C2** When I press Start catching up, then the oldest day opens with the session bar; at the minimum the line reads "Logged, 24 words", the badge drops within 2 s, and [Next unlogged day] opens the next one.
- **C3** When none remain, then the page area says "All caught up. 3 logged, 1 skipped." with Review this week and Go to today.
- **C4** Given 3 selected rows, when I Skip… with reason Leave, then 3 markers exist, the badge drops by 3, the streak is unchanged and Undo restores them. (M1-A4)
- **C5** Given a day with only jots, then its row reads "1 jot, not tidied", the day shows ◐ and counts as unlogged; given a logged past page I empty, then it returns to Catch up and the streak gap returns.
- **C6** Given a past week with nothing, when I open it in Review, then every working day is a tile that opens, and the empty state offers Catch up this week. (M1-A5)

Reviews and export
- **RV1** Month shows counts, sections in template order with dated items, "Other notes" last; Finished opens expanded. (M3-A2)
- **RV2** Year shows 12 rows within 2 s for 250 pages; a row opens that month. (M3-A3)
- **RV3** Rich text pastes formatted into Notes and Mail; Plain text has no `##` or `**`; Markdown pastes as headings and bullets. (M3-A4)
- **RV4** Save as Markdown gives one `.md` and an `assets/` folder with only the images used; PDF text is selectable. (M3-A5)
- **RV5** Unticking "Skipped days" changes the review and every copy and export (M3-A7); menu bar "Copy this week's summary" copies without opening the window.

Jot
- **J1** Given Today is open and I am mid-sentence, when I press ⌃⌥J in another app, type "call Ana" and press Return, then `- 14:32 call Ana` ends the page under `## Jots`; my text, caret and undo are untouched; the file has it within 2 s. (M2-A2, A3)
- **J2** Given today has no page, when I jot with the window closed, then only the Jots section is written; opening the day shows the template above it and the day reads "started". (M2-A4)
- **J3** Given 30 words of jots, then the day is still "0 words…", unlogged, and the reminder still fires.
- **J4** Given the folder is unavailable, then the panel says "Saved on this Mac…" and the line is added once, after the folder returns. (M2-A6)
- **J5** Given another app owns my chosen combination, then Settings refuses it. Esc closes the panel, writes nothing and returns focus. (M2-A1, A7)

Reminders
- **RM1** Strict at 4:55 pm with another app in front: one notification, the window forward once; if I close it, no re-open for 5 min and no keystroke is stolen; the third re-open adds "Not today? Skip day."
- **RM2** Strict while I type in a session or a page: the notice appears there, nothing navigates, my text does not move. Gentle: one notification, no window movement all evening.
- **RM3** Given 3 unlogged days and the morning notification on, then one notification at 9:30 on a working day, none if I opened Catch up first, and after 3 ignored nudges the next comes on Monday.
- **RM4** Given Gloamlog is quit and the reminder is 2 min away, a notification arrives and opens today's page; none arrives if today was logged or skipped. (M5-A1, A2) [Verify]
- **RM5** Settings > Reminders shows "Next reminder: <date, time>" and updates after I change the time. (M5-A3)

Onboarding, sync, Sources, Settings
- **O1** New user: accept defaults with Continue and Open Gloamlog and land on Today with the template; macOS asks for notification permission once, after the reason.
- **O2** Given a folder with 128 logs, step 1 offers it first and writes nothing; a v0.3 user sees one What's new sheet, then Today with the catch-up line.
- **S1** Given `2026-10-05 2.md`, then "1 conflict" shows; Merge both appends only new lines under a labelled heading and moves the file to safety copies. (M5-A7)
- **S2** Given an open page with my edits that changed elsewhere, then autosave pauses and I choose Keep mine, Take theirs or Keep both; nothing is overwritten silently. (M5-A6)
- **S3** Given iCloud placeholders, then "N days are still in iCloud. [Download all]" shows and those days are not treated as missing. (M5-A9)
- **X1** With Sources off, nothing outside the log folder is read. A hidden project never appears; Insert adds ordinary bullets with evidence; again adds none; a fake key shows redacted. (M6-A1, A4, A5)
- **T1** From the main window, click the Settings gear (not ⌘,): it opens in front in under 1 s; the same from ⌘, and the popover. (M1-A6)
- **T2** Change reminder time, style, theme and week start, quit and relaunch: all persist; badge, calendar and streak follow a working-days change without a restart. (M1-A7)

Accessibility
- **A1** VoiceOver on the calendar reads "Friday 2 October, started, 11 of 20 words"; the "Days to catch up" rotor jumps between ○ and ◐ cells.
- **A2** With the mouse unplugged I can reach Catch up, select rows, Skip, Start, Next unlogged day, Settings and the jot panel.
- **A3** With Reduce Motion, Increase Contrast and dark mode on, every status is still told apart by shape and text.

### 5.5 Build notes and open questions
- [Core] log start date stored and used by `Status.resolve` and `Streak.compute`; catch-up window setting; leading time stamp ignored by the word count; Jots section excluded by heading; day-end offset (Could).
- [Contract] `appendToSection`; a page that holds only Jots loads with the template above it; text size, font and width variables (Could).
- [Verify] Carbon hot key and non-activating panel over full-screen apps; `UNCalendarNotificationTrigger` with a quit, ad-hoc-signed app; Settings scene on macOS 13; ⌘↩ through the web view; `NSDataDetector` phrases ("last fri"). No `.inspector` (macOS 14), no macros.
- Open for the owner: Strict or Gentle as the first-run default (audit D7 says Gentle; v0.3 and the product premise say Strict); a "My day ends at" setting (audit G8 suggests 3:00 am; TRD keeps the key `dayStartsAtHour` hidden, default 0); whether a jots-only day should count (PRD Q1 says no); future-day pages (PRD says no).

## 6. Reconciliation
- **PRD_V1.md**: same scope, milestones and defaults (30-day window, Jots, ⌃⌥J, Section grouping, jots off, skipped days one line), Suggested-from-your-work strip, Keep mine / Take theirs / Keep both, Merge both, Download all. Differences: the UI says "unlogged" (PRD "missed" and "unwritten", DESIGN_V4 "not written"); the session button is "Next unlogged day"; future pages sit behind a hidden flag; the optional morning notification and Mondays back-off (M5a, Should, off by default); notification copy is informational (HIG); the log start date is stored, not derived; Settings opens through `openSettings(pane:)` with a plain-window fallback.
- **UX_AUDIT_AND_BENCHMARKS.md**: adopted: a calendar that creates (A1), Go to date with `-3` (A2), a forgiving, repairable streak shown in the footer plus a Today chip (A5, D3), no quota framing (D8), Settings as a footer item plus contextual links (A7, X4), reserved notice space (D7), safe-sync handling (X6). Not adopted, with reasons: a "written later" mark (S4; plain files carry no reliable timestamp and it would shame backfill, so the relative label is the only cue); a scratch "Write the week" page (a second writer); a streak-at-risk warning (UX_SPEC 5.3 and DESIGN_V4 principle 2 forbid streak-loss copy); six panes (the brief asks for 11, each kept to about 8 controls); Gentle as the default (left to the owner, 5.5); a "Notes" heading (PRD says Jots).
- **TRD.md** (settings keys): defaults agree (jots off, Jots heading, 24-hour stamp, ⌃⌥J, 30-day window, morning notification off, sound on, review view state remembered rather than a setting, `allowFutureDays` and `dayStartsAtHour` hidden).
- **DESIGN_V4.md** should follow this file on: one Review row plus the calendar, Recent = 7 newest pages; list and session both oldest first; per-row Skip and ⇧/⌘-click selection (no checkboxes); the session bar text; "Logged, N words"; the vocabulary above; the Export ▾ items and the two checkboxes; onboarding order; sync copy ("From other copy"); the Go menu and Dock menu. It already matches on the footer gear, toolbar order, ⌘T / ⇧⌘T, 11 toolbar tabs, jot panel keys and the conflict view.
