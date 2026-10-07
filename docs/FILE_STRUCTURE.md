# File structure

```
daily-log/
├── README.md              Overview, build, share
├── CHANGELOG.md           Release notes
├── .gitignore             Ignores build outputs (app/Gloamlog.app, app/Gloamlog.zip)
├── daily-log.sh           Script version: `install` writes a launchd job (Mon–Fri 4:55pm), run opens the page
├── daily-log.py           Script version: local Notion-style web form, stdlib only
├── app/
│   ├── Gloamlog.swift     The whole Mac app (Store, AppDelegate/reminder, views)
│   └── build.sh           swiftc → Gloamlog.app → ad-hoc codesign → Gloamlog.zip
└── docs/
    ├── ABOUT.md           What this is and why
    ├── EXPLANATION.md     How it works, in plain language
    ├── PRD.md             Product requirements
    ├── TRD.md             Technical requirements and decisions
    ├── ARCHITECTURE.md    Components and data flow
    ├── DESIGN_SYSTEM.md   Typography, colour, spacing, components
    └── FILE_STRUCTURE.md  This file
```

Generated, not committed: `app/Gloamlog.app/`, `app/Gloamlog.zip`.
Runtime data, outside the repo: `~/Gloamlog/YYYY-MM-DD.md`.

`Gloamlog.swift` is deliberately one file (~200 lines). Split it only if it grows past comfortable reading.
