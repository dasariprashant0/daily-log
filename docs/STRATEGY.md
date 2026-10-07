# Strategy

Synthesis of the four research reports in `docs/research/` (market, growth, SEO, Claude integration). Claims below are the reports' claims, dated 2026-10-06; none were independently re-verified except that the name `gloamlog` is unused on GitHub.

## Decision summary
- **Name:** Gloamlog (from "gloaming", dusk: the log you write at the end of the day). "Gloamlog" collides with 4+ projects and cannot rank. The name must never contain "Claude".
- **One line:** *A private Mac work journal for the end of your day. It fills itself in from your Claude Code sessions and git commits, so writing it up takes two minutes.*
- **Audience:** Mac professionals who run Claude Code several times a day and have to account for their work (standups, weekly updates, reviews). Product is general-purpose; marketing is developer-first.
- **Positioning:** a "flight recorder" for AI-assisted work. Private, local, markdown. Not a screen recorder, not an agent wrapper, not a usage monitor.

## What the evidence says
1. The pain is real: people cannot reconstruct what they did, and agent sessions sprawl and vanish. Claude Code deletes transcripts after 30 days; related GitHub issues have dozens of reactions.
2. The niche is crowded. Dayflow (native, MIT, ~7k stars) already ships a one-click standup from screen activity; a dozen newer repos summarise Claude Code sessions; Anthropic ships `/recap`, `/insights` and `/resume`. No session-narrative tool has broken out (all under ~340 stars).
3. Manual log and journal tools get little attention; zero-effort capture wins.
4. "Claude desktop" chats are server-side and not readable by a local app. Readable: Claude Code transcripts (CLI, VS Code, the Desktop Code tab) and Cowork. Regular chat can only reach the log through an MCP tool the user adds.
5. Notarisation is now a distribution requirement (official Homebrew casks disabled 600 un-notarised apps on 2026-09-01; right-click-Open no longer works on macOS 15+).
6. Growth is one prepared launch plus slow compounding. Stars understate real use for mature apps and overstate it for new ones.

## Product pillars
1. **Write it in two minutes.** A calm Notion-style page (headings, lists, to-dos, images, `/` menu), an optional template, autosave, a "logged" rule by word count, strict or gentle reminders, skip days. *(v0.3, in progress.)*
2. **It fills itself in.** "Sources" read what actually happened (Claude Code transcripts first, then git) and offer an editable, evidence-linked activity list you insert with one click. Always read-only, redacted, per-project allow/deny. *(v0.4.)*
3. **Never lose it.** Plain markdown on disk, versioned backups, an opt-in archive of session text beyond Claude Code's 30-day purge.
4. **Private by construction.** No network, no telemetry, no account, everything opt-in, exact-bytes preview before anything leaves the machine.

## Roadmap order
| Release | Content | Gate |
|---|---|---|
| 0.3 | Notion-style editor, declutter, autosave + backups, Gloamlog rename | you have run it and it feels right |
| 0.4 | Sources: Claude Code activity digest + git commits, redaction, per-project allow/deny, "Add a source" contributor guide | tests on synthetic fixtures; you confirm the transcript layout on your Mac |
| 0.5 | `Gloamlog --mcp` (log from Claude Desktop/Code chat), per-click "Draft with claude -p" with preview, optional Claude Code hook | consent UI reviewed |
| 1.0 | Notarised, Homebrew tap, landing page, demo GIF, sample-data mode | Apple Developer enrolment (yours) |

## Launch (details in `docs/research/GROWTH.md` section 5)
Soft launch to ~10 people first. Then one prepared Show HN from your own account (human-written post), then r/ClaudeAI and others one at a time, then lists (awesome-claude-code needs the repo to be 14+ days old or 100+ stars; official Homebrew cask needs notability and a 30+ day repo). Claim "writes itself from your Claude sessions" only once Sources ships.

## Will not do
Screen recording, accounts, cloud sync service, telemetry, team dashboards, wrapping or orchestrating agents, using Claude subscription tokens, "Claude" in the name.

## Needs you (I cannot do these)
- Apple Developer Program enrolment ($99/year) for notarisation.
- Record the demo GIF once the app feels right; post the Show HN and community posts yourself.
- Confirm where Desktop Code-tab/Cowork transcripts live on your Mac (structure-only commands in `docs/research/CLAUDE_INTEGRATION.md`, Appendix A).
- Optional: buy `gloamlog.dev` or `.app` for the landing page.

## Key risks
Anthropic absorbing the feature; unstable transcript format (mitigate with a defensive parser and fixtures); secrets inside transcripts (redaction, opt-in per project); crowded niche (test with the soft launch before investing in polish).
