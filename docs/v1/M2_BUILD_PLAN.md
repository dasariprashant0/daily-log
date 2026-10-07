# M2 Implementation Plan: Quick capture ("Jot") (0.5.0)

> **For agentic workers:** use the same working rules as `M1_BUILD_PLAN.md` sections 0 and 3 (frozen contracts, file ownership, test-first in `app/Core`, real-window evidence, no git, no macros, no network).

**Goal:** press a key in any app, type a thought, press Return, and find it as `- 14:32 call with Sam about pricing` under `## Jots` at the bottom of today's page, without ever losing a note or touching what the user is typing. Acceptance: `PRD_V1.md` M2-A1 to A7 (read them) and the owner check under M2.

**Design source:** `ARCHITECTURE.md` section 5.D (single-writer model, journal, `DayWriter`, `appendToSection`, hotkey and panel), `UX_FLOWS.md` (jot flow, copy), `DESIGN_V4.md` section 8 (panel, menu-bar field, dimensions). **Lean cuts** (deferred, listed so nobody builds them): the full `PageSync` state-machine extraction, spill files, compare-and-swap conflict handling and the model-based fuzz (M5b). The open-page path instead calls the editor's own transaction and relies on the existing autosave and data-safety guards.

---

## 1. Frozen contracts (already in the tree as compiling stubs)

`app/Core/Capture/CaptureTypes.swift` (final, not a stub): `CaptureItem`, `HotKeySpec` (`defaultJot` = control-option-J, keyCode 38, modifiers 0x1800), `CapturePrefs` (`hotKey?`, `timestamps`, `todoShorthand`, `jotsHeading`, `jotsCountTowardLogged`), `JotAppendResult`, `PageHandle`, `EditorLookup`, `CaptureReceipt`. `Settings.capture: CapturePrefs` exists.
Stubs to implement behind frozen signatures: `CapturePlacement` (`render`, `apply`, `contains`), `CaptureJournal` (`append`, `ack`, `pending`, `compact`), `DayWriter` (`capture`, `replayJournal`, `waiting`, `acknowledgeSaved`), `MarkdownBody` extension in `MarkdownBody+Jots.swift` (`counts`, `isJotsOnly`, `stripUntouchedTemplate`, `loggedWords`). Read each file's header comment: it is the specification.

**Editor bridge addition** (owned by stream E; documented in `docs/EDITOR_CONTRACT.md` when done). Swift calls `DailyLogEditor.appendToSection(callId, token, heading, markdown, {unlessPresent: true})`; the editor answers with a bridge message `{type: "appendResult", id: callId, result: "appended" | "alreadyPresent" | "stale", markdown: <normalised document markdown>}`. Rules: `token` is the page token set by `setMarkdown`; a mismatch returns `stale` and changes nothing. It runs ONE ProseMirror transaction on the live document: find the first heading whose normalised text equals `heading` (any level) and append `markdown` (one list item line) at the end of that section's content (extend the last bullet list when the section ends in one, else add a list); with no such heading, add `## <heading>` and the list at the end of the document. `unlessPresent` returns `alreadyPresent` when an identical list item already exists in that section. The caret, selection, scroll position and undo history of the user are untouched; the call must NOT emit a `change` message (Swift schedules the save itself). The appended note is undoable with ⌘Z like any edit.

**Logged rule:** jots never make a day "logged" unless `capture.jotsCountTowardLogged` is on. A page that is only a Jots block reads "started" (partial), not logged; the editor shows the template headings above the jots (editor-only) and never writes the template back.

---

## 2. Streams and ownership

| Stream | Owns (may edit) | Must not touch |
|---|---|---|
| **K Core** | `app/Core/Capture/**`, `app/Core/LogStore.swift`, `Models.swift`, `MarkdownBody.swift`, `WeeklyReview.swift` (only for the jots rule), `tests/**` | `app/UI/**`, `editor-web/**`, docs |
| **E Editor** | `editor-web/**`, `app/Resources/editor/index.html`, the Bridge sections of `docs/EDITOR_CONTRACT.md` | Core, UI, tests/ |
| **U UI and platform** | new `app/UI/HotKey.swift`, `JotPanel.swift`, `JotView.swift`, `ShortcutRecorder.swift`, `AppModel+Capture.swift`, `EditorBridge+Capture.swift`; and edits to `DayEditor.swift`, `AppModel.swift`, `AppModel+Editor.swift`, `EditorBridge.swift`, `MenuBarView.swift`, `SettingsPaneShortcuts.swift`, `AppCommands.swift`, `Sidebar.swift` (notes-waiting indicator only), `app/Tools/editor-check/ScenarioCapture.swift` | Core, editor-web, docs |
| **Orchestrator** | docs, README, CHANGELOG, `app/Tools/editor-check/main.swift`, `build.sh`, commits | |

Streams overlap: U compiles against the stubs now and works end to end when K and E land. If another stream's half-finished file breaks the build, wait 3 minutes and retry (up to 5 times).

---

## 3. Stream K: Core (tasks K1 to K4), test-first

- **K1 `CapturePlacement` and the Jots rules.** `render`, `apply`, `contains`, `counts`, `isJotsOnly`, `stripUntouchedTemplate`, `loggedWords` exactly as the header comments say. Tests: block in the middle / last / missing; last line a list vs a paragraph; markers in the text (`# x`, `- x`, `1. x`, `> x`) are escaped; `[]` to-do renders `- [ ] text`; multi-line note (continuation indent); a template page; `### Jots` and `# Jots` headings; case and emoji in the heading; idempotence (`contains` after `apply`); jots-only detection; the template-above-jots round trip (`stripUntouchedTemplate(template + "\n\n" + jots) == jots`, a page with the user's own text is returned unchanged).
- **K2 `CaptureJournal`.** `journal.jsonl`, mode 0600, fsync (F_FULLFSYNC) on append, ack lines, `pending()` tolerant of a torn last line and garbage, `compact()`. Tests: append-ack-pending; torn last line; unknown line; 2,000 items compact; unwritable directory throws; file mode is 0600.
- **K3 `DayWriter`.** Routing exactly as the header comment: normalise (trim, strip control characters except newline, cap 4,000, `[]` shorthand, time stamp from the injected clock and calendar), journal first, then page-open path (through `EditorLookup`/`PageHandle`), no-open-page path (load, `apply`, `LogStore.save`, ack), failure path (note stays, `waiting > 0`). Tests with fake `PageHandle` and a real `LogStore` on a temp folder: every `JotAppendResult` case; `.stale` re-routes once; unwritable folder keeps the note and `replayJournal` delivers it once the folder returns; replay is idempotent (no duplicate lines); `acknowledgeSaved` acks only notes whose line is in the written body; crash between journal append and save (simulate by dropping the writer) recovers on the next `replayJournal`; midnight (note captured at 23:59 belongs to that day).
- **K4 Logged rule.** `LogStore` (and `DayDocument`) use `loggedWords` so jots do not count: add `LogStore.jotsRules` (heading, countTowardLogged; defaults heading "Jots", false) that the app sets from `Settings.capture`; `fileStates(minWords:)`, `DayDocument.status`, streak, heatmap, week summary and catch-up follow it. A jots-only day is `.partial`. Tests: jots-only page is partial; jots plus 20 real words is logged; with `countTowardLogged` on a jots-only page of 20 words is logged; existing 1,271 tests stay green (change an assertion only if it encoded the old behaviour, and say which).

**Checkpoint K:** `bash tests/run-tests.sh` all pass, no warnings; no `STUB` left in `app/Core/Capture`.

## 4. Stream E: Editor bundle (task E1)

- **E1 `appendToSection`.** Implement per the bridge addition above in `editor-web/src/main.js` (plus `theme.css` only if needed), add fixtures and checks to `editor-web/test/` (append under an existing heading, extends an existing list, missing heading, `unlessPresent`, `stale` token, a template page, an empty document, undo restores the previous document, caret and selection unchanged, no `change` emitted, idempotent normalisation afterwards), rebuild the single-file bundle (`cd editor-web && npm run build`; local `node_modules` exists, no network needed, only registry.npmjs.org would be allowed if something is missing), update the Bridge sections of `docs/EDITOR_CONTRACT.md` and the CSP hash note. Verify in the built-in browser harness as before and then run `bash app/Tools/editor-check/run.sh` outside the sandbox to confirm the host checks still pass.

**Checkpoint E:** editor test page all PASS; new bundle size reported; host check passes.

## 5. Stream U: UI and platform (tasks U1 to U6)

- **U1 Hotkey.** `HotKey.swift`: `HotKeyCenter` using Carbon `RegisterEventHotKey` (no permission needed), `register(_:)` returning an `OSStatus` (`-9878` = taken by another app), `unregister()`, `isAllowed(_:)` (needs control or command; refuse option-only and option-shift-only), main-queue callback. Registers from `Settings.capture.hotKey` at launch and re-registers when it changes.
- **U2 Panel.** `JotPanel` (`NSPanel`: `.nonactivatingPanel`, `canBecomeKey`, `.floating`, `.canJoinAllSpaces` and `.fullScreenAuxiliary` so it shows over full-screen apps) hosting `JotView` (SwiftUI): header "Jot to Today" with the time, a multi-line field (Return saves, ⇧Return adds a line, Esc cancels and writes nothing), the 520 pt width and tokens from `DESIGN_V4.md` section 8; focus returns to the previous app on close; shows "Kept on this Mac, will be added when the folder is back" when `receipt.waiting > 0`; announces the result to VoiceOver.
- **U3 Wiring.** `AppModel+Capture.swift`: create `CaptureJournal` (Application Support), `DayWriter` (store, prefs from settings, clock, calendar), implement `EditorLookup` over the current editor and orphan editors; `jot(text:source:) -> CaptureReceipt?`; published `notesWaiting`; `replayJournal()` on launch, app activation, wake, folder change and when the folder returns; call `writer.acknowledgeSaved(day:body:)` after every successful page save; set `LogStore.jotsRules` from settings. `DayEditor` conforms to `PageHandle`: `appendJot` calls the bridge (`EditorBridge+Capture.swift`, token handling, `.stale` when the page was swapped, `.notLoaded` before load) and, on `.appended`, adopts the editor's normalised markdown as the latest text and schedules the normal autosave (no save before the page is ready, same guards as today).
- **U4 Jots-only page.** `DayEditor.initialBody` shows the template above a jots-only page (`MarkdownBody.isJotsOnly`) and `writable` applies `stripUntouchedTemplate` so the template is never written back; a jots-only day reads "started" in the header and sidebar. Keep every v0.3 data-safety guard.
- **U5 Entry points.** A 32 pt **Jot** field in the menu-bar popover (Return adds, shows "Added" for 600 ms), `Jot...` in the Page menu (with the recorded shortcut shown) and the Dock menu if cheap; a quiet "N notes waiting" indicator when `notesWaiting > 0`.
- **U6 Shortcuts pane and scenarios.** In `SettingsPaneShortcuts.swift`: a shortcut recorder (record, `Off`, `Reset`), an error "Already used by another app" when registration returns `-9878`, takes effect at once; switches for time stamps, to-do shorthand ("[]" at the start makes a task) and "Jots count toward logged". `ScenarioCapture.swift` with `runCaptureScenarios()` (hooked from `main.swift`, already stubbed): M2-A2 (type and Return writes `- HH:MM text` under `## Jots` within 2 s), A3 (page open with typed text: untouched, note appears, undo works), A4, A5, A6 (unwritable folder then restore: delivered once), A7 (re-record and off), journal replay after a simulated crash, plus real screenshots of the panel, popover field and Shortcuts pane (light and dark) saved to the evidence directory the orchestrator names. You cannot press a global hotkey in this harness: test the registration result and the callback path, and say so.

**Checkpoint U:** `bash app/build.sh` clean (no warnings); `bash app/Tools/editor-check/run.sh` all pass including the capture scenarios; screenshots viewed.

---

## 6. Integration and the owner check (orchestrator)

- [ ] Merge check with all three checkpoints; `bash tests/run-tests.sh`, `bash tests/run-kill-tests.sh`, `bash app/build.sh`, `bash app/Tools/editor-check/run.sh` all green together.
- [ ] Add a kill test for the journal (append, kill -9, relaunch, pending equals what was acknowledged by the writer).
- [ ] Owner's hands-on check (PRD M2): press the shortcut in the apps you really use (including a full-screen one); jot 3 notes and open today's `.md` in Finder; type in today's page then jot: nothing lost; rename the log folder, jot, rename it back: the note arrives; change the shortcut in Settings and see the old one stop.

## 7. Risks

| Risk | Mitigation |
|---|---|
| Global hotkey or panel behaves differently in full-screen apps on the owner's Mac | `.fullScreenAuxiliary` plus `.canJoinAllSpaces`; listed as unverified in the report; first item of the owner check |
| A note lands while the editor is mid-save | the editor transaction plus the existing autosave and `acknowledgeSaved`; the journal makes loss impossible even if the route fails |
| Bridge change breaks the editor | E1 reruns the host check; stale-token path tested |
| Option-only hotkeys are rejected by the system | `isAllowed` refuses them; default is control-option-J |
