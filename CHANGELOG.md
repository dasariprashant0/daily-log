# Changelog

All notable changes to this project. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versioning: [SemVer](https://semver.org/).

## [Unreleased]

### Added
- Planning docs in `docs/`: PRD, TRD, architecture, design system, file structure, about, explanation.

### Known issues
- The macOS app has been compiled but not launched or visually tested yet.
- Not notarised: recipients must right-click → Open on first launch.
- Reminder days are fixed to Mon–Fri.

## [0.1.0] - 2026-10-06

### Added
- Native SwiftUI Mac app (`app/DailyLog.swift`): Notion-style page, sidebar of past days, five required sections, Save disabled until all are filled.
- In-app reminder (default 4:55pm, Mon–Fri, configurable time) that brings the window forward until today is saved; runs as a login item.
- `app/build.sh`: compiles with `swiftc` (Command Line Tools only), writes `Info.plist`, ad-hoc signs, zips to `DailyLog.zip`.
- Script version: `daily-log.sh` (launchd installer) + `daily-log.py` (local Notion-style web form).
- Logs stored as markdown at `~/daily-log/YYYY-MM-DD.md`.

### Changed
- Views use `ObservableObject` / `@StateObject` instead of `@State`: `@State` is a macro that needs Xcode's SwiftUIMacros plugin, which Command Line Tools lack.
