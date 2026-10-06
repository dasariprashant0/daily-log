# PRD: Daily Log

**Status**: v1 built, compiled, not yet launched or UI-tested
**Author**: Prashant Dasari  **Version**: 1.0
**Platform**: macOS 13+, SwiftUI, single file (`app/DailyLog.swift`), built with Command Line Tools only

---

## 1. Problem

I end most working days unable to say what I actually did, what is stuck, and what to pick up tomorrow. Marketing/web work is fragmented (many small tasks, many tools), so context evaporates overnight and Monday-morning re-orientation costs time. Optional journalling does not stick; a habit needs a prompt and a small enforced structure.

**Evidence**: personal experience only (n=1). No usage data yet. Treat this as a hypothesis, not a validated need.

## 2. Goals

1. Make the end-of-day write-up a habit: the app prompts at a fixed time and keeps prompting until it is done.
2. Keep the write-up structured and short: five fixed sections, no free-form blank page.
3. Keep data mine and portable: plain markdown on disk, no account, no cloud.
4. Be shareable with a handful of colleagues/friends without an installer or developer account.

## 3. Non-Goals (v1)

- Sync, multi-device, or any cloud storage.
- Notion (or any other) integration.
- Weekly or periodic summaries, search, tags, analytics.
- Weekends or custom workdays (Mon-Fri is hard-coded).
- Team features, sharing logs, or manager visibility.
- Notarisation, App Store distribution, auto-update.

## 4. User Stories

- As a knowledge worker, I want the app to open at my reminder time so I do not rely on remembering.
- As the same user, I want all five sections required so I cannot skip the uncomfortable ones (Pending/blocked, To do next).
- As the same user, I want logs as plain markdown files so I can grep, back up, or paste them anywhere.
- As the same user, I want to browse and edit past days in a sidebar so I can reread last week or fix a mistake.
- As a colleague receiving the zip, I want to install it with one right-click > Open and no terminal.

## 5. Functional Requirements

| # | Requirement | Priority |
|---|-------------|----------|
| F1 | Each day has five sections: What I did, Finished, Started, Pending / blocked, To do next. | Must |
| F2 | "Save log" is disabled until all five are non-empty (whitespace-only counts as empty). A "n/5 filled" counter shows progress; "Saved" confirms. | Must |
| F3 | Save writes `~/daily-log/YYYY-MM-DD.md` (one file per day, `# date` heading then one `## ` heading per section); creates the folder if missing; surfaces write errors inline. | Must |
| F4 | A day counts as logged only if all five sections in its file are non-empty. | Must |
| F5 | Reminder time defaults to 4:55pm, applies Mon-Fri only, and is changeable via a time picker in the UI; the setting persists. | Must |
| F6 | At or after the reminder time on a weekday with today unlogged, the window comes to the front and the app activates (once at first trigger). | Must |
| F7 | While today is unlogged, a 60-second check re-opens the window if it was closed or minimised. It does not re-steal focus if the window is already visible. | Must |
| F8 | App keeps running when the window is closed (no quit on last-window-close); ⌘Q quits. | Must |
| F9 | App registers itself as a login item on launch so the reminder can fire after reboot. | Must |
| F10 | Sidebar lists Today plus all past days found in the folder, newest first, with a check icon when logged and an empty circle when not. | Must |
| F11 | Past days are editable and re-saved under the same all-five-required rule. | Should |
| F12 | "Open folder" button reveals `~/daily-log` in Finder. | Should |
| F13 | Notion-style page layout (large title, section headings, borderless-feeling text blocks, min window 820x600). | Should |
| F14 | Ad-hoc signed zip produced by `app/build.sh`; README documents right-click > Open and the `xattr` workaround. | Must |
| F15 | Configurable workdays (weekday picker). | Could (v1.1) |
| F16 | Notion export, weekly summary, notarisation, app icon. | Won't (v1) |

## 6. Success Metrics

Realistic for a one-person tool; self-reported, no telemetry.

| Metric | Target | Window |
|--------|--------|--------|
| Weekdays with a saved log (excluding leave) | >= 80% | First 4 weeks |
| Logs saved within 60 minutes of the reminder | >= 70% of saved logs | First 4 weeks |
| Still using it unprompted by me | Yes | 8 weeks |
| Colleagues/friends who install and are still using it after 2 weeks | >= 2 of those who receive it | 4 weeks after sharing |
| Install friction: recipients who got it running without my help | >= 75% | At sharing |

Kill signal: if I am regularly dismissing it with junk text to unlock Save, the required-sections rule is producing noise, not value. Revisit F2.

## 7. Assumptions

- The Mac is awake and the app is running at reminder time.
- A forced, repeating window is acceptable to me; it may be annoying to others.
- Five sections suit most knowledge workers' days.
- Recipients are comfortable with right-click > Open (or one `xattr` command).
- The `~/daily-log` folder is not sandboxed or blocked by macOS permissions.
- Wall-clock local time and system calendar are correct (travel and time-zone changes shift the reminder with the system clock).

## 8. Risks

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| App never launched or UI-tested; compile-only so far. Layout, focus-stealing, login-item registration, and reminder timing are unverified. | High | High | Run it before sharing. Smoke test: save, relaunch, change reminder time to now+2 min, close the window, confirm it re-opens. |
| Gatekeeper blocks unnotarised app; some recipients get stuck or distrust it. | High | Medium | README instructions; notarisation in roadmap (needs paid Apple Developer account). |
| Nagging is too aggressive (re-opens every minute-check when closed) and pushes users to quit the app, which silences it. | Medium | Medium | Gather feedback; consider snooze or a "skip today" option. |
| Mac asleep or app quit at reminder time: no reminder fires. | Medium | Medium | Known limit. Reminder also fires on launch if past due time and unlogged. |
| User text containing a line starting with `## ` splits a section on reload. | Low | Medium | Documented in code. Use another prefix or escape on save. |
| Required sections push junk input ("n/a"). | Medium | Low | Accept for v1; watch metric kill signal. |
| Login-item registration may need user approval in System Settings on some macOS versions. | Medium | Low | Verify on macOS 13 and latest; document in README. |
| `build.sh` and CLT-only build are unproven for other machines/architectures (no mention of universal binary). | Low | Medium | Confirm arm64/x86_64 target before sharing. |

## 9. Open Questions

- [ ] Does the nag feel supportive or hostile after a week of real use? (Owner: me, after week 1)
- [ ] Should weekends/leave be skippable without disabling the app? Is a weekday picker enough, or do I need "skip today"?
- [ ] Should past days with partial content be saveable as drafts, or is all-five-required for every day too strict?
- [ ] Is it worth paying for an Apple Developer account just to notarise a tool shared with a few friends?
- [ ] Do recipients want the shell/launchd script variant (`daily-log.sh` + `daily-log.py`) instead? It exists in the repo but is out of scope for this PRD.
- [ ] Where do logs go when I want Notion: manual paste, or an automated export?

## 10. Roadmap

Ordered by my guess of value. Each is gated on v1 being used for 2+ weeks.

| Version | Item | Why / trigger |
|---------|------|---------------|
| v1.0 (now) | Launch and UI-test it myself; fix what breaks | Blocks everything else, including sharing |
| v1.1 | Weekday picker (replace hard-coded Mon-Fri) | Anyone with a non-standard week or a weekend shift |
| v1.1 | App icon | Cheap polish before sharing widely |
| v1.1 | Weekly Claude summary of the week's logs | Highest-leverage use of the stored data; needs a decision on where the text is sent (logs may contain company data) |
| v1.1 | Notion export | Only if I keep copy-pasting into Notion by hand |
| v1.2 | Notarisation | Only if more than a handful of people install it |
