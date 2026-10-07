# Gloamlog

**A private Mac work journal for the end of your day.** One calm, Notion-style page per day, saved as plain markdown on your Mac. No account, no cloud, no telemetry.

> **Status: early development (v0.3), not ready for everyday use yet.** The engine and editor work and are tested, but the app is being rebuilt around real daily use: catching up on past days and weeks, quick capture, review and export, sync, and reminders. See [what's next](#whats-next).

## What works today

- **A page per day** with headings, bullets, to-do lists, quotes, code, tables, links and images. Type `/` for the block menu, or use markdown shortcuts (`# `, `- `, `[] `, `> `).
- **Autosave, no Save button.** Safety copies of your page are kept automatically, and you can restore a previous version.
- **An optional template** of headings for your day (the default is *What I did / Finished / Started / Pending / To do next*). Edit it in Settings, or use a blank page.
- **A "logged" rule that you set:** a day counts once you have written a minimum number of words.
- **Reminders:** a strict or gentle end-of-day reminder, snooze, and skip days (holiday, leave).
- **Streak, 12-week heatmap, search, weekly review** with "Copy as markdown" for standups.
- **Carry over** yesterday's to-dos and pending items into today.
- **Menu bar item** showing whether today is logged.

Your logs are ordinary files, one per day: `~/Gloamlog/2026-10-07.md`. Images you add go in `~/Gloamlog/assets/`. You can move the folder to iCloud Drive or Dropbox in Settings, and open the files in any editor.

## Privacy

Everything stays on your Mac. The app makes **no network requests**: the editor is bundled with the app and runs under a Content-Security-Policy that blocks all network access. There is no account and no analytics. Third-party code in the editor is MIT-licensed and listed in [THIRD_PARTY_LICENSES.md](THIRD_PARTY_LICENSES.md).

## Build from source

Needs macOS 13 or later and the Xcode Command Line Tools (`xcode-select --install`). Full Xcode is **not** required.

```bash
git clone https://github.com/dasariprashant0/gloamlog.git
cd gloamlog
bash app/build.sh        # builds app/Gloamlog.app (ad-hoc signed)
open app/Gloamlog.app
```

Run the tests:

```bash
bash tests/run-tests.sh                 # core logic
bash app/Tools/editor-check/run.sh      # the editor inside a real WebKit view (run from a normal terminal)
```

The editor is a prebuilt bundle (`app/Resources/editor/index.html`), so you only need Node if you change the editor itself (`cd editor-web && npm ci --ignore-scripts && npm run build`).

## What's next

The plan is driven by how the app is actually used: write at the end of the day, jot notes through the day, and catch up on missed days and weeks.

1. **Real-world flows:** a calendar and a "catch up" list for missed days, so you can write any past day or week; a fuller Settings window.
2. **Quick capture** from anywhere, **review** by week, month and year, **export** and share, **search** that holds up across years.
3. **Sources:** an editable activity list from your Claude Code sessions and Git commits.
4. **Sync** across Macs through a shared folder, and **reminders** that work when the app is closed.
5. A **notarised release** and a Homebrew install.

Details: [docs/STRATEGY.md](docs/STRATEGY.md). Contributions are welcome once the foundations settle; see [CONTRIBUTING.md](CONTRIBUTING.md).

## Docs

[Strategy](docs/STRATEGY.md) · [PRD](docs/PRD.md) · [Roadmap](docs/ROADMAP.md) · [Architecture](docs/ARCHITECTURE.md) · [TRD](docs/TRD.md) · [Editor contract](docs/EDITOR_CONTRACT.md) · [Design system](docs/DESIGN_SYSTEM.md) · [Changelog](CHANGELOG.md)

Some of these predate the v0.3 editor and are being rewritten.

## License

[MIT](LICENSE). Not affiliated with Anthropic.
