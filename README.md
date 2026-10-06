# Daily Log

A small Mac app that makes you write up your day: what you did, finished, started, what's pending, and what to do next. Every box is required before it saves. At your reminder time (default 4:55pm, Mon–Fri) it comes to the front until today's log is saved.

Logs are plain markdown at `~/daily-log/YYYY-MM-DD.md`.

## Build

Needs macOS 13+ and Xcode Command Line Tools.

```bash
cd app && ./build.sh
```

This produces `app/Daily Log.app` and `app/DailyLog.zip`.

## Share it

The app is ad-hoc signed, not notarised. Whoever receives the zip should unzip it, drag `Daily Log.app` to Applications, then right-click → Open the first time (or run `xattr -dr com.apple.quarantine "/Applications/Daily Log.app"`).

The app registers itself as a login item so the reminder can fire. Quit it with ⌘Q to stop it; remove it in System Settings → General → Login Items.

## Docs

[About](docs/ABOUT.md) · [How it works](docs/EXPLANATION.md) · [PRD](docs/PRD.md) · [TRD](docs/TRD.md) · [Architecture](docs/ARCHITECTURE.md) · [Design system](docs/DESIGN_SYSTEM.md) · [File structure](docs/FILE_STRUCTURE.md) · [Changelog](CHANGELOG.md)

## Scripts (no app)

`daily-log.sh` + `daily-log.py` do the same job without the app: a launchd job opens a Notion-style page in the browser. Run `./daily-log.sh install`.
