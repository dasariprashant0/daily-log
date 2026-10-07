# Market research: native macOS, open-source work journal / daily log / standup helper

Prepared 2026-10-06. Project working title: "daily-log" (placeholder only; it collides with several existing things, see section 5).
Hook under test: "auto-draft your day from your Claude Code / Claude desktop sessions". Treated as a hypothesis to test, not a spec.

## How to read this document

- A claim with a link is sourced. **[Inference]** marks my own synthesis. **[Unverified]** marks a single weak source or something I could not confirm.
- GitHub stars, licences, created and last-push dates were read from `api.github.com` on 2026-10-06. Stars are a popularity proxy, not a user count.
- Hacker News (HN) figures come from the thread pages. HN dates marked "approx." are derived from relative timestamps ("9 months ago") on 2026-10-06.
- Quotes are under 15 words each and carry their URL. Each quoted string was re-checked against the page by an exact-string lookup; the fetch tool summarises pages with a small model, so verify against the source before reusing any quote publicly.
- Strengths and weaknesses are my synthesis of the cited pages unless a source is attached. Closed-source products show "n/a" for stars.
- Not accessible in this session: Reddit (blocked for both search and fetch), the HN Algolia API (blocked by a network filter), X post pages (HTTP 402). See section 2.4 and Appendix B.

---

## 0. Executive summary

**Verdict.** The underlying pain (cannot reconstruct what I did; agent sessions sprawl and then vanish) is real, current and well evidenced. The idea as phrased is weaker than it looks, for three reasons.

1. **The space is already crowded.** The closest competitor, Dayflow, is a native, MIT-licensed Mac app with 7,234 stars that already ships a one-click standup. At least 14 related repos were created in 2026 among the ones I sampled. Anthropic itself ships `/recap` (Apr 2026), `/insights` (Feb), agent view (May) and Desktop `/resume` (Aug).
2. **"Claude desktop sessions" is mostly not a readable source.** Ordinary Claude chats are server-side and export-only (per export guides; the official local-storage page I could read covers only the third-party deployment variant). What is locally readable is Claude Code transcripts (`~/.claude/projects`, shared by the CLI, VS Code and the Desktop Code tab) and Cowork sessions. Reframe the hook as "Claude Code + Cowork", not "Claude desktop".
3. **Nobody has broken out with "narrative day log from agent sessions".** Every such tool I found has 339 stars or fewer. The big hits in the ecosystem solve agent memory (claude-mem, 96,877 stars), orchestration (vibe-kanban, 28,267), and usage anxiety (CodexBar 22,219; ccusage 18,894). That is either an open gap or a sign that demand is thinner than the pain. Public data cannot tell which.

What looks genuinely unserved is a **native, open-source, privacy-first app that turns agent sessions plus git/PR/calendar evidence into an editable, evidence-linked daily draft, and keeps a durable archive past Claude Code's 30-day purge**. The moat would be execution (trust, summary quality, UX), not capture, because capture is trivial to copy. First-party absorption by Anthropic is the main strategic risk.

### Hypothesis scorecard

| # | Hypothesis | Verdict | Confidence | Why (short) |
|---|---|---|---|---|
| H1 | People lose track of what they did, and AI sessions make it worse | Supported | High | GitHub data-loss issues with 31-51 reactions each; HN threads; Anthropic shipped agent view and recap |
| H2 | "Claude desktop sessions" are a readable input | Mostly false as phrased | Medium-High | Regular chats are server-side per secondary sources; Code tab transcripts live in `~/.claude/projects` and Cowork sessions are local files per Anthropic docs |
| H3 | The niche is open | False as phrased; the specific combination may be open | High / Medium | 14+ new repos in 2026; Dayflow, Contextify, Claudoscope, agentsview, vibe-log, clerk exist |
| H4 | "Auto-draft the day" alone is enough reason to install a new app | Unproven | Low-Medium | Manual-log tools get 1-3 HN points; DIY `/standup` skills are plentiful; Dayflow got 480 points with zero-effort capture |
| H5 | Native macOS is an advantage | Partly | Medium | CodexBar (native Swift) has 22k stars; but Mac is about one third of professional developers and cross-platform requests appear on Dayflow |
| H6 | Open source is an advantage | True for trust, unclear for sustainability | Medium | HN privacy objections favour local and auditable; rivals monetise via Pro tiers; forks are cheap |
| H7 | Anthropic will not build this itself | Doubtful | Medium | Recap, insights, agent view, Desktop resume, Routines, Cowork scheduled tasks, commit session links all shipped in 2026 |

### Recommendations in brief

1. Reframe the hook: "Claude Code (CLI, VS Code, Desktop Code tab) + Cowork", then Codex CLI second.
2. Lead with durability and trust (archive past 30 days, on-device summarising, redaction). Use the standup and brag drafts as the daily payoff.
3. Keep scope tight: no screen recording, no agent wrapper or orchestration, no team dashboards.
4. Do not put "Claude" in the name. Never use subscription OAuth tokens. Default to on-device or bring-your-own-key.
5. Before building, run the cheap kill test in Appendix C.

---

## 1. Competitive landscape

### 1.1 The closest competitors (what you actually have to beat)

| Tool | What it is, with numbers | Why it matters | Weak spot against this idea |
|---|---|---|---|
| **Dayflow** | Open-source (MIT), native Swift Mac app. Records the screen (about one frame per 10 s), a vision model writes a timeline, daily and weekly summaries, chat, and a one-click standup (yesterday / today / blockers). 7,234 stars, 441 forks, created 2025-09-23, last push 2026-09-25 ([API](https://api.github.com/repos/JerryZLiu/Dayflow), [README](https://github.com/JerryZLiu/Dayflow)). Free with your own keys or local models; Pro $20/mo (managed AI); Enterprise custom ([pricing](https://www.dayflow.so/pricing/)). Show HN: 480 points, 130 comments, 2025-09-24 ([HN](https://news.ycombinator.com/item?id=45361268)) | Proves demand for a zero-effort "automatic work journal" and already owns the "standup helper" claim on Mac. Uses Ollama/LM Studio, Gemini, or the user's local ChatGPT/Claude CLIs as providers. Site claims YC backing [Unverified vendor claim] | Needs Screen and System Audio Recording permission. HN commenters raised employer-surveillance, battery/CPU and multi-monitor problems, and one rated local-model accuracy well below Gemini (paraphrase). README mentions no Claude Code, Cowork or git ingestion. It infers intent from pixels, not from what the agent actually did |
| **Contextify** | macOS app (15+; summaries need macOS 26), Windows 11, Linux CLI. Indexes Claude Code and Codex sessions into a searchable timeline; local Apple Intelligence summaries; "Total Recall" lets Claude search its own past sessions ([site](https://contextify.sh/), [HN](https://news.ycombinator.com/item?id=46209081), 6 points, approx. Dec 2025). Local free; Cloud Pro $12/mo; Local Commercial $77/yr per seat; self-hosted server under FSL ([pricing](https://contextify.sh/pricing)). GitHub repo: 14 stars, licence NOASSERTION, pushed 2026-10-04 ([API](https://api.github.com/repos/PeterPym/contextify)) | Built because Claude Code deletes transcripts after 30 days. Shows people will be asked to pay for "keep history forever" | Proprietary, so not a like-for-like open-source rival. No daily standup or report feature in the site copy I could fetch. Low visibility |
| **Claudoscope** | Native Swift menu-bar app for Claude Code, Cowork and Desktop sessions: cost alerts, per-file diffs, secret scanning, config linting. MIT, 239 stars, created 2026-03-15, pushed 2026-10-04, v1.0.0, macOS 14+ Apple Silicon only, Homebrew cask ([API](https://api.github.com/repos/cordwainersmith/Claudoscope), [README](https://github.com/cordwainersmith/claudoscope)) | The only native open-source Mac app I found that reads Claude Code and Cowork session files | Monitoring and analytics first; README says no automated report generation. Small |
| **agentsview** | Go binary plus Tauri desktop app; indexes 20-50+ agents' sessions into local SQLite with full-text and semantic search, token and cost dashboards. MIT, 6,059 stars, 677 forks, created 2026-02-19, pushed 2026-10-06, v0.44.0 ([API](https://api.github.com/repos/kenn-io/agentsview), [README](https://github.com/kenn-io/agentsview)) | Strongest open-source session archive; could add narratives any week | README (as summarised) lists analytics and search but no standup or daily-narrative feature. Not a native Mac UI |
| **CLI trio: vibe-log, clerk, claude-code-worklog** (plus cc-journal) | vibe-log-cli: "Today's standup" from Claude Code and Codex sessions, 339 stars, MIT, last push 2026-04-19 ([API](https://api.github.com/repos/vibe-log/vibe-log-cli)). clerk: SessionStart/SessionEnd hooks, Claude API summaries to Markdown, daily and weekly reports, 38 stars, GPL-3.0, pushed 2026-05-13 ([API](https://api.github.com/repos/vulcanshen/clerk), [post](https://dev.to/vulcan_shen_acdbffa0285d2/clerk-auto-summarize-your-claude-code-sessions-4m87)). claude-code-worklog: daily/period reports by pure extraction, no LLM, 1 star, Apache-2.0 ([API](https://api.github.com/repos/P4suta/claude-code-worklog)). cc-journal: Go, Anthropic API summaries, 0 stars ([API](https://api.github.com/repos/natefaerber/cc-journal)) | Exactly the target feature, already built, in terminal form | Terminal only; hook and API setup; cost per summary; no review UI; no traction. Suggests many builders scratch this itch while few users adopt [Inference] |
| **BragLog and reflekto.app** | BragLog: Mac/iPhone/iPad brag-doc app, on-device Apple FoundationModels, one-time purchase, closed ([site](https://braglog.app/)). reflekto.app: macOS work log with manual entries, GitHub/GitLab PR sync and an MCP server; free; Show HN 3 points, approx. Feb 2026 ([HN](https://news.ycombinator.com/item?id=46900182)) | Native Mac "work log / brag doc" apps already exist | Manual logging plus PR sync; neither ingests agent sessions |
| **Anthropic first-party** | `/recap` (v2.1.114, Apr 2026), `/insights` (Feb 2026), agent view `claude agents` (May), Desktop `/resume` with search by title, folder or branch (Aug), Routines, Cowork scheduled tasks, Claude-Session links in commits. Timeline in 1.5(e) | The platform owner is moving into this space | Per-session or usage-oriented, not a cross-day narrative; CLI transcripts purge at 30 days by default; Claude-only; not cross-agent |

### 1.2 Journaling and daily-note apps

| Tool | What it does | Price / licence | Stars, last activity | Strengths | Weaknesses for this use case |
|---|---|---|---|---|---|
| **Day One** | Apple-first journal (also Windows/Android); E2E encryption, templates, prompts; Gold adds AI (Daily Chat, summaries). Official CLI with agent skills and an MCP server (needs Silver/Gold) ([guide](https://dayoneapp.com/guides/day-one-for-mac/day-one-mcp-server/)) | Closed. Basic free (1 photo per entry, single device); Silver $49.99/yr; Gold $74.99/yr ([pricing](https://dayoneapp.com/pricing/)). CLI repo GPL-2.0 | CLI repo: 2 stars, created 2026-08-21, pushed 2026-09-28 ([API](https://api.github.com/repos/Automattic/DayOne-Cli)) | Polish, brand, encryption. Now agent-ready, so a natural export target | Personal-life framing; no automatic capture from dev tools; sync and AI paywalled; closed |
| **Obsidian** | Local Markdown vault, core Daily Notes plugin, large plugin ecosystem. Widely paired with Claude Code in 2026 guides, e.g. [Kenneth Reitz](https://kennethreitz.org/essays/2026-03-06-obsidian_vaults_and_claude_code) | App closed-source; free for personal use; Sync $4/mo (annual); Publish $8/mo; optional Commercial licence $50/user/yr ([pricing](https://obsidian.md/pricing)) | Plugin registry repo: 22,016 stars ([API](https://api.github.com/repos/obsidianmd/obsidian-releases)) | Plain-Markdown ownership; ideal sink for generated daily notes | Nothing is captured automatically; setup burden and "tool paralysis" in the HN daily-log thread |
| **Reflect** | Networked notes with daily notes, AI, E2E encryption | Closed. Single plan about $10/mo billed annually ($120/yr), 14-day trial, no free tier, per third-party listings ([costbench](https://costbench.com/software/note-taking/reflect/)); the official pricing URL returned 404 when fetched | n/a | Fast daily-notes UX | Paid; general notes, not work-log or agent-aware |
| **Logseq** | Open-source outliner, journal-first | AGPL-3.0, free | 45,150 stars, pushed 2026-10-06 ([API](https://api.github.com/repos/logseq/logseq)). DB-based 2.0 beta shipped 2026-07-13; file-based "OG" moved to maintenance 2026-04-24, per secondary sources ([kompozy](https://kompozy.io/news/logseq-2-0-db-version-beta), [forum](https://discuss.logseq.com/t/whats-new-with-logseq-db-may-16th-2026/35020)) | Open, local, journal-first | Mid-transition churn (file to database); manual capture; learning curve [Inference] |
| **Apple Journal** | iPhone (iOS 17.2+), iPad and Mac (26.0+); on-device Journaling Suggestions; third-party apps can read the suggestions API ([Wikipedia](https://en.wikipedia.org/wiki/Journal_%28Apple%29)) | Free, bundled, closed | n/a | System integration, on-device privacy | Personal-life signals (photos, workouts, music); no work or developer signals |
| **jrnl** | CLI journal | GPL-3.0, free | 7,334 stars, pushed 2026-10-05 ([API](https://api.github.com/repos/jrnl-org/jrnl)) | Scriptable baseline | Terminal only; manual |

### 1.3 Work-log, standup and brag-document tools

| Tool | What it does | Price / licence | Stars, last activity | Strengths | Weaknesses |
|---|---|---|---|---|---|
| **Geekbot** | Slack/Teams async standup bot with AI insights | Closed. Free up to 10 users; Basic $2.50 per participant per month (list $3) ([pricing](https://geekbot.com/pricing/)). "200,000+ users" is a third-party claim ([standin](https://www.standin.co/blog/async-standup-bots-compared)) [Unverified] | n/a | Established team workflow | Team-owned and chat-bound; you still type the answer; no auto-capture |
| **Standuply** | Slack standups plus agile assistant; Team plan adds Jira/GitHub/Trello integrations | Free up to 3 users, 30-day trial; paid prices did not load when fetched ([pricing](https://standuply.com/pricing)). A listing says about $5/user/mo [Unverified] | n/a | Integrations | Same as Geekbot |
| **DailyBot** | Check-ins across Slack, Teams, Google Chat, Discord | Listings give $2.10-2.50/user/mo, sources disagree [Unverified] ([comparison](https://www.standin.co/blog/async-standup-bots-compared)) | n/a | Platform breadth | Same as Geekbot |
| **Standup.so** | Paste commits or tasks, get Yesterday / Today / Blockers ([HN](https://news.ycombinator.com/item?id=47191964)) | Not checked | small | Zero setup | Manual paste; git-only |
| **git-standup** | CLI that lists your commits across repos for the last working day | MIT | 7,856 stars; created 2016; last push 2025-07-07 (about 15 months stale); repo now at `nilbuild/git-standup` ([API](https://api.github.com/repos/kamranahmedse/git-standup)) | Zero-config, well loved | Git only (misses non-code work and agent reasoning); stale |
| **gitlogg** | Parses git logs of many repos to JSON | MIT | 135 stars; last push 2023-07-07 ([API](https://api.github.com/repos/dreamyguy/gitlogg)) | Data plumbing | Not a standup tool; abandoned |
| **BragLog** | Brag-doc app, quick-log, on-device Apple FoundationModels, Markdown/HTML export, iCloud sync | Closed; one-time purchase ([site](https://braglog.app/), [App Store](https://apps.apple.com/us/app/braglog/id6759666989)) | n/a | On-device privacy, one-time price | Manual logging; no agent or git ingestion; closed |
| **reflekto.app** | macOS work log: manual, auto GitHub/GitLab PR sync, MCP server | Free at launch; licence not stated ([HN](https://news.ycombinator.com/item?id=46900182)) | Show HN 3 points | Local-first, PR evidence, MCP | Tiny traction; no agent sessions |
| **Exceeds, JotChain** | Brag-doc and perf-review log apps (competency tags; summaries) | Free / unknown | HN 2 and 1 points ([Exceeds](https://news.ycombinator.com/item?id=47388823), [JotChain](https://news.ycombinator.com/item?id=46364104)) | Review-cycle framing | Manual; near-zero traction |
| **gitmore** | AI turns git history into weekly status reports and changelogs (Slack/email) | SaaS | HN 1 point ([item](https://news.ycombinator.com/item?id=46216313)) | Hands-off | Git only; SaaS data egress |
| **OSS brag-doc generators** | bostonaholic/reflect (merged PRs and issues to brag doc), promoteme (CLI), brag-ai | MIT / none / MIT | 36 / 6 / 2 stars ([reflect](https://github.com/bostonaholic/reflect), [promoteme](https://github.com/g4rcez/promoteme), [brag-ai](https://github.com/ruancomelli/brag-ai)) | Recurring DIY project | The reflect author notes mentoring and design work leave no PRs ([blog](https://matthewboston.com/blog/i-built-an-ai-tool-to-write-my-brag-document.html)) |
| **Brag Sheet skill + copilot-brag-sheet** (GitHub / Microsoft) | Mines Copilot CLI session logs, git commits and PRs into impact statements; action-result-evidence contract ([skill](https://github.com/github/awesome-copilot/blob/main/skills/brag-sheet/SKILL.md), [repo](https://github.com/microsoft/copilot-brag-sheet)) | MIT | 11 stars; created 2026-04-16; pushed 2026-09-30 ([API](https://api.github.com/repos/microsoft/copilot-brag-sheet)) | Same idea as this project, from big vendors, for another agent | Copilot CLI only; terminal skill |
| **daily-work-log (Worklog.app)** | macOS menu-bar app: end-of-day prompt, calendar dashboard, LLM weekly per-client summary, Markdown in `~/Documents/WorkLog` | No licence file | 0 stars; created 2026-07-20 ([repo](https://github.com/adampolicht/daily-work-log)) | Plain Markdown, simple nudge | Manual; early |
| **DayApp** | macOS offline tasks and notes with auto-journaling | MIT | 6 stars; created 2026-08-12 ([repo](https://github.com/faraz-35/dayapp)) | Native-feeling, offline | Early |

### 1.4 Automatic time and activity trackers

| Tool | What it does | Price / licence | Stars, last activity | Strengths | Weaknesses |
|---|---|---|---|---|---|
| **Timing** | macOS-only automatic time tracker | Closed. Professional $10/mo; Expert and Connect prices not shown in the fetched text; 30-day trial; not on the Mac App Store because of sandboxing; AI summaries in all tiers ([pricing](https://timingapp.com/pricing)) | n/a | Deepest macOS integration, mature | Sees apps and documents, not what happened inside an agent session; subscription |
| **Rize** | Mac/Windows tracker with AI categorisation and focus insights | Closed. $9.99/mo (500 AI credits), $23.99 (1,000), $39.99 (3,000), billed annually; 7-day trial; MCP server and API on Pro+ ([pricing](https://rize.io/pricing)) | n/a | AI categorisation, MCP | Credit-metered AI; no agent-session ingestion |
| **WakaTime** | Editor-plugin time tracking; has a Claude Code plugin tracking time, lines and files for AI coding ([plugin](https://github.com/wakatime/claude-code-wakatime)) | Free (1 week history); Basic $9/mo; Premium $14/mo; Team $21/dev ([pricing](https://wakatime.com/pricing)); CLI BSD-3-Clause | CLI: 460 stars, pushed 2026-10-05 ([API](https://api.github.com/repos/wakatime/wakatime-cli)) | Developer-native; tracks Claude Code, Cursor, Copilot, Codex adoption | Time and line metrics, not narrative; history paywalled; cloud |
| **ActivityWatch** | Open-source cross-platform automatic tracker with extensible watchers | MPL-2.0, free | 19,077 stars; created 2016; pushed 2026-10-06 ([API](https://api.github.com/repos/ActivityWatch/activitywatch)) | Local, mature, extensible. A community Claude Code plugin queries AW data per a [search result](https://www.claudepluginhub.com/plugins/bendrucker-activitywatch-plugins-activitywatch) | App and window events only; no semantic summary; not tied to agent sessions |
| **RescueTime** | Automatic tracking and focus tools | Closed. Focus $7/mo annual ($9 monthly); Solo+ (adds Timesheets) $12/mo annual ($15); free Lite after the 14-day trial ([pricing](https://www.rescuetime.com/pricing)) | n/a | Long-running | Coarse categories; cloud |
| **Screenpipe** | Records screen and audio, local search, "pipes" plugins, MCP into Cursor and Claude Code; now marketed to enterprises (repo description says "YC (S26)") | Source-available "Screenpipe Commercial License"; personal use free; Free/Basic/Business plans ([README](https://github.com/screenpipe/screenpipe)) | 21,828 stars; pushed 2026-10-06 ([API](https://api.github.com/repos/screenpipe/screenpipe)) | Powerful; large community | Not OSI open source; heavy capture; drifting to enterprise |
| **Rewind / Limitless** | Mac lifelogging app | Closed. Meta acquired Limitless 2025-12-05; Rewind capture disabled 2025-12-19 ([9to5Mac](https://9to5mac.com/2025/12/05/rewind-limitless-meta-acquisition/)) | defunct | Showed demand for "remember my day" | Closed lifelogging can disappear; local, exportable data is a selling point [Inference] |

### 1.5 The Claude Code / AI-coding-session ecosystem

**(a) Usage and cost (the loudest category)**

| Tool | What it does | Licence | Stars, last activity | Strength / weakness for this use case |
|---|---|---|---|---|
| **CodexBar** | Native Swift macOS menu-bar app: Codex and Claude Code usage stats without logging in | MIT | 22,219; created 2025-11-16; pushed 2026-10-06 ([API](https://api.github.com/repos/steipete/CodexBar)) | Strength: proof that a native Mac menu-bar utility for AI coding tools can go viral. Weakness: usage and limits only; no work narrative |
| **ccusage** | CLI token and cost reports (daily, weekly, monthly, session, 5-hour blocks, statusline) for about 18 agent CLIs | MIT per README; GitHub API reports NOASSERTION | 18,894; 862 forks; created 2025-05-29; pushed 2026-10-06 ([API](https://api.github.com/repos/ccusage/ccusage), [README](https://github.com/ccusage/ccusage)) | Strength: broadest agent coverage and a trusted per-day, per-session data model. Weakness: numbers, not narrative; CLI |
| **Claude-Code-Usage-Monitor** | Real-time usage monitor with predictions | MIT | 8,731; last push 2026-07-05 ([API](https://api.github.com/repos/Maciek-roboblog/Claude-Code-Usage-Monitor)) | Strength: predictions and warnings. Weakness: terminal monitor; quieter since July |
| **Tally** (jettoai/tally, ai-tally.app) | macOS menu-bar usage monitor for several Claude and Codex accounts | MIT | 8; created 2026-07-17 ([API](https://api.github.com/repos/jettoai/tally)) | Strength: multi-account quotas and a launcher. Weakness: tiny; usage only |

**(b) Session viewers, search and analytics**

| Tool | What it does | Licence | Stars, last activity | Strength / weakness for this use case |
|---|---|---|---|---|
| **claude-code-history-viewer** | Tauri desktop app to browse and analyse Claude Code history (multi-assistant, offline) | MIT | 2,223; pushed 2026-10-05 ([API](https://api.github.com/repos/jhlee0409/claude-code-history-viewer)) | Strength: cross-platform, local, active. Weakness: browse and analyse only; no summaries or standups |
| **claude-code-viewer** | Web client for sessions with full-text search and live view | MIT | 1,293; pushed 2026-08-18 ([API](https://api.github.com/repos/d-kimuson/claude-code-viewer)) | Strength: complete interactive client with strict schema validation. Weakness: web UI; a client more than a journal |
| **claude-code-transcripts** (Simon Willison) | Publish session transcripts as HTML | Apache-2.0 | 1,695; last push 2026-02-12 ([API](https://api.github.com/repos/simonw/claude-code-transcripts)) | Strength: shareable pages, trusted author. Weakness: per-session export; no day-level view; quiet since February |
| **claude-code-trace** | Rust viewer for desktop, web and TUI with live tail | MIT | 375; pushed 2026-10-03 ([API](https://api.github.com/repos/delexw/claude-code-trace)) | Strength: live tailing. Weakness: debugging orientation |
| **claude-history-manager** | Native Swift macOS browser: search, pin, tag, resume | NOASSERTION | 47; pushed 2026-04-26 ([API](https://api.github.com/repos/josephyaduvanshi/claude-history-manager)) | Strength: native Mac retrieval UX. Weakness: tiny, inactive since April 2026, licence unclear |
| ccrider, search-sessions | Go and Rust session search tools (SQLite or ripgrep) | various | HN 19 and 4 points ([ccrider](https://news.ycombinator.com/item?id=46512501), [search-sessions](https://news.ycombinator.com/item?id=47128630)) | Strength: fast search and resume. Weakness: terminal; retrieval only |

**(c) Memory, capture and summarising**

| Tool | What it does | Licence | Stars, last activity | Strength / weakness for this use case |
|---|---|---|---|---|
| **claude-mem** | Hooks plus MCP: captures what the agent does, compresses it with AI, re-injects context. Now multi-agent | Apache-2.0 | 96,877; 8,542 forks; created 2025-08-31; pushed 2026-10-06 ([API](https://api.github.com/repos/thedotmack/claude-mem)) | Strength: huge community; solves a daily agent pain. Weakness: a different job (feed context back to the agent, not a human-readable day log); HN skeptics say plain Markdown suffices and object to sending code to third parties |
| **Entire CLI** (Checkpoints) | Captures agent sessions into git refs on each commit; summaries at commit time; supports Claude Code, Cursor, Codex, Copilot CLI, Antigravity, Pi, OpenCode, Factory Droid. Company raised a $60M seed in Feb 2026 ([news](https://entire.io/news/former-github-ceo-thomas-dohmke-raises-60-million-seed-round/)) | MIT | 5,154; 333 open issues; created 2026-01-02; pushed 2026-10-06 ([API](https://api.github.com/repos/entireio/cli)) | Strength: strong backing and a principled model (sessions bound to commits). Weakness: repo- and team-level thesis rather than a personal daily log; checkpoint data in public repos is public per its README |
| **SpecStory** | Wrapper (`specstory run claude`) or `sync` that saves chats as Markdown in `.specstory/history`; optional cloud sync | Apache-2.0 | 1,347; created 2024-12-13; pushed 2026-10-06 ([API](https://api.github.com/repos/specstoryai/getspecstory)) | Strength: simple, portable Markdown history. Weakness: no narrative or day view; wrapper mode changes how you launch the agent; cloud pricing not verified |
| vibe-log, clerk, claude-code-worklog, cc-journal | See 1.1 | MIT / GPL-3.0 / Apache-2.0 / MIT | 339 / 38 / 1 / 0 | Strength: the exact feature. Weakness: terminal-only, setup, no traction |
| Chronicle (ChandlerHardy) | Multi-AI session recorder with summaries | MIT | 1; last push 2025-11-06 ([API](https://api.github.com/repos/ChandlerHardy/chronicle)) | Strength: right idea. Weakness: abandoned |

**(d) Apps that wrap or orchestrate agents (including ShipStudio)**

| Tool | What it does | Licence / price | Stars, last activity | Strength / weakness for this use case |
|---|---|---|---|---|
| **Ship Studio** | Free, local-first Mac desktop app bundling an agent terminal, live preview, git, deploy; works with Claude Code, Codex, OpenCode, Cursor. Targets freelancers, agencies and designers moving to agent-built sites ([site](https://www.ship.studio/)). No session journal, history or standup feature found | MIT; "100% free" per site | 285; 225 open issues; created 2026-01-16; pushed 2026-09-24 ([API](https://api.github.com/repos/ship-studio/ship-studio)) | Strength: free, local-first, bring-your-own agent, approachable for non-experts. Weakness: no history or journal; web-delivery focus; large open-issue backlog |
| **Conductor** | Mac app running parallel agents in git worktrees | Closed; free local tier, Pro about $50/mo per a third-party review ([review](https://vibecoding.app/blog/conductor-review)) [Unverified] | n/a | Strength: well-known Mac UX for parallel work. Weakness: closed; no journal; cloud features paid |
| **opcode** | GUI and toolkit for Claude Code (custom agents, sessions, background agents) | AGPL-3.0 | 22,422; pushed 2026-09-18 ([API](https://api.github.com/repos/getAsterisk/opcode)) | Strength: large community. Weakness: wraps rather than observes; 332 open issues |
| **vibe-kanban** | Kanban for coding agents | Apache-2.0 | 28,267; pushed 2026-09-19 ([API](https://api.github.com/repos/BloopAI/vibe-kanban)) | Strength: planning workflow, big audience. Weakness: orchestration, not logging |
| **Superset** | Agentic IDE for 100+ parallel agents | NOASSERTION | 14,923; pushed 2026-10-06 ([API](https://api.github.com/repos/superset-sh/superset)) | Strength: scale of parallelism. Weakness: licence unclear; orchestration |
| **Emdash** | Open-source agentic dev environment, provider-agnostic | Apache-2.0 | 5,917; pushed 2026-10-06 ([API](https://api.github.com/repos/generalaction/emdash)) | Strength: open and provider-agnostic. Weakness: orchestration |
| **Crystal** | Parallel Claude Code/Codex sessions in worktrees | MIT | 3,124; last push 2026-02-26 ([API](https://api.github.com/repos/stravu/crystal)) | Strength: worktree comparisons. Weakness: quiet since February |

Why wrappers matter here: worktree-per-task parallel sessions are exactly what makes "what did I do today?" hard. A passive reader of `~/.claude/projects` works regardless of which wrapper started the session [Inference]. Wrappers are also a distribution channel and a possible competitor if they add a journal.

**(e) Anthropic first-party features that overlap** (from the [weekly digest](https://code.claude.com/docs/en/whats-new), unless noted)

| When | Feature | What it does | Overlap / gap |
|---|---|---|---|
| Feb 2026 | `/insights` | 30-day HTML usage report at `~/.claude/usage-data/report.html`; reportedly caps sessions analysed ([write-up](https://www.zolkos.com/2026/02/03/deep-dive-how-claude-codes-insights-command-works.html)) | Usage and friction analytics, not a standup |
| Mar 23-27 | Transcript search with `/` | Search inside the transcript view | Per-session |
| Apr 13-17 | Routines | Scheduled or event-triggered cloud agents on Claude Code on the web | Could draft standups from GitHub activity, but runs in the cloud, not on local transcripts [Inference] |
| Apr 20-24 | Session recap (`/recap`, v2.1.114) | One-line "while you were away" summary after 3+ minutes unfocused ([digest](https://code.claude.com/docs/en/whats-new/2026-w17)) | Per-session. Three live recap issues exist; Desktop users ask for it too ([#91573](https://github.com/anthropics/claude-code/issues/91573)) |
| Apr 27-May 1 | `claude project purge`; PR URL in `/resume` finds the session | Cleanup; commit-to-session lookup | Links PRs to sessions |
| May 11-15 | Agent view (`claude agents`) | One screen for all sessions: running, blocked, done ([X](https://x.com/claudeai/status/2053940934736228454)) | Live status, not history |
| Jun 15-19 | Artifacts | Session output as a shareable live page (Team/Enterprise beta) | Sharing |
| Aug 3-7 | Cross-session messaging | Sessions message each other | Context hand-off |
| Aug 24-28 | Desktop `/resume` for CLI sessions | Search sessions by title, folder or branch | Session retrieval |
| about Sep 2026 | Claude-Session link in commits | Appended by default; disable with `attribution.sessionUrl: false`; link is private to the user ([HN](https://news.ycombinator.com/item?id=49515667), 13 points) [Unverified: confirm in the changelog] | Ties commits to sessions |
| 2026 | Cowork scheduled tasks | Hourly/daily/weekly tasks; daily briefings from connectors ([support](https://support.claude.com/en/articles/13854387-schedule-recurring-tasks-in-claude-cowork)). Whether they can read local folders is ambiguous across sources | Plausible first-party substitute [Unverified] |

### 1.6 Capability matrix for the closest tools

Yes / No / Part (partial) / ? (could not verify). Values come from the pages cited above.

| Tool | Reads Claude Code | Reads Cowork/Desktop | Narrative day draft | Standup / brag output | Links to commits/PRs | Local-LLM option | Native Mac UI | Open source | Keeps history past 30 days |
|---|---|---|---|---|---|---|---|---|---|
| Dayflow | No | No | Yes | Yes | No | Yes | Yes | Yes (MIT) | n/a (own recordings) |
| Claudoscope | Yes | Yes | No | No | Part (file diffs) | n/a (no LLM) | Yes | Yes (MIT) | ? |
| Contextify | Yes (+Codex) | ? | Part (per-session summaries on macOS 26) | Not found | Part (git-anchored search) | Yes (Apple Intelligence) | Yes | No | Yes (claims "forever") |
| agentsview | Yes (+20-50) | ? | No | No | Part (git outcome stats) | n/a | No (Go + Tauri) | Yes (MIT) | Part (local SQLite; survival of upstream deletion not verified) |
| vibe-log-cli | Yes (+Codex) | No | Yes | Yes | ? | Part (uses the user's own CLI; vendor still sees content) | No | Yes (MIT) | ? |
| clerk | Yes | No | Yes | Part (weekly) | No | No (Claude API) | No | Yes (GPL-3.0) | Yes (Markdown persists) |
| claude-code-worklog | Yes | No | Part (no LLM) | Part (daily/period) | ? | Yes (no LLM) | No | Yes (Apache-2.0) | ? |
| SpecStory | Yes | No | No | No | No | n/a | No | Yes (Apache-2.0) | Yes (Markdown) |
| Entire CLI | Yes (+7) | No | Part (commit summaries) | No | Yes | ? | No | Yes (MIT) | Yes (git refs) |
| BragLog | No | No | Part (from manual logs) | Yes | No | Yes (Apple FoundationModels) | Yes | No | Yes |
| reflekto | No | No | Part | Part ("summary for standup" prompt) | Yes (PR sync) | ? | Yes | ? | Yes (local) |
| Claude Code first-party | Yes | Part | Part (per-session recap) | No | No | No | n/a | No | No (30-day default, CLI) |

**Reading the matrix [Inference]:** no row combines Yes in "Narrative day draft", "Links to commits/PRs", "Local-LLM option", "Native Mac UI", "Open source" and "Keeps history". That empty cell is the opportunity, and the sheer number of near-misses is the danger.

### 1.7 What the star counts say about where energy is

| Job being solved | Exemplars | Stars |
|---|---|---|
| Agent memory and context | claude-mem | 96,877 |
| Parallel-agent orchestration | vibe-kanban / opcode / Superset / Emdash / Crystal | 28,267 / 22,422 / 14,923 / 5,917 / 3,124 |
| Usage and limits anxiety | CodexBar / ccusage / Usage Monitor | 22,219 / 18,894 / 8,731 |
| Screen-based automatic work journal | Dayflow (and Screenpipe at 21,828) | 7,234 |
| Session archive and analytics | agentsview / Entire / SpecStory | 6,059 / 5,154 / 1,347 |
| Session viewers | history-viewer / transcripts / viewer / trace / Claudoscope | 2,223 / 1,695 / 1,293 / 375 / 239 |
| Standup, brag or worklog from sessions | vibe-log / clerk / copilot-brag-sheet / worklog | 339 / 38 / 11 / 1 |
| Brag docs from GitHub | reflect / promoteme / brag-ai | 36 / 6 / 2 |
| Git standup (older, 2016) | git-standup | 7,856 |

[Inference] Tools that solve a daily, universal agent pain (forgetting, limits, parallelism) get tens of thousands of stars. Narrative logging from sessions has no breakout yet. Dayflow is the only "work journal" with real traction, and it got there through zero-effort capture, not through agent integration.

Related signal: at least 14 session-history, worklog or brag repos were created in 2026 among those I sampled: Entire (Jan 2), promoteme (Jan 19), agentsview (Feb 19), claude-code-trace and cc-journal (Mar 11), Claudoscope (Mar 15), clerk and copilot-brag-sheet (Apr 16), claude-history-manager (Apr 25), claude-session-viewer (Apr 30), claude-code-worklog (Jul 1), daily-work-log (Jul 20), agent-wrapped (Aug 4), DayApp (Aug 12).

### 1.8 Market context, sizing and timing

- **Scale (primary source).** Anthropic, 2026-02-12: Claude Code run-rate revenue above $2.5B, weekly active users doubled since Jan 1, business subscriptions quadrupled, about 4% of public GitHub commits ([Anthropic](https://www.anthropic.com/news/anthropic-raises-30-billion-series-g-funding-380-billion-post-money-valuation)). SEO statistics sites claim millions of weekly users and much larger later run-rates; I could not trace those to a primary source and do not use them [Unverified].
- **Platform share.** About one third of professional developers use macOS as primary OS (32.9-33.2% in secondary summaries of the 2025 Stack Overflow survey, [summary](https://commandlinux.com/statistics/developer-os-preference-stack-overflow-survey/); primary: [survey](https://survey.stackoverflow.co/2025/)).
- **Sizing, honestly.** I cannot responsibly give a +/-20% TAM. Anthropic does not publish an active-user count in the sources I reached. Directionally: the pool of Claude Code users is large and growing; roughly a third are on Mac; the subset who must account for their work (standups, client billing, reviews) is a fraction of that. Comparable tools suggest the realistic outcome for a good niche tool is hundreds to low tens of thousands of GitHub stars (Claudoscope 239, agentsview 6,059, Dayflow 7,234, CodexBar 22,219), not millions of users [Inference].
- **Willingness-to-pay anchors.** Dayflow Pro $20/mo; Contextify Cloud Pro $12/mo and Local Commercial $77/yr; BragLog one-time purchase; Day One Gold $74.99/yr; Obsidian Sync $4/mo; Rize $9.99-39.99/mo; Timing from $10/mo; WakaTime $9-14/mo; RescueTime $7-12/mo; Geekbot $2.50-3 per user per month. Most open-source rivals are free; the paid products charge for sync, managed AI or commercial licences.
- **Timing [Inference, low confidence].** The category is in early growth: first dedicated Show HNs in Dec 2025, then first-party features Apr-Aug 2026. Expect consolidation or first-party absorption within roughly 6-12 months. The window is open but closing.

---

## 2. Demand signals

### 2.1 Evidence table

| Signal | Source | Metric | Date | What it shows |
|---|---|---|---|---|
| Dayflow Show HN | [HN 45361268](https://news.ycombinator.com/item?id=45361268) | 480 pts / 130 comments | 2025-09-24 | Zero-effort work journal resonates; requests for standup summaries; privacy and local-model demands; lawyers and contractors see billing value |
| "If AI writes code, should the session be part of the commit?" | [HN 47212355](https://news.ycombinator.com/item?id=47212355) | 497 / 391 | approx. Mar 2026 | Sessions-as-artifacts is a hot debate; critics say sessions are noisy, supporters want the "why" |
| "Stop Claude Code from forgetting everything" | [HN 46426624](https://news.ycombinator.com/item?id=46426624) | 202 / 225 | approx. Dec 2025 - Jan 2026 | Context loss is a felt pain; many commenters prefer plain Markdown or object to sending code to third parties |
| "Recall" (project memory for Claude Code) | [HN 48622590](https://news.ycombinator.com/item?id=48622590) | 138 / 85 | approx. Jul 2026 | Same pain; skeptics say CLAUDE.md and status docs suffice |
| ccrider | [HN 46512501](https://news.ycombinator.com/item?id=46512501) | 19 / 4 | approx. Jan 2026 | Built-in `/resume` does not cover searching or finding forgotten sessions |
| Contextify | [HN 46209081](https://news.ycombinator.com/item?id=46209081) | 6 / 2 | approx. Dec 2025 | Created because of the 30-day purge |
| search-sessions | [HN 47128630](https://news.ycombinator.com/item?id=47128630) | 4 / 4 | approx. Feb-Mar 2026 | Gigabytes of session files with no way to resurface past decisions (paraphrase) |
| reflekto, Exceeds, JotChain, gitmore | HN [46900182](https://news.ycombinator.com/item?id=46900182), [47388823](https://news.ycombinator.com/item?id=47388823), [46364104](https://news.ycombinator.com/item?id=46364104), [46216313](https://news.ycombinator.com/item?id=46216313) | 3, 2, 1, 1 pts | Dec 2025 - Mar 2026 | Builders feel the brag-doc and status-report pain; mass interest in manual or git-only tools is near zero |
| "Ask HN: How do you maintain your daily log?" | [HN 33359329](https://news.ycombinator.com/item?id=33359329) | 88 / 85 | 2022-10-27 | Perennial need; friction and consistency kill logging. Earlier threads: [2017](https://news.ycombinator.com/item?id=14858558), [2018](https://news.ycombinator.com/item?id=18423820) |
| Claude Code GitHub: silent 30-day deletion | [#59248](https://github.com/anthropics/claude-code/issues/59248) | 44 reactions / 58 comments, open, label data-loss | 2026-05-14 | Strongest quantified evidence of session-loss pain |
| Same | [#62476](https://github.com/anthropics/claude-code/issues/62476) | 31 / 27, open | 2026-05-26 | Reporter lost months of history |
| Claude Code GitHub: history lost in VS Code | [#9258](https://github.com/anthropics/claude-code/issues/9258) | 51 / 47, open | 2025-10-10 | Same family of loss |
| Claude Code GitHub: session disappeared in Desktop | [#26452](https://github.com/anthropics/claude-code/issues/26452) | 33 / 53, open | 2026-02-18 | Desktop sessions vanish too |
| Claude Code GitHub: recap for Desktop | [#91573](https://github.com/anthropics/claude-code/issues/91573) | 1 / 3, open | 2026-09-02 | Users run many Desktop sessions, one per git worktree, and cannot tell where each stands |
| Dayflow issues: MCP/API, CLI export, iCal, privacy routing | [#181](https://github.com/JerryZLiu/Dayflow/issues/181), [#178](https://github.com/JerryZLiu/Dayflow/issues/178), [#183](https://github.com/JerryZLiu/Dayflow/issues/183), [#299](https://github.com/JerryZLiu/Dayflow/issues/299) | 7, 5, 8, 4 reactions | Dec 2025 - Jul 2026 | Users want programmatic access, export, and per-app privacy rules |
| Dayflow issues: Windows/Linux | [#3](https://github.com/JerryZLiu/Dayflow/issues/3), [#26](https://github.com/JerryZLiu/Dayflow/issues/26), [#318](https://github.com/JerryZLiu/Dayflow/issues/318) | 11, 6, 4 | Sep 2025 - Jul 2026 | Mac-only leaves demand on the table |
| Usage-limit anxiety (Claude Code) | [#16157](https://github.com/anthropics/claude-code/issues/16157), [#38335](https://github.com/anthropics/claude-code/issues/38335) | 726 and 545 reactions | Jan and Mar 2026 | Why usage tools get tens of thousands of stars |
| X posts (search-snippet level only) | [ArtemXTech](https://x.com/ArtemXTech/status/2028330693659332615), [Claude](https://x.com/claudeai/status/2053940934736228454) | n/a | 2026 | One user's `/recall yesterday` reportedly reconstructed 39 sessions from one day [Unverified]; Anthropic itself launched "one list of all your sessions" |

### 2.2 What people complain about

**A. "I cannot reconstruct what I did" (standups, status reports, reviews).**
- Perennial: three Ask HN threads from 2017 to 2022. One commenter: "A daily log in a simple text file is super useful for perf review" ([HN 33359329](https://news.ycombinator.com/item?id=33359329)).
- 2025-26 builders scratching the itch (paraphrases): an author re-typed ClickUp updates into Slack before every standup ([dev.to](https://dev.to/chaitrali_kakde_27694f6f9/i-was-tired-of-writing-daily-standups-so-i-built-an-ai-agent-using-claude-code-35g8)); an author tired of Friday afternoons turning commits into status reports ([HN 46216313](https://news.ycombinator.com/item?id=46216313)); review-time context missing ([HN 46364104](https://news.ycombinator.com/item?id=46364104)); scrambling every review cycle ([HN 47388823](https://news.ycombinator.com/item?id=47388823)).
- On Dayflow: "They would pay big money for something that recovered forgotten(unbilled) work throughout the day" ([HN 45361268](https://news.ycombinator.com/item?id=45361268)). Billing professionals are an adjacent segment.

**B. "My agent sessions evaporate or sprawl."**
- "I lost months of conversation history before realizing this was happening." ([GitHub #62476](https://github.com/anthropics/claude-code/issues/62476)).
- The Contextify author: "Claude Code automatically deletes your transcripts after 30 days" ([HN 46209081](https://news.ycombinator.com/item?id=46209081)).
- A June 2026 post (revised 2026-09-30, verified on v2.1.280) found a January-April gap in his own history and notes the default is still 30 days; raising the setting only protects future sessions ([Bryce Watson](https://brycewatson.com/blog/28-claude-code-deletes-old-logs/)). The same post says Desktop and Cowork sessions are kept by default since v2.1.248, while other sessions follow the cleanup period [secondary source].
- The `agent-wrapped` README notes that Claude Code prunes transcripts at about 30 days, so each run saves a snapshot ([repo](https://github.com/nitrimandylis/agent-wrapped)).
- Sprawl: Desktop users run "many" sessions, one per worktree ([#91573](https://github.com/anthropics/claude-code/issues/91573)); Anthropic shipped agent view and cross-session messaging.

**C. "Logging dies from friction; zero-effort capture wins."**
- HN daily-log thread themes (summarised): discoverability by date and project, consistency needing frictionless capture, tool paralysis.
- Manual or git-only log tools got 1-3 HN points; Dayflow's zero-effort capture got 480 [Inference].

**D. "Privacy and surveillance."**
- "I'd only ever consider doing it with a local model" ([HN 45361268](https://news.ycombinator.com/item?id=45361268)); another commenter raised employer surveillance (paraphrase).
- "I'd prefer not to send proprietary code to third-party servers" ([HN 46426624](https://news.ycombinator.com/item?id=46426624)).
- Dayflow users ask for privacy rules and provider routing by application ([#299](https://github.com/JerryZLiu/Dayflow/issues/299)). Claudoscope added secret scanning of session history.

**E. "Minutiae is not impact."**
- A skeptic on reflekto: "Promotion ought to be based on impact" ([HN 46900182](https://news.ycombinator.com/item?id=46900182)). The author of an AI brag-doc tool concedes mentoring and design work leave no PRs ([blog](https://matthewboston.com/blog/i-built-an-ai-tool-to-write-my-brag-document.html)).

**F. "Do I even need an app?"**
- "nothing works better than simply keeping my own library of markdown files" ([HN 46426624](https://news.ycombinator.com/item?id=46426624)). The Recall thread has similar views (paraphrase) ([HN 48622590](https://news.ycombinator.com/item?id=48622590)).
- DIY solutions abound: a Notion journal plugin ([dev.to](https://dev.to/cseeman/claude-code-journal-plugin-notion-session-summaries-at-a-glance-940)), a `/journal` skill plus Stop hook ([blog, Feb 2026](https://vivecuervo7.github.io/dev-blog/p/journalling-with-claude/)), and several "daily standup" skills on skill directories ([example](https://mcpmarket.com/tools/skills/daily-standup-generator)).

**G. "Standups themselves are disliked."**
- HN threads such as ["The pointlessness of daily standups"](https://news.ycombinator.com/item?id=21177240) and ["Daily standups are morale killers"](https://news.ycombinator.com/item?id=17354853). If teams abolish standups the need shrinks; if they stay, anything that removes the prep is welcome. Some commenters note yesterday is already in commit messages.

### 2.3 Counter-signals

- Recent manual-log, brag-doc and AI status-report tools draw 1-3 HN points and under 40 GitHub stars each (git-standup, from 2016, is the exception at 7,856). Builder interest is high; adopter interest is unproven [Inference].
- Session-viewer tools sit at 1-2k stars; the viewing job looks like a vitamin next to memory or usage tools [Inference].
- Skeptics prefer plain Markdown and CLAUDE.md; many DIY skills exist.
- AI-written updates risk "slop" backlash; see HN threads such as ["Stop Sloppypasta"](https://news.ycombinator.com/item?id=47389570) (not specific to standups). An edit-before-share step is mandatory.
- "Wrapped"-style shareable cards exist as repos with 0-3 stars ([claude-code-wrapped](https://github.com/kschrader/claude-code-wrapped), [agent-wrapped](https://github.com/nitrimandylis/agent-wrapped)), so virality of cards as a standalone product is unproven.

### 2.4 Coverage gaps (honest)

- **Reddit** (r/ClaudeAI, r/ClaudeCode, r/macapps, r/productivity, r/ExperiencedDevs): inaccessible. WebSearch rejects the domain, WebFetch refuses `old.reddit.com`, and the one archive mirror tried returned HTTP 429. No Reddit evidence is included. A 30-minute manual pass is recommended (Appendix C).
- **X:** only search-result snippets; post pages returned HTTP 402.
- **Not examined:** Discord and Slack communities, App Store reviews and rankings, download counts, Product Hunt.

---

## 3. Gap analysis

### 3.1 What is unserved

Jobs to be done, with the current best alternative:

| Job | Frequency | Evidence | Current best alternative |
|---|---|---|---|
| Prepare a standup ("what did I do yesterday") | Daily | HN threads; Dayflow standup feature; Standup.so; dev.to | Dayflow, git-standup, DIY skills |
| Weekly update to manager or client | Weekly | gitmore, daily-work-log, clerk weekly reports | DIY skills, Dayflow weekly |
| Review or promotion evidence | Quarterly to yearly | reflekto, Exceeds, JotChain, BragLog, brag-sheet | BragLog (manual), brag-doc CLIs |
| Resume context across many sessions and worktrees | Daily | #91573; agent view; ccrider; Contextify | Agent view, `/resume`, Contextify |
| Do not lose history | Continuous | #59248, #62476, #9258 | Setting `cleanupPeriodDays`, Contextify, SpecStory, agentsview |
| Bill clients or fill timesheets | Weekly to monthly | Dayflow HN commenters | Timing, Rize, Dayflow |

Unserved or poorly served combinations (I found no tool that does all of these):

1. **A narrative-first day log built from agent sessions, in a native open-source Mac app with an edit-and-approve loop.** Closest: Dayflow (screen, not sessions), Claudoscope (analytics, not narrative), Contextify (closed, per-session summaries), CLI trio (terminal).
2. **Evidence-linked output** (each bullet traces to sessions, commits, PRs, files) in a polished app. Only DIY skills and Microsoft/GitHub's Copilot-only brag sheet do this.
3. **A durable, open, cross-agent personal archive with native UX.** Contextify is closed; agentsview is not native or narrative.
4. **Privacy-first drafting for developers' secrets:** local summarising, pre-LLM redaction, a visible data-flow ledger. Claudoscope detects secrets but does not draft; Dayflow routes screenshots to cloud providers by choice.
5. **Non-code work next to agent work** (reviews, mentoring, meetings) with a two-second capture. BragLog and reflekto are manual-only.
6. **Standup ergonomics from sessions** (per-project sections, blockers, paste-ready for Slack). Only Dayflow does this, from pixels.

### 3.2 Where the gap may be illusory

- A free `/standup` skill plus cron is good enough for power users, and many exist.
- Anthropic can add a daily recap in a single release; Cowork scheduled tasks already do daily briefings from connectors.
- The people who need to report may be a narrower group than "people who run Claude Code".
- The 14-plus 2026 entrants with tiny star counts may signal builder itch rather than buyer demand.

### 3.3 Ranked list: the 10 features most likely to make the app loved and shared

Evidence strength: Strong = multiple independent primary signals; Moderate = some direct signals; Weak = indirect only.

| Rank | Feature | Why it earns love and shares | Evidence (strength) | Caveat |
|---|---|---|---|---|
| 1 | **First-run magic: backfill and draft in under a minute, no account, no API key.** On launch, ingest the existing `~/.claude/projects` history and show a timeline plus a drafted "yesterday" | Zero manual effort is the common factor in the one real hit (Dayflow, 480 HN points) while manual-log tools get 1-3 points. Screenshot-able first impression | Strong: [Dayflow HN](https://news.ycombinator.com/item?id=45361268), [daily-log HN](https://news.ycombinator.com/item?id=33359329), manual-log Show HNs | Local-model summary quality is uneven (Dayflow commenters); Apple's on-device model has an 8,192-token context ([WWDC26](https://developer.apple.com/videos/play/wwdc2026/241/)), so chunking and a no-LLM structured fallback (as in claude-code-worklog) are needed |
| 2 | **Never lose a session:** automatic, non-destructive archive that outlives Claude Code's 30-day purge, plus a one-click, explained fix for the retention setting | Loss aversion. People discover the purge after losing months of history | Strong: [#59248](https://github.com/anthropics/claude-code/issues/59248) (44 reactions), [#62476](https://github.com/anthropics/claude-code/issues/62476) (31), [#9258](https://github.com/anthropics/claude-code/issues/9258) (51), [Contextify origin](https://news.ycombinator.com/item?id=46209081), [Watson](https://brycewatson.com/blog/28-claude-code-deletes-old-logs/) | Easy to replicate (one setting), so a hook, not a moat. Regulated orgs may enforce deletion (the HIPAA configuration reportedly deletes Desktop Code sessions after the cleanup period; see the [HIPAA setup docs](https://code.claude.com/docs/en/hipaa-setup) [Unverified at source]), so make archiving opt-in per project and store derived summaries by default |
| 3 | **One-click standup (Yesterday / Today / Blockers), paste-ready, always editable before copy** | Replaces a daily chore; the paste-into-Slack moment is the share moment | Moderate-Strong: Dayflow ships it; [Standup.so](https://news.ycombinator.com/item?id=47191964); [dev.to](https://dev.to/chaitrali_kakde_27694f6f9/i-was-tired-of-writing-daily-standups-so-i-built-an-ai-agent-using-claude-code-35g8); Geekbot scale | Standups are disliked; value is killing prep time. AI "slop" concerns, so show the draft as a draft |
| 4 | **Evidence-linked entries:** every bullet traces to sessions, commits, PRs and files, including the new Claude-Session commit link | Trust and receipts; turns a summary into something you can defend in a review | Moderate: Brag Sheet's action-result-evidence contract ([skill](https://github.com/github/awesome-copilot/blob/main/skills/brag-sheet/SKILL.md)); reflekto PR sync; Entire's thesis ($60M seed, 5,154 stars); [497-point HN debate](https://news.ycombinator.com/item?id=47212355) | HN skeptics prefer impact over minutiae, so prompt for impact rather than list commits |
| 5 | **Privacy by construction:** on-device or local models, bring-your-own key, pre-LLM secret and PII redaction, per-project and per-provider rules, a visible "what left this Mac" ledger, no telemetry | Removes the objection that dominates HN threads; a credible differentiator against screen recording | Strong: [HN](https://news.ycombinator.com/item?id=45361268) and [HN](https://news.ycombinator.com/item?id=46426624) quotes; [Dayflow #299](https://github.com/JerryZLiu/Dayflow/issues/299); Claudoscope secret scanning; BragLog on-device pitch; Anthropic credential rules (section 4) | On-device quality limits; the free Private Cloud Compute tier's terms for non-App-Store apps are not stated in what I could read |
| 6 | **Open, scriptable outputs:** Markdown in a folder you choose (Obsidian-ready), CLI and MCP server so any agent can ask "what did I do last Tuesday?", export to Day One via its CLI | Fits how developers already work; "ask your day" is a demo-able, shareable trick | Moderate-Strong: Dayflow [#181](https://github.com/JerryZLiu/Dayflow/issues/181), [#178](https://github.com/JerryZLiu/Dayflow/issues/178), [#183](https://github.com/JerryZLiu/Dayflow/issues/183); Rize and reflekto MCP; Day One CLI and MCP; Obsidian plus Claude Code guides; HN Markdown-folder consensus | MCP surfaces sensitive data to agents, so default read scopes must be narrow |
| 7 | **Weekly and quarterly roll-ups and a brag-doc or self-review export with "impact prompts"** | Recurring, high-stakes use; a second reason to keep the app installed | Moderate: reflekto, Exceeds, JotChain, BragLog, [Boston](https://matthewboston.com/blog/i-built-an-ai-tool-to-write-my-brag-document.html) | Seasonal; low HN traction; HR-adjacent |
| 8 | **Cheap multi-source:** git, PRs and calendar, plus a menu-bar hotkey for non-agent work; Codex CLI as the second agent | Covers the work sessions cannot see (reviews, mentoring, meetings) | Moderate: Boston's caveat; reflekto; ccusage (about 18 agents), agentsview (20-50+), Entire (8) show multi-agent is table stakes | Parser upkeep is a tax (agentsview [#1642](https://github.com/kenn-io/agentsview/issues/1642) is an OpenCode parser break); keep v1 to two agents |
| 9 | **By-product analytics people already star:** tokens, cost and time-in-agent per project and day, in the same view | Gives a reason to open the app daily and a screenshot-able panel | Moderate: CodexBar 22,219, ccusage 18,894, Usage Monitor 8,731 stars; [#16157](https://github.com/anthropics/claude-code/issues/16157) 726 reactions | Different job, saturated; risk of becoming a me-too usage tool |
| 10 | **Native craft plus a redacted shareable "week card":** menu bar, end-of-day nudge, Shortcuts and Spotlight, signed and notarised, Homebrew cask, low CPU | Polish is what makes native Mac tools get shared (CodexBar is the example); a share-safe card is the viral hook | Weak-Moderate: CodexBar; Dayflow's footprint claims versus HN battery/CPU complaints; Homebrew requests ([history-viewer #123](https://github.com/jhlee0409/claude-code-history-viewer/issues/123)); wrapped-card repos exist but are tiny | Card virality is unproven; redaction must be default-on |

### 3.4 Deliberate non-goals (suggested)

- No screen or audio recording (that is Dayflow and Screenpipe territory, with permission and privacy costs).
- No agent wrapper, orchestrator or terminal replacement (crowded: Conductor, vibe-kanban, opcode, Superset, Emdash, Ship Studio).
- No manager or team dashboards (surveillance perception; Geekbot territory).
- No scraping of Claude.ai chat UIs or caches; use official exports only.
- No Claude.ai login and no handling of subscription tokens.

---

## 4. Risks

### 4.1 Anthropic terms and privacy

| Risk | Evidence | Likelihood / impact | Mitigation |
|---|---|---|---|
| Using Pro/Max OAuth tokens, or offering Claude.ai login, in a third-party app | Anthropic's page says OAuth is for ordinary use of Claude Code and native apps; developers should use API keys; it does not permit routing requests through Free/Pro/Max credentials or storing or intermediating Claude.ai credentials ([legal](https://code.claude.com/docs/en/legal-and-compliance)). Enforcement: server-side blocks from 2026-01-09, doc clause 2026-02-19, OpenCode removed its OAuth plugin in March (secondary: [zbuild](https://www.zbuild.io/resources/news/opencode-blocked-anthropic-2026), [abit.ee](https://abit.ee/en/artificial-intelligence/anthropic-claude-code-oauth-openclaw-opencode-claude-max-subscription-api-ban-terms-of-service-en)) | High if ignored / severe | Order of preference: on-device model, local Ollama or MLX, bring-your-own API key. Shelling out to the user's own unmodified `claude` binary (what Dayflow and vibe-log do) is a gray zone; make it opt-in and get written clarification before relying on it [Inference] |
| Naming and logos | The same page: you cannot use the Claude, Claude Code or Anthropic names or logos as part of your product, feature or company name, or imply endorsement; plain-text "runs Claude Code" is fine ([legal](https://code.claude.com/docs/en/legal-and-compliance)) | High if ignored / medium | Neutral product name; describe compatibility in plain text |
| Transcripts contain secrets and proprietary data | Plaintext under `~/.claude/projects` ([data usage](https://code.claude.com/docs/en/data-usage)); Claudoscope adds secret scanning for this reason; HN privacy objections | High / high | Local by default; pre-LLM redaction; per-project opt-in; store derived summaries rather than raw transcripts by default; encrypted store; no telemetry |
| Employer policy and surveillance perception | HN commenters on Dayflow | Medium / high for adoption | Personal-only tool; no manager views; no network by default; open source |
| Desktop chat scraping | Regular chats are server-side; export is user-initiated Settings > Privacy > Export ([guide](https://univik.com/help/export-claude-chats.html), secondary) | Medium / medium | Do not scrape; offer import of the export file instead |

### 4.2 Crowded niche

| Risk | Evidence | Likelihood / impact | Mitigation |
|---|---|---|---|
| A strong incumbent adds the feature | Dayflow already drives Claude and ChatGPT CLIs and has issues for MCP and CLI export; agentsview describes "insights"; Claudoscope is native; Contextify has paid tiers | Medium / high | Ship the evidence-linked narrative first; offer import from adjacent tools rather than fighting them |
| Weak differentiation against DIY skills | Many `/standup` and `/journal` skills; HN skeptics | High / medium | Zero-setup, review UI, durable archive, redaction, cross-agent |

### 4.3 Copycats

| Risk | Evidence | Likelihood / impact | Mitigation |
|---|---|---|---|
| Cloning is cheap: parse JSONL, call an LLM | 14+ related repos in 2026; Dayflow has 441 forks and several same-name copies appear in search results; an HN thread complains about low-effort AI-generated Show HNs ([HN 47212355](https://news.ycombinator.com/item?id=47212355)) | High / medium | Compete on trust, quality and speed; choose the licence deliberately (permissive maximises reach; AGPL or FSL-style deters commercial forks, as opcode and Contextify do); register the name; build community |

### 4.4 Platform risk

| Risk | Evidence | Likelihood / impact | Mitigation |
|---|---|---|---|
| First-party absorption | Recap, insights, agent view, Desktop resume with search, Routines, Cowork scheduled tasks, Claude-Session commit links (table 1.5e); three live recap issues | High over 12 months / high for the "auto-draft" hook, lower for archive, cross-agent and privacy | Differentiate on what first-party will not do: cross-agent, durable beyond 30 days, local-only, evidence-linked, user-owned Markdown |
| Unstable transcript format | The JSONL is internal; a request for a stable schema was closed ([#53516](https://github.com/anthropics/claude-code/issues/53516)); multiple third-party parsers have crashed on malformed or changed lines ([example](https://dev.to/nickelsec/i-parsed-76801-lines-of-my-own-claude-code-history-three-things-nearly-broke-my-parser-h44)); Claude Code shipped 7-11 versions per week in Aug-Sep 2026 (digest ranges) | High / medium | Tolerant versioned parsers; fixture corpus across versions; hooks (`SessionEnd` provides `transcript_path`, per [hooks](https://code.claude.com/docs/en/hooks)) as a second capture path; visible "unparsed lines" counter |
| Shift from local to cloud sessions | Routines and cloud sessions leave no local transcript; `claude --teleport` pulls on demand ([guide](https://dev.to/proflead/claude-code-tutorial-syncing-web-sessions-to-local-cli-34e0)) | Medium / medium | Use git, PR and commit-trailer evidence as a second source |
| Apple platform | macOS 27 and Foundation Models changed at WWDC26; on-device context is 8,192 tokens; free Private Cloud Compute is stated for developers with under 2M first-time downloads, non-App-Store eligibility not stated ([WWDC26](https://developer.apple.com/videos/play/wwdc2026/241/)); Timing avoids the Mac App Store because of sandboxing ([pricing](https://timingapp.com/pricing)) | Medium / medium | Distribute notarised via Developer ID and Homebrew; abstract the model layer (Apple, Ollama, MLX, API key) |
| Other vendors | GitHub and Microsoft brag-sheet for Copilot CLI; Entire ($60M) building a platform on session capture; Day One now has CLI and MCP | Medium / low-medium | Stay cross-agent and personal |

### 4.5 Business and quality

| Risk | Evidence | Mitigation |
|---|---|---|
| Free open-source anchor and maintenance load | Dayflow is free but sells Pro at $20/mo; Contextify sells Cloud Pro and commercial licences; BragLog is a one-time purchase. Open-issue counts (Dayflow 103, Ship Studio 225, Entire 333) show the maintenance load | Decide early: sponsorship, optional Pro (sync or managed AI), or pure hobby. Keep the core free |
| Wrong or hallucinated summaries | HN "slop" discussions; local-model accuracy complaints on Dayflow | Evidence links on every bullet; edit-before-share; label as AI-drafted; no-LLM fallback |
| Narrow Mac-only audience | About one third of professional developers; Dayflow cross-platform requests | Keep the core portable (parsers and storage) while the UI stays native |

---

## 5. Names already taken in this space

**Collisions with the working title "daily-log" / "DailyLog" / "Daily Log"**
- `joemasilotti/daily-log`, a Rails and iOS habit tracker ([GitHub](https://github.com/joemasilotti/daily-log))
- DailyLog, an Android quick-logging app ([F-Droid](https://f-droid.org/packages/com.app.dailylog/))
- daily-work-log / Worklog.app, a macOS menu-bar work log ([GitHub](https://github.com/adampolicht/daily-work-log))
- Daily - Hours & Time Tracker ([App Store](https://apps.apple.com/us/app/daily-hours-time-tracker/id686910553))
- The "Day*" family is crowded: Day One, Dayflow, DayApp ([GitHub](https://github.com/faraz-35/dayapp)), Daybook ([App Store](https://apps.apple.com/us/app/daybook-ai-journal-diary/id1332489182))

**Work-log, brag and standup names**
- Worklog ([worklog.ai](https://www.worklog.ai/); several App Store apps), WorkLogix Logbook, Logbook (Interstitial Journal on the App Store; a Logbook MCP server), BragLog ([braglog.app](https://braglog.app/)), reflekto.app, Exceeds, JotChain, Shiplog, Brag Sheet and copilot-brag-sheet, Brag AI, promoteme, `reflect` (bostonaholic; also Reflect Notes at reflect.app), gitmore, Standup.so, Standin (standin.co), standup-for-one, Geekbot, Standuply, DailyBot, git-standup, gitlogg, jrnl.

**AI-session tooling names**
- Contextify, Claudoscope, ClaudeBar, CodexBar, Tally ([jettoai/tally](https://github.com/jettoai/tally), ai-tally.app), Chronicle (several repos: ChandlerHardy/chronicle, inxilpro/chronicle-gui, leesj-dev/chronicles, aichronicles), claude-history-manager, cc-journal, clerk, vibe-log, claude-code-worklog (cc-worklog), agentsview, SpecStory, Entire and Checkpoints, claude-mem, ccrider, search-sessions, Recall (an HN Show HN, and Microsoft Recall), Total Recall (Contextify), Session Recap (a skill), opcode, Conductor, Crystal, Superset, Emdash, Vibe Kanban, Ship Studio, agent-wrapped, Claude Code Wrapped, Year in Code, vibewatt.

**Words already owned by first-party features or products**
- Recap (`/recap`), Insights (`/insights`), Agent view, Routines, Artifacts, Checkpoints (Claude Code checkpointing and Entire), Memory, Cowork, Journal (Apple), Rewind and Limitless (defunct but trademarked).

**Hard constraint**
- Do not use "Claude", "Claude Code" or "Anthropic" (or logos) in the product, feature or company name ([legal](https://code.claude.com/docs/en/legal-and-compliance)). Avoid near-coinages such as "Claudia", "Claudoscope" style names.

**Generic words that are effectively exhausted:** journal, log, logbook, daybook, worklog, brag, standup, recap, chronicle, tally, flow.

**Before committing to any name, check:** GitHub org and repo, Homebrew cask, npm, App Store, `.com`/`.app`/`.dev` domains, USPTO and EUIPO (classes 9 and 42), X and Bluesky handles, plus a search for "<name> Claude Code". I did not test candidate coinages in this pass; this section lists collisions only.

---

## 6. Recommended positioning and target user

**Positioning (one paragraph).** Position the app as a private, native Mac "flight recorder" for AI-assisted work: it quietly archives and understands the sessions your coding agents already write (Claude Code first, including the Desktop Code tab and Cowork; Codex CLI second), joins them with git, PR and calendar evidence, and each evening hands you an editable, evidence-linked draft of your day that you can paste as a standup, keep as Markdown in your vault, or roll up into a brag doc. It does this with no screen recording, no wrapper, no account, and on-device summarising by default. It beats Dayflow on privacy, accuracy and footprint (it reads what actually happened rather than guessing from pixels); beats viewers and analytics tools on narrative and output; beats CLI skills on zero-setup and review UX; and beats Anthropic's own `/recap` and `/insights` by being cross-agent, durable past the 30-day purge, and yours to own. Lead with "your AI-assisted day, written for you", keep "Claude" out of the name, and treat first-party absorption as the thing to outrun.

**Target user (one sentence).** A Mac-based professional developer who runs several Claude Code sessions a day, often across git worktrees, and has to account for their work (standups, weekly updates, client billing or performance reviews) but cannot reconstruct it from memory, git log or scattered sessions.

---

## Appendix A. Data-source facts relevant to feasibility

- **Claude Code transcripts** (CLI, VS Code extension, Desktop Code tab): JSONL under `~/.claude/projects/<encoded-cwd>/<session-uuid>.jsonl`, plaintext, 30-day retention by default (`cleanupPeriodDays`, minimum 1, not surfaced in `/config`) ([data usage](https://code.claude.com/docs/en/data-usage); [#59248](https://github.com/anthropics/claude-code/issues/59248)). The line format is internal and changes between versions (see 4.4).
- **Hooks** ([docs](https://code.claude.com/docs/en/hooks)): `SessionStart`, `SessionEnd`, `Stop`, `UserPromptSubmit`, `PostToolUse` and others. Payloads include `session_id`, `transcript_path` and `cwd`. `SessionEnd` is observational and cannot block.
- **Claude Desktop, official layout** (documented for the third-party "3P" variant, directory `Claude-3p`; [docs](https://claude.com/docs/third-party/claude-desktop/data-storage)): `claude-code-sessions/` holds session records (working folder, settings, title, sometimes a short summary) while the transcripts remain in `~/.claude/projects`; `local-agent-mode-sessions/` holds Cowork and Chat sessions as `local_<uuid>.json` plus a working directory and an HMAC-chained `audit.jsonl`; Cowork memory is Markdown; artifacts and scheduled-task outputs go to `~/Claude/`. Conversations are not encrypted at rest beyond FileVault. For standard Claude Desktop, Claudoscope reads `~/Library/Application Support/Claude/` per its README [layout not confirmed in official docs I could reach].
- **Regular Claude chats** (claude.ai, and Desktop signed in to Anthropic): stored server-side; the user-initiated export is Settings > Privacy > Export (emailed link, JSON) [secondary sources]. No local live transcript was documented.
- **Claude Code on the web / cloud sessions:** run on Anthropic infrastructure; `claude --teleport` pulls them to local [secondary sources].
- **Git:** Claude Code now appends a Claude-Session link to commits by default (`attribution.sessionUrl: false` disables) ([HN](https://news.ycombinator.com/item?id=49515667)) [Unverified]. Useful for linking commits to sessions; the link itself is private to the user.
- **Other agents:** Copilot CLI keeps sessions in `~/.copilot/session-state` ([brag-sheet](https://github.com/github/awesome-copilot/blob/main/skills/brag-sheet/SKILL.md)); ccusage, agentsview and Entire document support for many more CLIs.
- **Apple on-device model:** 8,192-token context window; the server model on Private Cloud Compute has a larger context and is free to developers under 2M first-time downloads, with distribution conditions not stated ([WWDC26 session 241](https://developer.apple.com/videos/play/wwdc2026/241/); first-gen: [WWDC25 session 286](https://developer.apple.com/videos/play/wwdc2025/286/)). The framework can also plug in Claude or Gemini via a Swift package; the developer handles auth and billing.

## Appendix B. Method, limitations and source quality

- **Retrieved:** 2026-10-06 via WebSearch and WebFetch. Dozens of GitHub API reads, roughly 30 HN threads, vendor pricing pages, Anthropic and Apple documentation, and a handful of blog posts.
- **Source tiers.** Tier 1 (primary): vendor docs and pricing pages, GitHub API, HN thread pages, Anthropic and Apple pages. Tier 2 (secondary): blogs, dev.to, news. Tier 3 (aggregators and SEO statistics): flagged [Unverified] and not relied on.
- **Fetch-tool caveat:** pages are summarised by a small model. I re-verified the eight quotes used with exact-string checks, but other paraphrased details (comment themes, feature lists) may contain summarisation error.
- **Blocked or unavailable:** Reddit; HN Algolia API; X post pages; official Reflect pricing (404); SpecStory pricing (404); Standuply paid prices (did not load).
- **Not researched:** Windows and Linux, enterprise sales, App Store ranking and download data, paid-acquisition cost, the long tail of 2026 Show HNs, legal review of the Consumer Terms beyond the Claude Code compliance page.
- **Star counts** measure attention, not active users. Closed-source apps show no counts.
- **Confidence summary:** High on the existence and traction of competitors, on the 30-day purge and its complaint volume, and on credential and naming rules. Medium-High on regular Claude Desktop chats being server-side (secondary sources only). Medium on demand for narrative standups (many builders, few adopters). Low on sizing, the timing window, and what Anthropic will ship next.

## Appendix C. Cheap validation before building (suggested)

1. **Reddit pass (about 30 minutes, manual):** search r/ClaudeAI, r/ClaudeCode, r/macapps, r/productivity and r/ExperiencedDevs for "standup", "brag doc", "what did I do", "session history", "30 days", "Dayflow", "Contextify". Record counts and top complaints.
2. **Ten conversations** with heavy Claude Code users (five or more sessions a day): how do you write standups today, what did you lose to the 30-day purge, would you install a Mac app or use a skill, what would you refuse to send to an LLM.
3. **One-week spike:** parse `~/.claude/projects` into a daily timeline and a draft; compare against Dayflow and clerk on your own week; measure how much you edit the draft.
4. **Kill criteria to pre-register:** for example, fewer than about 4 of 10 testers prefer the draft over a free skill, or the draft needs heavy editing even with evidence links, or Anthropic ships a cross-day recap.
