# Gloamlog design v4: any date, one app

Extends `docs/DESIGN_SYSTEM.md` (all its tokens and rules still apply, nothing is renamed) for the product in `docs/v1/PRD_V1.md`; tags M1 to M6 are the PRD's milestones, D-numbers are defects in `docs/v1/UX_AUDIT_AND_BENCHMARKS.md`. Behaviour and flows are in `docs/v1/UX_FLOWS.md`: where the two differ, flows win on behaviour and this file on pixels and tokens.

**Status.** Nothing here is built or seen on screen. Inputs: the v0.3 renders (`shots-v03/`) and sources. New colour pairs were computed with the antislop contrast tool. API availability was compile-checked with `swiftc -typecheck -target arm64-apple-macos13.0`; SF Symbol names against CoreGlyphs `name_availability.plist` (all introduced by macOS 13.0). `[verify]` marks an assumption to test on a running build.

**Why v0.3 failed the owner** ("why am i not able to add anything for previous days or weeks ... no settings options ... not even ready for me to use"). In the code: the sidebar lists only days that already have a file (`AppModel.historyDays`), so a day without a file cannot be opened; there is no calendar, date entry or toolbar; Settings is 3 tabs with no visible entry; the only review is one week and hides empty days; search is a single field.

## 0. Principles (adds to DESIGN_SYSTEM section 1)
1. **Any date, no file needed.** Calendar, Go to date, Catch up and the week tiles open a page for a day with no file. A file is still written only after a real edit (EDITOR_CONTRACT).
2. **Missing is a state, not a scolding.** Amber marks only past scheduled days with no page; one click writes or skips them. No red for missing, no streak-loss copy.
3. **Native first.** Unified toolbar, sidebar material, `Form(.grouped)`, Settings toolbar tabs, system popovers, sheets and menus. Custom only: calendar grid, catch-up rows, week tiles, review cards, Jot panel.
4. **One green accent** for selection, logged and the primary action; amber = needs a page; red = failed. v4 adds zero colours.
5. **One mark vocabulary** everywhere (sidebar calendar, popover, week tiles, catch-up rows, heatmap, menu-bar strip): filled disc logged, half disc started, hollow ring not written, dash skipped. Shape carries the meaning, hue only helps.
6. **Honest numbers.** Every count and mark is computed from files. No deltas, no "vs last month", no sample data.

## 1. Navigation model (M1)

Two columns (`NavigationSplitView`), unified toolbar, no third pane. Window 1000x760 default, 860x600 minimum; sidebar 220 / 240 / 280; 720 reading column (all unchanged).

```
+-------------------------------------------------------------------------------------------------+
| (o)(o)(o) [|=]  [<][Today][>] [cal]                                            [share v] [jot]  |
+--------------------------+----------------------------------------------------------------------+
| [Q Search your logs     ]|  notices and banners (at most 2, 720 column)                         |
|  o  Today                |  Tuesday, 6 October                                             ...  |
|  !  Catch up          3  |  [12 day streak]  8 words. Counts as logged at 20.            Saved  |
|  =  Review               |  ------------------------------------------------------------------  |
|                          |  > From yesterday  Mon 5 Oct . 4 items                 [Carry over]  |
|  October 2026 v    <  >  |                                                                      |
|  (calendar, section 3)   |  What I did                                                          |
|                          |  Write about your day, or press / for commands                       |
|  Recent                  |                                                                      |
|   v  Mon 5 Oct           |                                                                      |
|   v  Thu 1 Oct           |                                                                      |
|                          |                                                                      |
|--------------------------|                                                                      |
| 12 day streak  Synced [g]|                                                                      |
+--------------------------+----------------------------------------------------------------------+
```

| Sidebar block | Spec |
|---|---|
| Search | 28 high, margin 12 h / 8 v, `radiusMd`, `surface` + `border` (existing `SearchField`). |
| Rows | **Today**, **Catch up**, **Review**: 30 high, glyph 16, gap 8, padding-h 10, 1 apart (existing `SidebarRow`). Glyphs `calendar.badge.exclamationmark` and `doc.richtext`. Review opens at the last scale used. |
| Count badge | On Catch up: 18 high, min width 18, padding-h 6, capsule, `warningTint` fill, 11/600 `warning` mono digits. Counts unwritten scheduled days in the catch-up window (default last 30; not written and started; today excluded). Hidden at 0, "99+" cap, tooltip "3 days need a page". The only number in the sidebar that asks for action. |
| Calendar | 12 below the rows, 242 high (section 3). Under 640 window height it becomes a one-week strip, 82 high. |
| Recent | Header 28 (12/600 `textSecondary`), the 7 newest days with a page (not today), rows 28 high, scrolls. Replaces the v0.3 month groups: calendar, Year review and search now cover older browsing [decision, reversible]. |
| Footer | 40 high, 1pt top `border`, padding-h 12. Streak left (13/600; click opens the existing 12-week popover). Sync chip (section 9; click opens Settings, Storage and sync; icon only under 240 wide; absent when there is nothing to say). **Gear** right: `gearshape` 14, 28x28 hit, tooltip "Settings (⌘,)", the main window's visible Settings entry (PRD SET-1). It lives here and not in the toolbar because the HIG advises against a Settings button in a window toolbar. |

**Sidebar material.** v0.3 paints a flat fill that hides the system material. v4 removes it and lays `Theme.sidebar` at 80% over the split view's own material, so the sidebar reads native while contrast stays bounded. At an assumed worst-case backdrop (#D0D2D0 light, #3C3F3D dark) the wash resolves to #EAECEA / #191C1B. Without the wash `textSecondary` is 4.30 and `textTertiary` 3.53 in light (both fail). Rule: sidebar text is `textPrimary` or `textSecondary`, never `textTertiary`. Reduce Transparency: wash 1.0 (flat token). Increase Contrast: `border` becomes `borderStrong`. [verify over black, white and saturated wallpapers]

**Day page** keeps the 32/600 title, From yesterday strip, editor and `...` menu (which gains `Settings...` at its end). Changes: past days show a relative label before the word count ("6 days ago", 13/400 `textSecondary`); the streak chip shows on Today only (audit D13, it was on every page); quieter meta copy, "8 words. Counts as logged at 20." instead of "8 / 20 words to log today" (audit D8, quota framing), "Logged, 63 words" once logged; on Today the quiet Catch up notice (section 4) may show. A jots-only day reads "Started", never "Logged" (PRD Q1 default).

| Toolbar (`.windowToolbarStyle(.unified(showsTitle: false))`) | Leading | Principal | Trailing |
|---|---|---|---|
| Day | `<` `Today` `>` = previous / today / next calendar day (⌘[ ⌘T ⌘]; `Today` and next disabled on today), Go to date (`calendar`, ⇧⌘T) | none | Share menu (`square.and.arrow.up`: Copy as Markdown, Plain text, Rich text, Show in Finder; Share... M3), Jot (`square.and.pencil`, M2) |
| Review | `<` `>` previous / next period | segmented Week, Month, Year, Range (260 wide) | Export menu (section 5) |

Catch up and Search add no toolbar items. Every item has `.help`, an accessibility label and a menu command (HIG). Settings opens from the footer gear, ⌘, and the app menu, the page `...` menu, the menu-bar popover, the Dock menu, and chip and banner links, all through one `openSettings(pane:)`.

| Menu | Items (shortcut) |
|---|---|
| Gloamlog | About; **Settings... ⌘,**; Quit |
| File | Save Now ⌘S; Export... ⇧⌘E; Copy as Markdown ⇧⌘C (acts on the open screen); Open Log Folder ⇧⌘O |
| Edit | Search Logs ⌘F; Next / Previous Result ⌘G / ⇧⌘G (existing) |
| Go (new) | Today ⌘T and ⌘1; Catch Up ⌘2; Week ⌘3; Month ⌘4; Year ⌘5; Previous / Next Day ⌘[ ⌘]; Go to Date... ⇧⌘T |
| Page (was Log) | Focus Page ⌘E; Carry Over ⇧⌘Y; Skip Day... ⇧⌘K; Remind Me Later ⇧⌘L; Jot... ⌃⌥J (M2; shows the recorded hotkey, none when Off); Restore Previous Version...; Settings... |
| View | Show / Hide Sidebar (`SidebarCommands`) |
| Dock menu | Today, Jot, Catch Up, Settings... |

| Window state | Behaviour |
|---|---|
| 1000x760 default | detail 760, so the reading column is 664 (it reaches 720 only from 1056 wide); week tiles 88 wide; month grid in the sidebar; Recent shows about 8 rows |
| 860x600 minimum | detail 640, column 544; tiles 71; calendar becomes the week strip (window under 640 high); Recent about 8 rows; no toolbar item hides |
| Sidebar hidden (⌃⌘S) | detail takes the width, column stays centred, 720 at most; nothing else changes |
| Large or full screen | column stays 720 and centred; nothing stretches |

State model: `Destination` becomes `.day(String)`, `.catchUp(CatchScope)`, `.session(CatchSession)`, `.review(ReviewScale, Date)`, `.search`; add `model.settingsPane`. Core: a log start date replaces `states.keys.min()` as `since` in `Status.resolve` (PRD CUP-3); ⌘[ and ⌘] step calendar days, not days with files.

## 2. Tokens: deltas only

```swift
// Theme additions: sizes and one alpha. No new colours.
static let sidebarWash = 0.80                                   // 1.0 under Reduce Transparency
static let calMin: CGFloat = 28, calMax: CGFloat = 34, calH: CGFloat = 30, calGap: CGFloat = 2, calMark: CGFloat = 6
static let popCellW: CGFloat = 36, popCellH: CGFloat = 32, weekTileW: CGFloat = 96 /* max; tiles are (column - 48) / 7, min 64 */, weekTileH: CGFloat = 64
static let catchRowH: CGFloat = 44, sessionBarH: CGFloat = 44, badgeH: CGFloat = 18, hitRowMin: CGFloat = 40
static let jotW: CGFloat = 520, settingsW: CGFloat = 840, settingsCol: CGFloat = 640
static let panelIn = Animation.easeOut(duration: 0.12), panelOut = Animation.easeIn(duration: 0.08), cross = Animation.easeInOut(duration: 0.14)
```

Type: screen title (Catch up, Review, Search) 28/600, tracking -0.4, as `WeeklyReviewView` and `SearchView` already draw it; the day title stays 32/600. Calendar number 12/400 mono digits (600 for today and selected). Everything else reuses DESIGN_SYSTEM section 3. Layouts are identical in light and dark; only tokens differ. In dark, `sidebar` is darker than `bg`, so strips (session bar, notices, From yesterday) read as insets, as in the v0.3 dark renders, and surfaces get lighter as they rise (`bg` #141716, `surface` #1C201E, `hover` #252B28):

| New surface | Light | Dark |
|---|---|---|
| Selected day: fill / number | `accent` #0E7A5F / #FFFFFF | #45C29C / #06241C |
| Day in a range | `accentTint` #DDF0E8 | #1B3A31 |
| Marks: logged / started / not written / skipped | #0E7A5F / #566059 / #9A5B00 / #636D67 | #45C29C / #A3ADA7 / #E0A23A / #8A948E |
| Count badge: fill / text | #FBF0DC / #9A5B00 | #3A2E14 / #E0A23A |
| Session bar, notices, From yesterday strip | `sidebar` #F0F2F0 | #101312 |
| Jot panel: fill / edge / shadow | #FFFFFF / `border` / `0 8 24 rgba(20,30,26,0.14)` | #1C201E / `borderStrong` / `0 8 24 rgba(0,0,0,0.5)` |
| Changed line in conflict view | `warningTint` #FBF0DC | #3A2E14 |

| New pair (computed) | Light | Dark |
|---|---|---|
| `onAccent` on `accent` (selected day, primary button) | 5.29 | 7.40 |
| `warning` on `warningTint` (badge, conflict text) | 4.81 | 5.95 |
| `warning` on `sidebar` flat / on `hover` / on `accentTint` / on `surface` | 4.82 / 4.59 / 4.57 / 5.43 | 8.36 / 6.46 / 5.54 / 7.37 |
| Sidebar worst case with wash (#EAECEA / #191C1B): `textSecondary`, `textTertiary`, `accent` mark (needs 3) | 5.50, 4.52, 4.46 | 7.43, 5.48, 7.73 |
| Same backdrops without wash (#D0D2D0 / #3C3F3D): `textSecondary`, `textTertiary` | 4.30 fail, 3.53 fail | 4.61, not computed |
| `textSecondary` on assumed grouped-form backdrop (#ECECEC / #323232) | 5.53 | 5.55 |

Reused as already documented: `textPrimary` on `accentTint` 13.92 / 10.39 (range days, selected rows), on `warningTint` 14.62 / 11.14, `textTertiary` on `surface` 5.37 / 5.26. Never `textTertiary` on `accentTint` in dark (3.95). Marks need 3:1, all pass.

## 3. Calendar and Go to date (M1)

`CalendarGrid(month, size, selection, range)` reads `model.states` and `status(of:)`, no disk. Always 6 rows, so height never jumps. Weekday labels follow `cal.firstWeekday` (Settings, General: System, Mon or Sun).

```
  September 2026 v         <  >     key   *  logged    (  started    o  not written    -  skipped
    M   T   W   T   F   S   S          [6] today ring     {6} selected     shaded = in a range
   21  22  23  24  25  26  27
    o   *   *   -   (
   28  29  30
    *   (   *
```

| Part | Sidebar | Go to date popover (⇧⌘T) |
|---|---|---|
| Width | sidebar width - 24 | 280, padding 12 |
| Header 28 | title button 13/600 + `chevron.down` 9 (opens a 232 wide, about 164 high picker: 4x3 months, cells 64x32, year `<` `>`); `<` `>` 24x24 hit, 11/600 `textSecondary` | same |
| Weekday row 16 | 11/400 `textSecondary` | same |
| Cell | w = clamp(floor(width / 7), 28, 34), h 30, gap 2; number 12 at y 11, mark 6 at y 23 | 36x32, gap 2 |
| Extra | none; total 242 with 8 bottom padding | typed-date field 28 above, feedback line 16 below, about 330 high |

| Cell state | Number | Fill | Mark (6, shape first) |
|---|---|---|---|
| Logged | `textPrimary` | none | filled disc `accent` |
| Started (some words, or jots only) | `textPrimary` | none | `circle.lefthalf.filled` `textSecondary` |
| Not written (past scheduled day, on or after the log start date) | `textPrimary` | none | hollow ring 1.25 `warning` |
| Skipped | `textPrimary` | none | dash 7x1.5 `textTertiary` |
| Off day or before the log start date, no page | `textSecondary` | none | none (a page shows its own mark) |
| Today | 600 | none | 1.5 `accent` ring, inset 1, `radiusMd`; never the amber ring |
| Hover | | `hover`, 80ms | tooltip "Wed 30 Sep: not written" |
| Selected (page open) | `onAccent` 600 | `accent` | mark redrawn in `onAccent` |
| In a range | `textPrimary` | `accentTint` | unchanged |
| Future | `textTertiary` | none | none; inert, tooltip "Upcoming" (future pages are out of scope) |
| Keyboard focus | | | custom ring: 1.5 `accent` inside, `focusRing` 3 outside |

- The 12-week heatmap and the menu-bar strip adopt the same marks: not written = `warning` ring (was a `borderStrong` outline, 1.69:1), started = half disc (was a heat-2 fill, 1.91:1); both failed 3:1 (audit D19).
- Click opens the day, any past date, file or not. Shift-click or drag (4pt threshold) selects a range; ⌘-click toggles one day. Two or more days open Catch up scoped to them (chip "Selected days").
- Context menu: Open, Skip day..., Catch up from here (a session starting at that day), Show in Finder and Copy as Markdown (page exists only).
- The grid is one tab stop. Arrows move 1 or 7 days, Home / End the week start / end, Page Up / Down the month, Option-Page Up / Down the year, Return opens, T goes to today. Review screens shade their period in the grid (Week: that row).
- Go to date: a text field takes "last friday", "3 oct" or "2026-09-30" (`NSDataDetector`, local, no network); the grid sits below; Return opens; feedback line reads "Fri 2 Oct 2026", "Couldn't read that date" or "That day hasn't happened yet."

## 4. Catch up (M1)

Catch up = scheduled days in the window (default last 30, set in Settings, Page) that are not written or only started; skipped days and today are excluded. Same list feeds the badge, the screen and the session. The segmented control changes this view only; Settings, Page sets the default window.

```
Catch up                                                              [Next missed day]
4 days need a page.  ( Last 14 | Last 30 | Since log start )          [Skip... v]
Week of 28 Sep                                                         0 of 2 written
 o  Fri 2 Oct     Not started                                          [Write]  Skip
 (  Tue 29 Sep    Started, 8 of 20 words                               [Write]  Skip
Week of 21 Sep                                                         0 of 2 written
 (  Fri 25 Sep    Started, 12 of 20 words                              [Write]  Skip
 o  Mon 21 Sep    Not started                                          [Write]  Skip
Older: 3 more days                                                       Show
Days before 1 Sep (your log start) never count. Change in Settings.
```

- Layout: 720 column, title 28/600, subtitle 13/400, controls row 32, group header 28 (12/600 `textSecondary`, count 11/400 right). Rows 44, padding-h 12, `radiusMd`; two lines (13/600 date, 12/400 state), actions right: `Write` (`SecondaryButtonStyle`, 28) and `Skip` (`TextButtonStyle`, hit 44x28), 12 apart. Hover `hover`, selected `accentTint`, focus ring custom. A click selects; double-click or Return = `Write`.
- Row glyphs (16): not started `circle.dashed` `warning`; started `circle.lefthalf.filled` `textSecondary`; written now `checkmark.circle.fill` `accent` (stays until you leave the screen so the list does not jump); skipped now `minus.circle` `textTertiary`, row fades out in 180ms.
- Multi-select: ⇧ or ⌘-click, ⌘A. A 44 high bar pins to the bottom: "3 selected", `Skip...`, `Clear`. Skip uses the existing Skip sheet in list mode ("Skip these 3 days?", chips Holiday, Leave, Sick, Day off, Other; no range picker), then a success banner "Skipped 3 days as Leave." with `Undo` (8s).
- `Skip...` menu: "Skip all N days...", "Skip days before..." (default reason "Didn't track"). Older than the window: collapsed under "Older" so an old log never shows a wall of rows.
- **Session** ("Next missed day"): oldest first so From yesterday chains forward (the list is newest first). The day page appears with a 44 high bar above the title (fill `sidebar`, `radiusLg`, padding-h 16) and a 3 high progress line (`accent` on `border`, width animates 200ms):

```
[End]  Catching up 3 of 4 . Tue 29 Sep        [<]  [Skip day]  [Next missed day  ⌘↩]
===========================================-------------------------------------------
Tuesday, 29 September          7 days ago   8 words. Counts as logged at 20.      Saved
> From Mon 28 Sep . 3 items                                              [Carry over]
```

  `Next missed day` is always enabled (primary): it advances to the next unwritten day after this one, wrapping once, and ends when none remain; leaving a day under the minimum keeps it in the list. Skip day opens the Skip sheet, then advances. Esc or End returns to the list. At the end the page area shows "All caught up." with "3 written, 1 skipped" and `Review this week` / `Go to today`. VoiceOver announces each step.
- **Quiet notice** on Today (`SlimNotice`, PRD CUP-4): "2 earlier days have no page." `Catch up`, dismiss; once per day; hidden while the reminder notice shows.
- Sources (M6): the "Suggested from your work" strip takes the slot under the bar; not rendered when Sources is off.

## 5. Review and export (M1 week fixes, M3 the rest)

One screen, toolbar segmented control Week, Month, Year, Range (Range = two `DatePicker(.field)` in the controls row). Title 28/600, summary 13/400 mono digits ("Logged 2 of 5 scheduled days, 1 skipped, 2 not written"; logged + skipped + not written = scheduled days, and not written includes started days, PRD M3-A2), controls row 32: `Last week`, `This month`, checkboxes `Skipped days` (on) and `Jots` (off), `Group by` Day or Section (existing).

```
Week of 21 Sep to 27 Sep 2026                                                 [Catch up this week]
Logged 2 of 5 scheduled days . 1 skipped . 2 not written
[Last week] [This month]            [x] Skipped days  [ ] Jots     Group by ( Day | Section )
+------+------+------+------+------+------+------+     tiles (column - 48) / 7 wide, 96 at 720, min 64, 64 high, gap 8
| Mon  | Tue  | Wed  | Thu  | Fri  | Sat  | Sun  |     weekday 11/400 `textSecondary`
| 21 o | 22 * | 23 * | 24 - | 25 ( | 26   | 27   |     number 15/600 + mark 8; bottom line 11/400:
|Write | 63 w | 41 w | Leave| 8 w  |      |      |     `radiusLg`, `surface`, `border`; "63 words", "Write", "Leave"
+------+------+------+------+------+------+------+
[ReviewCard per day or per section, 720 wide (existing)]
```

- **Week** lists every scheduled day, empty weeks included (the v0.3 bug), each tile opens that day; Sat and Sun are dimmed but clickable. `Catch up this week` shows whenever a scheduled day is unwritten and opens Catch up scoped to the week. Empty week: "Nothing written for this week yet." with `Catch up this week` (primary) and `Go to today`. Tiles are buttons: bottom line is the word count, `Write` (13/600 `accentText`) when not written, the skip reason when skipped; hover `hover`; today 1.5 `accent` ring; off days dim; custom focus ring; tooltip carries the full status.
- **Month** and **Range**: no tiles; counts line, then cards grouped by Day or by Section (headings, `Jots`, "Other notes"), each item dated (56 wide mono day column, existing `WeekSectionCard`). Clamp long entries with Show more (existing).
- **Year**: header "2026" and one summary line; a native `Table`, 12 rows x 32, header 28: Month (140), Logged, Skipped, Not written (90 each, right-aligned mono digits), no row colours. Click a row opens that Month. Future months show "-" and are inert. Fast because it needs states only, so no word counts. Rendering within 2s for 250 pages (M3-A3).
- **Export menu** (⇧⌘E): Copy as Markdown, Plain text, Rich text (button flashes "Copied" 2s); Save as Markdown... (`<name>.md` plus an `assets/` folder holding only used images); Save as PDF...; Share... (`ShareLink` with a lazily exported file). `Skipped days` and `Jots` apply to every copy and export. Failure: banner "Couldn't save “Week 40.md”. The folder may be read-only or the disk full." with `Try again`, `Choose another place...`.

## 6. Search (M1 look, M4 scale)

Sidebar field unchanged; results fill the detail pane. Title `Search: "pricing"` 28/600 and the count right ("1,284 matches in 212 days", 13/400 mono; a small `ProgressView` appears beside it only if a query runs past 200ms). Scope row 32: date range menu (All time, This month, This year, Custom...), heading menu (existing, template headings), sort (Newest, Oldest).

```
Search: "pricing"                                          1,284 matches in 212 days   (spinner)
[ All time v ] [ All headings v ] [ Newest v ]                      Indexing 40%, results may be partial
2026  (sticky 28)   October (sticky 28)
 Mon 5 Oct     Finished      Pricing table update shipped ...
 Fri 2 Oct     Notes         ... pricing page copy with Ana ...
                                     [ Show 200 more ]
```

- Rows min 40: heading column 130 (12/600 `textSecondary`), snippet 13/400 up to 2 lines, match run `textPrimary` on `accentTint`; hover `hover`, cursor row `accentTint`. First 200 hits render, then `Show 200 more`; year and month headers are sticky (`LazyVStack(pinnedViews:)`).
- Keys: ⌘F focuses the field, Down moves into results, ⌘G / ⇧⌘G next / previous, Return opens the day at the text, Esc clears. A focused empty field offers up to 6 recent searches (28 rows, `Clear`).
- States: no results (restricted scope): "No matches for “pricing” in this year." with `Search all time`; no results (all time): "No matches. Try a shorter word." with `Clear search`; index building: slim notice "Indexing 40%. Results may be partial."; unreadable files: notice naming the file ("2026-09-12.md could not be searched", or "3 files...") with `Show`, results still arrive; error: Banner (error).

## 7. Settings window (M1)

Native `Settings` scene with `TabView`: toolbar tabs, window title follows the tab, 840 wide fixed, content column 640 centred, height per pane (300 to 560, scrolls above). Every change applies at once; no Save. Controls follow the system accent except where `.tint(Theme.accent)` reaches them [verify].

```
+----------------------------------------------------------------------------------------------------------------------+
|(o)(o)(o)                                              Reminders                                                      |
|  [gear]   [alarm]   [doc]   [brush]        [drive]       [clock]    [kbd]     [tray]      [bell]     [gear2]    [i]  |
| General  Reminders   Page  Appearance  Storage and sync   Backup  Shortcuts  Sources  Notifications  Advanced  About |
+----------------------------------------------------------------------------------------------------------------------+
|                        Reminder                                                                                      |
|                        +--------------------------------------------------------------------+                        |
|                        | Remind me at                                           [ 4:55 pm ] |                        |
|                        | On these days                                [M][T][W][T][F][ ][ ] |                        |
|                        | Next reminder: Thu 8 Oct, 16:55                                    |                        |
|                        +--------------------------------------------------------------------+                        |
+----------------------------------------------------------------------------------------------------------------------+
```

| Pane (symbol, height) | Rows (grouped `Form`; section footers say "Shared across your Macs" or "This Mac only" once sync ships) | Ships |
|---|---|---|
| **General** `gearshape` 340 | Open at login (switch, approval message); Show in menu bar; Show in Dock; Open at launch: Today or last page; Week starts on: System, Mon, Sun | M1 |
| **Reminders** `alarm` 480 | Remind me at; On these days (also the days Catch up and the streak expect; one setting, one control); Style: Strict or Gentle (existing `ModeRow`); Snooze for; Next reminder row; Remind on this Mac (M5a) | M1, M5a |
| **Page** `doc.text` 560 | A day counts after N words (existing); Log start date (`DatePicker(.field)`, "Days before it are never listed as missed or break your streak"); Catch-up window: 14, 30, 60, 90 days or since log start; New day template (existing editor 150 high); Carried over from yesterday (existing); Jots count toward logged (switch, off, M2) | M1, M2 |
| **Appearance** `paintbrush` 300 | Theme: System, Light, Dark (`NSApp.appearance`); Accent: Gloamlog green or System accent; Show streak (footer and page chip). Text size and page width need an editor contract change, so they are not in v1 | M1 |
| **Storage and sync** `externaldrive` 540 | Folder path (mono 12), Choose..., Show in Finder, Use default, summary line (existing); Search index: status, `Rebuild search index` (M4); Sync across Macs: `Set up sync...`, `Join from another Mac...`, status row, conflicted copies row with `Review...`, "N days are still in iCloud" with `Download all` (M5b). Line: "Gloamlog doesn't run sync. Your folder provider moves the files." | M1, M4, M5b |
| **Backup** `clock.arrow.circlepath` 400 | Safety copies: location (outside the log folder), Show in Finder, `Restore previous version...` (existing sheet); whole-folder backup: `Back up now...` to a place you choose, last backup row, `Restore from backup...` always into a new folder, never over the current one | M1 safety copies; whole-folder rows when built |
| **Shortcuts** `keyboard` 520 | Jot shortcut recorder (default ⌃⌥J, `Off`; a combination another app owns shows "Already used by another app", M2); read-only grouped list of every menu shortcut (Go, Page, Review, Catch up) | M1, M2 |
| **Sources** `tray.and.arrow.down` 460 | Claude Code sessions and Git switches (off), folder rows, per-project allow / deny `Table`, redaction (locked on), `Preview what would be added` | M6; tab hidden before |
| **Notifications** `bell.badge` 360 | Permission row with `Allow` or `Open System Settings` (existing); Sound; Dock badge: days to catch up; Menu-bar count; Notify me about sync conflicts (M5b); `Send a test notification`; "Nothing fires while the Mac sleeps; Focus can silence it." | M1, M5 |
| **Advanced** `gearshape.2` 340 | Run setup again...; Rescan folder; Reset settings... (confirm, logs untouched); Copy diagnostics (versions and counts, no page text); open log folder, backups, settings file | M1 |
| **About** `info.circle` 340 | Icon 64, name, version and build, one line, "No network requests, no account, no telemetry."; `What's new`, `Acknowledgements`, `Report an issue` (opens the browser) | M1 |

`model.settingsPane` is the `TabView` selection (last pane restored, `@AppStorage`), set before opening, so banners and chips deep-link ("Open Reminders settings"). 11 tabs need about 800 wide; if the toolbar overflows, shorten "Storage and sync" to "Storage" [verify]. Each pane keeps to about 8 controls (audit 1.2); Storage and sync is the exception and uses three sections (Folder, Search, Sync).

Row anatomy (native grouped `Form`, 13/400 `textPrimary` label left, control right, min height 28): helper text 12/400 `textSecondary` under the row; section header 13/600; status row = symbol 14 + text + trailing button (permission, sync, backup); destructive action text in `danger`, always behind a confirmation; a row that cannot apply yet (no notification permission) stays visible, disabled, with the reason as helper text.

## 8. Jot panel and menu bar (M2)

Global hotkey (default ⌃⌥J) opens a floating panel over any app, full-screen apps included; focus returns to the previous app on close. Return saves, ⇧Return adds a line, Esc cancels. Saved as a time-stamped bullet under `## Jots` at the end of today's page (PRD M2-A2). Today only in v1.

```
+----------------------------------------------------------+
|  Jot to Today                                      14:32 |   header 28: 13/600, time 12/400 `textSecondary`
|  call with Sam about pricing                             |   field 15/400, 1 to 6 lines (44 to 144)
|  Return adds . Shift-Return new line . Esc cancels       |   footer 28: 12/400 `textSecondary`
+----------------------------------------------------------+
```

- Panel 520 wide, 148 to 248 high, padding 16, `surface`, `radiusLg`, elevation 2 (section 2), no blur. Centred horizontally on the screen with the pointer, top edge at 22% of the visible frame [verify with two displays]. In 120ms / out 80ms (opacity + 6pt Y).
- States: empty (hint only); typing; saved (check + "Added to Today", `accentText`, 600ms then closes; adds "Today is logged." only if this crossed the word rule); folder unavailable (`info.circle` "Kept on this Mac. It will be added when the folder returns."); error (`danger` "Couldn't save. Your note is still here." with `Try again`); shortcut taken is shown in Settings, Shortcuts, not here.
- Menu-bar popover, 320 wide, about 330 high: today line, state, reminder line; a 32 high **Jot** field (`surface`, `border`, `radiusMd`; Return adds, then "Added" 600ms); `Catch up: 3 days` row (hidden at 0); streak and 7-day strip (existing marks); `Open Gloamlog` (primary), `Jot...` ⌃⌥J, `Skip today...`; `Settings...` ⌘,; `Quit`. Icon states unchanged; with "Menu-bar count" on, the digit sits right of the icon.

```
+------------------------------------+
| Today . Tue 6 Oct                  |
| (o) Not logged yet, due 4:55 pm    |
| [ Jot a line for today...      <-] |
| Catch up: 3 days                 > |
| 12 day streak    M T W T F S S     |
| Open Gloamlog                 ⌘O   |
| Jot...                      ⌃⌥J   |
| Settings...                   ⌘,   |
+------------------------------------+
```

## 9. Sync and conflict states (M5b; folder and banner states already M1)

Gloamlog does not sync; it watches the folder and reports. Sidebar chip (13/400, symbol 14): hidden, `Synced` (`externaldrive.badge.checkmark`), `Syncing` (mini `ProgressView`), `2 to review` (`externaldrive.badge.exclamationmark`, `warning`), `Folder unavailable` (`exclamationmark.triangle`, `danger`).

| State | Where | Kind and text | Actions |
|---|---|---|---|
| Open page changed elsewhere, no edits here | Day, slim notice | "Updated from another Mac." (page reloads within 10s) | `Undo` |
| Open page changed elsewhere, edits here | Day, banner | Warning "This page changed on another Mac while you were writing. Autosave is paused for this page." | `Keep mine`, `Take theirs`, `Keep both` |
| Conflict copy found ("name 2.md", "conflicted copy", "sync-conflict") | Chip, Settings row, banner at launch | Warning "1 conflict in ~/Gloamlog." | `Review...` |
| Days still in iCloud | Day (if open) and Settings | Info "3 days are still in iCloud." | `Download all` |
| Folder missing or read-only | Day, banner | Existing `FolderBanner` | existing |

Conflict sheet 720x520, `Grid` of aligned line pairs in two 336 columns headed "This Mac, 5:02 pm, 63 words" and "Other copy, 4:40 pm, 71 words"; differing lines on `warningTint`. `Merge both` (primary) appends the other version under "From other copy (4:40 pm)" and moves the extra file to backups; `Keep this Mac's`; `Use other copy`. Nothing is ever deleted.

Order and limits: at most 2 notices show above the page, in this priority: folder problem, save error, conflict, editor problem, raw-text-only, sync status, reminder, Catch up notice, roll-over, transient. Errors and warnings with actions never auto-dismiss; info and success go after 4s, 8s when they carry `Undo`; the page never shifts by more than the notice's own height (reserve the space, audit D7).

## 10. Onboarding (M1; sheet 600x520, existing frame)

Four steps, capsules 28x4 top-left, `Skip setup` top-right on step 1, primary bottom-right; padding 40; choice cards 264x96, gap 12 (template and mode cards keep their existing heights).

```
Where are your logs?                                                    - - - -   [Skip setup]
+-----------------------------+  +-----------------------------+
| (o) I'm new                 |  | ( ) I already have logs     |      third card, M5b: "Join from another Mac"
| Start a fresh log           |  | Use a folder I have         |
+-----------------------------+  +-----------------------------+
 Found: ~/Gloamlog   212 pages, Mar 2025 to Oct 2026                     (28 high radio rows)
 Nothing is moved or rewritten. 3 files aren't recognised.     Log starts [ 1 Mar 2025 v ]
 [Back]                                                              [Continue]
```

1. **Your logs.** New: folder radios (existing: on this Mac, iCloud Drive if present, another folder) and a checkbox "Let me fill in recent days" (log start = 14 days back; default start = today). Existing: detected folders (default folder, iCloud `Gloamlog`, the old folder setting) with counts and date range, `Choose another folder...`, summary, and `Log starts` (default = first page); helper "Days before this are never listed under Catch up." Empty folder chosen as "existing": "No Gloamlog pages here. Start fresh in this folder?"
2. **Your page.** Existing template cards and words rule; for existing logs add "Your pages stay as they are. The template only fills new days."
3. **Reminder.** Existing (time, days, Strict or Gentle).
4. **All set.** Open at login, notifications `Allow`, Jot shortcut recorder (M2). CTA `Start writing` (new) or `Open Gloamlog` (existing); when N unwritten days exist a text button `Catch up on N days first`. Dropping a folder from Finder onto the main window later offers the same "Use this folder?" sheet.

## 11. Empty and error states

Each says cause and next action; no illustration (DESIGN_SYSTEM 6.13). Shown centred in the 720 column, 15/400 `textSecondary` with a 13/600 title above.

| Where | Message | Actions |
|---|---|---|
| Catch up, nothing to do | "All caught up." "Every scheduled day since 1 Sep has a page or a skip." | `Go to today`, `Review this week` |
| Catch up, new user | "Nothing to catch up on yet." "Days before your first page don't count." | `Open calendar`, `Log start date...` |
| Week or Month, nothing written | "Nothing written for this week yet." | `Catch up this week`, `Go to today` |
| Year, no pages | "No pages in 2026 yet." | `Go to today` |
| Search, empty field focused | recent searches or "Search every day in ~/Gloamlog." | none |
| Recent, no pages yet | "Pages you write appear here." 12/400 `textSecondary`, padding 16 | none |
| Calendar day before the log start | page opens normally; footnote "Before your log start. It won't appear in Catch up." (12/400) | none |
| Folder missing, not writable | existing `FolderBanner` | existing |
| Editor unavailable, raw text only | existing banners | existing |
| Jot hotkey in use | Settings, Shortcuts: "⌃⌥J is already used by another app." | `Record another...`, `Off` |
| Notifications denied | "Notifications are off for Gloamlog. Gentle needs them." | `Open System Settings` |
| Backup failed | "Last backup failed: the destination isn't available." | `Choose destination...`, `Back up now` |
| Files unreadable | "2 files in ~/Gloamlog could not be read." (warning banner) | `Show them` |
| Skip failed | existing Skip sheet error text | `Try again` |

## 12. Interaction details

- **Hover:** `hover` fill, 80ms linear, on rows, tiles, calendar cells; tooltips (`.help`) after the system delay carry full status text. No hover-only controls: row actions are always visible.
- **Focus:** system rings stay on native controls (cannot be hidden or recoloured on macOS 13, `focusEffectDisabled` is 14+). Fully custom views (calendar cell, tile, catch-up row) also draw the token ring: 1.5 `accent` inside, `focusRing` 3 outside, 120ms.
- **Selection:** one page open = `accent` fill (calendar) or `accentTint` (rows); ranges and multi-select = `accentTint`; never an outline alone.
- **Drag:** across calendar cells to select a range (4pt threshold); a folder from Finder onto the main window opens "Use this folder?"; images and text into the page (existing); template headings reorder in Settings, Page (`onMove`).
- **Focus order, main window:** toolbar left to right; Search; Today, Catch up, Review; calendar header; calendar grid (one stop, arrows inside); Recent (one stop, up and down); footer streak, sync chip, gear; then the detail: banner actions in order, page `...` menu, From yesterday (disclosure, Carry over), editor. ⌘E jumps to the page, ⌘F to search. Catch up: scope control, `Next missed day`, rows (up and down; Tab reaches `Write` then `Skip`), Older. Review: segmented control, quick buttons, checkboxes, tiles, cards, Export. Settings: tabs (left and right arrows), then rows top to bottom. Jot panel: field first, nothing else needs Tab. Without Full Keyboard Access Tab visits text fields only.
- **Catch up keys:** up / down move, Return = Write, S or Delete = Skip, ⌘A all, Esc clears selection or ends the session, ⌘Return = Next missed day [verify it reaches the menu while the editor has focus].

| Motion | Property | Duration | Curve |
|---|---|---|---|
| Month change in calendar, review scale switch | cross-fade (no slide) | 140ms | ease in-out |
| Catch-up row removed | opacity + height | 180ms | ease-in |
| Session progress line | width | 200ms | ease-out |
| Jot panel in / out | opacity + 6pt Y | 120ms / 80ms | ease-out / ease-in |
| "Added" hold, then close | none | 600ms | none |
| Settings pane change | window resize | system (about 200ms) | system |
| Count badge, marks, sidebar wash | none (instant) | 0 | none |

Everything else keeps DESIGN_SYSTEM section 8. **Reduce Motion** (`accessibilityReduceMotion`, via `Theme.animation`): all durations 0 except opacity, capped at 100ms; no cross-fades. Nothing loops; the only spinner is the system `ProgressView` while work is really running.

## 13. Accessibility

- Calendar: container "Calendar, October 2026"; cell "Monday 5 October, logged, 63 words" / "Wednesday 30 September, not written" / "..., skipped, Leave" / "..., today"; traits button and selected. Custom rotor "Days to catch up" (`accessibilityRotor`). Range and session changes are announced ("Catching up, 2 of 5, Wednesday 30 September") through `UIAnnounce`.
- Never colour alone: marks differ by shape; catch-up rows and tiles also say the state in text; Differentiate Without Colour needs nothing extra. Increase Contrast: `border` to `borderStrong`, mark strokes 1.25 to 2. All text pairs at least 4.5:1, marks at least 3:1 (section 2).
- Targets: calendar cells at least 28x30; icon buttons 24x24 visible, 28 hit; `Skip` hit 44x28. Minimum text 11.
- Jot panel: label "Jot to Today"; the confirmation is announced; Esc always closes; reachable by VoiceOver although the panel is non-activating [verify].
- Settings: native controls only; helper text bound with `.accessibilityHint`; tabs reachable by arrows.
- Dates use `Calendar.current` for week start and weekday symbols; `DayKey.format` is English only, so new strings must go through one formatter (localisation is a PRD non-goal).

## 14. SwiftUI feasibility (macOS 13, no macros)

`@State` is a macro in this SDK and fails to compile here without its plugin (confirmed with `swiftc`); `@Observable` and `#Preview` are macros too. Keep `Box<T>` + `@StateObject`, `@FocusState`, `@AppStorage`. Every API below was compile-checked at macOS 13 unless marked; behaviour is not verified until run.

| Need | Use | AppKit? | Note |
|---|---|---|---|
| Split view, widths, unified toolbar | `NavigationSplitView`, `.navigationSplitViewColumnWidth`, `Window` scene, `.windowToolbarStyle(.unified(showsTitle: false))`, `ToolbarItem` (`.navigation`, `.principal`, `.primaryAction`), `.toolbarRole(.editor)` | no | sidebar toggle and `SidebarCommands()` are free |
| Sidebar material | drop the opaque fill, `Theme.sidebar.opacity(0.8)` over it, `accessibilityReduceTransparency` | fallback only | [verify] material shows through a custom `ScrollView`; else `NSVisualEffectView(.sidebar)` wrapper |
| Sidebar and catch-up rows | custom rows (as now), `.focusable()` + `.onMoveCommand`, `NSEvent.modifierFlags` for ⇧ / ⌘-click | no | `List(selection:)` gives keys for free but paints the system accent; no type-select |
| Calendar grid | `LazyVGrid` 7 columns, `DragGesture(minimumDistance: 4)`, `.accessibilityRotor` | no | native `DatePicker` (`.field`, `.graphical`) has no marks: use it only where marks are not needed (Skip through, Range, log start) |
| Natural-language date | `NSDataDetector(.date)` | no | Foundation |
| Settings window | `Settings` + `TabView` (toolbar tabs), `Form.formStyle(.grouped)`, `LabeledContent`, `Picker`, `Toggle(.switch/.checkbox)`, `Stepper`, `DatePicker(.field)` | no | 11 tabs [verify] overflow; `SettingsLink` is 14+: use it under `if #available(macOS 14, *)`, else `NSApp.sendAction(Selector(("showSettingsWindow:")))` (existing). The PRD doubts it opens on the owner's macOS: if `sendAction` returns false or no Settings window shows within 300ms, open a fallback `Window("Settings", id: "settings")` with the same panes [verify on that Mac] |
| Deep link to a pane | `TabView(selection: $model.settingsPane)` | no | set before opening |
| Year summary | `Table` with `TableColumn`, no sort | no | selection paints the system accent [verify `.tint`]; fallback 12 custom rows |
| Sources projects list | `Table` + `Toggle` cells | no | M6 |
| Review tiles, cards | `HStack`, `LazyVStack(pinnedViews:)`, `Grid` for the conflict view | no | `ContentUnavailableView` is 14+: custom `EmptyState` |
| Search scope row | custom `Menu`s under the existing sidebar field (it already routes results and ⌘F) | no | `searchable(placement: .sidebar)` and `searchScopes` compile on 13 and are the fallback if the custom field misbehaves |
| Export | `fileExporter` or `NSSavePanel`; PDF via `WKWebView.createPDF`; rich text via `AttributedString(markdown:)` to `NSPasteboard`; `ShareLink(item:preview:)` with `Transferable` `FileRepresentation` | PDF and pasteboard | lazy export so Share does not write until chosen |
| Jot panel | `NSPanel` subclass (`.nonactivatingPanel`, `canBecomeKey`, `level .floating`, `.fullScreenAuxiliary`, `.canJoinAllSpaces`) hosting `NSHostingView`; `TextField(axis: .vertical).lineLimit(1...6)` | **yes** | [verify] Return vs ⇧Return via `onSubmit` + modifier check |
| Global hotkey and recorder | Carbon `RegisterEventHotKey` (no Accessibility permission); recorder via `NSEvent` local monitor | **yes** | [verify] it returns an error when another app owns the combo (PRD M2-A7 needs that) |
| Menu bar | `MenuBarExtra(.window)`, `TextField` inside | closing the popover needs AppKit | [verify] text focus inside the popover |
| Dock badge, Dock menu | `NSApp.dockTile.badgeLabel`, `applicationDockMenu` | **yes** | one line each |
| Folder watching, iCloud state | `DispatchSource` file system object, `NSMetadataQuery`, `URLResourceValues.ubiquitousItemDownloadingStatus` | no | Foundation |
| Drop a folder | `.dropDestination(for: URL.self)` | no | |
| Symbols | all names used verified against macOS 13.0 | no | |
| Not available on 13 | `SettingsLink`, `ContentUnavailableView`, `.inspector`, `.onKeyPress`, `.focusEffectDisabled`, `Section(isExpanded:)`, `.onChange(of:initial:)`, `alternatingRowBackgrounds`, `symbolEffect` | | confirmed by compile |

## 15. Milestone map and decisions

M1: sidebar, toolbar, calendar, Go to date, Catch up and session, Week fixes, Settings (all panes except Sources), onboarding branch, empty states. M2: Jot panel, menu-bar Jot, shortcut recorder. M3: Review Month, Year, Range, Export. M4: search scope and index state. M5: Reminders rows, sync and conflict UI. M6: Sources pane and the session strip. PRD checks map to screens: R1 section 3, R2 and R9 section 5, R3 and R4 section 4, R5 section 7, R8 section 6; run R1 to R9 on the built app before M2.

Open decisions: (1) the log start date and catch-up window are new Core state; (2) sidebar wash 0.80 and dropping the month groups need a look on screen; (3) Settings is 840 wide for 11 tabs; (4) the Settings gear sits in the sidebar footer, not the toolbar (HIG advice against a toolbar button, PRD SET-1 wants a gear in the window); (5) not designed because the PRD is silent or excludes them: month previews, a year heat grid, a per-week note (PRD Q2), change date or delete day (audit G7), import from other vaults (G11), "my day ends at" (G8); (6) text size and page width wait for an editor contract change; (7) the Jot default ⌃⌥J is the PRD's proposal [verify conflicts].
