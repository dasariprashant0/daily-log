# Changelog

All notable changes to this project. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/).

## [Unreleased]

Being rebuilt around real daily use (calendar and catch-up for missed days and weeks, a fuller Settings window, quick capture, review and export, sources, sync). See `docs/STRATEGY.md`.

### Known issues
- Past days can only be reached from the sidebar if they already have a file, or through the Week view. There is no calendar or "catch up" list yet.
- Settings (⌘,) has few options and nothing in the main window points to it.
- Not notarised: macOS asks you to approve the app once (System Settings → Privacy & Security → Open Anyway), or build it from source.
- The app has had automated checks (core tests, real-WebKit editor checks) but little real-world use.

## [0.3.0] - 2026-10-07 (checkpoint, not released)

### Changed
- **Renamed to Gloamlog** (was Daily Log). New bundle identifier `io.github.dasariprashant0.gloamlog`; default log folder for new installs is `~/Gloamlog`. A first-launch migration carries over settings and backups from the old name.
- **One free-form page per day** replaces the five fixed boxes. The five prompts are now an optional, editable template of headings.
- The page is a **Notion-style editor** (Milkdown Crepe, MIT) bundled into one self-contained file: headings, lists, to-dos, quotes, code, tables, links, images, `/` menu, drag handles. It runs with a Content-Security-Policy that forbids all network access.
- **Autosave** replaces the Save button. A day counts as logged once you write `minWords` words (default 20). Carried-over tasks do not count.
- Declutter: no cards, progress ring or bottom bar; the heatmap moved into a popover from the streak chip.
- Core logic reworked and covered by 580+ automated tests; 130+ checks run the real editor in WebKit.

### Added
- Versioned backups of every page (kept outside the log folder) and "Restore previous version".
- Image support: paste or drop images; they are stored in `assets/` next to your logs.
- Carry over yesterday's to-dos and pending items; weekly review by day or by section; search with heading context.
- Third-party licence file for the editor bundle.

### Removed
- The v0.1 shell/Python script version (`daily-log.sh`, `daily-log.py`); the app replaces it.

## [0.2.0] - 2026-10-06 (internal)
- Five-section SwiftUI app with sidebar, streak and heatmap, search, weekly review, menu bar item, Settings, onboarding, strict/gentle reminders, skip days, app icon, tests and CI.

## [0.1.0] - 2026-10-06 (internal, then called Daily Log)
- First native SwiftUI app: five required sections, reminder at 4:55pm on weekdays, markdown logs.
- Views use `ObservableObject` / `@StateObject` instead of `@State`: `@State` is a macro that needs Xcode's SwiftUIMacros plugin, which Command Line Tools lack.
