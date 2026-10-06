# Daily Log Design System

Native macOS SwiftUI app, styled like a Notion page. Source of truth: `app/DailyLog.swift` (ContentView, DayView, Block). The earlier web version (`daily-log.py`) supplied the original palette.

> **Verification status:** the UI compiles but has not been visually verified yet. Everything below describes what the code specifies, not what has been seen on screen. Treat spacing, contrast and dark-mode behaviour as unconfirmed until checked in a running build.

## 1. Principles

- **Calm.** One column, generous whitespace, no chrome beyond a sidebar and a single primary button.
- **Document-like.** The day is a page: big title, date, divider, headings, editable blocks. Same five headings as the markdown file on disk.
- **Forced but friendly.** Save stays disabled until all 5 sections are filled, and the window re-opens at reminder time. The tone is a progress counter ("3/5 filled"), never a warning.
- **System first.** Use semantic system colours and fonts so light/dark and accent follow macOS without custom code.

## 2. Typography

| Role | Spec | Where |
|---|---|---|
| Page title | `.system(size: 40, weight: .bold)` | "Daily log" |
| Date line | default body, `.secondary` | `Store.pretty(day)` |
| Section heading | `.title2.bold()` | 5 section titles (emoji + text) |
| Block text | `.system(size: 15)` | TextEditor |
| Placeholder | default body, `.tertiary` | Block hint |
| Controls / status | default body | Save, progress, picker, Open folder |

Web version for reference: 40px h1, 20px h2, 16px body, system sans stack.

## 3. Colour tokens

No custom colours in the app; all semantic.

| Token | Use | Light / Dark |
|---|---|---|
| `.primary` (default text) | Titles, headings, editor text | Follows system |
| `.secondary` | Date, "n/5 filled", "Saved ✓" | Follows system |
| `.tertiary` | Block placeholder | Follows system |
| `Color.primary.opacity(0.05)` | Block fill | Faint grey on light, faint light on dark |
| `.red` | Save error text | System red |
| System accent | Prominent Save button, selection, picker | User's macOS accent (not fixed) |

Web palette (legacy, not ported): `--bg #fff / #191919`, `--fg #37352f / #e6e6e4`, `--mute #9b9a97 / #7f7f7d`, `--line #e9e9e7 / #2f2f2f`, `--hover #f7f7f5 / #252525`, accent `#2383e2`. The native app does not use these hex values; it approximates the feel via system colours.

## 4. Spacing and layout

| Item | Value |
|---|---|
| Page padding | 56 horizontal, 40 vertical |
| Content max width | 780, leading-aligned |
| Stack spacing | 6 (title/date); divider padding 12 vertical |
| Section heading top padding | 18 |
| Block min height | 90 |
| Block inner padding | 6 |
| Block corner radius | 6 |
| Action row | spacing 14, top padding 28 |
| Sidebar width | min 190, ideal 220 |
| Window | default 980x740, minimum 820x600 |

## 5. Components

- **Sidebar row.** `Label` with `checkmark.circle.fill` (logged, 5/5) or `circle` (not logged). Title is "Today" for the current day, otherwise `EEEE, d MMMM yyyy`. Newest first; today always present.
- **Page header.** Title, date, `Divider`.
- **Section heading + Block.** `.title2.bold` heading above a `TextEditor` on a 5% fill with radius 6. Placeholder is overlaid top-left, `.tertiary`, hidden once text exists, not hit-testable. Plain background (`scrollContentBackground(.hidden)`).
- **Save button.** "Save log", `.borderedProminent`, `.large`, disabled while `filled < 5`.
- **Progress text.** "3/5 filled"; becomes "Saved ✓" after save, resets on any edit. Whitespace-only counts as empty.
- **Reminder picker.** `DatePicker("Remind me at")`, hour and minute, stored in `@AppStorage("remindMinutes")`, default 16:55.
- **Open folder.** Plain button, opens `~/daily-log` in Finder.

## 6. States

| State | Appearance |
|---|---|
| Empty | All blocks show placeholders; Save disabled; "0/5 filled"; sidebar circle |
| Partially filled | Save disabled; "n/5 filled" |
| Complete, unsaved | Save enabled; "5/5 filled"; sidebar still circle |
| Saved | "Saved ✓"; sidebar `checkmark.circle.fill` |
| Error | Red `localizedDescription` next to the status text; Save stays enabled |

## 7. Interaction and forcing

- Weekdays only (Mon-Fri), from the reminder time onward, if today is not fully logged.
- First nag of the day always brings the window to front and activates the app. Afterwards it re-opens only if closed or minimised, checked every 60 seconds.
- Closing the window does not quit the app; it registers as a login item so the nag can fire.
- Editing clears "Saved ✓". Switching days reloads the editor (`.id(day)`).

## 8. Accessibility

Gaps, stated honestly:
- **Dynamic Type:** not applicable on macOS. The fixed 40 and 15 sizes do not follow a text-size setting.
- **VoiceOver:** no accessibility labels set yet. The block editors have no label beyond the placeholder, which is not exposed. Sidebar status icons rely on the symbol name only.
- **Contrast:** `.tertiary` placeholder on the 5% fill is unverified and likely below 4.5:1. Check in both appearances.
- **Colour only:** logged vs not logged uses different glyph shapes, not just colour (good). Error text is red but also textual.
- **Keyboard:** standard controls are focusable; tab order inside the action row is unchecked.
- **Reduce transparency / increased contrast:** the 5% fill may vanish under high-contrast settings; unchecked.

## 9. App icon brief

Rounded-square macOS icon, flat and calm. A white document page with a soft fold and a single green check or small checklist lines, on a muted warm-neutral or deep graphite ground. One accent only (system-blue-adjacent or green for "logged"). No text, no gradients beyond a subtle top light. Must read at 16px, so keep to one bold shape. Deliver 1024px master plus the standard macOS iconset sizes.

## 10. Proposed next (not built)

- App icon per the brief above (currently default).
- Empty states: friendly first-run message when no past days exist; a nudge line when 0/5.
- Accent colour setting (currently follows system accent).
- Placeholder contrast fix and VoiceOver labels for blocks and sidebar rows.
- Visual verification pass in light and dark, then update this doc with measured results.
